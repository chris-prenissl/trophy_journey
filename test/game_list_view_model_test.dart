import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/game_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_games.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeGameRepository implements GameRepository {
  @override
  Future<List<Game>> getGames() async => const [
        Game(
          id: 'ff1',
          title: 'Final Fantasy',
          numeral: 'I',
          coverAsset: '',
          trophyCount: 24,
        ),
        Game(
          id: 'ff2',
          title: 'Final Fantasy II',
          numeral: 'II',
          coverAsset: '',
          trophyCount: 28,
        ),
      ];
}

class _FakeProgressRepository implements TrophyProgressRepository {
  Map<String, Set<String>> byGame = {};

  @override
  Future<Set<String>> getAchievedIds(String gameId) async =>
      {...?byGame[gameId]};

  @override
  Future<Map<String, Set<String>>> getAllAchievedIds() async => byGame;

  @override
  Future<void> setAchieved(String gameId, String trophyId, bool achieved) =>
      throw UnimplementedError();
}

void main() {
  test('loads games and per-game progress counts', () async {
    final progress = _FakeProgressRepository()
      ..byGame = {
        'ff1': {'x', 'y'},
      };
    final viewModel = GameListViewModel(
      GetGames(_FakeGameRepository()),
      GetAllAchievedTrophyIds(progress),
    );
    await viewModel.load();

    expect(viewModel.loading, isFalse);
    expect(viewModel.games, hasLength(2));
    expect(viewModel.achievedCountFor('ff1'), 2);
    expect(viewModel.achievedCountFor('ff2'), 0);
    expect(viewModel.totalTrophyCount, 52);
    expect(viewModel.totalAchievedCount, 2);
  });

  test('refreshProgress picks up new achievements', () async {
    final progress = _FakeProgressRepository();
    final viewModel = GameListViewModel(
      GetGames(_FakeGameRepository()),
      GetAllAchievedTrophyIds(progress),
    );
    await viewModel.load();
    expect(viewModel.totalAchievedCount, 0);

    progress.byGame = {
      'ff2': {'a'},
    };
    await viewModel.refreshProgress();

    expect(viewModel.achievedCountFor('ff2'), 1);
    expect(viewModel.totalAchievedCount, 1);
  });
}
