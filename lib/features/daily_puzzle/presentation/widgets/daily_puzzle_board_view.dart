import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../core/design_system/app_spacing.dart';
import '../../../puzzle/presentation/widgets/puzzle_board.dart';
import '../../../puzzle/presentation/widgets/puzzle_piece_tray.dart';
import '../../../puzzle/presentation/widgets/puzzle_preview_thumbnail.dart';
import '../bloc/daily_challenge_cubit.dart';
import '../bloc/daily_challenge_state.dart';

/// The board + tray for an in-progress Daily Challenge — reuses the same
/// [PuzzleBoard]/[PuzzlePieceTray] widgets a regular level uses.
class DailyPuzzleBoardView extends StatelessWidget {
  const DailyPuzzleBoardView({super.key, required this.state});

  final DailyChallengeReady state;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        PuzzlePreviewThumbnail(imageUrl: state.imageUrl),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: PuzzleBoard(
            difficulty: state.challenge.difficulty,
            imageUrl: state.imageUrl,
            placedPieceIds: state.placedPieceIds,
            onDrop: (pieceIndex, slotIndex) => context
                .read<DailyChallengeCubit>()
                .attemptPlacePiece(pieceIndex, slotIndex),
          ),
        ),
        const SizedBox(height: AppSpacing.lg),
        PuzzlePieceTray(
          difficulty: state.challenge.difficulty,
          shuffleSeed: state.challenge.dateKey.hashCode,
          imageUrl: state.imageUrl,
          placedPieceIds: state.placedPieceIds,
        ),
      ],
    );
  }
}
