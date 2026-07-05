import 'package:final_fantasy_guide/features/trophies/presentation/widgets/game_tile.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import 'trophy_list_screen.dart';

class GameListScreen extends StatelessWidget {
  const GameListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Final Fantasy Trophy Guide'),
        actions: [
          if (!viewModel.loading)
            Padding(
              padding: const EdgeInsets.only(right: 16),
              child: Center(
                child: Text(
                  '${viewModel.totalAchievedCount} / ${viewModel.totalTrophyCount}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
            ),
        ],
      ),
      body: viewModel.loading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: viewModel.games.length,
              itemBuilder: (context, index) {
                final game = viewModel.games[index];
                return GameTile(
                  game: game,
                  achievedCount: viewModel.achievedCountFor(game.id),
                  onTap: () => Navigator.of(context)
                      .push(
                        MaterialPageRoute<void>(
                          builder: (_) => TrophyListScreen(game: game),
                        ),
                      )
                      .then((_) => viewModel.refreshProgress()),
                );
              },
            ),
    );
  }
}
