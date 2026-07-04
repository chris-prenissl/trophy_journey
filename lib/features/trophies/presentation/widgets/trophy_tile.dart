import 'package:flutter/material.dart';

import '../../domain/entities/trophy.dart';
import 'trophy_badges.dart';

class TrophyTile extends StatelessWidget {
  const TrophyTile({
    super.key,
    required this.trophy,
    required this.achieved,
    required this.onToggle,
    required this.onTap,
  });

  final Trophy trophy;
  final bool achieved;
  final VoidCallback onToggle;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Opacity(
          opacity: achieved ? 0.55 : 1,
          child: Padding(
            padding: const EdgeInsets.all(10),
            child: Row(
              children: [
                ClipRRect(
                  borderRadius: BorderRadius.circular(6),
                  child: Image.asset(
                    trophy.iconAsset,
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
                      Text(
                        trophy.title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          decoration:
                              achieved ? TextDecoration.lineThrough : null,
                        ),
                      ),
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
                Checkbox(
                  value: achieved,
                  onChanged: (_) => onToggle(),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
