import 'dart:async';

import 'package:flutter_bloc/flutter_bloc.dart';

import '../../../levels/domain/entities/level.dart';
import '../../../puzzle/domain/puzzle_board_size.dart';
import '../../../puzzle/domain/tile_swap_engine.dart';
import '../../data/photo_progress_service.dart';
import '../../domain/photo_puzzle.dart';

sealed class PhotoPuzzleState {
  const PhotoPuzzleState();
}

final class PhotoPuzzleLoading extends PhotoPuzzleState {
  const PhotoPuzzleLoading();
}

final class PhotoPuzzleError extends PhotoPuzzleState {
  const PhotoPuzzleError(this.message);
  final String message;
}

final class PhotoPuzzleReady extends PhotoPuzzleState {
  const PhotoPuzzleReady({
    required this.photo,
    required this.arrangement,
    required this.rotations,
    required this.minimalSwaps,
    this.moves = 0,
    this.elapsedSeconds = 0,
    this.isSolved = false,
    this.stars = 0,
    this.firstCompletion = false,
    this.isNewBest = false,
    this.coinsAwarded = 0,
    this.bestStars = 0,
  });

  final PhotoPuzzle photo;
  final List<int> arrangement;
  final List<int> rotations;
  final int minimalSwaps;
  final int moves;
  final int elapsedSeconds;
  final bool isSolved;

  /// 1-3, from how close [moves] is to [minimalSwaps] — same rule as
  /// regular levels.
  final int stars;

  /// True when this solve is the player's very first completion of the
  /// photo — the only solve that pays out coins.
  final bool firstCompletion;

  /// True when this solve beats the previously recorded best star count.
  final bool isNewBest;
  final int coinsAwarded;

  /// Best stars previously recorded for this photo (0 if never solved).
  final int bestStars;

  PhotoPuzzleReady copyWith({
    List<int>? arrangement,
    List<int>? rotations,
    int? moves,
    int? elapsedSeconds,
    bool? isSolved,
    int? stars,
    bool? firstCompletion,
    bool? isNewBest,
    int? coinsAwarded,
    int? bestStars,
  }) {
    return PhotoPuzzleReady(
      photo: photo,
      arrangement: arrangement ?? this.arrangement,
      rotations: rotations ?? this.rotations,
      minimalSwaps: minimalSwaps,
      moves: moves ?? this.moves,
      elapsedSeconds: elapsedSeconds ?? this.elapsedSeconds,
      isSolved: isSolved ?? this.isSolved,
      stars: stars ?? this.stars,
      firstCompletion: firstCompletion ?? this.firstCompletion,
      isNewBest: isNewBest ?? this.isNewBest,
      coinsAwarded: coinsAwarded ?? this.coinsAwarded,
      bestStars: bestStars ?? this.bestStars,
    );
  }
}

/// Drives a single photo puzzle: the same swap-tiles mechanic as a
/// regular level (fixed Medium 4x5 board, rotation enabled), scored on
/// moves vs. the shuffle's minimal swaps. Coins pay out exactly once per
/// photo — on the first completion — so the section is fun without being
/// farmable.
class PhotoPuzzleCubit extends Cubit<PhotoPuzzleState> {
  PhotoPuzzleCubit(this._progress) : super(const PhotoPuzzleLoading());

  final PhotoProgressService _progress;

  Timer? _timer;
  int _restartCount = 0;
  Map<String, int> _bestStars = {};
  PhotoPuzzle? _photo;

  Future<void> load(PhotoPuzzle photo) async {
    emit(const PhotoPuzzleLoading());
    try {
      _photo = photo;
      _bestStars = await _progress.loadBestStars();
      final dimensions = boardDimensionsFor(LevelDifficulty.medium);
      final board = TileSwapEngine.shuffledArrangement(
        pieceCount: dimensions.pieceCount,
        seed: photo.id.hashCode + _restartCount,
        withRotation: true,
      );
      emit(
        PhotoPuzzleReady(
          photo: photo,
          arrangement: board.arrangement,
          rotations: board.rotations,
          minimalSwaps: TileSwapEngine.minimalSwaps(board.arrangement),
          bestStars: _bestStars[photo.id] ?? 0,
        ),
      );
      _startTimer();
    } catch (e) {
      emit(PhotoPuzzleError(e.toString()));
    }
  }

  /// Re-loads the current photo from scratch: fresh shuffle, zero moves
  /// and time.
  Future<void> restart() async {
    final photo = _photo;
    if (photo == null) return;
    _restartCount += 1;
    await load(photo);
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      final current = state;
      if (current is PhotoPuzzleReady && !current.isSolved) {
        emit(current.copyWith(elapsedSeconds: current.elapsedSeconds + 1));
      }
    });
  }

  Future<void> swapPieces(int fromCell, int toCell) async {
    final current = state;
    if (current is! PhotoPuzzleReady || current.isSolved) return;

    final newState = TileSwapEngine.swap(
      (arrangement: current.arrangement, rotations: current.rotations),
      fromCell,
      toCell,
    );
    if (identical(newState.arrangement, current.arrangement) &&
        identical(newState.rotations, current.rotations)) {
      return;
    }
    _move(current, newState.arrangement, newState.rotations);
  }

  Future<void> rotatePiece(int cell) async {
    final current = state;
    if (current is! PhotoPuzzleReady || current.isSolved) return;
    if (TileSwapEngine.isCellLocked(
      (arrangement: current.arrangement, rotations: current.rotations),
      cell,
    )) {
      return;
    }
    final rotations = List<int>.of(current.rotations);
    rotations[cell] = (rotations[cell] + 1) % 4;
    _move(current, current.arrangement, rotations);
  }

  void _move(
    PhotoPuzzleReady current,
    List<int> arrangement,
    List<int> rotations,
  ) {
    final moves = current.moves + 1;
    final solved = TileSwapEngine.isSolved(
      (arrangement: arrangement, rotations: rotations),
    );

    // The solved transition is a single complete emit (stars, coins,
    // best-stars) — not a bare "isSolved" emit followed by an enriched
    // one — so listeners react exactly once and never see an incomplete
    // solved state.
    if (!solved) {
      emit(
        current.copyWith(
          arrangement: arrangement,
          rotations: rotations,
          moves: moves,
        ),
      );
      return;
    }

    _timer?.cancel();
    final stars = starsFor(moves, current.minimalSwaps);
    final previousBest = _bestStars[current.photo.id] ?? 0;
    final firstCompletion = previousBest == 0;
    final isNewBest = stars > previousBest;
    if (isNewBest) {
      _bestStars = Map<String, int>.from(_bestStars)
        ..[current.photo.id] = stars;
      // Fire-and-forget persistence — the in-memory best is already set.
      _progress.saveBestStars(current.photo.id, stars);
    }

    emit(
      current.copyWith(
        arrangement: arrangement,
        rotations: rotations,
        moves: moves,
        isSolved: true,
        stars: stars,
        firstCompletion: firstCompletion,
        isNewBest: isNewBest,
        coinsAwarded: firstCompletion ? stars * 20 : 0,
        bestStars: isNewBest ? stars : previousBest,
      ),
    );
  }

  /// 1-3 stars from how close moves are to the minimal swaps — the same
  /// single source of truth as regular levels.
  static int starsFor(int moves, int minimalSwaps) {
    if (moves <= minimalSwaps + 1) return 3;
    if (moves <= minimalSwaps * 2 + 2) return 2;
    return 1;
  }

  @override
  Future<void> close() {
    _timer?.cancel();
    return super.close();
  }
}
