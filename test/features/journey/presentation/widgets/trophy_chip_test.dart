import 'package:trophy_journey/features/journey/presentation/widgets/trophy_chip.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const sinspawn = Trophy(
  id: 'tr1',
  title: 'Sinspawn Slayer',
  type: TrophyType.silver,
  description: 'description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/tr1.png',
  order: 0,
);

Future<void> pumpChip(WidgetTester tester, Trophy trophy) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: Center(child: TrophyChip(trophy: trophy)),
    ),
  ),
);

void main() {
  testWidgets('shows the trophy title', (tester) async {
    await pumpChip(tester, sinspawn);

    expect(find.text('Sinspawn Slayer'), findsOneWidget);
    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
  });

  testWidgets('colours itself by trophy type', (tester) async {
    await pumpChip(tester, sinspawn);

    final icon = tester.widget<Icon>(find.byIcon(Icons.emoji_events));
    expect(icon.color, trophyTypeColors[TrophyType.silver]);
  });

  testWidgets('uses the platinum colour for platinum trophies', (tester) async {
    await pumpChip(
      tester,
      const Trophy(
        id: 'tr2',
        title: 'Platinum',
        type: TrophyType.platinum,
        description: 'description',
        guide: 'guide',
        missable: false,
        iconAsset: 'assets/icons/tr2.png',
        order: 1,
      ),
    );

    final icon = tester.widget<Icon>(find.byIcon(Icons.emoji_events));
    expect(icon.color, trophyTypeColors[TrophyType.platinum]);
  });
}
