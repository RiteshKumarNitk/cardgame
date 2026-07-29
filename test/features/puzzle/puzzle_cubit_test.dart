// Unit tests for PuzzleCubit's matching game logic: correct/wrong drops,
// star rating, and — on solving — persisting through LevelService
// (marking the level complete and unlocking the next one). Pure Dart,
// backed by an in-memory fake LevelsRepository; no widgets, no gestures.
//
// Note: loading a level starts a repeating Timer (the elapsed-time
// clock), so every test closes the cubit in tearDown to cancel it —
// otherwise it's a leaked pending Timer.

import 'package:flutter_test/flutter_test.dart';

import 'package:puzzle_cards/features/levels/domain/entities/level.dart';
import 'package:puzzle_cards/features/levels/domain/repositories/levels_repository.dart';
import 'package:puzzle_cards/features/levels/domain/services/level_service.dart';
import 'package:puzzle_cards/features/puzzle/presentation/bloc/puzzle_cubit.dart';
import 'package:puzzle_cards/features/puzzle/presentation/bloc/puzzle_state.dart';

class _FakeLevelsRepository implements LevelsRepository {
  List<Level> stored = [
    const Level(
      id: 1,
      title: 'Level 1',
      difficulty: LevelDifficulty.easy, // 3x3 = 9 pieces
      stars: 0,
      isCompleted: false,
      isUnlocked: true,
    ),
    const Level(
      id: 2,
      title: 'Level 2',
      difficulty: LevelDifficulty.easy,
      stars: 0,
      isCompleted: false,
      isUnlocked: false,
    ),
  ];

  @override
  Future<List<Level>> loadLevels() async => List.of(stored);

  @override
  Future<void> saveLevels(List<Level> levels) async {
    stored = List.of(levels);
  }
}

Future<void> _solve(PuzzleCubit cubit) async {
  for (var piece = 1; piece <= 9; piece++) {
    await cubit.attemptPlacePiece(piece, piece - 1);
  }
}

void main() {
  late _FakeLevelsRepository repository;
  late PuzzleCubit cubit;

  setUp(() {
    repository = _FakeLevelsRepository();
    cubit = PuzzleCubit(LevelService(repository));
  });

  tearDown(() async {
    await cubit.close();
  });

  test('loadLevel emits the requested level with nothing placed', () async {
    await cubit.loadLevel(1);

    final state = cubit.state as PuzzleLoaded;
    expect(state.level.id, 1);
    expect(state.placedPieceIds, isEmpty);
    expect(state.isSolved, isFalse);
  });

  test('emits an error for an unknown level id', () async {
    await cubit.loadLevel(999);

    expect(cubit.state, isA<PuzzleError>());
  });

  test('a wrong drop increments moves/wrongAttempts without placing the piece', () async {
    await cubit.loadLevel(1);

    final correct = await cubit.attemptPlacePiece(1, 5);

    expect(correct, isFalse);
    final state = cubit.state as PuzzleLoaded;
    expect(state.moves, 1);
    expect(state.wrongAttempts, 1);
    expect(state.placedPieceIds, isEmpty);
  });

  test('a correct drop places the piece', () async {
    await cubit.loadLevel(1);

    final correct = await cubit.attemptPlacePiece(1, 0);

    expect(correct, isTrue);
    final state = cubit.state as PuzzleLoaded;
    expect(state.placedPieceIds, {1});
    expect(state.isSolved, isFalse);
  });

  test(
    'placing every piece solves it, awards 3 stars with no mistakes, '
    'unlocks the next level, and persists',
    () async {
      await cubit.loadLevel(1);

      await _solve(cubit);

      final state = cubit.state as PuzzleLoaded;
      expect(state.isSolved, isTrue);
      expect(state.coinsAwarded, 60, reason: '3 stars * 20 coins');

      final saved = repository.stored.firstWhere((l) => l.id == 1);
      expect(saved.isCompleted, isTrue);
      expect(saved.stars, 3);

      final next = repository.stored.firstWhere((l) => l.id == 2);
      expect(next.isUnlocked, isTrue);
    },
  );

  test('mistakes lower the star rating, matching state.stars', () async {
    await cubit.loadLevel(1);

    await cubit.attemptPlacePiece(1, 5); // wrong
    await cubit.attemptPlacePiece(1, 6); // wrong again
    await _solve(cubit);

    final state = cubit.state as PuzzleLoaded;
    expect(state.stars, 2);
    final saved = repository.stored.firstWhere((l) => l.id == 1);
    expect(saved.stars, 2);
  });

  test('nextLevelId points at the following level, then null past the last one', () async {
    await cubit.loadLevel(1);
    expect(cubit.nextLevelId, 2);

    await cubit.loadLevel(2);
    expect(cubit.nextLevelId, isNull, reason: 'level 2 is the last in this fake repository');
  });
}
