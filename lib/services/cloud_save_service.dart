import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import '../features/levels/domain/entities/level.dart';
import '../game/game_progress_manager.dart';

class CloudSaveService {
  static final CloudSaveService _instance = CloudSaveService._();
  factory CloudSaveService() => _instance;
  CloudSaveService._();

  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  User? get currentUser => _auth.currentUser;

  Future<void> signInAnonymously() async {
    try {
      // Don't sign in if we already are
      if (_auth.currentUser != null) return;
      
      final userCredential = await _auth.signInAnonymously();
      debugPrint("CloudSaveService: Signed in as ${userCredential.user?.uid}");
    } catch (e) {
      debugPrint("CloudSaveService Auth Error: $e");
    }
  }

  Future<void> backupWallet(int coins) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      await _firestore.collection('users').doc(user.uid).set(
        {'coins': coins, 'lastSynced': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("CloudSaveService Wallet Backup Error: $e");
    }
  }

  Future<void> backupProgress(GameProgress progress, List<Level> levels) async {
    final user = _auth.currentUser;
    if (user == null) return;
    try {
      final completedLevelIds = levels.where((l) => l.isCompleted).map((l) => l.id).toList();
      
      await _firestore.collection('users').doc(user.uid).set(
        {
          'totalStars': progress.totalStars,
          'completedCount': progress.completedCount,
          'completedLevelIds': completedLevelIds,
          'lastSynced': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("CloudSaveService Progress Backup Error: $e");
    }
  }
}
