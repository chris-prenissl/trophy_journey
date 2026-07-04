import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';

class TrophyFilterChips extends StatelessWidget {
  const TrophyFilterChips({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    return Wrap(
      spacing: 8,
      children: [
        FilterChip(
          label: const Text('Missables'),
          avatar: viewModel.missablesOnly
              ? null
              : const Icon(Icons.warning_amber_rounded, size: 18),
          selected: viewModel.missablesOnly,
          onSelected: viewModel.setMissablesOnly,
        ),
        FilterChip(
          label: const Text('Hide achieved'),
          avatar: viewModel.hideAchieved
              ? null
              : const Icon(Icons.visibility_off_outlined, size: 18),
          selected: viewModel.hideAchieved,
          onSelected: viewModel.setHideAchieved,
        ),
      ],
    );
  }
}
