import 'package:material_ui/material_ui.dart';

import '../../../../core/di/app_scope.dart';
import '../../../journey/presentation/screens/journey_screen.dart';
import '../../domain/entities/game.dart';
import '../../domain/entities/trophy.dart';
import '../viewmodels/trophy_list_view_model.dart';
import '../widgets/progress_circle.dart';
import '../widgets/trophy_filter_chips.dart';
import '../widgets/trophy_tile.dart';
import 'trophy_detail_screen.dart';

class TrophyListScreen extends StatefulWidget {
  const TrophyListScreen({super.key, required this.game});

  final Game game;

  @override
  State<TrophyListScreen> createState() => _TrophyListScreenState();
}

class _TrophyListScreenState extends State<TrophyListScreen> {
  late final TrophyListViewModel _viewModel;
  bool _hasJourney = false;

  @override
  void initState() {
    super.initState();
    final dependencies = AppScope.of(context);
    _viewModel = dependencies.createTrophyListViewModel(widget.game.id);
    _viewModel.load();
    dependencies.hasJourneyUseCase(widget.game.id).then((hasJourney) {
      if (mounted && hasJourney) setState(() => _hasJourney = true);
    });
  }

  @override
  void dispose() {
    _viewModel.dispose();
    super.dispose();
  }

  void _openJourney() {
    Navigator.of(
      context,
    ).push(MaterialPageRoute(builder: (_) => JourneyScreen(game: widget.game)));
  }

  void _openTrophyDetail(Trophy trophy) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) =>
            TrophyDetailScreen(gameId: widget.game.id, trophy: trophy),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(widget.game.title)),
      floatingActionButton: _hasJourney
          ? FloatingActionButton.extended(
              onPressed: _openJourney,
              icon: const Icon(Icons.map_outlined),
              label: const Text('Journey'),
            )
          : null,
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final trophies = _viewModel.visibleTrophies;
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ProgressCircle(
                  achieved: _viewModel.achievedCount,
                  total: _viewModel.totalCount,
                ),
              ),
              TrophyFilterChips(viewModel: _viewModel),
              const SizedBox(height: 8),
              Expanded(
                child: trophies.isEmpty
                    ? const Center(child: Text('No trophies match filters'))
                    : ListView.builder(
                        padding: EdgeInsets.only(bottom: _hasJourney ? 88 : 16),
                        itemCount: trophies.length,
                        itemBuilder: (context, index) {
                          final trophy = trophies[index];
                          return TrophyTile(
                            key: ValueKey(trophy.id),
                            trophy: trophy,
                            achieved: _viewModel.isAchieved(trophy.id),
                            onTap: () => _openTrophyDetail(trophy),
                          );
                        },
                      ),
              ),
            ],
          );
        },
      ),
    );
  }
}
