import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';

/// The reference photo the player is reassembling — hidden by default and
/// unlockable by spending coins, so checking the answer costs something
/// instead of being free. Unlocked state is session-only (not persisted):
/// re-opening the puzzle re-locks it.
class PuzzlePreviewThumbnail extends StatefulWidget {
  const PuzzlePreviewThumbnail({
    super.key,
    required this.imageUrl,
    this.unlockCost = 15,
  });

  final String imageUrl;
  final int unlockCost;

  @override
  State<PuzzlePreviewThumbnail> createState() =>
      _PuzzlePreviewThumbnailState();
}

class _PuzzlePreviewThumbnailState extends State<PuzzlePreviewThumbnail> {
  bool _unlocked = false;

  Future<void> _unlock() async {
    final success = await context.read<WalletCubit>().spendCoins(
      widget.unlockCost,
    );
    if (!mounted) return;
    if (success) {
      setState(() => _unlocked = true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Not enough coins')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.sm),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: AppRadius.smRadius,
            child: SizedBox(
              width: 56,
              height: 56,
              child: _unlocked ? _UnlockedImage(imageUrl: widget.imageUrl) : _LockedThumb(),
            ),
          ),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: _unlocked
                ? Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_rounded,
                            size: 15,
                            color: AppColors.secondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Reassemble this photo',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Drag pieces on the board to swap them',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  )
                : Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.visibility_off_rounded,
                            size: 15,
                            color: AppColors.textSecondary,
                          ),
                          const SizedBox(width: AppSpacing.xs),
                          Text(
                            'Preview locked',
                            style: textTheme.labelMedium?.copyWith(
                              color: AppColors.textSecondary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Spend coins to see the full photo',
                        style: textTheme.bodySmall?.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
          ),
          if (!_unlocked) ...[
            const SizedBox(width: AppSpacing.sm),
            GameButton(
              label: '${widget.unlockCost}',
              icon: Icons.monetization_on_rounded,
              variant: GameButtonVariant.premium,
              width: 92,
              height: 40,
              onTap: _unlock,
            ),
          ],
        ],
      ),
    );
  }
}

class _LockedThumb extends StatelessWidget {
  const _LockedThumb();

  @override
  Widget build(BuildContext context) {
    return const ColoredBox(
      color: AppColors.border,
      child: Icon(Icons.lock_rounded, color: AppColors.textSecondary, size: 22),
    );
  }
}

class _UnlockedImage extends StatelessWidget {
  const _UnlockedImage({required this.imageUrl});

  final String imageUrl;

  @override
  Widget build(BuildContext context) {
    return Image.network(
      imageUrl,
      fit: BoxFit.cover,
      loadingBuilder: (context, child, progress) =>
          progress == null ? child : const ColoredBox(color: AppColors.border),
      errorBuilder: (context, error, stackTrace) => const ColoredBox(
        color: AppColors.border,
        child: Icon(
          Icons.image_not_supported_rounded,
          size: 20,
          color: AppColors.textSecondary,
        ),
      ),
    );
  }
}
