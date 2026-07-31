import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import 'artwork.dart';

class GameTile extends StatelessWidget {
  const GameTile({
    super.key,
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
    final progress = game.completion(achievedCount);
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
                child: GameCover(game: game),
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
                      backgroundColor: theme.colorScheme.onSurface.withValues(
                        alpha: 0.1,
                      ),
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

@Preview(name: 'No Progress', group: 'Game Tile')
Widget gameTileNoProgress() => GameTile(
  game: const Game(
    id: 'ff7',
    title: 'Final Fantasy VII',
    numeral: 'VII',
    trophyCount: 50,
  ),
  achievedCount: 0,
  onTap: () {},
);

@Preview(name: 'Partial Progress', group: 'Game Tile')
Widget gameTilePartial() => GameTile(
  game: const Game(
    id: 'ff8',
    title: 'Final Fantasy VIII',
    numeral: 'VIII',
    trophyCount: 50,
  ),
  achievedCount: 20,
  onTap: () {},
);

@Preview(name: 'Complete', group: 'Game Tile')
Widget gameTileComplete() => GameTile(
  game: const Game(
    id: 'ff9',
    title: 'Final Fantasy IX',
    numeral: 'IX',
    trophyCount: 50,
  ),
  achievedCount: 50,
  onTap: () {},
);
