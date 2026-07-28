import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../domain/puzzle_board_size.dart';
import 'puzzle_state.dart';

/// Loads the [Level] a Puzzle screen was opened for and drives the
/// drag-and-drop matching game on top of it: a piece is "correct" when
/// its 1-based index matches the 0-based slot index it's dropped on
/// (piece 1 -> slot 0, piece 2 -> slot 1, ...).
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
      emit(PuzzleLoaded(level: _levels[index]));
      _startTimer();
    } catch (e) {
      emit(PuzzleError(e.toString()));
    }
  }

  /// Attempts to drop [pieceIndex] onto [slotIndex]. Returns whether the
  /// placement was correct — callers use this to trigger "wrong drop"
  /// feedback (e.g. a shake animation) without needing to inspect state.
  Future<bool> attemptPlacePiece(int pieceIndex, int slotIndex) async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return false;

    final isCorrect = pieceIndex - 1 == slotIndex;
    if (!isCorrect) {
      emit(
        current.copyWith(
          moves: current.moves + 1,
          wrongAttempts: current.wrongAttempts + 1,
        ),
      );
      return false;
    }

    final placed = {...current.placedPieceIds, pieceIndex};
    final totalPieces =
        boardSizeFor(current.level.difficulty) *
        boardSizeFor(current.level.difficulty);
    final solved = placed.length == totalPieces;

    final updated = current.copyWith(
      placedPieceIds: placed,
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

    return true;
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
