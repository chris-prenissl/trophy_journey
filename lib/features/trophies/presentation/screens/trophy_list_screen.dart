import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../widgets/progress_circle.dart';
import '../widgets/trophy_filter_chips.dart';
import '../widgets/trophy_tile.dart';
import 'trophy_detail_screen.dart';

class TrophyListScreen extends StatelessWidget {
  const TrophyListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final viewModel = AppScope.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Final Fantasy X HD Trophies')),
      body: viewModel.loading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  child: ProgressCircle(
                    achieved: viewModel.achievedCount,
                    total: viewModel.totalCount,
                  ),
                ),
                const TrophyFilterChips(),
                const SizedBox(height: 8),
                Expanded(
                  child: viewModel.visibleTrophies.isEmpty
                      ? const Center(child: Text('No trophies match filters'))
                      : ListView.builder(
                          padding: const EdgeInsets.only(bottom: 16),
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
                                  builder: (_) =>
                                      TrophyDetailScreen(trophy: trophy),
                                ),
                              ),
                            );
                          },
                        ),
                ),
              ],
            ),
    );
  }
}
