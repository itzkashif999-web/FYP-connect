import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class RecommendationService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Fetches all supervisor profiles from Firestore
  Future<List<Map<String, dynamic>>> getAllSupervisors() async {
    final querySnapshot = await _firestore.collection('supervisor_profiles').get();
    return querySnapshot.docs.map((doc) => doc.data()).toList();
  }

  /// Fetches the current student's profile
  Future<Map<String, dynamic>?> getCurrentStudentProfile() async {
    final user = _auth.currentUser;
    if (user == null) return null;

    final doc = await _firestore.collection('student_profiles').doc(user.uid).get();
    return doc.exists ? doc.data() : null;
  }

  /// Calculates match score between student and supervisor
  /// Higher score means better match
  int calculateMatchScore(Map<String, dynamic> student, Map<String, dynamic> supervisor) {
    int score = 0;
    
    // Extract interests and skills from student profile
    List<String> studentInterests = _extractList(student['interest']);
    List<String> studentSkills = _extractList(student['skills']);
    
    // Extract specialization, preference areas, and project history from supervisor
    String supervisorSpecialization = supervisor['specialization'] ?? '';
    List<String> supervisorPreferenceAreas = _extractList(supervisor['preferenceAreas']);
    List<String> supervisorProjectHistory = _extractList(supervisor['projectHistoryCategories']);
    
    // Match student interests with supervisor specialization (highest weight)
    for (String interest in studentInterests) {
      if (supervisorSpecialization.toLowerCase().contains(interest.toLowerCase())) {
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
      return value.split(',').map((item) => item.trim()).where((item) => item.isNotEmpty).toList();
    }
    return [];
  }

  /// Returns recommended supervisors sorted by match score
  Future<List<Map<String, dynamic>>> getRecommendedSupervisors() async {
    final student = await getCurrentStudentProfile();
    if (student == null) return [];
    
    final supervisors = await getAllSupervisors();
    
    // Calculate match scores
    List<Map<String, dynamic>> recommendationsWithScores = supervisors.map((supervisor) {
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