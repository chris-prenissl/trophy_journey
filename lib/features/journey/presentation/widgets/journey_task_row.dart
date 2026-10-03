import 'package:material_ui/material_ui.dart';

import '../../../trophies/domain/entities/trophy.dart';
import '../../../trophies/presentation/widgets/trophy_badges.dart';
import '../../domain/entities/journey.dart';
import 'trophy_chip.dart';

class const JourneyTaskRow({
  super.key,
  required final JourneyTask task,
  required final bool checked,
  required final List<Trophy> trophies,
  required final VoidCallback onToggle,
}) extends StatelessWidget {
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
