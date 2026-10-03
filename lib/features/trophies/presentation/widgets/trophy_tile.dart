import 'package:material_ui/material_ui.dart';

import '../../domain/entities/trophy.dart';
import 'artwork.dart';
import 'trophy_badges.dart';

class TrophyTile extends StatelessWidget {
  const TrophyTile({
    super.key,
    required this.trophy,
    required this.achieved,
    required this.onTap,
  });

  final Trophy trophy;
  final bool achieved;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
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
                child: TrophyIcon(trophy: trophy),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(trophy.title, style: theme.textTheme.titleSmall),
                    const SizedBox(height: 2),
                    Text(
                      trophy.description,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                    const SizedBox(height: 6),
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
              if (achieved)
                Icon(
                  Icons.check_circle,
                  size: 24,
                  color: theme.colorScheme.primary,
                )
              else
                Icon(
                  Icons.circle_outlined,
                  size: 24,
                  color: theme.colorScheme.onSurfaceVariant.withValues(
                    alpha: 0.4,
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
