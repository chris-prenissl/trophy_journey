import 'package:flutter/material.dart';

import '../../../../core/di/app_scope.dart';
import '../../../trophies/domain/entities/game.dart';
import '../viewmodels/journey_view_model.dart';
import '../widgets/journey_step_card.dart';

class JourneyScreen extends StatefulWidget {
  const JourneyScreen({super.key, required this.game});

  final Game game;

  @override
  State<JourneyScreen> createState() => _JourneyScreenState();
}

class _JourneyScreenState extends State<JourneyScreen> {
  JourneyViewModel? _viewModel;
  final _stepKeys = <String, GlobalKey>{};
  bool _didAutoScroll = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    _viewModel ??= AppScope.journeyFactoryOf(context)(widget.game.id)..load();
  }

  @override
  void dispose() {
    _viewModel?.dispose();
    super.dispose();
  }

  void _scrollToInitialStep(JourneyViewModel viewModel) {
    if (_didAutoScroll) return;
    _didAutoScroll = true;
    final steps = viewModel.steps;
    final index = viewModel.initialStepIndex;
    if (index <= 0 || index >= steps.length) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final context = _stepKeys[steps[index].id]?.currentContext;
      if (context == null) return;
      Scrollable.ensureVisible(
        context,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = _viewModel!;
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Journey — ${widget.game.title}')),
      body: ListenableBuilder(
        listenable: viewModel,
        builder: (context, _) {
          if (viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          _scrollToInitialStep(viewModel);
          final steps = viewModel.steps;
          return ListView(
            padding: const EdgeInsets.only(bottom: 24),
            children: [
              Card(
                margin: const EdgeInsets.all(12),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Single-playthrough roadmap',
                        style: theme.textTheme.titleSmall,
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(2),
                        child: LinearProgressIndicator(
                          value: viewModel.progress,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${viewModel.checkedTaskCount} / '
                        '${viewModel.totalTaskCount} tasks done',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              for (final (index, step) in steps.indexed)
                KeyedSubtree(
                  key: _stepKeys.putIfAbsent(step.id, GlobalKey.new),
                  child: JourneyStepCard(
                    step: step,
                    stepNumber: index + 1,
                    viewModel: viewModel,
                    initiallyExpanded: index == viewModel.initialStepIndex,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
