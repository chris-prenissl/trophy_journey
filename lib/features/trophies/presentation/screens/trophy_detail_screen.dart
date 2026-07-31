import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../domain/entities/trophy.dart';
import '../state/trophy_progress_store.dart';
import '../widgets/artwork.dart';
import '../widgets/trophy_badges.dart';

class TrophyDetailScreen extends StatefulWidget {
  const TrophyDetailScreen({
    super.key,
    required this.gameId,
    required this.trophy,
  });

  final String gameId;
  final Trophy trophy;

  @override
  State<TrophyDetailScreen> createState() => _TrophyDetailScreenState();
}

class _TrophyDetailScreenState extends State<TrophyDetailScreen> {
  late final TrophyProgressStore _progress;

  @override
  void initState() {
    super.initState();
    _progress = AppScope.of(context).trophyProgressStore;
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final trophy = widget.trophy;
    return Scaffold(
      appBar: AppBar(title: Text(trophy.title)),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: TrophyIcon(trophy: trophy, size: 80),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trophy.title, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 4),
                    Text(
                      trophy.description,
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 4,
                      children: [
                        TrophyTypeBadge(type: trophy.type),
                        if (trophy.missable) const MissableBadge(),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ListenableBuilder(
            listenable: _progress,
            builder: (context, _) {
              final achieved = _progress.isAchieved(widget.gameId, trophy.id);
              return ListTile(
                leading: Icon(
                  achieved ? Icons.check_circle : Icons.circle_outlined,
                  color: achieved
                      ? theme.colorScheme.primary
                      : theme.colorScheme.onSurfaceVariant,
                ),
                title: Text(achieved ? 'Earned' : 'Not earned yet'),
                subtitle: const Text('Synced from PlayStation Network'),
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              );
            },
          ),
          if (trophy.hasGuide) ...[
            const Divider(),
            const SizedBox(height: 8),
            Text('How to achieve', style: theme.textTheme.titleMedium),
            const SizedBox(height: 8),
            Text(
              trophy.guide,
              style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
            ),
          ],
        ],
      ),
    );
  }
}
