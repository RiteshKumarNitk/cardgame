import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/analytics_service.dart';
import '../../../achievements/domain/services/achievement_events.dart';
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
  PuzzleCubit(this._levelService, {AchievementEvents? achievementEvents})
    : _achievementEvents = achievementEvents,
      super(const PuzzleInitial());

  final LevelService _levelService;

  /// Optional sink for milestone events (achievements). Nullable so the
  /// cubit stays constructible standalone in tests.
  final AchievementEvents? _achievementEvents;

  List<Level> _levels = [];
  Timer? _timer;

  /// How many times the current level has been restarted, so each restart
  /// re-shuffles into a different arrangement instead of restoring the
  /// exact same board (the base seed is the level id).
  int _restartCount = 0;

  /// Increments on every (re)shuffle — the board key the UI uses to
  /// replay the deal-in entrance animation.
  int _shuffleGeneration = 0;

  /// Consecutive moves that locked no piece. Reaching [_stallThreshold]
  /// makes the UI offer a free pity shuffle.
  int _stalledStreak = 0;
  static const int _stallThreshold = 6;

  /// True after [_stallThreshold] consecutive no-progress moves — the UI
  /// offers a free shuffle to unstick the player.
  bool get _stuckShuffleReady => _stalledStreak >= _stallThreshold;

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
      final withRotation = level.difficulty == LevelDifficulty.hard ||
          level.difficulty == LevelDifficulty.expert ||
          level.difficulty == LevelDifficulty.master;

      final state = TileSwapEngine.shuffledArrangement(
        pieceCount: boardDimensionsForLevel(level.id).pieceCount,
        seed: level.id + _restartCount,
        withRotation: withRotation,
      );
      _shuffleGeneration += 1;
      _stalledStreak = 0;
      emit(
        PuzzleLoaded(
          level: level,
          arrangement: state.arrangement,
          rotations: state.rotations,
          minimalSwaps: TileSwapEngine.minimalSwaps(state.arrangement),
          shuffleGeneration: _shuffleGeneration,
        ),
      );
      AnalyticsService().logEvent(
        AnalyticsService.levelStart,
        parameters: {
          'level_id': level.id,
          'difficulty': level.difficulty.name,
          'pieces': state.arrangement.length,
        },
      );
      _startTimer();
    } catch (e) {
      emit(PuzzleError(e.toString()));
    }
  }

  /// Re-loads the current level from scratch: fresh shuffle, zero moves
  /// and time. No-op unless a level is loaded.
  Future<void> restart() async {
    final current = state;
    if (current is! PuzzleLoaded) return;
    _restartCount += 1;
    await loadLevel(current.level.id);
  }

  /// Free "pity shuffle": re-shuffles the current level after the player
  /// has been stuck (no progress for [_stallThreshold] moves). The timer
  /// restarts with the fresh board.
  Future<void> shuffleBoard() async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;
    _restartCount += 1;
    await loadLevel(current.level.id);
  }

  /// Stops the elapsed clock while [paused] is true and resumes it when
  /// false, so time never ticks while the pause menu is up. No-op on a
  /// non-loaded or already-solved puzzle.
  void setPaused(bool paused) {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;
    if (paused) {
      _timer?.cancel();
      _timer = null;
    } else {
      _startTimer();
    }
    emit(current.copyWith(isPaused: paused));
  }

  /// Swaps the pieces in [fromCell] and [toCell]. A no-op if either cell
  /// is already locked (solved) or the puzzle is already complete.
  Future<void> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;

    final newState = TileSwapEngine.swap(
      (arrangement: current.arrangement, rotations: current.rotations),
      fromCell,
      toCell,
    );
    if (identical(newState.arrangement, current.arrangement) && identical(newState.rotations, current.rotations)) return;
    
    // Check equality properly, since identical on records or generated lists might be false even if nothing changed. 
    // But swap already returns the same state if nothing changes due to locks.
    
    _checkSolveAndEmit(current, newState, movesDelta: 1);
  }

  /// Rotates the piece in [cellIndex] by 90 degrees clockwise.
  Future<void> rotatePiece(int cellIndex) async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;
    if (TileSwapEngine.isCellLocked((arrangement: current.arrangement, rotations: current.rotations), cellIndex)) return;

    final newRotations = List<int>.of(current.rotations);
    newRotations[cellIndex] = (newRotations[cellIndex] + 1) % 4;

    _checkSolveAndEmit(current, (arrangement: current.arrangement, rotations: newRotations), movesDelta: 1);
  }

  /// Automatically finds a piece that is in the wrong place, finds its correct home,
  /// swaps it into place, and fixes its rotation.
  Future<void> useHint() async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;

    final boardState = (arrangement: current.arrangement, rotations: current.rotations);
    AnalyticsService().logEvent(AnalyticsService.hintUsed);
    
    // Find first cell that is not locked
    for (int i = 0; i < current.arrangement.length; i++) {
      if (!TileSwapEngine.isCellLocked(boardState, i)) {
        // The cell i is not locked. We want to place piece (i + 1) here.
        // Where is piece (i + 1)?
        final targetPiece = i + 1;
        final currentPosOfTarget = current.arrangement.indexOf(targetPiece);
        
        // Swap them and fix rotation
        var newState = TileSwapEngine.swap(boardState, i, currentPosOfTarget);
        final newRotations = List<int>.of(newState.rotations);
        newRotations[i] = 0; // Fix rotation of the hinted cell
        newState = (arrangement: newState.arrangement, rotations: newRotations);

        _checkSolveAndEmit(current, newState, movesDelta: 1);
        return;
      }
    }
  }

  DateTime? _lastLockTime;

  void _checkSolveAndEmit(PuzzleLoaded current, BoardState newState, {required int movesDelta}) async {
    int lockedBefore = 0;
    for (int i = 0; i < current.arrangement.length; i++) {
      if (TileSwapEngine.isCellLocked((arrangement: current.arrangement, rotations: current.rotations), i)) {
        lockedBefore++;
      }
    }

    int lockedAfter = 0;
    for (int i = 0; i < newState.arrangement.length; i++) {
      if (TileSwapEngine.isCellLocked(newState, i)) {
        lockedAfter++;
      }
    }

    int newCombo = current.currentCombo;
    if (lockedAfter > lockedBefore) {
      final now = DateTime.now();
      if (_lastLockTime != null && now.difference(_lastLockTime!).inSeconds <= 3) {
        newCombo = newCombo <= 1 ? 2 : newCombo + (lockedAfter - lockedBefore);
      } else {
        newCombo = 1; // Start chain
      }
      _lastLockTime = now;
    } else if (movesDelta > 0) {
      newCombo = 0; // Reset on non-scoring move
    }

    final solved = TileSwapEngine.isSolved(newState);
    final madeProgress = lockedAfter > lockedBefore;
    _stalledStreak = madeProgress ? 0 : _stalledStreak + 1;
    final updated = current.copyWith(
      arrangement: newState.arrangement,
      rotations: newState.rotations,
      moves: current.moves + movesDelta,
      isSolved: solved,
      currentCombo: newCombo,
      stuckShuffleReady: !solved && _stuckShuffleReady,
    );
    emit(updated);

    if (solved) {
      _timer?.cancel();
      AnalyticsService().logEvent(
        AnalyticsService.levelComplete,
        parameters: {
          'level_id': updated.level.id,
          'stars': updated.stars,
          'moves': updated.moves,
          'time_seconds': updated.elapsedSeconds,
        },
      );
      _levels = await _levelService.completeLevel(
        _levels,
        updated.level.id,
        stars: updated.stars,
        timeSeconds: updated.elapsedSeconds,
        moves: updated.moves,
      );
      await _achievementEvents?.onPuzzleCompleted(
        stars: updated.stars,
        timeSeconds: updated.elapsedSeconds,
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
