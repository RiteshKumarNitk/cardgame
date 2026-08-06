import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_colors.dart';
import '../../../../core/design_system/app_radius.dart';
import '../../../../core/design_system/app_spacing.dart';
import '../../../../game/wallet_cubit.dart';
import '../../../../shared/widgets/coin_flight_animation.dart';
import '../../../../shared/widgets/game_button.dart';
import '../../../../shared/widgets/game_card.dart';
import '../../domain/daily_reward_service.dart';

class DailyRewardsModal extends StatefulWidget {
  const DailyRewardsModal({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      barrierDismissible: false,
      builder: (_) => const DailyRewardsModal(),
    );
  }

  @override
  State<DailyRewardsModal> createState() => _DailyRewardsModalState();
}

class _DailyRewardsModalState extends State<DailyRewardsModal> {
  final _service = DailyRewardService();
  late int _nextDay;
  late bool _available;
  bool _claiming = false;
  final GlobalKey _claimButtonKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    _nextDay = _service.getNextStreakDay();
    _available = _service.isRewardAvailable();
  }

  Future<void> _claim() async {
    if (!_available || _claiming) return;
    setState(() => _claiming = true);
    
    final dayClaimed = await _service.claimReward();
    final reward = _service.getRewardForDay(dayClaimed);
    
    if (!mounted) return;
    
    context.read<WalletCubit>().addCoins(reward);
    
    // Fly coins upwards from the button
    CoinFlightOverlay.show(
      context: context,
      startKey: _claimButtonKey,
      endOffset: Offset(MediaQuery.of(context).size.width / 2, -100),
      count: reward > 100 ? 20 : 10,
    );
    
    setState(() {
      _available = false;
      _claiming = false;
    });
    
    // Wait for flight to finish before closing
    await Future.delayed(const Duration(milliseconds: 1500));
    if (mounted) Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final textTheme = Theme.of(context).textTheme;

    return Dialog(
      backgroundColor: Colors.transparent,
      insetPadding: const EdgeInsets.all(AppSpacing.lg),
      child: GameCard(
        padding: const EdgeInsets.all(AppSpacing.lg),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Daily Reward',
              style: textTheme.headlineSmall?.copyWith(
                color: AppColors.textDark,
                fontWeight: FontWeight.w900,
              ),
            ),
            const SizedBox(height: AppSpacing.sm),
            Text(
              'Come back every day for bigger rewards!',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium?.copyWith(
                color: AppColors.textSecondary,
              ),
            ),
            const SizedBox(height: AppSpacing.lg),
            
            // 7 day calendar
            Wrap(
              spacing: 8,
              runSpacing: 8,
              alignment: WrapAlignment.center,
              children: List.generate(7, (index) {
                final day = index + 1;
                final isToday = day == _nextDay;
                final isPast = day < _nextDay;
                final reward = _service.getRewardForDay(day);
                
                return _DayCard(
                  day: day,
                  reward: reward,
                  isToday: isToday,
                  isPast: isPast,
                  available: _available,
                );
              }),
            ),
            
            const SizedBox(height: AppSpacing.xl),
            
            GameButton(
              key: _claimButtonKey,
              label: _available ? (_claiming ? 'Claiming...' : 'Claim Reward') : 'Come back tomorrow',
              icon: _available ? Icons.redeem_rounded : Icons.check_circle_rounded,
              variant: _available ? GameButtonVariant.premium : GameButtonVariant.secondary,
              width: double.infinity,
              onTap: _available ? _claim : () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
  }
}

class _DayCard extends StatelessWidget {
  const _DayCard({
    required this.day,
    required this.reward,
    required this.isToday,
    required this.isPast,
    required this.available,
  });

  final int day;
  final int reward;
  final bool isToday;
  final bool isPast;
  final bool available;

  @override
  Widget build(BuildContext context) {
    final bool highlighted = isToday && available;
    final bool claimed = isPast || (isToday && !available);
    
    return Container(
      width: 65,
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: highlighted ? AppColors.accent : (claimed ? AppColors.success.withOpacity(0.15) : AppColors.background),
        borderRadius: AppRadius.mdRadius,
        border: Border.all(
          color: highlighted ? Colors.white : (claimed ? AppColors.success : AppColors.border),
          width: highlighted ? 2 : 1,
        ),
      ),
      child: Column(
        children: [
          Text(
            'Day $day',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: highlighted ? Colors.white : AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 4),
          Icon(
            claimed ? Icons.check_circle_rounded : Icons.monetization_on_rounded,
            color: highlighted ? Colors.white : (claimed ? AppColors.success : AppColors.accent),
            size: 24,
          ),
          const SizedBox(height: 4),
          Text(
            '+$reward',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w900,
              color: highlighted ? Colors.white : AppColors.textDark,
            ),
          ),
        ],
      ),
    );
  }
}
