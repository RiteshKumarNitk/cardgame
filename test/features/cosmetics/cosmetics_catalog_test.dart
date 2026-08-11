// Catalog invariants: unique ids, exactly one free default per category,
// positive prices everywhere else, and safe lookups that fall back to
// the default instead of throwing on unknown ids.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/cosmetics/domain/services/cosmetics_catalog.dart';

void main() {
  test('ids are unique within each category', () {
    String? duplicate(Iterable<String> ids) {
      final seen = <String>{};
      for (final id in ids) {
        if (!seen.add(id)) return id;
      }
      return null;
    }

    expect(duplicate(CosmeticsCatalog.frames.map((f) => f.id)), isNull);
    expect(duplicate(CosmeticsCatalog.pieceStyles.map((p) => p.id)), isNull);
    expect(duplicate(CosmeticsCatalog.avatars.map((a) => a.id)), isNull);
  });

  test('exactly one free default item per category, positive prices elsewhere', () {
    int freeCount(List<int> prices) => prices.where((p) => p == 0).length;

    expect(freeCount(CosmeticsCatalog.frames.map((f) => f.price).toList()), 1);
    expect(
      freeCount(CosmeticsCatalog.pieceStyles.map((p) => p.price).toList()),
      1,
    );
    expect(
      freeCount(CosmeticsCatalog.avatars.map((a) => a.price).toList()),
      1,
    );

    for (final price in [
      ...CosmeticsCatalog.frames.map((f) => f.price),
      ...CosmeticsCatalog.pieceStyles.map((p) => p.price),
      ...CosmeticsCatalog.avatars.map((a) => a.price),
    ]) {
      expect(price, greaterThanOrEqualTo(0));
    }
  });

  test('the free item of each category is the player default', () {
    expect(
      CosmeticsCatalog.frames.firstWhere((f) => f.price == 0).id,
      'classic',
    );
    expect(
      CosmeticsCatalog.pieceStyles.firstWhere((p) => p.price == 0).id,
      'classic',
    );
    expect(
      CosmeticsCatalog.avatars.firstWhere((a) => a.price == 0).id,
      'default',
    );
  });

  test('lookups fall back to the first (default) item for unknown ids', () {
    expect(CosmeticsCatalog.frameById('nope').id, 'classic');
    expect(CosmeticsCatalog.pieceStyleById('nope').id, 'classic');
    expect(CosmeticsCatalog.avatarById('nope').id, 'default');
  });

  test('the catalog gives the wallet a meaningful long-term sink', () {
    final totalSink =
        CosmeticsCatalog.frames.fold<int>(0, (s, f) => s + f.price) +
        CosmeticsCatalog.pieceStyles.fold<int>(0, (s, p) => s + p.price) +
        CosmeticsCatalog.avatars.fold<int>(0, (s, a) => s + a.price);

    // Everything costs thousands of coins total, so the economy has
    // something to absorb earnings over the long run.
    expect(totalSink, greaterThan(3000));
  });
}
