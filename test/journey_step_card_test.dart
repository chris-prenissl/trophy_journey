import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_progress_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_checked_task_ids.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_bookmark.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_journey_bookmark.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_task_checked.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/journey/presentation/widgets/journey_step_card.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const _gameId = 'test-game';

final _step = JourneyStep(
  id: 'step-1',
  title: 'Besaid',
  instructions: 'Grab everything here.',
  tasks: const [
    JourneyTask(id: 'primer', title: 'Primer II', trophyIds: ['ling']),
    JourneyTask(
      id: 'sphere',
      title: 'Destruction Sphere',
      trophyIds: ['anima'],
      flag: TaskFlag.recommended,
    ),
    JourneyTask(
      id: 'lost',
      title: 'One-time pickup',
      trophyIds: ['ling'],
      flag: TaskFlag.missable,
    ),
  ],
);

class _FakeJourneyRepository implements JourneyRepository {
  @override
  Future<Journey> getJourney(String gameId) async =>
      Journey(gameId: _gameId, steps: [_step]);
  @override
  Future<bool> hasJourney(String gameId) async => true;
}

class _FakeJourneyProgressRepository implements JourneyProgressRepository {
  final Map<String, Set<String>> checked = {};
  final Map<String, String> bookmarks = {};
  @override
  Future<Set<String>> getCheckedTaskIds(String g) async => {...?checked[g]};
  @override
  Future<void> setTaskChecked(String g, String t, bool v) async =>
      v ? (checked[g] ??= {}).add(t) : (checked[g] ??= {}).remove(t);
  @override
  Future<String?> getBookmark(String g) async => bookmarks[g];
  @override
  Future<void> setBookmark(String g, String? s) async =>
      s == null ? bookmarks.remove(g) : bookmarks[g] = s;
}

class _FakeTrophyRepository implements TrophyRepository {
  @override
  Future<List<Trophy>> getTrophies(String gameId) async => [
        _t('ling'),
        _t('anima'),
      ];
}

Trophy _t(String id) => Trophy(
      id: id,
      title: id,
      type: TrophyType.gold,
      description: 'd',
      guide: 'g',
      missable: false,
      iconAsset: 'i.jpg',
      order: 0,
    );

Future<JourneyViewModel> _loadedVm() async {
  final progress = _FakeJourneyProgressRepository();
  final vm = JourneyViewModel(
    _gameId,
    GetJourney(_FakeJourneyRepository()),
    GetTrophies(_FakeTrophyRepository()),
    GetCheckedTaskIds(progress),
    SetTaskChecked(progress),
    GetJourneyBookmark(progress),
    SetJourneyBookmark(progress),
  );
  await vm.load();
  return vm;
}

Widget _host(Widget child) =>
    MaterialApp(home: Scaffold(body: ListView(children: [child])));

void main() {
  testWidgets('renders header, step badges and expanded task rows',
      (tester) async {
    final vm = await _loadedVm();
    await tester.pumpWidget(_host(JourneyStepCard(
      step: _step,
      stepNumber: 1,
      viewModel: vm,
      initiallyExpanded: true,
    )));
    await tester.pumpAndSettle();

    expect(find.text('Besaid'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    // A recommended and a missable task in the step surface both badges.
    expect(find.byType(MissableBadge), findsWidgets);
    expect(find.byType(RecommendedBadge), findsWidgets);
    // Expanded body shows the instructions and every task title.
    expect(find.text('Grab everything here.'), findsOneWidget);
    expect(find.text('Destruction Sphere'), findsOneWidget);
    expect(find.text('One-time pickup'), findsOneWidget);
  });

  testWidgets('bookmark button toggles the step bookmark', (tester) async {
    final vm = await _loadedVm();
    // The card is stateless; mirror the app by rebuilding it on notify.
    await tester.pumpWidget(_host(AnimatedBuilder(
      animation: vm,
      builder: (context, _) => JourneyStepCard(
        step: _step,
        stepNumber: 1,
        viewModel: vm,
        initiallyExpanded: false,
      ),
    )));

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pump();

    expect(vm.isBookmarked('step-1'), isTrue);
    expect(find.byIcon(Icons.bookmark), findsOneWidget);
  });

  testWidgets('checking a task updates the completed count', (tester) async {
    final vm = await _loadedVm();
    await tester.pumpWidget(_host(JourneyStepCard(
      step: _step,
      stepNumber: 1,
      viewModel: vm,
      initiallyExpanded: true,
    )));
    await tester.pumpAndSettle();

    await tester.tap(find.byType(Checkbox).first);
    await tester.pump();

    expect(vm.checkedCountOf(_step), 1);
  });
}
