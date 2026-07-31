import 'package:trophy_journey/features/trophies/presentation/widgets/game_tile.dart';
import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../domain/entities/game.dart';
import '../viewmodels/game_list_view_model.dart';
import '../widgets/game_filter_bar.dart';
import 'trophy_list_screen.dart';

class GameListScreen extends StatefulWidget {
  const GameListScreen({super.key});

  @override
  State<GameListScreen> createState() => _GameListScreenState();
}

class _GameListScreenState extends State<GameListScreen> {
  late final GameListViewModel _viewModel;

  @override
  void initState() {
    super.initState();
    _viewModel = AppScope.of(context).createGameListViewModel();
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openGame(Game game) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => TrophyListScreen(game: game)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: _viewModel,
      builder: (context, _) {
        return Scaffold(
          appBar: AppBar(
            title: const Text('Trophy Journey'),
            actions: [
              if (!_viewModel.loading) ...[
                Center(
                  child: Text(
                    '${_viewModel.totalAchievedCount} / '
                    '${_viewModel.totalTrophyCount}',
                    style: Theme.of(context).textTheme.titleSmall,
                  ),
                ),
                _SortMenu(viewModel: _viewModel),
              ],
            ],
          ),
          body: _viewModel.loading
              ? const Center(child: CircularProgressIndicator())
              : Column(
                  children: [
                    GameFilterBar(viewModel: _viewModel),
                    Expanded(
                      child: _viewModel.visibleGames.isEmpty
                          ? Center(
                              child: Text(
                                'No games match',
                                style: Theme.of(context).textTheme.bodyMedium,
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(vertical: 8),
                              itemCount: _viewModel.visibleGames.length,
                              itemBuilder: (context, index) {
                                final game = _viewModel.visibleGames[index];
                                return GameTile(
                                  game: game,
                                  achievedCount: _viewModel.achievedCountFor(
                                    game.id,
                                  ),
                                  onTap: () => _openGame(game),
                                );
                              },
                            ),
                    ),
                  ],
                ),
        );
      },
    );
  }
}

class _SortMenu extends StatelessWidget {
  const _SortMenu({required this.viewModel});

  final GameListViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    return MenuAnchor(
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
      builder: (context, controller, _) => IconButton(
        icon: const Icon(Icons.sort),
        tooltip: 'Sort',
        onPressed: () =>
            controller.isOpen ? controller.close() : controller.open(),
      ),
    );
  }
}
