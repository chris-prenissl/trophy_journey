import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ordinary = Trophy(
  id: 't1',
  title: 'Ordinary',
  type: TrophyType.bronze,
  description: 'A short description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/final-fantasy-xvi/fistful-of-steel.png',
  order: 0,
);

const missable = Trophy(
  id: 't2',
  title: 'Missable',
  type: TrophyType.gold,
  description: 'Another description',
  guide: 'guide',
  missable: true,
  iconAsset: 'assets/icons/final-fantasy-xvi/every-damn-sinew.png',
  order: 1,
);

Future<void> pumpTile(
  WidgetTester tester, {
  Trophy trophy = ordinary,
  bool achieved = false,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: TrophyTile(
        trophy: trophy,
        achieved: achieved,
        onTap: onTap ?? () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the title, description and type badge', (tester) async {
    await pumpTile(tester);

    expect(find.text('Ordinary'), findsOneWidget);
    expect(find.text('A short description'), findsOneWidget);
    expect(find.text('BRONZE'), findsOneWidget);
    expect(find.byType(MissableBadge), findsNothing);
  });

  testWidgets('shows a missable badge for missable trophies', (tester) async {
    await pumpTile(tester, trophy: missable);

    expect(find.byType(MissableBadge), findsOneWidget);
    expect(find.text('GOLD'), findsOneWidget);
  });

  testWidgets('marks earned trophies with a filled check', (tester) async {
    await pumpTile(tester, achieved: true);

    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNothing);
  });

  testWidgets('shows an empty marker for unearned trophies', (tester) async {
    await pumpTile(tester, achieved: false);

    expect(find.byIcon(Icons.circle_outlined), findsOneWidget);
    expect(find.byIcon(Icons.check_circle), findsNothing);
  });

  testWidgets('does not strike through the title', (tester) async {
    await pumpTile(tester, achieved: true);

    final title = tester.widget<Text>(find.text('Ordinary'));
    expect(title.style?.decoration, isNot(TextDecoration.lineThrough));
  });

  testWidgets('offers no way to tick the trophy off', (tester) async {
    await pumpTile(tester, achieved: false);

    expect(find.byType(Checkbox), findsNothing);
  });

  testWidgets('calls onTap when the tile is tapped', (tester) async {
    int taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    await tester.tap(find.text('Ordinary'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
