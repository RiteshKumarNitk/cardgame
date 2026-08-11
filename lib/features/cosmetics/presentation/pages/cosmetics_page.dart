import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../services/audio_service.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/press_scale.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../domain/entities/cosmetic_items.dart';
import '../../domain/entities/player_cosmetics.dart';
import '../../domain/services/cosmetics_catalog.dart';
import '../bloc/cosmetics_cubit.dart';
import '../widgets/cosmetic_previews.dart';

/// Which category the page opens on; parsed from the route param and
/// validated against the catalog so a stale deep link falls back to
/// frames instead of crashing.
enum CosmeticsCategory {
  frames('Board Frames', 'frame', 'board'),
  pieces('Piece Styles', 'piece', 'piece_style'),
  avatars('Avatars', 'avatar', 'avatar');

  const CosmeticsCategory(this.label, this.singularLabel, this.routeValue);

  final String label;
  final String singularLabel;
  final String routeValue;

  static CosmeticsCategory fromRoute(String? value) =>
      values.firstWhere((c) => c.routeValue == value, orElse: () => frames);
}

/// The cosmetics shop: buy and equip board frames, piece styles, and
/// avatars with coins. Tabs across the three categories; each item card
/// previews the item and offers Buy (with a live can-afford state) or
/// Equip once owned. Buying also equips immediately.
class CosmeticsPage extends StatefulWidget {
  const CosmeticsPage({super.key, this.initialCategory});

  /// Route-provided initial tab (null → frames).
  final CosmeticsCategory? initialCategory;

  @override
  State<CosmeticsPage> createState() => _CosmeticsPageState();
}

class _CosmeticsPageState extends State<CosmeticsPage> {
  late CosmeticsCategory _category;

  @override
  void initState() {
    super.initState();
    _category = widget.initialCategory ?? CosmeticsCategory.frames;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: GameBackground(
        showFloatingPieces: false,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                _CosmeticsTopBar(),
                const SizedBox(height: AppSpacing.md),
                _CategoryTabs(
                  selected: _category,
                  onSelected: (c) => setState(() => _category = c),
                ),
                const SizedBox(height: AppSpacing.md),
                Expanded(
                  child: BlocBuilder<CosmeticsCubit, PlayerCosmetics>(
                    builder: (context, cosmetics) {
                      final wallet = context.watch<WalletCubit>().state;
                      return GridView.builder(
                        padding: EdgeInsets.zero,
                        physics: const BouncingScrollPhysics(),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 2,
                              childAspectRatio: 0.78,
                              crossAxisSpacing: AppSpacing.md,
                              mainAxisSpacing: AppSpacing.md,
                            ),
                        itemCount: _itemsFor(_category).length,
                        itemBuilder: (context, index) {
                          final item = _itemsFor(_category)[index];
                          return _CosmeticItemCard(
                            item: item,
                            owned: cosmetics.owns(item),
                            equipped: cosmetics.isEquipped(item),
                            affordable: wallet >= item.price,
                            onTap: () => _onItemTap(item),
                          );
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  List<CosmeticItem> _itemsFor(CosmeticsCategory category) => switch (category) {
    CosmeticsCategory.frames => CosmeticsCatalog.frames,
    CosmeticsCategory.pieces => CosmeticsCatalog.pieceStyles,
    CosmeticsCategory.avatars => CosmeticsCatalog.avatars,
  };

  Future<void> _onItemTap(CosmeticItem item) async {
    final cubit = context.read<CosmeticsCubit>();
    if (cubit.owns(item)) {
      if (!cubit.state.isEquipped(item)) {
        await cubit.equip(item);
        AudioService().playPieceSnap();
      }
      return;
    }

    final messenger = ScaffoldMessenger.of(context);
    final success = await cubit.buy(
      item,
      (amount) => context.read<WalletCubit>().spendCoins(amount),
    );
    if (!mounted) return;
    if (success) {
      AudioService().playCoinReward();
      messenger.showSnackBar(
        SnackBar(content: Text('${item.name} equipped!')),
      );
    } else {
      messenger.showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Top bar: back — title — coin balance
/// ────────────────────────────────────────────────────────────────────
class _CosmeticsTopBar extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        CircleIconButton(
          icon: Icons.arrow_back_rounded,
          onTap: () {
            if (context.canPop()) {
              context.pop();
            } else {
              context.goNamed(RouteNames.home);
            }
          },
        ),
        const SizedBox(width: AppSpacing.md),
        Expanded(
          child: Text(
            'Cosmetics',
            style: Theme.of(
              context,
            ).textTheme.titleMedium?.copyWith(color: AppColors.textDark),
          ),
        ),
        BlocBuilder<WalletCubit, int>(
          builder: (context, coins) => StatChip(
            icon: Icons.monetization_on_rounded,
            value: formatThousands(coins),
            iconColor: AppColors.accent,
          ),
        ),
      ],
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// Segmented category tabs (Frames / Pieces / Avatars)
/// ────────────────────────────────────────────────────────────────────
class _CategoryTabs extends StatelessWidget {
  const _CategoryTabs({required this.selected, required this.onSelected});

  final CosmeticsCategory selected;
  final ValueChanged<CosmeticsCategory> onSelected;

  @override
  Widget build(BuildContext context) {
    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.xs),
      child: Row(
        children: [
          for (final category in CosmeticsCategory.values) ...[
            if (category != CosmeticsCategory.values.first)
              const SizedBox(width: AppSpacing.xs),
            Expanded(
              child: _TabPill(
                label: category.label,
                selected: category == selected,
                onTap: () => onSelected(category),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _TabPill extends StatelessWidget {
  const _TabPill({
    required this.label,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return PressScale(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: selected ? AppColors.primary : Colors.transparent,
          borderRadius: AppRadius.smRadius,
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: Theme.of(context).textTheme.labelLarge?.copyWith(
            color: selected ? Colors.white : AppColors.textSecondary,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
    );
  }
}

/// ────────────────────────────────────────────────────────────────────
/// One item: preview — name — Buy / Equip / Equipped
/// ────────────────────────────────────────────────────────────────────
class _CosmeticItemCard extends StatelessWidget {
  const _CosmeticItemCard({
    required this.item,
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.onTap,
  });

  final CosmeticItem item;
  final bool owned;
  final bool equipped;
  final bool affordable;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        children: [
          Expanded(child: _preview(context)),
          const SizedBox(height: AppSpacing.sm),
          Text(
            item.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: textTheme.titleSmall?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            item.description,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: AppSpacing.sm),
          _ActionButton(
            owned: owned,
            equipped: equipped,
            affordable: affordable,
            price: item.price,
            onTap: onTap,
          ),
        ],
      ),
    );
  }

  Widget _preview(BuildContext context) {
    return switch (item) {
      BoardFrame f => FramePreview(frame: f),
      PieceStyle p => PieceStylePreview(style: p),
      Avatar a => AvatarPreview(avatar: a),
    };
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.owned,
    required this.equipped,
    required this.affordable,
    required this.price,
    required this.onTap,
  });

  final bool owned;
  final bool equipped;
  final bool affordable;
  final int price;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    // Equipped state: static badge, no tap needed.
    if (equipped) {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: AppColors.success.withValues(alpha: 0.14),
          borderRadius: AppRadius.pillRadius,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.check_rounded, color: AppColors.success, size: 18),
            const SizedBox(width: 4),
            Text(
              'Equipped',
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: AppColors.success,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      );
    }

    final label = owned ? 'Equip' : '$price';
    final color = owned
        ? AppColors.secondary
        : (affordable ? AppColors.primary : AppColors.textSecondary);

    return PressScale(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: AppSpacing.sm),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: AppRadius.pillRadius,
          border: Border.all(color: color.withValues(alpha: 0.5), width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            if (!owned) ...[
              const Icon(
                Icons.monetization_on_rounded,
                color: AppColors.accent,
                size: 18,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: Theme.of(context).textTheme.labelLarge?.copyWith(
                color: color,
                fontWeight: FontWeight.w800,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
