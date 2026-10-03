import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/game_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_games_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/game_list_view_model.dart';

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
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});

    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
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
      when(progressRepository.getAllEarnedIds()).thenAnswer(
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
      when(progressRepository.getAllEarnedIds()).thenAnswer(
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

      await store.applyEarned('ffx', {'t1'});

      expect(notifications, 1);
      expect(viewModel.achievedCountFor('ffx'), 1);
      expect(viewModel.totalAchievedCount, 1);
    });

    test('stops listening to the store once disposed', () async {
      await viewModel.load();
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      viewModel.dispose();
      await store.applyEarned('ffx', {'t1'});

      expect(notifications, 0);

      viewModel = GameListViewModel(GetGamesUseCase(gameRepository), store);
    });
  });

  group('sorting and filtering', () {
    const alpha = Game(
      id: 'alpha',
      title: 'Alpha',
      trophyCount: 4,
      platform: 'PS4',
      guideSlug: 'alpha',
    );
    const beta = Game(
      id: 'beta',
      title: 'Beta',
      trophyCount: 2,
      platform: 'PS5',
    );
    const gamma = Game(
      id: 'gamma',
      title: 'Gamma',
      trophyCount: 5,
      platform: 'PS4,PS5',
    );

    setUp(() {
      when(gameRepository.getGames())
          .thenAnswer((_) async => [gamma, alpha, beta]);
    });

    test('shows every game in repository order by default', () async {
      await viewModel.load();

      expect(viewModel.sort, GameSort.recentlyPlayed);
      expect(viewModel.visibleGames, [gamma, alpha, beta]);
    });

    test('filters by title query, ignoring case', () async {
      await viewModel.load();

      viewModel.setQuery('BET');

      expect(viewModel.visibleGames, [beta]);
    });

    test('filters by play status', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'alpha': {'t1'},
          'beta': {'t1', 't2'},
        },
      );
      await store.load();
      await viewModel.load();

      viewModel.setStatusFilter(GameStatusFilter.inProgress);
      expect(viewModel.visibleGames, [alpha]);

      viewModel.setStatusFilter(GameStatusFilter.completed);
      expect(viewModel.visibleGames, [beta]);

      viewModel.setStatusFilter(GameStatusFilter.notStarted);
      expect(viewModel.visibleGames, [gamma]);
    });

    test('lists distinct platforms and filters by selection', () async {
      await viewModel.load();

      expect(viewModel.platforms, ['PS4', 'PS5']);

      viewModel.togglePlatform('PS5');
      expect(viewModel.visibleGames, [gamma, beta]);

      viewModel.togglePlatform('PS5');
      expect(viewModel.visibleGames, [gamma, alpha, beta]);
    });

    test('filters to games with a bundled guide', () async {
      await viewModel.load();

      viewModel.setGuideOnly(true);

      expect(viewModel.visibleGames, [alpha]);
    });

    test('sorts by title', () async {
      await viewModel.load();

      viewModel.setSort(GameSort.title);

      expect(viewModel.visibleGames, [alpha, beta, gamma]);
    });

    test('sorts by completion percentage, highest first', () async {
      when(progressRepository.getAllEarnedIds()).thenAnswer(
        (_) async => {
          'alpha': {'t1'},
          'beta': {'t1', 't2'},
        },
      );
      await store.load();
      await viewModel.load();

      viewModel.setSort(GameSort.completion);

      expect(viewModel.visibleGames, [beta, alpha, gamma]);
    });

    test('re-sorts when progress changes elsewhere', () async {
      await viewModel.load();
      viewModel.setSort(GameSort.completion);

      await store.applyEarned('gamma', {'t1', 't2', 't3', 't4', 't5'});

      expect(viewModel.visibleGames, [gamma, alpha, beta]);
    });
  });
}
