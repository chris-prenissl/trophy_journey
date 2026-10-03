import 'package:material_ui/material_ui.dart';

import '../viewmodels/game_list_view_model.dart';
import 'game_sort_menu.dart';
import 'trophy_count_card.dart';

class const GameFilterBar({
  super.key,
  required final GameListViewModel viewModel,
}) extends StatelessWidget {
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
        if (platforms.length > 1)
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
              ],
            ),
          ),
      ],
    );
  }
}
