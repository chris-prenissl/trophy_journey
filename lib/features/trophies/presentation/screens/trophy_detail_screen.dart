import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../domain/entities/trophy.dart';
import '../widgets/trophy_badges.dart';

class TrophyDetailScreen extends StatelessWidget {
  const TrophyDetailScreen({super.key, required this.trophy});

  final Trophy trophy;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final viewModel = AppScope.of(context);
    final achieved = viewModel.isAchieved(trophy.id);
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
                child: Image.asset(
                  trophy.iconAsset,
                  width: 80,
                  height: 80,
                  fit: BoxFit.cover,
                ),
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
          SwitchListTile(
            title: const Text('Achieved'),
            value: achieved,
            onChanged: (_) => viewModel.toggleAchieved(trophy.id),
            contentPadding: const EdgeInsets.symmetric(horizontal: 8),
          ),
          const Divider(),
          const SizedBox(height: 8),
          Text('How to achieve', style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          Text(
            trophy.guide,
            style: theme.textTheme.bodyMedium?.copyWith(height: 1.5),
          ),
        ],
      ),
    );
  }
}
