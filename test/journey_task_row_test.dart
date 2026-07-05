import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/presentation/widgets/journey_task_row.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

Widget _host(
  JourneyTask task, {
  VoidCallback? onToggle,
  List<Trophy> trophies = const [],
}) =>
    MaterialApp(
      home: Scaffold(
        body: JourneyTaskRow(
          task: task,
          checked: false,
          trophies: trophies,
          onToggle: onToggle ?? () {},
        ),
      ),
    );

void main() {
  testWidgets('recommended task shows the DO EARLY badge only', (tester) async {
    await tester.pumpWidget(_host(const JourneyTask(
      id: 't',
      title: 'do it early',
      trophyIds: ['x'],
      flag: TaskFlag.recommended,
    )));

    expect(find.byType(RecommendedBadge), findsOneWidget);
    expect(find.byType(MissableBadge), findsNothing);
    expect(find.text('DO EARLY'), findsOneWidget);
  });

  testWidgets('missable task shows the MISSABLE badge only', (tester) async {
    await tester.pumpWidget(_host(const JourneyTask(
      id: 't',
      title: 'grab it now',
      trophyIds: ['x'],
      flag: TaskFlag.missable,
    )));

    expect(find.byType(MissableBadge), findsOneWidget);
    expect(find.byType(RecommendedBadge), findsNothing);
  });

  testWidgets('ordinary task shows no flag badge', (tester) async {
    await tester.pumpWidget(_host(const JourneyTask(
      id: 't',
      title: 'nothing special',
      trophyIds: ['x'],
    )));

    expect(find.byType(MissableBadge), findsNothing);
    expect(find.byType(RecommendedBadge), findsNothing);
  });

  testWidgets('renders a chip for each linked trophy', (tester) async {
    await tester.pumpWidget(_host(
      const JourneyTask(id: 't', title: 'collect', trophyIds: ['ling']),
      trophies: [
        const Trophy(
          id: 'ling',
          title: 'Master Linguist',
          type: TrophyType.gold,
          description: 'd',
          guide: 'g',
          missable: false,
          iconAsset: 'i.jpg',
          order: 0,
        ),
      ],
    ));

    expect(find.text('Master Linguist'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('tapping the row invokes the toggle callback', (tester) async {
    var toggled = 0;
    await tester.pumpWidget(_host(
      const JourneyTask(id: 't', title: 'tap me', trophyIds: ['x']),
      onToggle: () => toggled++,
    ));

    await tester.tap(find.text('tap me'));
    expect(toggled, 1);
  });
}
