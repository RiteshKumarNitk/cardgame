import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../services/analytics_service.dart';
import '../../../../shared/utils/context_read_or_null.dart';
import '../../../../shared/utils/number_format.dart';
import '../../../../shared/widgets/circle_icon_button.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../../../shared/widgets/stat_chip.dart';
import '../../../cosmetics/domain/entities/cosmetic_items.dart';
import '../../../cosmetics/domain/services/cosmetics_catalog.dart';
import '../../../cosmetics/presentation/bloc/cosmetics_cubit.dart';
import '../../../cosmetics/presentation/widgets/avatar_badge.dart';
import '../../../daily_puzzle/data/daily_challenge_repository_impl.dart';
import '../../../daily_puzzle/domain/services/daily_challenge_service.dart';
import '../../../levels/data/datasources/levels_local_datasource.dart';
import '../../../levels/data/repositories/levels_repository_impl.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../../photos/data/photo_progress_service.dart';
import '../../domain/profile_service.dart';

/// A snapshot of the player's lifetime stats for the Profile screen.
class ProfileStats {
  const ProfileStats({
    required this.levelsCompleted,
    required this.totalLevels,
    required this.totalStars,
    required this.photosCollected,
    required this.bestStreak,
  });

  final int levelsCompleted;
  final int totalLevels;
  final int totalStars;
  final int photosCollected;
  final int bestStreak;
}

/// The player's profile: equipped avatar, editable display name (used on
/// the leaderboard too), and lifetime stats. Stats load through an
/// injectable [loadStats] so tests never need real storage.
class ProfilePage extends StatefulWidget {
  const ProfilePage({
    super.key,
    ProfileService? profileService,
    Future<ProfileStats> Function()? loadStats,
  }) : _profileService = profileService,
       _loadStats = loadStats;

  final ProfileService? _profileService;
  final Future<ProfileStats> Function()? _loadStats;

  @override
  State<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends State<ProfilePage> {
  late final ProfileService _profileService;
  String _name = '';
  ProfileStats? _stats;

  @override
  void initState() {
    super.initState();
    _profileService = widget._profileService ?? HiveProfileService();
    _name = _profileService.name;
    _loadStats();
  }

  Future<void> _loadStats() async {
    final loader = widget._loadStats ?? _loadDefaultStats;
    final stats = await loader();
    if (!mounted) return;
    setState(() => _stats = stats);
  }

  /// Default stats loader wired to the real Hive-backed services.
  static Future<ProfileStats> _loadDefaultStats() async {
    final levels = await LevelService(
      LevelsRepositoryImpl(HiveLevelsLocalDataSource()),
    ).loadLevels();
    final photos = await HivePhotoProgressService().loadBestStars();
    final challenge = await DailyChallengeService(
      HiveDailyChallengeRepository(),
    ).loadToday(DateTime.now());
    return ProfileStats(
      levelsCompleted: levels.where((l) => l.isCompleted).length,
      totalLevels: levels.length,
      totalStars: levels.fold(0, (sum, l) => sum + l.stars),
      photosCollected: photos.length,
      bestStreak: challenge.streak,
    );
  }

  Future<void> _editName() async {
    final controller = TextEditingController(text: _name);
    final newName = await showDialog<String>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.card,
        shape: RoundedRectangleBorder(borderRadius: AppRadius.lgRadius),
        title: Text(
          'Your name',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            color: AppColors.textDark,
            fontWeight: FontWeight.w800,
          ),
        ),
        content: TextField(
          controller: controller,
          autofocus: true,
          maxLength: 20,
          decoration: const InputDecoration(
            hintText: 'Enter a display name',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text(
              'Cancel',
              style: TextStyle(color: AppColors.textSecondary),
            ),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(dialogContext).pop(controller.text.trim()),
            child: const Text(
              'Save',
              style: TextStyle(
                color: AppColors.primary,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
    if (newName == null || newName.isEmpty || newName == _name) return;
    await _profileService.saveName(newName);
    if (!mounted) return;
    setState(() => _name = newName);
    AnalyticsService().logEvent(
      AnalyticsService.profileUpdated,
      parameters: {'name_length': newName.length},
    );
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;
    final stats = _stats;

    return Scaffold(
      body: GameBackground(
        showFloatingPieces: true,
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(AppSpacing.lg),
            child: Column(
              children: [
                Row(
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
                        'Profile',
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Avatar + name ──
                _EquippedAvatarBadge(onTap: _editName),
                const SizedBox(height: AppSpacing.sm),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Flexible(
                      child: Text(
                        _name.isEmpty ? 'Tap to set a name' : _name,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: textTheme.headlineSmall?.copyWith(
                          color: AppColors.textDark,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
                    ),
                    const SizedBox(width: AppSpacing.xs),
                    InkWell(
                      onTap: _editName,
                      borderRadius: AppRadius.pillRadius,
                      child: const Padding(
                        padding: EdgeInsets.all(4),
                        child: Icon(
                          Icons.edit_rounded,
                          size: 18,
                          color: AppColors.secondary,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: AppSpacing.xs),
                Text(
                  'Your name shows on the leaderboard',
                  style: textTheme.bodySmall?.copyWith(
                    color: AppColors.textSecondary,
                  ),
                ),
                const SizedBox(height: AppSpacing.md),

                // ── Wallet ──
                BlocBuilder<WalletCubit, int>(
                  builder: (context, coins) => StatChip(
                    icon: Icons.monetization_on_rounded,
                    value: formatThousands(coins),
                    iconColor: AppColors.accent,
                  ),
                ),
                const SizedBox(height: AppSpacing.lg),

                // ── Stats grid ──
                stats == null
                    ? const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: AppColors.primary,
                          ),
                        ),
                      )
                    : Expanded(
                        child: SingleChildScrollView(
                          physics: const BouncingScrollPhysics(),
                          child: Column(
                            children: [
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.check_circle_rounded,
                                      label: 'Levels Solved',
                                      value:
                                          '${stats.levelsCompleted}/${stats.totalLevels}',
                                      color: AppColors.success,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.star_rounded,
                                      label: 'Total Stars',
                                      value: '${stats.totalStars}',
                                      color: AppColors.accent,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.md),
                              Row(
                                children: [
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.photo_library_rounded,
                                      label: 'Photos Collected',
                                      value: '${stats.photosCollected}',
                                      color: AppColors.secondary,
                                    ),
                                  ),
                                  const SizedBox(width: AppSpacing.md),
                                  Expanded(
                                    child: _StatCard(
                                      icon: Icons.local_fire_department_rounded,
                                      label: 'Best Streak',
                                      value: '${stats.bestStreak}',
                                      color: AppColors.danger,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: AppSpacing.lg),
                              GameButton(
                                label: 'Customize Avatar',
                                icon: Icons.face_rounded,
                                variant: GameButtonVariant.secondary,
                                width: double.infinity,
                                onTap: () => context.goNamed(
                                  RouteNames.cosmeticsCategory,
                                  pathParameters: {'category': 'avatar'},
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// The equipped avatar badge (falls back to the default avatar when no
/// cosmetics cubit is above — standalone tests).
class _EquippedAvatarBadge extends StatelessWidget {
  const _EquippedAvatarBadge({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final cosmetics = context.watchOrNull<CosmeticsCubit>()?.state;
    final avatar = cosmetics == null
        ? defaultAvatar
        : CosmeticsCatalog.avatarById(cosmetics.equippedAvatar);
    return AvatarBadge(
      avatar: avatar,
      size: 96,
      onTap: onTap,
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return GameCard(
      padding: const EdgeInsets.all(AppSpacing.md),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 28),
          const SizedBox(height: AppSpacing.xs),
          Text(
            value,
            style: textTheme.titleLarge?.copyWith(
              color: AppColors.textDark,
              fontWeight: FontWeight.w900,
            ),
          ),
          Text(
            label,
            textAlign: TextAlign.center,
            style: textTheme.labelSmall?.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}
