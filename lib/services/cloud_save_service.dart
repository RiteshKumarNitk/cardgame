import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../features/levels/domain/entities/level.dart';
import '../game/game_progress_manager.dart';

class CloudSaveService {
  static final CloudSaveService _instance = CloudSaveService._();
  factory CloudSaveService() => _instance;
  CloudSaveService._();

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

  User? get currentUser => _auth?.currentUser;

  Future<void> signInAnonymously() async {
    final auth = _auth;
    if (auth == null) return;
    try {
      // Don't sign in if we already are
      if (auth.currentUser != null) return;

      final userCredential = await auth.signInAnonymously();
      debugPrint("CloudSaveService: Signed in as ${userCredential.user?.uid}");
    } catch (e) {
      debugPrint("CloudSaveService Auth Error: $e");
    }
  }

  Future<void> backupWallet(int coins) async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;
    if (auth == null || firestore == null || user == null) return;
    try {
      await firestore.collection('users').doc(user.uid).set(
        {'coins': coins, 'lastSynced': FieldValue.serverTimestamp()},
        SetOptions(merge: true),
      );
    } catch (e) {
      debugPrint("CloudSaveService Wallet Backup Error: $e");
    }
  }

  Future<void> backupProgress(GameProgress progress, List<Level> levels) async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;
    if (auth == null || firestore == null || user == null) return;
    try {
      final completedLevelIds = levels.where((l) => l.isCompleted).map((l) => l.id).toList();

      await firestore.collection('users').doc(user.uid).set(
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
