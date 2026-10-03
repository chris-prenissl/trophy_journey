import 'package:material_ui/material_ui.dart';

import '../viewmodels/game_list_view_model.dart';

class GameSortMenu extends StatelessWidget {
  const GameSortMenu({super.key, required this.viewModel});

  final GameListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
      alignmentOffset: const Offset(0, 4),
      menuChildren: [
        for (final sort in GameSort.values)
          RadioMenuButton<GameSort>(
            value: sort,
            groupValue: viewModel.sort,
            onChanged: (value) {
              if (value != null) viewModel.setSort(value);
            },
            child: Text(sort.label),
          ),
      ],
      builder: (context, controller, _) => FilledButton.tonalIcon(
        icon: const Icon(Icons.sort, size: 20),
        label: Text(viewModel.sort.label),
        style: FilledButton.styleFrom(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 18),
        ),
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
