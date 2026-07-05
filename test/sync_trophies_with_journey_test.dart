import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/sync_trophies_with_journey.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'package:flutter_test/flutter_test.dart';

const _gameId = 'test-game';

class _FakeProgressRepository implements TrophyProgressRepository {
  final Map<String, Set<String>> achieved = {};
  int writeCount = 0;

  @override
  Future<Set<String>> getAchievedIds(String gameId) async =>
      {...?achieved[gameId]};

  @override
  Future<Map<String, Set<String>>> getAllAchievedIds() async => {
        for (final e in achieved.entries)
          if (e.value.isNotEmpty) e.key: {...e.value},
      };

  @override
  Future<void> setAchieved(String gameId, String trophyId, bool value) async {
    writeCount++;
    final ids = achieved.putIfAbsent(gameId, () => {});
    value ? ids.add(trophyId) : ids.remove(trophyId);
  }
}

void main() {
  // Trophy 'single' is covered by one task, 'multi' by three tasks
  // spread over two steps.
  final journey = Journey(
    gameId: _gameId,
    steps: [
      JourneyStep(
        id: 'step-1',
        title: 'Step 1',
        instructions: 'First leg.',
        tasks: const [
          JourneyTask(id: 'step-1-a', title: 'a', trophyIds: ['single']),
          JourneyTask(id: 'step-1-b', title: 'b', trophyIds: ['multi']),
          JourneyTask(id: 'step-1-c', title: 'c', trophyIds: ['multi']),
        ],
      ),
      JourneyStep(
        id: 'step-2',
        title: 'Step 2',
        instructions: 'Second leg.',
        tasks: const [
          JourneyTask(id: 'step-2-d', title: 'd', trophyIds: ['multi']),
        ],
      ),
    ],
  );

  late _FakeProgressRepository repository;
  late SyncTrophiesWithJourney sync;

  setUp(() {
    repository = _FakeProgressRepository();
    sync = SyncTrophiesWithJourney(SetTrophyAchieved(repository));
  });

  test('checking the only task covering a trophy marks it achieved', () async {
    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['single'],
      checkedBefore: {},
      checkedAfter: {'step-1-a'},
    );

    expect(repository.achieved[_gameId], {'single'});
  });

  test('partial coverage writes nothing', () async {
    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['multi'],
      checkedBefore: {'step-1-b'},
      checkedAfter: {'step-1-b', 'step-1-c'},
    );

    expect(repository.achieved, isEmpty);
    expect(repository.writeCount, 0);
  });

  test('checking the last covering task marks the trophy', () async {
    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['multi'],
      checkedBefore: {'step-1-b', 'step-1-c'},
      checkedAfter: {'step-1-b', 'step-1-c', 'step-2-d'},
    );

    expect(repository.achieved[_gameId], {'multi'});
  });

  test('breaking coverage un-marks the trophy', () async {
    repository.achieved[_gameId] = {'multi'};

    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['multi'],
      checkedBefore: {'step-1-b', 'step-1-c', 'step-2-d'},
      checkedAfter: {'step-1-b', 'step-1-c'},
    );

    expect(repository.achieved[_gameId], isEmpty);
  });

  test('does not clobber manually achieved trophies without a transition',
      () async {
    repository.achieved[_gameId] = {'multi'};

    // Coverage of 'multi' is false before and after this toggle.
    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['multi'],
      checkedBefore: {},
      checkedAfter: {'step-1-b'},
    );

    expect(repository.achieved[_gameId], {'multi'});
    expect(repository.writeCount, 0);
  });

  test('trophies without journey tasks are never written', () async {
    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['unreferenced'],
      checkedBefore: {},
      checkedAfter: {'step-1-a'},
    );

    expect(repository.writeCount, 0);
  });

  test('is idempotent for identical before/after sets', () async {
    await sync(
      gameId: _gameId,
      journey: journey,
      trophyIds: ['single'],
      checkedBefore: {'step-1-a'},
      checkedAfter: {'step-1-a'},
    );

    expect(repository.writeCount, 0);
  });
}
