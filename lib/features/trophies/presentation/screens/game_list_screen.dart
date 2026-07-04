import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../domain/entities/game.dart';
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
                return _GameTile(
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

class _GameTile extends StatelessWidget {
  const _GameTile({
    required this.game,
    required this.achievedCount,
    required this.onTap,
  });

  final Game game;
  final int achievedCount;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress =
        game.trophyCount == 0 ? 0.0 : achievedCount / game.trophyCount;
    final complete = achievedCount == game.trophyCount && game.trophyCount > 0;
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(10),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(6),
                child: game.coverAsset.isEmpty
                    ? Container(
                        width: 56,
                        height: 56,
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.videogame_asset),
                      )
                    : Image.asset(
                        game.coverAsset,
                        width: 56,
                        height: 56,
                        fit: BoxFit.cover,
                      ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(game.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 4),
                    Text(
                      '$achievedCount / ${game.trophyCount} trophies',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
                    LinearProgressIndicator(
                      value: progress,
                      minHeight: 4,
                      borderRadius: BorderRadius.circular(2),
                      backgroundColor:
                          theme.colorScheme.onSurface.withValues(alpha: 0.1),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              Icon(
                complete ? Icons.emoji_events : Icons.chevron_right,
                color: complete ? const Color(0xFFE6B93C) : null,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
