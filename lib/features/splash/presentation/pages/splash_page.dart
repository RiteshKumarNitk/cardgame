import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../services/app_bootstrap.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/outlined_text.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/puzzle_piece_loader.dart';
import '../../../../shared/widgets/sparkle_particles.dart';

/// Splash screen: soft brand gradient + glowing blobs + drifting clouds +
/// softly floating puzzle pieces (Flame) + a light sparkle layer, behind a
/// fading/scaling, gently-glowing logo.
///
/// The loader is the game's own identity: six puzzle tiles assemble and
/// scatter in a loop while the real startup work ([AppBootstrap]) runs
/// behind it — status text and progress advance per stage (login → sync →
/// ads). Navigation fires once the bootstrap is ready, with a minimum
/// display time and a hard timeout so a slow network can never trap the
/// player on this screen.
class SplashPage extends StatefulWidget {
  const SplashPage({super.key});

  @override
  State<SplashPage> createState() => _SplashPageState();
}

class _SplashPageState extends State<SplashPage>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _fadeAnimation;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(vsync: this, duration: AppAnimations.slow);
    _fadeAnimation = CurvedAnimation(
      parent: _controller,
      curve: AppAnimations.fadeCurve,
    );
    _scaleAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: AppAnimations.entranceCurve),
    );
    _controller.forward();
    _scheduleNavigation();
  }

  Future<void> _scheduleNavigation() async {
    final bootstrap = AppBootstrap();

    // Minimum display time so the brand moment lands before any jump.
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;

    // Wait for real readiness when a boot is actually running; never wait
    // longer than the cap (tests never start a bootstrap, so this path is
    // skipped entirely there).
    if (bootstrap.started) {
      await bootstrap
          .whenReady()
          .timeout(const Duration(seconds: 3), onTimeout: () {});
      if (!mounted) return;
    }

    context.goNamed(RouteNames.home);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Scaffold(
      body: GameBackground(
        showClouds: true,
        child: Stack(
          children: [
            const Positioned.fill(
              child: IgnorePointer(child: SparkleParticles()),
            ),
            Center(
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ScaleTransition(
                  scale: _scaleAnimation,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      PulsingGlow(
                        color: AppColors.primary,
                        borderRadius: BorderRadius.circular(60),
                        blurRadius: 40,
                        child: const AppLogo(),
                      ),
                      const SizedBox(height: AppSpacing.lg),
                      OutlinedText(
                        AppConstants.appName,
                        outlineWidth: 3,
                        style: textTheme.headlineMedium?.copyWith(
                          color: AppColors.primary,
                          fontWeight: FontWeight.w900,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: AppSpacing.xxl + AppSpacing.sm,
              left: 0,
              right: 0,
              child: FadeTransition(
                opacity: _fadeAnimation,
                child: ValueListenableBuilder<BootstrapStage>(
                  valueListenable: AppBootstrap().stage,
                  builder: (context, stage, _) => Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const PuzzlePieceLoader(),
                      const SizedBox(height: AppSpacing.md),
                      AnimatedSwitcher(
                        duration: AppAnimations.medium,
                        child: Text(
                          _statusMessage(stage),
                          key: ValueKey(stage),
                          style: textTheme.bodyMedium?.copyWith(
                            color: AppColors.textSecondary,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      const SizedBox(height: AppSpacing.sm),
                      _StageProgress(stage: stage),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _statusMessage(BootstrapStage stage) => switch (stage) {
    BootstrapStage.preparing => 'Shuffling the deck…',
    BootstrapStage.loggingIn => 'Signing you in…',
    BootstrapStage.syncing => 'Syncing your progress…',
    BootstrapStage.loadingAds => 'Preparing rewards…',
    BootstrapStage.ready => 'Ready!',
  };
}

/// Thin brand progress bar that eases between bootstrap stages.
class _StageProgress extends StatelessWidget {
  const _StageProgress({required this.stage});

  final BootstrapStage stage;

  static const Map<BootstrapStage, double> _fractions = {
    BootstrapStage.preparing: 0.08,
    BootstrapStage.loggingIn: 0.35,
    BootstrapStage.syncing: 0.62,
    BootstrapStage.loadingAds: 0.85,
    BootstrapStage.ready: 1.0,
  };

  @override
  Widget build(BuildContext context) {
    final target = _fractions[stage] ?? 0.0;

    return TweenAnimationBuilder<double>(
      tween: Tween<double>(begin: 0.0, end: target),
      duration: AppAnimations.medium,
      curve: AppAnimations.pageCurve,
      builder: (context, value, _) => Container(
        width: 180,
        height: 5,
        decoration: BoxDecoration(
          color: AppColors.border.withValues(alpha: 0.5),
          borderRadius: BorderRadius.circular(99),
        ),
        alignment: Alignment.centerLeft,
        child: FractionallySizedBox(
          widthFactor: value.clamp(0.0, 1.0),
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(99),
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryGradientStart,
                  AppColors.accent,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
