import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart';

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
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetches the current student's profile
  Future<Map<String, dynamic>?> getCurrentStudentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc =
        await _firestore.collection('student_profiles').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
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
        }
      } catch (e) {
        print("❌ AI recommendation error: $e");
        // If AI recommendations fail, we'll fall back to pattern matching
      }
    }

    // Fallback to pattern matching if AI isn't available or fails
    if (recommendations.isEmpty) {
      print("⚠️ Using fallback pattern-matching recommendations");
      recommendations = await _getPatternMatchingRecommendations(student, supervisors);
    }

    // Filter out supervisors with 0% matchPercentage, then return top 5
    final filtered = recommendations.where((rec) {
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
          return {
            ...supervisor,
            'matchScore': score,
            'matchPercentage': _calculatePercentage(score),
          };
        }).toList();

    // Sort by score (highest first)
    recommendationsWithScores.sort((a, b) => b['matchScore'] - a['matchScore']);

    return recommendationsWithScores;
  }

  /// Convert score to percentage (max score considered as 40)
  int _calculatePercentage(int score) {
    // Max score would be around 30-40 for perfect matches
    const maxScore = 40;
    final percentage = (score / maxScore * 100).round();
    // Cap at 99% to avoid overpromising
    return percentage > 99 ? 99 : percentage;
  }
}
