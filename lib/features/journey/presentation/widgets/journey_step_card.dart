import 'package:flutter/material.dart';
import 'package:flutter/widget_previews.dart';

import '../../../trophies/presentation/widgets/trophy_badges.dart';
import '../../domain/entities/journey.dart';
import '../preview_mocks/mock_journey_view_model.dart';
import '../viewmodels/journey_view_model.dart';
import 'journey_task_row.dart';

class JourneyStepCard extends StatelessWidget {
  const JourneyStepCard({
    super.key,
    required this.step,
    required this.stepNumber,
    required this.viewModel,
    required this.initiallyExpanded,
  });

  final JourneyStep step;
  final int stepNumber;
  final JourneyViewModel viewModel;
  final bool initiallyExpanded;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final checkedCount = viewModel.checkedCountOf(step);
    final complete = viewModel.isStepComplete(step);
    final bookmarked = viewModel.isBookmarked(step.id);
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      child: ExpansionTile(
        key: PageStorageKey(step.id),
        shape: const Border(),
        collapsedShape: const Border(),
        initiallyExpanded: initiallyExpanded,
        leading: CircleAvatar(
          radius: 14,
          backgroundColor: complete
              ? theme.colorScheme.primary
              : theme.colorScheme.surfaceContainerHighest,
          child: complete
              ? Icon(Icons.check, size: 16, color: theme.colorScheme.onPrimary)
              : Text(
                  '$stepNumber',
                  style: theme.textTheme.labelMedium?.copyWith(
                    color: theme.colorScheme.onSurface,
                  ),
                ),
        ),
        title: Text(step.title, style: theme.textTheme.titleSmall),
        subtitle: Row(
          spacing: 6,
          children: [
            Text(
              '$checkedCount / ${step.tasks.length}',
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (step.hasMissable) ...[const MissableBadge()],
            if (step.hasRecommended) ...[const RecommendedBadge()],
          ],
        ),
        trailing: IconButton(
          icon: Icon(
            bookmarked ? Icons.bookmark : Icons.bookmark_border,
            color: bookmarked
                ? theme.colorScheme.primary
                : theme.colorScheme.onSurfaceVariant,
          ),
          tooltip: bookmarked ? 'Remove bookmark' : 'Bookmark this step',
          onPressed: () => viewModel.toggleBookmark(step.id),
        ),
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  step.instructions,
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 8),
                for (final task in step.tasks)
                  JourneyTaskRow(
                    key: ValueKey(task.id),
                    task: task,
                    checked: viewModel.isTaskChecked(task.id),
                    trophies: task.trophyIds
                        .map(viewModel.trophyById)
                        .nonNulls
                        .toList(),
                    onToggle: () => viewModel.toggleTask(task.id),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

@Preview(name: 'Basic Step', group: 'Journey Step Card')
Widget journeyStepCardBasic() => JourneyStepCard(
  step: const JourneyStep(
    id: 'step_1',
    title: 'First Steps',
    instructions: 'Begin your journey here. Talk to the guide.',
    tasks: [
      JourneyTask(id: 'task_1', title: 'Talk to guide', trophyIds: []),
      JourneyTask(id: 'task_2', title: 'Check map', trophyIds: []),
      JourneyTask(id: 'task_3', title: 'Equip sword', trophyIds: []),
    ],
  ),
  stepNumber: 1,
  viewModel: MockJourneyViewModel(),
  initiallyExpanded: true,
);

@Preview(name: 'With Missable', group: 'Journey Step Card')
Widget journeyStepCardMissable() => JourneyStepCard(
  step: const JourneyStep(
    id: 'step_2',
    title: 'Hidden Secrets',
    instructions: 'Find optional rewards. Some items can be missed!',
    tasks: [
      JourneyTask(
        id: 'task_4',
        title: 'Find hidden materia',
        trophyIds: [],
        flag: TaskFlag.missable,
      ),
      JourneyTask(
        id: 'task_5',
        title: 'Collect rare item',
        trophyIds: [],
        flag: TaskFlag.recommended,
      ),
    ],
  ),
  stepNumber: 2,
  viewModel: MockJourneyViewModel(),
  initiallyExpanded: false,
);
