import 'package:flutter/material.dart';

import '../../domain/entities/trophy.dart';

const trophyTypeColors = <TrophyType, Color>{
  TrophyType.bronze: Color(0xFFCD7F32),
  TrophyType.silver: Color(0xFFB6BDC6),
  TrophyType.gold: Color(0xFFE6B93C),
  TrophyType.platinum: Color(0xFF7FD4E4),
};

class TrophyTypeBadge extends StatelessWidget {
  const TrophyTypeBadge({super.key, required this.type});

  final TrophyType type;

  @override
  Widget build(BuildContext context) {
    final color = trophyTypeColors[type]!;
    return _Badge(
      label: type.name.toUpperCase(),
      color: color,
      icon: Icons.emoji_events,
    );
  }
}

class MissableBadge extends StatelessWidget {
  const MissableBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Badge(
      label: 'MISSABLE',
      color: Color(0xFFE05A5A),
      icon: Icons.warning_amber_rounded,
    );
  }
}

class RecommendedBadge extends StatelessWidget {
  const RecommendedBadge({super.key});

  @override
  Widget build(BuildContext context) {
    return const _Badge(
      label: 'DO EARLY',
      color: Color(0xFFE0A32E),
      icon: Icons.bolt,
    );
  }
}

class _Badge extends StatelessWidget {
  const _Badge({required this.label, required this.color, required this.icon});

  final String label;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
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
          Icon(icon, size: 12, color: color),
          const SizedBox(width: 3),
          Text(
            label,
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
