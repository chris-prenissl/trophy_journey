import 'package:material_ui/material_ui.dart';
import 'package:flutter/widget_previews.dart';

class ProgressCircle extends StatelessWidget {
  const ProgressCircle({
    super.key,
    required this.achieved,
    required this.total,
  });

  final int achieved;
  final int total;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final progress = total == 0 ? 0.0 : achieved / total;
    return TweenAnimationBuilder<double>(
      tween: Tween(end: progress),
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeOutCubic,
      builder: (context, value, _) {
        return SizedBox(
          width: 120,
          height: 120,
          child: Stack(
            fit: StackFit.expand,
            alignment: Alignment.center,
            children: [
              CircularProgressIndicator(
                value: value,
                strokeWidth: 8,
                strokeCap: StrokeCap.round,
                backgroundColor: theme.colorScheme.onSurface.withValues(
                  alpha: 0.1,
                ),
              ),
              Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    '$achieved / $total',
                    style: theme.textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    '${(value * 100).round()}%',
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ],
          ),
        );
      },
    );
  }
}

@Preview(name: 'Partial Progress', group: 'Progress Circle')
Widget progressCirclePartial() => const ProgressCircle(achieved: 15, total: 50);

@Preview(name: 'Complete', group: 'Progress Circle')
Widget progressCircleComplete() => const ProgressCircle(achieved: 50, total: 50);

@Preview(name: 'Empty', group: 'Progress Circle')
Widget progressCircleEmpty() => const ProgressCircle(achieved: 0, total: 50);
