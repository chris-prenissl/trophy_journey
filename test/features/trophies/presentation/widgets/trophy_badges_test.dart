import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_badges.dart';

Future<void> pumpBadge(WidgetTester tester, Widget badge) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(body: Center(child: badge)),
  ),
);

void main() {
  testWidgets('labels every trophy type', (tester) async {
    for (final type in TrophyType.values) {
      await pumpBadge(tester, TrophyTypeBadge(type: type));

      expect(find.text(type.name.toUpperCase()), findsOneWidget);
    }
  });

  testWidgets('colours the badge by trophy type', (tester) async {
    await pumpBadge(tester, const TrophyTypeBadge(type: TrophyType.platinum));

    final icon = tester.widget<Icon>(find.byIcon(Icons.emoji_events));
    expect(icon.color, trophyTypeColors[TrophyType.platinum]);
  });

  testWidgets('marks missable trophies', (tester) async {
    await pumpBadge(tester, const MissableBadge());

    expect(find.text('MISSABLE'), findsOneWidget);
    expect(find.byIcon(Icons.warning_amber_rounded), findsOneWidget);
  });

  testWidgets('marks recommended tasks', (tester) async {
    await pumpBadge(tester, const RecommendedBadge());

    expect(find.text('DO EARLY'), findsOneWidget);
    expect(find.byIcon(Icons.bolt), findsOneWidget);
  });
}
