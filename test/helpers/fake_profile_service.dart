import 'package:puzzle_cards/features/profile/domain/profile_service.dart';

/// In-memory [ProfileService] fake for tests — no Hive needed.
class FakeProfileService implements ProfileService {
  FakeProfileService([this.name = '']);

  @override
  String name;

  @override
  Future<void> saveName(String name) async {
    this.name = name;
  }
}
