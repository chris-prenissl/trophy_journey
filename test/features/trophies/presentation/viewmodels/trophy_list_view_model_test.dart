import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

import 'trophy_list_view_model_test.mocks.dart';

const first = Trophy(
  id: 't1',
  title: 'First',
  type: TrophyType.bronze,
  description: 'description',
  guide: 'guide',
  iconAsset: 'assets/icons/t1.png',
  order: 0,
);

const missable = Trophy(
  id: 't2',
  title: 'Missable',
  type: TrophyType.silver,
  description: 'description',
  guide: 'guide',
  missable: true,
  iconAsset: 'assets/icons/t2.png',
  order: 1,
);

const last = Trophy(
  id: 't3',
  title: 'Last',
  type: TrophyType.gold,
  description: 'description',
  guide: 'guide',
  iconAsset: 'assets/icons/t3.png',
  order: 2,
);

@GenerateNiceMocks([
  MockSpec<TrophyRepository>(),
  MockSpec<TrophyProgressRepository>(),
])
void main() {
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late TrophyProgressStore store;
  late TrophyListViewModel viewModel;

  setUp(() async {
    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();
    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [first, missable, last]);
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});

    store = TrophyProgressStore(progressRepository);
    await store.load();
    viewModel = TrophyListViewModel('ffx', trophyRepository, store);
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  group('load', () {
    test('fetches trophies for its game and clears the loading flag', () async {
      expect(viewModel.loading, isTrue);
      final notifications = <bool>[];
      viewModel.addListener(() => notifications.add(viewModel.loading));

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.totalCount, 3);
      expect(notifications, [true, false]);
      verify(trophyRepository.getTrophies('ffx')).called(1);
    });

    test('reports whether the game has missable trophies', () async {
      await viewModel.load();
      expect(viewModel.hasMissables, isTrue);

      when(trophyRepository.getTrophies('ffx'))
          .thenAnswer((_) async => [first, last]);
      await viewModel.load();

      expect(viewModel.hasMissables, isFalse);
    });
  });

  group('progress', () {
    test('derives counts from the shared store', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1'},
        },
      );
      await store.load();
      await viewModel.load();

      expect(viewModel.achievedCount, 1);
      expect(viewModel.totalCount, 3);
      expect(viewModel.progress, closeTo(1 / 3, 0.0001));
      expect(viewModel.isAchieved('t1'), isTrue);
      expect(viewModel.isAchieved('t2'), isFalse);
    });

    test('ignores progress belonging to another game', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffvii': {'t1'},
        },
      );
      await store.load();
      await viewModel.load();

      expect(viewModel.achievedCount, 0);
      expect(viewModel.isAchieved('t1'), isFalse);
    });

    test('is zero when the game has no trophies', () async {
      when(trophyRepository.getTrophies('ffx')).thenAnswer((_) async => []);
      await viewModel.load();

      expect(viewModel.progress, 0);
    });
  });

  group('visibleTrophies', () {
    test('sorts unachieved before achieved, keeping source order', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1'},
        },
      );
      await store.load();
      await viewModel.load();

      expect(viewModel.visibleTrophies.map((t) => t.id), ['t2', 't3', 't1']);
    });

    test('filters to missables only', () async {
      await viewModel.load();

      viewModel.setMissablesOnly(true);

      expect(viewModel.visibleTrophies.map((t) => t.id), ['t2']);
    });

    test('hides achieved trophies', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1'},
        },
      );
      await store.load();
      await viewModel.load();

      viewModel.setHideAchieved(true);

      expect(viewModel.visibleTrophies.map((t) => t.id), ['t2', 't3']);
    });

    test('combines both filters', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t2'},
        },
      );
      await store.load();
      await viewModel.load();

      viewModel
        ..setMissablesOnly(true)
        ..setHideAchieved(true);

      expect(viewModel.visibleTrophies, isEmpty);
    });

    test('is computed once and reused between reads', () async {
      await viewModel.load();

      expect(
        identical(viewModel.visibleTrophies, viewModel.visibleTrophies),
        isTrue,
      );
    });

    test('is recomputed after a filter change', () async {
      await viewModel.load();
      final before = viewModel.visibleTrophies;

      viewModel.setMissablesOnly(true);

      expect(identical(before, viewModel.visibleTrophies), isFalse);
    });

    test('is recomputed after progress changes', () async {
      await viewModel.load();
      viewModel.setHideAchieved(true);
      final before = viewModel.visibleTrophies;

      await store.applyEarned('ffx', {'t1'});

      expect(identical(before, viewModel.visibleTrophies), isFalse);
      expect(viewModel.visibleTrophies.map((t) => t.id), ['t2', 't3']);
    });
  });

  group('filters', () {
    test('notify listeners when changed', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.setMissablesOnly(true);
      viewModel.setHideAchieved(true);

      expect(viewModel.missablesOnly, isTrue);
      expect(viewModel.hideAchieved, isTrue);
      expect(notifications, 2);
    });
  });

  group('psn earned', () {
    test('folds in what PSN reports as earned on load', () async {
      when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
          .thenAnswer((_) async => {'t1'});
      viewModel = TrophyListViewModel(
        'ffx',
        trophyRepository,
        store,
        syncWithPsn: true,
      );

      await viewModel.load();

      expect(viewModel.isAchieved('t1'), isTrue);
      expect(viewModel.isAchieved('t2'), isFalse);
      expect(viewModel.achievedCount, 1);
    });

    test('keeps the list when the earned lookup fails', () async {
      when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
          .thenThrow(Exception('offline'));
      viewModel = TrophyListViewModel(
        'ffx',
        trophyRepository,
        store,
        syncWithPsn: true,
      );

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.totalCount, 3);
    });

    test('re-emits when the store changes elsewhere', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await store.applyEarned('ffx', {'t1'});

      expect(notifications, 1);
      expect(viewModel.achievedCount, 1);
    });

    test('stops listening to the store once disposed', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.dispose();
      await store.applyEarned('ffx', {'t1'});

      expect(notifications, 0);

      viewModel = TrophyListViewModel('ffx', trophyRepository, store);
    });
  });
}
