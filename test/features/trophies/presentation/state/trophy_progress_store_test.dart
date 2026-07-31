import 'dart:async';

import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'trophy_progress_store_test.mocks.dart';

@GenerateNiceMocks([MockSpec<TrophyProgressRepository>()])
void main() {
  late MockTrophyProgressRepository repository;
  late TrophyProgressStore store;

  TrophyProgressStore buildStore() => TrophyProgressStore(
    GetAllAchievedTrophyIdsUseCase(repository),
    SetTrophyAchievedUseCase(repository),
  );

  setUp(() {
    repository = MockTrophyProgressRepository();
    when(repository.getAllAchievedIds()).thenAnswer((_) async => {});
    when(repository.setAchieved(any, any, any))
        .thenAnswer((_) => Future.value());
    store = buildStore();
  });

  tearDown(() => store.dispose());

  group('load', () {
    test('starts empty and loading', () {
      expect(store.loading, isTrue);
      expect(store.achievedFor('ffx'), isEmpty);
    });

    test('exposes achieved ids per game and notifies once', () async {
      when(repository.getAllAchievedIds()).thenAnswer(
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

    test('counts achieved trophies per game and in total', () async {
      when(repository.getAllAchievedIds()).thenAnswer(
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
      when(repository.getAllAchievedIds()).thenAnswer(
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

  group('setAchieved', () {
    test(
      'applies the change and notifies before the write completes',
      () async {
        await store.load();
        final writeGate = Completer<void>();
        when(repository.setAchieved('ffx', 't1', true))
            .thenAnswer((_) => writeGate.future);
        var notifications = 0;
        store.addListener(() => notifications++);

        final pending = store.setAchieved('ffx', 't1', true);
        await pumpEventQueue();

        expect(store.isAchieved('ffx', 't1'), isTrue);
        expect(notifications, 1);

        writeGate.complete();
        await pending;

        expect(store.isAchieved('ffx', 't1'), isTrue);
        expect(notifications, 1);
      },
    );

    test('persists through the use case', () async {
      await store.load();

      await store.setAchieved('ffx', 't1', true);
      await store.setAchieved('ffx', 't1', false);

      verify(repository.setAchieved('ffx', 't1', true)).called(1);
      verify(repository.setAchieved('ffx', 't1', false)).called(1);
    });

    test('removes the id when set to false', () async {
      when(repository.getAllAchievedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1', 't2'},
        },
      );
      await store.load();

      await store.setAchieved('ffx', 't1', false);

      expect(store.achievedFor('ffx'), {'t2'});
    });

    test('does not mutate a set handed out earlier', () async {
      when(repository.getAllAchievedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1'},
        },
      );
      await store.load();
      final before = store.achievedFor('ffx');

      await store.setAchieved('ffx', 't2', true);

      expect(before, {'t1'});
      expect(store.achievedFor('ffx'), {'t1', 't2'});
    });

    test('rolls back and rethrows when the write fails', () async {
      await store.load();
      when(repository.setAchieved('ffx', 't1', true))
          .thenThrow(StateError('disk full'));
      var notifications = 0;
      store.addListener(() => notifications++);

      await expectLater(store.setAchieved('ffx', 't1', true), throwsStateError);

      expect(store.isAchieved('ffx', 't1'), isFalse);
      expect(notifications, 2, reason: 'optimistic update then rollback');
    });
  });

  group('toggle', () {
    test('flips the current value', () async {
      await store.load();

      await store.toggle('ffx', 't1');
      expect(store.isAchieved('ffx', 't1'), isTrue);

      await store.toggle('ffx', 't1');
      expect(store.isAchieved('ffx', 't1'), isFalse);

      verify(repository.setAchieved('ffx', 't1', true)).called(1);
      verify(repository.setAchieved('ffx', 't1', false)).called(1);
    });
  });
}
