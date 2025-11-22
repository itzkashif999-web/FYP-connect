import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  // API endpoint for the Ollama backend server
  final String _apiUrl = 'http://localhost:5000/recommend';

  // Flag to control whether to use AI recommendations or fallback to pattern matching
  final bool _useAiRecommendations = true;

  /// Fetches all supervisor profiles from Firestore
  Future<List<Map<String, dynamic>>> getAllSupervisors() async {
    final querySnapshot =
        await _firestore.collection('supervisor_profiles').get();
    return querySnapshot.docs
        .map((doc) => _sanitizeFirestoreData(doc.data()))
        .toList();
  }

  /// Fetches the current student's profile
  Future<Map<String, dynamic>?> getCurrentStudentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('student_profiles').doc(user.uid).get();
    return doc.exists ? _sanitizeFirestoreData(doc.data()!) : null;
  }

  /// Sanitizes Firestore data by converting Timestamps to ISO strings
  /// This makes the data JSON-serializable for API calls
  Map<String, dynamic> _sanitizeFirestoreData(Map<String, dynamic> data) {
    final sanitized = <String, dynamic>{};
    
    data.forEach((key, value) {
      if (value is Timestamp) {
        // Convert Firestore Timestamp to ISO 8601 string
        sanitized[key] = value.toDate().toIso8601String();
      } else if (value is Map) {
        // Recursively sanitize nested maps
        sanitized[key] = _sanitizeFirestoreData(Map<String, dynamic>.from(value));
      } else if (value is List) {
        // Handle lists that might contain Timestamps
        sanitized[key] = value.map((item) {
          if (item is Timestamp) {
            return item.toDate().toIso8601String();
          } else if (item is Map) {
            return _sanitizeFirestoreData(Map<String, dynamic>.from(item));
          }
          return item;
        }).toList();
      } else {
        sanitized[key] = value;
      }
    });
    
    return sanitized;
  }

  /// Calculates match score between student and supervisor
  /// Higher score means better match
  int calculateMatchScore(
    Map<String, dynamic> student,
    Map<String, dynamic> supervisor,
  ) {
    int score = 0;

    // Extract interests and skills from student profile
    List<String> studentInterests = _extractList(student['interest']);
    List<String> studentSkills = _extractList(student['skills']);

    // Extract specialization, preference areas, and project history from supervisor
    String supervisorSpecialization = supervisor['specialization'] ?? '';
    List<String> supervisorPreferenceAreas = _extractList(
      supervisor['preferenceAreas'],
    );
    List<String> supervisorProjectHistory = _extractList(
      supervisor['projectHistoryCategories'],
    );

    // Match student interests with supervisor specialization (highest weight)
    for (String interest in studentInterests) {
      if (supervisorSpecialization.toLowerCase().contains(
        interest.toLowerCase(),
      )) {
        score += 15;
      }
    }

    // Match student interests with supervisor preference areas
    for (String interest in studentInterests) {
      for (String area in supervisorPreferenceAreas) {
        if (area.toLowerCase().contains(interest.toLowerCase()) ||
            interest.toLowerCase().contains(area.toLowerCase())) {
          score += 10;
        }
      }
    }

    // Match student skills with supervisor project history
    for (String skill in studentSkills) {
      for (String project in supervisorProjectHistory) {
        if (project.toLowerCase().contains(skill.toLowerCase()) ||
            skill.toLowerCase().contains(project.toLowerCase())) {
          score += 5;
        }
      }
    }

    return score;
  }

  /// Helper method to split comma-separated string into list
  List<String> _extractList(dynamic value) {
    if (value == null) return [];
    if (value is List) return List<String>.from(value);
    if (value is String) {
      return value
          .split(',')
          .map((item) => item.trim())
          .where((item) => item.isNotEmpty)
          .toList();
    }
    return [];
  }

  /// Returns recommended supervisors sorted by match score
  /// Uses Ollama AI if available, otherwise falls back to pattern matching
  Future<List<Map<String, dynamic>>> getRecommendedSupervisors() async {
    final student = await getCurrentStudentProfile();
    if (student == null) return [];

    final supervisors = await getAllSupervisors();
    List<Map<String, dynamic>> recommendations = [];
    String recommendationSource = 'pattern_matching'; // Track the source

    if (_useAiRecommendations) {
      try {
        // Try to use Ollama AI recommendations
        final aiRecommendations = await _getOllamaRecommendations(
          student,
          supervisors,
        );

        // If we got AI recommendations, use them
        if (aiRecommendations.isNotEmpty) {
          print("✅ Using AI-generated recommendations");
          recommendations = aiRecommendations;
          recommendationSource = 'ai_rag';
        }
      } catch (e) {
        print("❌ AI recommendation error: $e");
        // If AI recommendations fail, we'll fall back to pattern matching
      }
    }

    // Fallback to pattern matching if AI isn't available or fails
    if (recommendations.isEmpty) {
      print("⚠️ Using fallback pattern-matching recommendations");
      recommendations = await _getPatternMatchingRecommendations(
        student,
        supervisors,
      );
      recommendationSource = 'pattern_matching';
    }

    // Add the recommendation source to each recommendation
    recommendations = recommendations.map((rec) {
      return {
        ...rec,
        'recommendationSource': recommendationSource,
      };
    }).toList();

    // Filter out supervisors with 0% matchPercentage, then return top 5
    final filtered =
        recommendations.where((rec) {
          final percent = rec['matchPercentage'] ?? 0;
          return percent > 0;
        }).toList();
    return filtered.take(5).toList();
  }

  /// Gets recommendations using the Ollama LLM through the Python backend
  Future<List<Map<String, dynamic>>> _getOllamaRecommendations(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> supervisors,
  ) async {
    try {
      print("📡 Requesting AI recommendations from local server...");

      // Prepare the request payload
      final payload = jsonEncode({
        'student': student,
        'supervisors': supervisors,
      });

      // Set headers for the request
      final headers = {'Content-Type': 'application/json'};

      // Call the backend API
      final response = await http
          .post(Uri.parse(_apiUrl), headers: headers, body: payload)
          .timeout(const Duration(seconds: 30)); // Set timeout

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = List<Map<String, dynamic>>.from(
          data['recommendations'] ?? [],
        );

        // Return empty list if no recommendations
        if (recommendations.isEmpty) {
          print(
            "⚠️ AI returned no recommendations, falling back to pattern matching",
          );
          return [];
        }

        print(
          "✅ Received ${recommendations.length} AI-generated recommendations",
        );
        return recommendations;
      } else {
        print("❌ API error: ${response.statusCode} - ${response.body}");
        return [];
      }
    } catch (e) {
      print("❌ Error getting AI recommendations: $e");
      return [];
    }
  }

  /// Gets recommendations using the original pattern matching algorithm
  Future<List<Map<String, dynamic>>> _getPatternMatchingRecommendations(
    Map<String, dynamic> student,
    List<Map<String, dynamic>> supervisors,
  ) async {
    // Calculate match scores
    List<Map<String, dynamic>> recommendationsWithScores =
        supervisors.map((supervisor) {
          final score = calculateMatchScore(student, supervisor);
          final matchDetails = _getMatchDetails(student, supervisor);
          return {
            ...supervisor,
            'matchScore': score,
            'matchPercentage': _calculatePercentage(score),
            'matchDetails': matchDetails, // Add detailed breakdown
            'confidenceScore': _calculateConfidence(score), // Add confidence level
          };
        }).toList();

    // Sort by score (highest first)
    recommendationsWithScores.sort((a, b) => b['matchScore'] - a['matchScore']);

    return recommendationsWithScores;
  }

  /// Get detailed match breakdown
  Map<String, dynamic> _getMatchDetails(
    Map<String, dynamic> student,
    Map<String, dynamic> supervisor,
  ) {
    List<String> studentInterests = _extractList(student['interest']);
    List<String> studentSkills = _extractList(student['skills']);
    String supervisorSpecialization = supervisor['specialization'] ?? '';
    List<String> supervisorPreferenceAreas = _extractList(
      supervisor['preferenceAreas'],
    );
    List<String> supervisorProjectHistory = _extractList(
      supervisor['projectHistoryCategories'],
    );

    List<String> matchedInterests = [];
    List<String> matchedSkills = [];
    List<String> matchedAreas = [];

    // Find matched interests
    for (String interest in studentInterests) {
      if (supervisorSpecialization.toLowerCase().contains(
        interest.toLowerCase(),
      )) {
        matchedInterests.add(interest);
      }
    }

    // Find matched preference areas
    for (String interest in studentInterests) {
      for (String area in supervisorPreferenceAreas) {
        if (area.toLowerCase().contains(interest.toLowerCase()) ||
            interest.toLowerCase().contains(area.toLowerCase())) {
          matchedAreas.add(area);
        }
      }
    }

    // Find matched skills
    for (String skill in studentSkills) {
      for (String project in supervisorProjectHistory) {
        if (project.toLowerCase().contains(skill.toLowerCase()) ||
            skill.toLowerCase().contains(project.toLowerCase())) {
          matchedSkills.add(skill);
        }
      }
    }

    return {
      'matchedInterests': matchedInterests,
      'matchedSkills': matchedSkills,
      'matchedAreas': matchedAreas,
    };
  }

  /// Convert score to percentage with a more robust scale
  /// Score breakdown:
  /// 0-10: Poor match (0-25%)
  /// 11-20: Fair match (26-50%)
  /// 21-35: Good match (51-75%)
  /// 36-50: Excellent match (76-95%)
  int _calculatePercentage(int score) {
    if (score == 0) return 0;
    if (score <= 10) return (score / 10 * 25).round();
    if (score <= 20) return 25 + ((score - 10) / 10 * 25).round();
    if (score <= 35) return 50 + ((score - 20) / 15 * 25).round();
    // For scores above 35, scale to 76-95%
    final percentage = 75 + ((score - 35) / 15 * 20).round();
    return percentage > 95 ? 95 : percentage;
  }

  /// Calculate confidence level for the match
  String _calculateConfidence(int score) {
    if (score >= 36) return 'Excellent';
    if (score >= 21) return 'Good';
    if (score >= 11) return 'Fair';
    return 'Low';
  }
}
