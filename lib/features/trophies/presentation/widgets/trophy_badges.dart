import 'package:material_ui/material_ui.dart';

import '../../domain/entities/trophy.dart';

const trophyTypeColors = <TrophyType, Color>{
  TrophyType.bronze: Color(0xFFCD7F32),
  TrophyType.silver: Color(0xFFB6BDC6),
  TrophyType.gold: Color(0xFFE6B93C),
  TrophyType.platinum: Color(0xFF7FD4E4),
};

class const TrophyTypeBadge({super.key, required final TrophyType type})
    extends StatelessWidget {
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

class const MissableBadge({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _Badge(
      label: 'MISSABLE',
      color: Color(0xFFE05A5A),
      icon: Icons.warning_amber_rounded,
    );
  }
}

class const RecommendedBadge({super.key}) extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return const _Badge(
      label: 'DO EARLY',
      color: Color(0xFFE0A32E),
      icon: Icons.bolt,
    );
  }
}

class const _Badge({
  required final String label,
  required final Color color,
  required final IconData icon,
}) extends StatelessWidget {
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
