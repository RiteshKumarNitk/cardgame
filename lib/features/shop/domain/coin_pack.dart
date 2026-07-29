/// A purchasable coin bundle. Prices are display-only labels — there's no
/// real store/payment integration wired up (no App Store/Play Console
/// product IDs exist for this project), so buying one just credits the
/// wallet directly. Swap this out for real `in_app_purchase` products
/// when the app is actually being published.
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
