import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../journey/presentation/screens/journey_screen.dart';
import '../../domain/entities/game.dart';
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
  TrophyListViewModel? _viewModel;
  bool _hasJourney = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_viewModel == null) {
      _viewModel = AppScope.trophyListFactoryOf(context)(widget.game.id)
        ..load();
      AppScope.hasJourneyOf(context)(widget.game.id).then((hasJourney) {
        if (mounted && hasJourney) setState(() => _hasJourney = true);
      });
    }
  }

  void _openJourney() {
    Navigator.of(context)
        .push(
          MaterialPageRoute<void>(
            builder: (_) => JourneyScreen(game: widget.game),
          ),
        )
        .then((_) => _viewModel?.refreshProgress());
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;
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
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 16),
                child: ProgressCircle(
                  achieved: viewModel.achievedCount,
                  total: viewModel.totalCount,
                ),
              ),
              TrophyFilterChips(viewModel: viewModel),
              const SizedBox(height: 8),
              Expanded(
                child: viewModel.visibleTrophies.isEmpty
                    ? const Center(child: Text('No trophies match filters'))
                    : ListView.builder(
                        padding:
                            EdgeInsets.only(bottom: _hasJourney ? 88 : 16),
                        itemCount: viewModel.visibleTrophies.length,
                        itemBuilder: (context, index) {
                          final trophy = viewModel.visibleTrophies[index];
                          return TrophyTile(
                            key: ValueKey(trophy.id),
                            trophy: trophy,
                            achieved: viewModel.isAchieved(trophy.id),
                            onToggle: () =>
                                viewModel.toggleAchieved(trophy.id),
                            onTap: () => Navigator.of(context).push(
                              MaterialPageRoute<void>(
                                builder: (_) => TrophyDetailScreen(
                                  trophy: trophy,
                                  viewModel: viewModel,
                                ),
                              ),
                            ),
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
