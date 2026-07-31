import 'package:final_fantasy_guide/features/trophies/presentation/widgets/game_tile.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../domain/entities/game.dart';
import '../viewmodels/game_list_view_model.dart';
import 'trophy_list_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  late final GameListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AppScope.of(context).createGameListViewModel();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openGame(Game game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrophyListScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Final Fantasy Trophy Guide'),
            actions: [
              if (!_viewModel.loading)
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: Center(
                    child: Text(
                      '${_viewModel.totalAchievedCount} / '
                      '${_viewModel.totalTrophyCount}',
                      style: Theme.of(context).textTheme.titleSmall,
                    ),
                  ),
                ),
            ],
          ),
          body: _viewModel.loading
              ? const Center(child: CircularProgressIndicator())
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  itemCount: _viewModel.games.length,
                  itemBuilder: (context, index) {
                    final game = _viewModel.games[index];
                    return GameTile(
                      game: game,
                      achievedCount: _viewModel.achievedCountFor(game.id),
                      onTap: () => _openGame(game),
                    );
                  },
                ),
        );
      },
    );
  }
}
