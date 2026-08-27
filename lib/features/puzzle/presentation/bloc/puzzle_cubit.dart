import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../../services/analytics_service.dart';
import '../../../achievements/domain/services/achievement_events.dart';
import '../../../levels/domain/entities/level.dart';
import '../../../levels/domain/entities/level_config.dart';
import '../../../levels/domain/services/chapter_catalog.dart';
import '../../../levels/domain/services/level_service.dart';
import '../../domain/puzzle_adjacency.dart';
import '../../domain/puzzle_board_size.dart';
import '../../domain/puzzle_group.dart';
import '../../domain/tile_swap_engine.dart';
import 'puzzle_state.dart';

/// Loads the [Level] a Puzzle screen was opened for and drives the
/// tile-swap mechanic on top of it: every piece starts already placed on
/// the board, shuffled — drag one piece onto another to swap them.
///
/// Correct adjacencies create connections between cells, visually joining
/// them by removing shared borders. Connected cells form movable groups
/// that can be dragged as a single unit. Groups are NEVER locked — they
/// remain fully movable until the puzzle is ultimately solved.
///
/// The puzzle engine consumes a [LevelConfig] — a pure data class that
/// carries all puzzle parameters. The engine never knows about chapters,
/// sections, or progression. The data flow is:
/// ```
/// ChapterCatalog → LevelConfig → Puzzle Engine → Puzzle State → UI
/// ```
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

  /// Consecutive moves that formed no new adjacency. Reaching
  /// [_stallThreshold] makes the UI offer a free pity shuffle.
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

      // Build the LevelConfig — the single source of truth for all
      // puzzle parameters. The engine never touches Chapter or Section.
      final config = ChapterCatalog.levelConfigFor(level.id);
      final dims = boardDimensionsFromConfig(config);
      final seed = config.seed + _restartCount;

      // Shuffle the arrangement.
      final boardState = TileSwapEngine.shuffledArrangement(
        pieceCount: dims.pieceCount,
        seed: seed,
      );

      // Compute initial adjacency and groups.
      final adjacency = computeAdjacency(
        arrangement: boardState.arrangement,
        cols: dims.cols,
        rows: dims.rows,
      );
      final grouping = PuzzleGrouping.fromAdjacency(
        adjacency: adjacency,
        cols: dims.cols,
        rows: dims.rows,
      );

      _shuffleGeneration += 1;
      _stalledStreak = 0;
      emit(
        PuzzleLoaded(
          level: level,
          config: config,
          arrangement: boardState.arrangement,
          minimalSwaps: TileSwapEngine.minimalSwaps(boardState.arrangement),
          adjacency: adjacency,
          grouping: grouping,
          shuffleGeneration: _shuffleGeneration,
        ),
      );
      AnalyticsService().logEvent(
        AnalyticsService.levelStart,
        parameters: {
          'level_id': level.id,
          'difficulty': config.difficulty.name,
          'pieces': boardState.arrangement.length,
          'connections': adjacency.totalConnections,
          'progress_role': config.progressRole.name,
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

  /// Swaps or moves the piece(s) involving [fromCell] and [toCell].
  ///
  /// When groups are present, dragging any cell in a group moves the
  /// entire group by the displacement from [fromCell] to [toCell].
  /// Any cell can be moved — there are no locked cells.
  ///
  /// Returns whether the move was accepted. A group move can be rejected
  /// when its shifted shape doesn't fit the vacated cells (never because
  /// of a locked cell — no cell is ever locked by its position) — the
  /// caller uses this to play a neutral physical rejection (shake/haptic),
  /// never a colored target.
  Future<bool> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return false;

    final newState = current.hasGroups
        ? _swapWithGroups(current, fromCell, toCell)
        : TileSwapEngine.swap(
            (arrangement: current.arrangement),
            fromCell,
            toCell,
          );
    if (identical(newState.arrangement, current.arrangement)) return false;

    _checkSolveAndEmit(current, newState, movesDelta: 1);
    return true;
  }

  /// Group-aware swap: finds the group at fromCell, computes the
  /// displacement, and moves the entire group.
  BoardState _swapWithGroups(
    PuzzleLoaded state,
    int fromCell,
    int toCell,
  ) {
    final grouping = state.grouping!;
    final arrangement = (arrangement: state.arrangement);
    final cols = grouping.cols;

    final sourceGroup = grouping.findGroup(fromCell);

    if (sourceGroup != null) {
      // Compute displacement: how far the target cell is from the
      // source cell, in row/col terms.
      final fromRow = fromCell ~/ cols;
      final fromCol = fromCell % cols;
      final toRow = toCell ~/ cols;
      final toCol = toCell % cols;
      final dRow = toRow - fromRow;
      final dCol = toCol - fromCol;

      if (TileSwapEngine.canMoveGroupByCells(
        sourceGroup,
        dRow,
        dCol,
        grouping,
      )) {
        return TileSwapEngine.moveGroupByCells(
          arrangement,
          grouping,
          sourceGroup,
          dRow,
          dCol,
        );
      }
      return arrangement;
    }

    // Source is a solo tile. If the DESTINATION cell belongs to a
    // connected group, that group is a single physical object — a plain
    // two-cell swap would overwrite one member and split the group.
    // Instead displace the whole destination group toward the solo
    // tile's cell, or reject cleanly (board unchanged) if it can't fit.
    final destGroup = grouping.findGroup(toCell);
    if (destGroup != null) {
      final fromRow = fromCell ~/ cols;
      final fromCol = fromCell % cols;
      final toRow = toCell ~/ cols;
      final toCol = toCell % cols;
      final dRow = fromRow - toRow;
      final dCol = fromCol - toCol;

      if (TileSwapEngine.canMoveGroupByCells(
        destGroup,
        dRow,
        dCol,
        grouping,
      )) {
        return TileSwapEngine.moveGroupByCells(
          arrangement,
          grouping,
          destGroup,
          dRow,
          dCol,
        );
      }
      return arrangement;
    }

    // Both cells are ungrouped — standard swap.
    return TileSwapEngine.swap(arrangement, fromCell, toCell);
  }

  /// Automatically finds a piece that is not at its correct position
  /// and swaps it into place.
  ///
  /// For grouped levels, moves the first group toward its home position.
  Future<void> useHint() async {
    final current = state;
    if (current is! PuzzleLoaded || current.isSolved) return;

    final boardState = (arrangement: current.arrangement);
    AnalyticsService().logEvent(AnalyticsService.hintUsed);

    if (current.hasGroups) {
      // Find the first group not fully at home and move it toward (0,0).
      final grouping = current.grouping!;
      final cols = grouping.cols;
      for (final group in grouping.groups) {
        // Check if the group is at home (all cells at correct positions).
        var isHome = true;
        for (final cell in group.cells) {
          if (current.arrangement[cell] != cell + 1) {
            isHome = false;
            break;
          }
        }
        if (isHome) continue;

        // Compute displacement toward home: average cell position → (0,0).
        var sumRow = 0;
        var sumCol = 0;
        for (final cell in group.cells) {
          sumRow += cell ~/ cols;
          sumCol += cell % cols;
        }
        final avgRow = sumRow ~/ group.size;
        final avgCol = sumCol ~/ group.size;
        final dRow = -avgRow;
        final dCol = -avgCol;

        if (dRow == 0 && dCol == 0) continue;

        if (TileSwapEngine.canMoveGroupByCells(
          group,
          dRow,
          dCol,
          grouping,
        )) {
          final newState = TileSwapEngine.moveGroupByCells(
            boardState,
            grouping,
            group,
            dRow,
            dCol,
          );
          _checkSolveAndEmit(current, newState, movesDelta: 1);
        }
        return;
      }
    } else {
      // Find first cell that is not at its correct position.
      for (int i = 0; i < current.arrangement.length; i++) {
        if (current.arrangement[i] != i + 1) {
          final targetPiece = i + 1;
          final currentPosOfTarget = current.arrangement.indexOf(targetPiece);
          final newState = TileSwapEngine.swap(
            boardState,
            i,
            currentPosOfTarget,
          );
          _checkSolveAndEmit(current, newState, movesDelta: 1);
          return;
        }
      }
    }
  }

  DateTime? _lastConnectionTime;

  void _checkSolveAndEmit(PuzzleLoaded current, BoardState newState, {required int movesDelta}) async {
    final dims = boardDimensionsFromConfig(current.config);

    // Compute new adjacency and groups.
    final newAdjacency = computeAdjacency(
      arrangement: newState.arrangement,
      cols: dims.cols,
      rows: dims.rows,
    );
    final newGrouping = PuzzleGrouping.fromAdjacency(
      adjacency: newAdjacency,
      cols: dims.cols,
      rows: dims.rows,
    );

    // Count new connections formed.
    final connectionsBefore = current.adjacency.totalConnections;
    final connectionsAfter = newAdjacency.totalConnections;
    final newConnections = connectionsAfter - connectionsBefore;

    int newCombo = current.currentCombo;
    if (newConnections > 0) {
      final now = DateTime.now();
      if (_lastConnectionTime != null &&
          now.difference(_lastConnectionTime!).inSeconds <= 3) {
        newCombo = newCombo <= 1 ? 2 : newCombo + newConnections;
      } else {
        newCombo = 1; // Start chain
      }
      _lastConnectionTime = now;
    } else if (movesDelta > 0) {
      newCombo = 0; // Reset on non-scoring move
    }

    final solved = TileSwapEngine.isSolved(newState);
    final madeProgress = newConnections > 0;
    _stalledStreak = madeProgress ? 0 : _stalledStreak + 1;
    final updated = current.copyWith(
      arrangement: newState.arrangement,
      adjacency: newAdjacency,
      grouping: newGrouping,
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
