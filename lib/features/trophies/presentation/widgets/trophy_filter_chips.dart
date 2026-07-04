import 'package:flutter/material.dart';

import '../viewmodels/trophy_list_view_model.dart';

class TrophyFilterChips extends StatelessWidget {
  const TrophyFilterChips({super.key, required this.viewModel});

  final TrophyListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      children: [
        if (viewModel.hasMissables)
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
