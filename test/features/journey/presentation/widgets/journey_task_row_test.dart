import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trophy_journey/features/journey/domain/entities/journey.dart';
import 'package:trophy_journey/features/journey/presentation/widgets/journey_task_row.dart';
import 'package:trophy_journey/features/journey/presentation/widgets/trophy_chip.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_badges.dart';

const plain = JourneyTask(id: 't1', title: 'Beat Sinspawn', trophyIds: []);

const withNote = JourneyTask(
  id: 't2',
  title: 'Grab the chest',
  note: 'Behind the waterfall',
  trophyIds: [],
);

const sinspawn = Trophy(
  id: 'tr1',
  title: 'Sinspawn Slayer',
  type: TrophyType.silver,
  description: 'description',
  guide: 'guide',
  iconAsset: 'assets/icons/tr1.png',
  order: 0,
);

Future<void> pumpRow(
  WidgetTester tester, {
  JourneyTask task = plain,
  bool checked = false,
  List<Trophy> trophies = const [],
  VoidCallback? onToggle,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: JourneyTaskRow(
        task: task,
        checked: checked,
        trophies: trophies,
        onToggle: onToggle ?? () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the task title', (tester) async {
    await pumpRow(tester);

    expect(find.text('Beat Sinspawn'), findsOneWidget);
    expect(find.byType(TrophyChip), findsNothing);
  });

  testWidgets('shows the note when there is one', (tester) async {
    await pumpRow(tester, task: withNote);

    expect(find.text('Behind the waterfall'), findsOneWidget);
  });

  testWidgets('lists the trophies the task unlocks', (tester) async {
    await pumpRow(tester, trophies: const [sinspawn]);

    expect(find.byType(TrophyChip), findsOneWidget);
    expect(find.text('Sinspawn Slayer'), findsOneWidget);
  });

  testWidgets('shows a missable badge', (tester) async {
    await pumpRow(
      tester,
      task: const JourneyTask(
        id: 't3',
        title: 'Missable task',
        trophyIds: [],
        flag: TaskFlag.missable,
      ),
    );

    expect(find.byType(MissableBadge), findsOneWidget);
    expect(find.byType(RecommendedBadge), findsNothing);
  });

  testWidgets('shows a recommended badge', (tester) async {
    await pumpRow(
      tester,
      task: const JourneyTask(
        id: 't4',
        title: 'Recommended task',
        trophyIds: [],
        flag: TaskFlag.recommended,
      ),
    );

    expect(find.byType(RecommendedBadge), findsOneWidget);
    expect(find.byType(MissableBadge), findsNothing);
  });

  testWidgets('strikes through the title when checked', (tester) async {
    await pumpRow(tester, checked: true);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
    final title = tester.widget<Text>(find.text('Beat Sinspawn'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('toggles from the row and from the checkbox', (tester) async {
    var toggles = 0;
    await pumpRow(tester, onToggle: () => toggles++);

    await tester.tap(find.text('Beat Sinspawn'));
    await tester.pumpAndSettle();
    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(toggles, 2);
  });
}
