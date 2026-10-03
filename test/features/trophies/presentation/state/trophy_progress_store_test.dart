import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';

import 'trophy_progress_store_test.mocks.dart';

@GenerateNiceMocks([MockSpec<TrophyProgressRepository>()])
void main() {
  late MockTrophyProgressRepository repository;
  late TrophyProgressStore store;

  TrophyProgressStore buildStore() => TrophyProgressStore(
    GetAllEarnedTrophyIdsUseCase(repository),
    ReplaceEarnedTrophiesUseCase(repository),
  );

  setUp(() {
    repository = MockTrophyProgressRepository();
    when(repository.getAllEarnedIds()).thenAnswer((_) async => {});
    when(repository.replaceEarned(any, any)).thenAnswer((_) => Future.value());
    store = buildStore();
  });

  tearDown(() => store.dispose());

  group('load', () {
    test('starts empty and loading', () {
      expect(store.loading, isTrue);
      expect(store.achievedFor('ffx'), isEmpty);
    });

    test('exposes the earned ids per game and notifies once', () async {
      when(repository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1', 't2'},
          'ffvii': {'t9'},
        },
      );
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.load();

      expect(store.loading, isFalse);
      expect(store.achievedFor('ffx'), {'t1', 't2'});
      expect(store.achievedFor('ffvii'), {'t9'});
      expect(store.achievedFor('unknown'), isEmpty);
      expect(notifications, 1);
    });

    test('counts earned trophies per game and in total', () async {
      when(repository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1', 't2'},
          'ffvii': {'t9'},
        },
      );

      await store.load();

      expect(store.countFor('ffx'), 2);
      expect(store.countFor('ffvii'), 1);
      expect(store.countFor('unknown'), 0);
      expect(store.totalAchievedCount, 3);
    });
  });

  group('isAchieved', () {
    test('reports membership scoped to the game', () async {
      when(repository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1'},
        },
      );

      await store.load();

      expect(store.isAchieved('ffx', 't1'), isTrue);
      expect(store.isAchieved('ffx', 't2'), isFalse);
      expect(store.isAchieved('ffvii', 't1'), isFalse);
    });
  });

  group('applyEarned', () {
    test('persists and reflects the earned set', () async {
      await store.load();
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.applyEarned('ffx', {'t1', 't2'});

      expect(store.isAchieved('ffx', 't1'), isTrue);
      expect(store.isAchieved('ffx', 't2'), isTrue);
      expect(store.countFor('ffx'), 2);
      expect(notifications, 1);
      verify(repository.replaceEarned('ffx', {'t1', 't2'})).called(1);
    });

    test('replaces the previous earned set for the game', () async {
      await store.load();
      await store.applyEarned('ffx', {'t1', 't2'});

      await store.applyEarned('ffx', {'t1'});

      expect(store.achievedFor('ffx'), {'t1'});
    });

    test('leaves other games untouched', () async {
      when(repository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'ffvii': {'t9'},
        },
      );
      await store.load();

      await store.applyEarned('ffx', {'t1'});

      expect(store.achievedFor('ffvii'), {'t9'});
      expect(store.achievedFor('ffx'), {'t1'});
    });
  });
}
