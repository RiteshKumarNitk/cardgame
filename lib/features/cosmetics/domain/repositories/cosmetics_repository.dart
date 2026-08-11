import '../entities/player_cosmetics.dart';

/// Persistence for the player's cosmetic loadout. An interface so tests
/// can supply an in-memory fake instead of touching real Hive storage.
abstract interface class CosmeticsRepository {
  Future<PlayerCosmetics> load();
  Future<void> save(PlayerCosmetics cosmetics);
}
