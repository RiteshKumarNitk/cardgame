import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_constants.dart';
import '../../../../core/design_system/app_animations.dart';
import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../core/router/route_paths.dart';
import '../../../../shared/widgets/app_logo.dart';
import '../../../../shared/widgets/game_background.dart';
import '../../../../shared/widgets/outlined_text.dart';
import '../../../../shared/widgets/pulsing_glow.dart';
import '../../../../shared/widgets/sparkle_particles.dart';

/// Splash screen: soft brand gradient + glowing blobs + drifting clouds +
/// softly floating puzzle pieces (Flame) + a light sparkle layer, behind a
/// fading/scaling, gently-glowing logo. Automatically advances to Home
/// after a short delay.
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
    await Future.delayed(const Duration(seconds: 2));
    if (!mounted) return;
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
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const SizedBox(
                      width: 28,
                      height: 28,
                      child: CircularProgressIndicator(
                        strokeWidth: 3,
                        color: AppColors.primary,
                      ),
                    ),
                    const SizedBox(height: AppSpacing.sm),
                    Text(
                      'Loading...',
                      style: textTheme.bodyMedium?.copyWith(
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
