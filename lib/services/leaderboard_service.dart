import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
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

  /// True only when a Firebase App has been initialized. Guards every
  /// method so the service is a safe no-op on platforms where Firebase
  /// was never bootstrapped (web, widget tests, failed init) instead of
  /// throwing `[core/no-app]`.
  static bool get _firebaseReady {
    try {
      return Firebase.apps.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  FirebaseAuth? get _auth => _firebaseReady ? FirebaseAuth.instance : null;
  FirebaseFirestore? get _firestore =>
      _firebaseReady ? FirebaseFirestore.instance : null;

  Future<void> submitTimeAttackScore(int timeRemaining) async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;
    if (auth == null || firestore == null || user == null) return;

    try {
      final docRef = firestore.collection('leaderboard').doc(user.uid);
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
    final firestore = _firestore;
    if (firestore == null) return [];

    try {
      final snapshot = await firestore
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
