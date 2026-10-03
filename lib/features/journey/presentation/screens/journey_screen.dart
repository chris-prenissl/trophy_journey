import 'package:material_ui/material_ui.dart';

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
  late final JourneyViewModel _viewModel;
  final _stepKeys = <String, GlobalKey>{};
  bool _didAutoScroll = false;

  @override
  void initState() {
    super.initState();
    _viewModel = AppScope.of(context).createJourneyViewModel(widget.game.id);
    _viewModel.addListener(_scrollToInitialStep);
    _viewModel.load();
  }

  @override
  void dispose() {
    _viewModel.removeListener(_scrollToInitialStep);
    _viewModel.dispose();
    super.dispose();
  }

  void _scrollToInitialStep() {
    if (_didAutoScroll || _viewModel.loading) return;

    final steps = _viewModel.steps;
    final index = _viewModel.initialStepIndex;
    _didAutoScroll = true;
    if (index <= 0 || index >= steps.length) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final stepContext = _stepKeys[steps[index].id]?.currentContext;
      if (stepContext == null) return;

      Scrollable.ensureVisible(
        stepContext,
        alignment: 0.1,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: Text('Journey — ${widget.game.title}')),
      body: ListenableBuilder(
        listenable: _viewModel,
        builder: (context, _) {
          if (_viewModel.loading) {
            return const Center(child: CircularProgressIndicator());
          }
          final steps = _viewModel.steps;
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
                          value: _viewModel.progress,
                          minHeight: 4,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '${_viewModel.checkedTaskCount} / '
                        '${_viewModel.totalTaskCount} tasks done',
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
                    viewModel: _viewModel,
                    initiallyExpanded: index == _viewModel.initialStepIndex,
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
