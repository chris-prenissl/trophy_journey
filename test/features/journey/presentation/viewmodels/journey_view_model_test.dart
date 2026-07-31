import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_progress_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_checked_task_ids_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_bookmark_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_journey_bookmark_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_task_checked_use_case.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'journey_view_model_test.mocks.dart';

const zanarkand = Trophy(
  id: 'tr1',
  title: 'Zanarkand',
  type: TrophyType.bronze,
  description: 'description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/tr1.png',
  order: 0,
);

@GenerateNiceMocks([
  MockSpec<JourneyRepository>(),
  MockSpec<JourneyProgressRepository>(),
  MockSpec<TrophyRepository>(),
])
void main() {
  late MockJourneyRepository journeyRepository;
  late MockJourneyProgressRepository progressRepository;
  late MockTrophyRepository trophyRepository;
  late JourneyViewModel viewModel;

  final journey = Journey(
    gameId: 'ffx',
    steps: const [
      JourneyStep(
        id: 's1',
        title: 'Zanarkand',
        instructions: 'Play the intro',
        tasks: [
          JourneyTask(id: 't1', title: 'Beat Sinspawn', trophyIds: ['tr1']),
          JourneyTask(
            id: 't2',
            title: 'Grab the chest',
            trophyIds: [],
            flag: TaskFlag.missable,
          ),
        ],
      ),
      JourneyStep(
        id: 's2',
        title: 'Besaid',
        instructions: 'Do the trials',
        tasks: [JourneyTask(id: 't3', title: 'Cloister', trophyIds: [])],
      ),
    ],
  );

  setUp(() {
    journeyRepository = MockJourneyRepository();
    progressRepository = MockJourneyProgressRepository();
    trophyRepository = MockTrophyRepository();

    when(journeyRepository.getJourney('ffx')).thenAnswer((_) async => journey);
    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [zanarkand]);
    when(progressRepository.getCheckedTaskIds('ffx'))
        .thenAnswer((_) async => <String>{});
    when(progressRepository.getBookmark('ffx')).thenAnswer((_) async => null);
    when(progressRepository.setTaskChecked(any, any, any))
        .thenAnswer((_) => Future.value());
    when(progressRepository.setBookmark(any, any))
        .thenAnswer((_) => Future.value());

    viewModel = JourneyViewModel(
      'ffx',
      GetJourneyUseCase(journeyRepository),
      GetTrophiesUseCase(trophyRepository),
      GetCheckedTaskIdsUseCase(progressRepository),
      SetTaskCheckedUseCase(progressRepository),
      GetJourneyBookmarkUseCase(progressRepository),
      SetJourneyBookmarkUseCase(progressRepository),
    );
  });

  tearDown(() => viewModel.dispose());

  group('load', () {
    test('exposes steps, trophies and progress', () async {
      when(progressRepository.getCheckedTaskIds('ffx'))
          .thenAnswer((_) async => {'t1'});
      when(progressRepository.getBookmark('ffx')).thenAnswer((_) async => 's2');

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.steps.map((s) => s.id), ['s1', 's2']);
      expect(viewModel.trophyById('tr1'), zanarkand);
      expect(viewModel.trophyById('missing'), isNull);
      expect(viewModel.isTaskChecked('t1'), isTrue);
      expect(viewModel.bookmarkedStepId, 's2');
    });

    test('toggles the loading flag around the fetch', () async {
      final loadingStates = <bool>[];
      viewModel.addListener(() => loadingStates.add(viewModel.loading));

      await viewModel.load();

      expect(loadingStates, [true, false]);
    });
  });

  group('counts', () {
    test('tracks checked tasks against the total', () async {
      when(progressRepository.getCheckedTaskIds('ffx'))
          .thenAnswer((_) async => {'t1', 't3'});

      await viewModel.load();

      expect(viewModel.totalTaskCount, 3);
      expect(viewModel.checkedTaskCount, 2);
      expect(viewModel.progress, closeTo(2 / 3, 0.0001));
    });

    test('counts per step and reports completion', () async {
      when(progressRepository.getCheckedTaskIds('ffx'))
          .thenAnswer((_) async => {'t1', 't2'});

      await viewModel.load();

      expect(viewModel.checkedCountOf(viewModel.steps[0]), 2);
      expect(viewModel.isStepComplete(viewModel.steps[0]), isTrue);
      expect(viewModel.isStepComplete(viewModel.steps[1]), isFalse);
    });

    test('is zero before loading', () {
      expect(viewModel.totalTaskCount, 0);
      expect(viewModel.checkedTaskCount, 0);
      expect(viewModel.progress, 0);
      expect(viewModel.steps, isEmpty);
    });
  });

  group('initialStepIndex', () {
    test('points at the first incomplete step', () async {
      when(progressRepository.getCheckedTaskIds('ffx'))
          .thenAnswer((_) async => {'t1', 't2'});

      await viewModel.load();

      expect(viewModel.initialStepIndex, 1);
    });

    test('prefers the bookmarked step', () async {
      when(progressRepository.getBookmark('ffx')).thenAnswer((_) async => 's2');

      await viewModel.load();

      expect(viewModel.initialStepIndex, 1);
    });

    test('falls back to the first step when everything is done', () async {
      when(progressRepository.getCheckedTaskIds('ffx'))
          .thenAnswer((_) async => {'t1', 't2', 't3'});

      await viewModel.load();

      expect(viewModel.initialStepIndex, 0);
    });
  });

  group('toggleTask', () {
    test('checks and unchecks, persisting each change', () async {
      await viewModel.load();

      await viewModel.toggleTask('t1');
      expect(viewModel.isTaskChecked('t1'), isTrue);

      await viewModel.toggleTask('t1');
      expect(viewModel.isTaskChecked('t1'), isFalse);

      verify(progressRepository.setTaskChecked('ffx', 't1', true)).called(1);
      verify(progressRepository.setTaskChecked('ffx', 't1', false)).called(1);
    });

    test('does nothing before the journey is loaded', () async {
      await viewModel.toggleTask('t1');

      expect(viewModel.isTaskChecked('t1'), isFalse);
      verifyNever(progressRepository.setTaskChecked(any, any, any));
    });

    test('rolls back and rethrows when the write fails', () async {
      await viewModel.load();
      when(progressRepository.setTaskChecked('ffx', 't1', true))
          .thenThrow(StateError('disk full'));
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await expectLater(viewModel.toggleTask('t1'), throwsStateError);

      expect(viewModel.isTaskChecked('t1'), isFalse);
      expect(notifications, 2, reason: 'optimistic update then rollback');
    });
  });

  group('toggleBookmark', () {
    test('sets and clears the bookmark', () async {
      await viewModel.load();

      await viewModel.toggleBookmark('s2');
      expect(viewModel.isBookmarked('s2'), isTrue);

      await viewModel.toggleBookmark('s2');
      expect(viewModel.isBookmarked('s2'), isFalse);

      verify(progressRepository.setBookmark('ffx', 's2')).called(1);
      verify(progressRepository.setBookmark('ffx', null)).called(1);
    });

    test('moves the bookmark to another step', () async {
      await viewModel.load();

      await viewModel.toggleBookmark('s1');
      await viewModel.toggleBookmark('s2');

      expect(viewModel.isBookmarked('s1'), isFalse);
      expect(viewModel.isBookmarked('s2'), isTrue);
    });

    test('rolls back and rethrows when the write fails', () async {
      await viewModel.load();
      when(progressRepository.setBookmark('ffx', 's2'))
          .thenThrow(StateError('disk full'));

      await expectLater(viewModel.toggleBookmark('s2'), throwsStateError);

      expect(viewModel.isBookmarked('s2'), isFalse);
      expect(viewModel.bookmarkedStepId, isNull);
    });
  });
}
