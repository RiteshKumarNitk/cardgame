import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import '../features/levels/domain/entities/level.dart';
import '../game/game_progress_manager.dart';
import 'analytics_service.dart';

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
      AnalyticsService().setUserId(userCredential.user?.uid);
      AnalyticsService().logEvent(AnalyticsService.authSignedIn);
    } catch (e) {
      debugPrint("CloudSaveService Auth Error: $e");
      await AnalyticsService().recordError(
        e,
        StackTrace.current,
        reason: 'Anonymous sign-in failed',
      );
    }
  }

  /// Writes [coins] to the player's cloud document. Transient failures
  /// (offline, throttling) retry once after a short delay rather than
  /// dropping the save; real errors are logged and swallowed so a backup
  /// failure never interrupts gameplay.
  Future<void> backupWallet(int coins) => _writeBackup(() async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;
    if (auth == null || firestore == null || user == null) return;
    await firestore.collection('users').doc(user.uid).set(
      {'coins': coins, 'lastSynced': FieldValue.serverTimestamp()},
      SetOptions(merge: true),
    );
  });

  /// Writes [progress] to the local player's cloud document. Transient
  /// failures retry once; real errors are logged, never surfaced.
  Future<void> backupProgress(GameProgress progress, List<Level> levels) async {
    final auth = _auth;
    final firestore = _firestore;
    final user = auth?.currentUser;
    if (auth == null || firestore == null || user == null) return;

    final completedLevelIds = levels
        .where((l) => l.isCompleted)
        .map((l) => l.id)
        .toList();

    await _writeBackup(() async {
      await firestore.collection('users').doc(user.uid).set(
        {
          'totalStars': progress.totalStars,
          'completedCount': progress.completedCount,
          'completedLevelIds': completedLevelIds,
          'lastSynced': FieldValue.serverTimestamp(),
        },
        SetOptions(merge: true),
      );
    });
  }

  /// Runs [write] once, retrying exactly once after a short delay if it
  /// throws (covers transient offline/throttle failures), and records the
  /// error for monitoring. Never rethrows.
  Future<void> _writeBackup(Future<void> Function() write) async {
    bool failed = false;
    Future<void> attempt() async {
      try {
        await write();
      } catch (e, st) {
        failed = true;
        debugPrint('CloudSaveService Backup Error: $e');
        await AnalyticsService().recordError(
          e,
          st,
          reason: 'Cloud save failed',
        );
      }
    }

    await attempt();
    if (failed) {
      await Future<void>.delayed(const Duration(seconds: 1));
      await attempt();
    }
  }
}
