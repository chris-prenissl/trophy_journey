import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:flutter/material.dart';

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