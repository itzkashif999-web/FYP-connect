import 'dart:convert';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:http/http.dart' as http;

/// Service to track recommendations and calculate precision metrics
class RecommendationTrackingService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final String _metricsUrl = 'http://localhost:5000/metrics/precision';

  /// Track when recommendations are shown to a student
  Future<void> trackRecommendationsShown({
    required List<Map<String, dynamic>> recommendations,
    required String source, // 'ai_rag' or 'pattern_matching'
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Extract supervisor IDs in order
      final supervisorIds = recommendations.map((r) => r['id'] as String).toList();

      await _firestore.collection('recommendation_tracking').add({
        'studentId': user.uid,
        'supervisorIds': supervisorIds,
        'source': source,
        'timestamp': FieldValue.serverTimestamp(),
        'shown': true,
        'accepted': false,
      });

      print('📊 Tracked ${recommendations.length} recommendations ($source) for student ${user.uid}');
    } catch (e) {
      print('❌ Error tracking recommendations: $e');
    }
  }

  /// Track when a student accepts/selects a supervisor
  Future<void> trackSupervisorAccepted({
    required String supervisorId,
  }) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      // Find the most recent recommendations shown to this student
      final trackingDocs = await _firestore
          .collection('recommendation_tracking')
          .where('studentId', isEqualTo: user.uid)
          .where('accepted', isEqualTo: false)
          .orderBy('timestamp', descending: true)
          .limit(1)
          .get();

      if (trackingDocs.docs.isEmpty) {
        print('⚠️ No tracked recommendations found for this student');
        return;
      }

      // Update with accepted supervisor
      final docId = trackingDocs.docs.first.id;
      await _firestore.collection('recommendation_tracking').doc(docId).update({
        'acceptedSupervisorId': supervisorId,
        'accepted': true,
        'acceptedAt': FieldValue.serverTimestamp(),
      });

      print('✅ Tracked supervisor acceptance: $supervisorId');
    } catch (e) {
      print('❌ Error tracking supervisor acceptance: $e');
    }
  }

  /// Calculate precision metrics from tracked data
  Future<Map<String, dynamic>?> calculatePrecisionMetrics({
    int k = 5,
  }) async {
    try {
      // Fetch all accepted recommendations from Firestore
      final trackingDocs = await _firestore
          .collection('recommendation_tracking')
          .where('accepted', isEqualTo: true)
          .get();

      if (trackingDocs.docs.isEmpty) {
        print('⚠️ No accepted recommendations found for precision calculation');
        return null;
      }

      // Format data for backend
      final outcomes = trackingDocs.docs.map((doc) {
        final data = doc.data();
        return {
          'recommendations': List<String>.from(data['supervisorIds'] ?? []),
          'accepted_supervisor_id': data['acceptedSupervisorId'],
          'source': data['source'] ?? 'unknown',
        };
      }).toList();

      print('📊 Calculating precision for ${outcomes.length} outcomes');

      // Call backend to calculate metrics
      final response = await http.post(
        Uri.parse(_metricsUrl),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'outcomes': outcomes,
          'k': k,
        }),
      );

      if (response.statusCode == 200) {
        final metrics = jsonDecode(response.body);
        print('✅ Precision@$k: ${metrics['percentage']}');
        return metrics;
      } else {
        print('❌ Error from metrics API: ${response.statusCode}');
        return null;
      }
    } catch (e) {
      print('❌ Error calculating precision metrics: $e');
      return null;
    }
  }

  /// Get summary statistics for display
  Future<Map<String, dynamic>> getTrackingSummary() async {
    try {
      final trackingDocs = await _firestore
          .collection('recommendation_tracking')
          .get();

      final total = trackingDocs.docs.length;
      final accepted = trackingDocs.docs
          .where((doc) => doc.data()['accepted'] == true)
          .length;

      final aiDocs = trackingDocs.docs
          .where((doc) => doc.data()['source'] == 'ai_rag')
          .toList();
      final patternDocs = trackingDocs.docs
          .where((doc) => doc.data()['source'] == 'pattern_matching')
          .toList();

      final aiAccepted = aiDocs
          .where((doc) => doc.data()['accepted'] == true)
          .length;
      final patternAccepted = patternDocs
          .where((doc) => doc.data()['accepted'] == true)
          .length;

      return {
        'total_shown': total,
        'total_accepted': accepted,
        'acceptance_rate': total > 0 ? (accepted / total * 100).toStringAsFixed(1) : '0.0',
        'ai_rag_shown': aiDocs.length,
        'ai_rag_accepted': aiAccepted,
        'ai_acceptance_rate': aiDocs.isNotEmpty 
            ? (aiAccepted / aiDocs.length * 100).toStringAsFixed(1) 
            : '0.0',
        'pattern_shown': patternDocs.length,
        'pattern_accepted': patternAccepted,
        'pattern_acceptance_rate': patternDocs.isNotEmpty 
            ? (patternAccepted / patternDocs.length * 100).toStringAsFixed(1) 
            : '0.0',
      };
    } catch (e) {
      print('❌ Error getting tracking summary: $e');
      return {};
    }
  }
}
