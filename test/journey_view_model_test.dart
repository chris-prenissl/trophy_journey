import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_progress_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_checked_task_ids.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_bookmark.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_journey_bookmark.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_task_checked.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'package:flutter_test/flutter_test.dart';

const _gameId = 'test-game';

Trophy _trophy(String id, int order) => Trophy(
      id: id,
      title: id,
      type: TrophyType.bronze,
      description: 'desc $id',
      guide: 'guide $id',
      missable: false,
      iconAsset: 'assets/icons/$_gameId/$id.jpg',
      order: order,
    );

Journey _journey() => Journey(
      gameId: _gameId,
      steps: [
        JourneyStep(
          id: 'step-1',
          title: 'Step 1',
          instructions: 'First leg.',
          tasks: const [
            JourneyTask(id: 'step-1-a', title: 'a', trophyIds: ['single']),
            JourneyTask(id: 'step-1-b', title: 'b', trophyIds: ['multi']),
          ],
        ),
        JourneyStep(
          id: 'step-2',
          title: 'Step 2',
          instructions: 'Second leg.',
          tasks: const [
            JourneyTask(id: 'step-2-c', title: 'c', trophyIds: ['multi']),
          ],
        ),
      ],
    );

class _FakeJourneyRepository implements JourneyRepository {
  @override
  Future<Journey> getJourney(String gameId) async => _journey();

  @override
  Future<bool> hasJourney(String gameId) async => gameId == _gameId;
}

class _FakeJourneyProgressRepository implements JourneyProgressRepository {
  final Map<String, Set<String>> checked = {};
  final Map<String, String> bookmarks = {};

  @override
  Future<Set<String>> getCheckedTaskIds(String gameId) async =>
      {...?checked[gameId]};

  @override
  Future<void> setTaskChecked(
    String gameId,
    String taskId,
    bool value,
  ) async {
    final ids = checked.putIfAbsent(gameId, () => {});
    value ? ids.add(taskId) : ids.remove(taskId);
  }

  @override
  Future<String?> getBookmark(String gameId) async => bookmarks[gameId];

  @override
  Future<void> setBookmark(String gameId, String? stepId) async {
    stepId == null ? bookmarks.remove(gameId) : bookmarks[gameId] = stepId;
  }
}

class _FakeTrophyRepository implements TrophyRepository {
  @override
  Future<List<Trophy>> getTrophies(String gameId) async =>
      [_trophy('single', 0), _trophy('multi', 1)];
}

class _FakeTrophyProgressRepository implements TrophyProgressRepository {
  final Map<String, Set<String>> achieved = {};

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
    final ids = achieved.putIfAbsent(gameId, () => {});
    value ? ids.add(trophyId) : ids.remove(trophyId);
  }
}

void main() {
  late _FakeJourneyProgressRepository journeyProgress;
  late _FakeTrophyProgressRepository trophyProgress;
  late JourneyViewModel viewModel;

  JourneyViewModel build() => JourneyViewModel(
        _gameId,
        GetJourney(_FakeJourneyRepository()),
        GetTrophies(_FakeTrophyRepository()),
        GetCheckedTaskIds(journeyProgress),
        SetTaskChecked(journeyProgress),
        GetJourneyBookmark(journeyProgress),
        SetJourneyBookmark(journeyProgress),
      );

  setUp(() async {
    journeyProgress = _FakeJourneyProgressRepository();
    trophyProgress = _FakeTrophyProgressRepository();
    viewModel = build();
    await viewModel.load();
  });

  test('loads steps, checked state and bookmark', () {
    expect(viewModel.loading, isFalse);
    expect(viewModel.steps.map((s) => s.id), ['step-1', 'step-2']);
    expect(viewModel.totalTaskCount, 3);
    expect(viewModel.checkedTaskCount, 0);
    expect(viewModel.bookmarkedStepId, isNull);
    expect(viewModel.trophyById('single')?.id, 'single');
  });

  test('toggling a task updates state, persists and syncs its trophy',
      () async {
    await viewModel.toggleTask('step-1-a');

    expect(viewModel.isTaskChecked('step-1-a'), isTrue);
    expect(viewModel.checkedTaskCount, 1);
    expect(viewModel.progress, closeTo(1 / 3, 1e-9));
    expect(journeyProgress.checked[_gameId], {'step-1-a'});
    expect(trophyProgress.achieved[_gameId], {'single'});
  });

  test('multi-task trophy only syncs once all its tasks are checked',
      () async {
    await viewModel.toggleTask('step-1-b');
    expect(trophyProgress.achieved[_gameId], isNull);

    await viewModel.toggleTask('step-2-c');
    expect(trophyProgress.achieved[_gameId], {'multi'});

    await viewModel.toggleTask('step-2-c');
    expect(trophyProgress.achieved[_gameId], isEmpty);
  });

  test('step progress and completion are derived from checked tasks',
      () async {
    final step1 = viewModel.steps.first;
    expect(viewModel.checkedCountOf(step1), 0);
    expect(viewModel.isStepComplete(step1), isFalse);

    await viewModel.toggleTask('step-1-a');
    await viewModel.toggleTask('step-1-b');

    expect(viewModel.checkedCountOf(step1), 2);
    expect(viewModel.isStepComplete(step1), isTrue);
  });

  test('bookmark sets, moves and clears on re-tap', () async {
    await viewModel.toggleBookmark('step-2');
    expect(viewModel.isBookmarked('step-2'), isTrue);
    expect(journeyProgress.bookmarks[_gameId], 'step-2');

    await viewModel.toggleBookmark('step-1');
    expect(viewModel.bookmarkedStepId, 'step-1');

    await viewModel.toggleBookmark('step-1');
    expect(viewModel.bookmarkedStepId, isNull);
    expect(journeyProgress.bookmarks, isEmpty);
  });

  test('initialStepIndex prefers the bookmark, else first incomplete step',
      () async {
    expect(viewModel.initialStepIndex, 0);

    await viewModel.toggleTask('step-1-a');
    await viewModel.toggleTask('step-1-b');
    expect(viewModel.initialStepIndex, 1);

    await viewModel.toggleBookmark('step-1');
    expect(viewModel.initialStepIndex, 0);
  });

  test('state persists across view model instances', () async {
    await viewModel.toggleTask('step-1-a');
    await viewModel.toggleBookmark('step-2');

    final reloaded = build();
    await reloaded.load();

    expect(reloaded.isTaskChecked('step-1-a'), isTrue);
    expect(reloaded.bookmarkedStepId, 'step-2');
    expect(reloaded.initialStepIndex, 1);
  });
}
