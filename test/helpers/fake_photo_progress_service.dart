import 'package:puzzle_cards/features/photos/data/photo_progress_service.dart';

/// In-memory [PhotoProgressService] for tests — no Hive needed.
class FakePhotoProgressService implements PhotoProgressService {
  final Map<String, int> bestStars = {};

  int saveCount = 0;

  @override
  Future<Map<String, int>> loadBestStars() async => Map.of(bestStars);

  @override
  Future<void> saveBestStars(String photoId, int stars) async {
    saveCount += 1;
    bestStars[photoId] = stars;
  }
}
