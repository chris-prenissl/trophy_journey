import 'package:flutter/material.dart';

import '../viewmodels/game_list_view_model.dart';

class TrophyCountCard extends StatelessWidget {
  const TrophyCountCard({super.key, required this.viewModel});

  final GameListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final achieved = viewModel.totalAchievedCount;
    final total = viewModel.totalTrophyCount;
    final progress = total == 0 ? 0.0 : achieved / total;

    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return Container(
          padding: const EdgeInsets.fromLTRB(14, 10, 14, 12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            gradient: LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [
                theme.colorScheme.primaryContainer,
                theme.colorScheme.surfaceContainerHighest,
              ],
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Icon(
                    Icons.emoji_events,
                    size: 20,
                    color: theme.colorScheme.primary,
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '$achieved / $total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    '${(value * 100).round()}%',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: value,
                  minHeight: 6,
                  backgroundColor: theme.colorScheme.onSurface.withValues(
                    alpha: 0.1,
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
