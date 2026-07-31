import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_tile.dart';
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
  VoidCallback? onToggle,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: TrophyTile(
        trophy: trophy,
        achieved: achieved,
        onToggle: onToggle ?? () {},
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

  testWidgets('checkbox follows the achieved flag', (tester) async {
    await pumpTile(tester, achieved: true);

    final checkbox = tester.widget<Checkbox>(find.byType(Checkbox));
    expect(checkbox.value, isTrue);
  });

  testWidgets('strikes through the title once achieved', (tester) async {
    await pumpTile(tester, achieved: true);

    final title = tester.widget<Text>(find.text('Ordinary'));
    expect(title.style?.decoration, TextDecoration.lineThrough);
  });

  testWidgets('calls onToggle when the checkbox is tapped', (tester) async {
    var toggles = 0;
    await pumpTile(tester, onToggle: () => toggles++);

    await tester.tap(find.byType(Checkbox));
    await tester.pumpAndSettle();

    expect(toggles, 1);
  });

  testWidgets('calls onTap when the tile is tapped', (tester) async {
    int taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    await tester.tap(find.text('Ordinary'));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
