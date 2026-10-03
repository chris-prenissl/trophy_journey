import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';

class TrophyChip extends StatelessWidget {
  final Trophy trophy;

  const TrophyChip({super.key, required this.trophy});

  @override
  Widget build(BuildContext context) {
    final color = trophyTypeColors[trophy.type]!;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        border: Border.all(color: color.withValues(alpha: 0.6)),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.emoji_events, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            trophy.title,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              letterSpacing: 0.5,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Bronze', group: 'Trophy Chip')
Widget trophyChipBronze() => const TrophyChip(
  trophy: Trophy(
    id: 'bronze_1',
    title: 'Bronze Trophy',
    type: TrophyType.bronze,
    description: 'Earn a bronze trophy',
    guide: 'Complete any task',
    missable: false,
    iconAsset: 'assets/trophies/bronze.png',
    order: 1,
  ),
);

@Preview(name: 'Gold', group: 'Trophy Chip')
Widget trophyChipGold() => const TrophyChip(
  trophy: Trophy(
    id: 'gold_1',
    title: 'Gold Trophy',
    type: TrophyType.gold,
    description: 'Earn a gold trophy',
    guide: 'Complete all tasks',
    missable: false,
    iconAsset: 'assets/trophies/gold.png',
    order: 2,
  ),
);

@Preview(name: 'Platinum', group: 'Trophy Chip')
Widget trophyChipPlatinum() => const TrophyChip(
  trophy: Trophy(
    id: 'plat_1',
    title: 'Platinum Trophy',
    type: TrophyType.platinum,
    description: 'Earn platinum',
    guide: 'Unlock all trophies',
    missable: false,
    iconAsset: 'assets/trophies/platinum.png',
    order: 3,
  ),
);
