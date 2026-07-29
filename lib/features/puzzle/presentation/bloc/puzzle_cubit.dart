import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../domain/puzzle_board_size.dart';
import '../../domain/tile_swap_engine.dart';
import 'puzzle_state.dart';

/// Loads the [Level] a Puzzle screen was opened for and drives the
/// tile-swap mechanic on top of it: every piece starts already placed on
/// the board, shuffled — drag one piece onto another to swap them. A cell
/// locks once its piece is correct; the puzzle is solved once every cell
/// is locked.
///
/// On completion, persists the result through [LevelService.completeLevel]
/// — the same unlock-next-level/best-score logic built in Phase 5, now
/// wired to real gameplay for the first time.
class PuzzleCubit extends Cubit<PuzzleState> {
  PuzzleCubit(this._levelService) : super(const PuzzleInitial());

  final LevelService _levelService;
  List<Level> _levels = [];
  Timer? _timer;

  Future<void> loadLevel(int levelId) async {
    emit(const PuzzleLoading());
    try {
      _levels = await _levelService.loadLevels();
      final index = _levels.indexWhere((l) => l.id == levelId);
      if (index == -1) {
        emit(PuzzleError('Level $levelId not found'));
        return;
      }
      final level = _levels[index];
      final arrangement = TileSwapEngine.shuffledArrangement(
        size: boardSizeFor(level.difficulty),
        seed: level.id,
      );
      emit(
        PuzzleLoaded(
          level: level,
          arrangement: arrangement,
          minimalSwaps: TileSwapEngine.minimalSwaps(arrangement),
        ),
      );
      _startTimer();
    } catch (e) {
      emit(PuzzleError(e.toString()));
    }
  }

  /// Swaps the pieces in [fromCell] and [toCell]. A no-op if either cell
  /// is already locked (solved) or the puzzle is already complete.
  Future<void> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;

    final arrangement = TileSwapEngine.swap(
      current.arrangement,
      fromCell,
      toCell,
    );
    if (identical(arrangement, current.arrangement)) return;

    final solved = TileSwapEngine.isSolved(arrangement);
    final updated = current.copyWith(
      arrangement: arrangement,
      moves: current.moves + 1,
      isSolved: solved,
    );
    emit(updated);

    if (solved) {
      _timer?.cancel();
      await _levelService.completeLevel(
        _levels,
        updated.level.id,
        stars: updated.stars,
        timeSeconds: updated.elapsedSeconds,
        moves: updated.moves,
      );
    }
  }

  /// The level right after the currently loaded one, or `null` if it was
  /// the last in the list.
  int? get nextLevelId {
    final current = state;
    if (current is! PuzzleLoaded) return null;
    return current.level.id < _levels.length ? current.level.id + 1 : null;
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current is PuzzleLoaded && !current.isSolved) {
        emit(current.copyWith(elapsedSeconds: current.elapsedSeconds + 1));
      }
    });
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
