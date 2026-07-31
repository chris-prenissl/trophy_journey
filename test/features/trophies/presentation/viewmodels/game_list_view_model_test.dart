import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/game_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_games_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'game_list_view_model_test.mocks.dart';

const ffx = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: 'assets/covers/ffx.png',
  trophyCount: 3,
);

const ffvii = Game(
  id: 'ffvii',
  title: 'Final Fantasy VII',
  numeral: 'VII',
  coverAsset: 'assets/covers/ffvii.png',
  trophyCount: 2,
);

@GenerateNiceMocks([
  MockSpec<GameRepository>(),
  MockSpec<TrophyProgressRepository>(),
])
void main() {
  late MockGameRepository gameRepository;
  late MockTrophyProgressRepository progressRepository;
  late TrophyProgressStore store;
  late GameListViewModel viewModel;

  setUp(() async {
    gameRepository = MockGameRepository();
    progressRepository = MockTrophyProgressRepository();
    when(gameRepository.getGames()).thenAnswer((_) async => [ffx, ffvii]);
    when(progressRepository.getAllAchievedIds()).thenAnswer((_) async => {});
    when(progressRepository.setAchieved(any, any, any))
        .thenAnswer((_) => Future<void>.value());

    store = TrophyProgressStore(
      GetAllAchievedTrophyIdsUseCase(progressRepository),
      SetTrophyAchievedUseCase(progressRepository),
    );
    await store.load();
    viewModel = GameListViewModel(GetGamesUseCase(gameRepository), store);
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  group('load', () {
    test('exposes the games and clears the loading flag', () async {
      expect(viewModel.loading, isTrue);
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await viewModel.load();

      expect(viewModel.loading, isFalse);
      expect(viewModel.games, [ffx, ffvii]);
      expect(notifications, 1);
      verify(gameRepository.getGames()).called(1);
    });
  });

  group('counts', () {
    test('reads achieved counts from the shared store', () async {
      when(progressRepository.getAllAchievedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1', 't2'},
          'ffvii': {'t9'},
        },
      );
      await store.load();
      await viewModel.load();

      expect(viewModel.achievedCountFor('ffx'), 2);
      expect(viewModel.achievedCountFor('ffvii'), 1);
      expect(viewModel.totalAchievedCount, 3);
      expect(viewModel.totalTrophyCount, 5);
    });

    test('ignores stored progress for games that are not listed', () async {
      when(progressRepository.getAllAchievedIds()).thenAnswer(
        (_) async => {
          'ffx': {'t1'},
          'ff-unknown': {'t1', 't2'},
        },
      );
      await store.load();
      await viewModel.load();

      expect(viewModel.totalAchievedCount, 1);
    });

    test('is zero before any progress is loaded', () async {
      await viewModel.load();

      expect(viewModel.totalAchievedCount, 0);
      expect(viewModel.achievedCountFor('ffx'), 0);
    });
  });

  group('shared progress', () {
    test('re-emits when a trophy is toggled elsewhere', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      await store.setAchieved('ffx', 't1', true);

      expect(notifications, 1);
      expect(viewModel.achievedCountFor('ffx'), 1);
      expect(viewModel.totalAchievedCount, 1);
    });

    test('stops listening to the store once disposed', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.dispose();
      await store.setAchieved('ffx', 't1', true);

      expect(notifications, 0);

      viewModel = GameListViewModel(GetGamesUseCase(gameRepository), store);
    });
  });
}
