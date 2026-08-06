import 'package:flutter/material.dart';

import '../viewmodels/game_list_view_model.dart';
import 'game_sort_menu.dart';
import 'trophy_count_card.dart';

class GameFilterBar extends StatelessWidget {
  const GameFilterBar({super.key, required this.viewModel});

  final GameListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final platforms = viewModel.platforms;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
          child: SearchBar(
            hintText: 'Search games',
            leading: const Icon(Icons.search),
            elevation: const WidgetStatePropertyAll(0),
            onChanged: viewModel.setQuery,
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: Row(
            children: [
              Expanded(child: TrophyCountCard(viewModel: viewModel)),
              const SizedBox(width: 12),
              GameSortMenu(viewModel: viewModel),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 0),
          child: SegmentedButton<GameStatusFilter>(
            segments: const [
              ButtonSegment(value: GameStatusFilter.all, label: Text('All')),
              ButtonSegment(
                value: GameStatusFilter.inProgress,
                label: Text('Playing'),
              ),
              ButtonSegment(
                value: GameStatusFilter.notStarted,
                label: Text('New'),
              ),
              ButtonSegment(
                value: GameStatusFilter.completed,
                label: Text('Done'),
              ),
            ],
            selected: {viewModel.statusFilter},
            showSelectedIcon: false,
            onSelectionChanged: (selection) =>
                viewModel.setStatusFilter(selection.first),
          ),
        ),
        if (platforms.length > 1 || viewModel.hasGuides)
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
            child: Row(
              children: [
                for (final platform in platforms) ...[
                  FilterChip(
                    label: Text(platform),
                    selected: viewModel.selectedPlatforms.contains(platform),
                    onSelected: (_) => viewModel.togglePlatform(platform),
                  ),
                  const SizedBox(width: 8),
                ],
                if (viewModel.hasGuides)
                  FilterChip(
                    label: const Text('Has guide'),
                    avatar: viewModel.guideOnly
                        ? null
                        : const Icon(Icons.menu_book_outlined, size: 18),
                    selected: viewModel.guideOnly,
                    onSelected: viewModel.setGuideOnly,
                  ),
              ],
            ),
          ),
      ],
    );
  }
}
