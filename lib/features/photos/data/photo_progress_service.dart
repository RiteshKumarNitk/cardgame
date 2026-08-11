import 'package:hive/hive.dart';

import '../../../core/constants/app_constants.dart';

/// Persistence for the player's best stars per photo puzzle. An interface
/// so tests can supply an in-memory fake.
abstract interface class PhotoProgressService {
  Future<Map<String, int>> loadBestStars();
  Future<void> saveBestStars(String photoId, int stars);
}

class HivePhotoProgressService implements PhotoProgressService {
  Box get _box => Hive.box(AppConstants.photosBoxName);

  @override
  Future<Map<String, int>> loadBestStars() async {
    final raw = _box.get(AppConstants.photosBestStarsKey);
    if (raw is Map) {
      return raw.map(
        (key, value) => MapEntry(key.toString(), (value as num).toInt()),
      );
    }
    return {};
  }

  @override
  Future<void> saveBestStars(String photoId, int stars) async {
    final current = await loadBestStars();
    final next = Map<String, int>.from(current)..[photoId] = stars;
    await _box.put(AppConstants.photosBestStarsKey, next);
  }
}
