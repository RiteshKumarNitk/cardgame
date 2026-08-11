import 'package:puzzle_cards/features/cosmetics/domain/entities/player_cosmetics.dart';
import 'package:puzzle_cards/features/cosmetics/domain/repositories/cosmetics_repository.dart';

/// In-memory [CosmeticsRepository] fake shared by cosmetics tests —
/// avoids touching real Hive storage.
class FakeCosmeticsRepository implements CosmeticsRepository {
  FakeCosmeticsRepository([PlayerCosmetics? initial])
    : _saved = initial ?? PlayerCosmetics.defaults();

  PlayerCosmetics _saved;

  /// The last persisted loadout, for round-trip assertions.
  PlayerCosmetics get saved => _saved;

  @override
  Future<PlayerCosmetics> load() async => _saved;

  @override
  Future<void> save(PlayerCosmetics cosmetics) async {
    _saved = cosmetics;
  }
}
