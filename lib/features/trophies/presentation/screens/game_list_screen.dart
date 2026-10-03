import 'package:trophy_journey/features/trophies/presentation/widgets/game_tile.dart';
import 'package:material_ui/material_ui.dart';

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
  final _scaffoldKey = GlobalKey<ScaffoldState>();
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

  Future<void> _signOut() async {
    final authViewModel = AppScope.of(context).authViewModel;
    Navigator.of(context).pop();
    await authViewModel.signOut();
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
          key: _scaffoldKey,
          appBar: AppBar(
            title: const Text('Trophy Journey'),
            actions: [
              IconButton(
                icon: const Icon(Icons.menu),
                tooltip: 'Menu',
                onPressed: () => _scaffoldKey.currentState?.openEndDrawer(),
              ),
            ],
          ),
          endDrawer: _AppMenu(onSignOut: _signOut),
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

class _AppMenu extends StatelessWidget {
  const _AppMenu({required this.onSignOut});

  final VoidCallback onSignOut;

  @override
  Widget build(BuildContext context) {
    return Drawer(
      width: 260,
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 20, 20, 4),
              child: Text(
                'Account',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            ListTile(
              leading: const Icon(Icons.logout),
              title: const Text('Sign out of PSN'),
              onTap: onSignOut,
            ),
          ],
        ),
      ),
    );
  }
}
