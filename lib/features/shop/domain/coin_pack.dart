/// A purchasable coin bundle. Purchases are handled by `PurchaseService`
/// (RevenueCat): each pack maps to a store package whose identifier — or
/// underlying product identifier — equals [CoinPack.id], e.g. a product
/// `pack_small`. [priceLabel] is display-only; the real price comes from
/// the store. When RevenueCat isn't configured (dev/web), the Shop page
/// falls back to granting coins locally.
class CoinPack {
  const CoinPack({
    required this.id,
    required this.coins,
    required this.priceLabel,
    this.bestValue = false,
  });

  final String id;
  final int coins;
  final String priceLabel;
  final bool bestValue;
}

const List<CoinPack> coinPacks = [
  CoinPack(id: 'pack_small', coins: 100, priceLabel: r'$0.99'),
  CoinPack(
    id: 'pack_medium',
    coins: 550,
    priceLabel: r'$3.99',
    bestValue: true,
  ),
  CoinPack(id: 'pack_large', coins: 1200, priceLabel: r'$7.99'),
];
