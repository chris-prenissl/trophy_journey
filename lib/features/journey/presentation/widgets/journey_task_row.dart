import 'package:trophy_journey/features/journey/presentation/widgets/trophy_chip.dart';
import 'package:flutter/material.dart';

import '../../../trophies/domain/entities/trophy.dart';
import '../../../trophies/presentation/widgets/trophy_badges.dart';
import '../../domain/entities/journey.dart';

class JourneyTaskRow extends StatelessWidget {
  const JourneyTaskRow({
    super.key,
    required this.task,
    required this.checked,
    required this.trophies,
    required this.onToggle,
  });

  final JourneyTask task;
  final bool checked;
  final List<Trophy> trophies;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onToggle,
      borderRadius: BorderRadius.circular(8),
      child: Opacity(
        opacity: checked ? 0.55 : 1,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Checkbox(value: checked, onChanged: (_) => onToggle()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        task.title,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          decoration: checked
                              ? TextDecoration.lineThrough
                              : null,
                        ),
                      ),
                      if (task.note.isNotEmpty) ...[
                        const SizedBox(height: 2),
                        Text(
                          task.note,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                      if (trophies.isNotEmpty ||
                          task.flag != TaskFlag.none) ...[
                        const SizedBox(height: 6),
                        Wrap(
                          spacing: 4,
                          runSpacing: 4,
                          children: [
                            if (task.isMissable) const MissableBadge(),
                            if (task.isRecommended) const RecommendedBadge(),
                            for (final trophy in trophies)
                              TrophyChip(trophy: trophy),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
