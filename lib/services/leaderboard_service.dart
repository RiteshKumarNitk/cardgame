import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

class LeaderboardEntry {
  final String uid;
  final int score;
  final DateTime timestamp;

  LeaderboardEntry({required this.uid, required this.score, required this.timestamp});

  factory LeaderboardEntry.fromMap(Map<String, dynamic> data) {
    return LeaderboardEntry(
      uid: data['uid'] ?? 'Anonymous',
      score: data['score'] ?? 0,
      timestamp: (data['timestamp'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }
}

class LeaderboardService {
  static final LeaderboardService _instance = LeaderboardService._();
  factory LeaderboardService() => _instance;
  LeaderboardService._();

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  Future<void> submitTimeAttackScore(int timeRemaining) async {
    final user = _auth.currentUser;
    if (user == null) return;

    try {
      final docRef = _firestore.collection('leaderboard').doc(user.uid);
      final doc = await docRef.get();
      
      if (doc.exists) {
        final currentBest = doc.data()?['score'] ?? 0;
        // Keep the highest score (most time remaining)
        if (timeRemaining > currentBest) {
          await docRef.update({
            'score': timeRemaining,
            'timestamp': FieldValue.serverTimestamp(),
          });
        }
      } else {
        await docRef.set({
          'uid': user.uid,
          'score': timeRemaining,
          'timestamp': FieldValue.serverTimestamp(),
        });
      }
    } catch (e) {
      debugPrint("Leaderboard Submit Error: $e");
    }
  }

  Future<List<LeaderboardEntry>> getTopSolvers() async {
    try {
      final snapshot = await _firestore
          .collection('leaderboard')
          .orderBy('score', descending: true)
          .limit(50)
          .get();

      return snapshot.docs
          .map((doc) => LeaderboardEntry.fromMap(doc.data()))
          .toList();
    } catch (e) {
      debugPrint("Leaderboard Fetch Error: $e");
      return [];
    }
  }
}
