import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

/// The player's profile: currently a display name, used on the Profile
/// screen and to label the player's leaderboard entries. An interface so
/// tests can supply an in-memory fake instead of touching real storage.
abstract interface class ProfileService {
  /// The player's chosen display name ('' when never set).
  String get name;

  Future<void> saveName(String name);
}

class HiveProfileService implements ProfileService {
  Box get _box => Hive.box(AppConstants.profileBoxName);

  @override
  String get name =>
      (_box.get(AppConstants.profileNameKey) as String?)?.trim() ?? '';

  @override
  Future<void> saveName(String name) async {
    await _box.put(AppConstants.profileNameKey, name.trim());
  }
}
