import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/game_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

const ffx = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: '',
  trophyCount: 4,
);

Future<void> pumpTile(
  WidgetTester tester, {
  Game game = ffx,
  int achievedCount = 0,
  VoidCallback? onTap,
}) => tester.pumpWidget(
  MaterialApp(
    home: Scaffold(
      body: GameTile(
        game: game,
        achievedCount: achievedCount,
        onTap: onTap ?? () {},
      ),
    ),
  ),
);

void main() {
  testWidgets('shows the title and trophy count', (tester) async {
    await pumpTile(tester, achievedCount: 1);

    expect(find.text('Final Fantasy X'), findsOneWidget);
    expect(find.text('1 / 4 trophies'), findsOneWidget);
  });

  testWidgets('shows a placeholder icon when there is no cover', (
    tester,
  ) async {
    await pumpTile(tester);

    expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    expect(find.byType(Image), findsNothing);
  });

  testWidgets('shows the cover when the game has one', (tester) async {
    await pumpTile(
      tester,
      game: const Game(
        id: 'ffxvi',
        title: 'Final Fantasy XVI',
        numeral: 'XVI',
        coverAsset: 'assets/covers/final-fantasy-xiii.png',
        trophyCount: 1,
      ),
    );

    expect(find.byType(Image), findsOneWidget);
    expect(find.byIcon(Icons.videogame_asset), findsNothing);
  });

  testWidgets('reflects partial progress in the indicator', (tester) async {
    await pumpTile(tester, achievedCount: 1);

    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.25);
    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
  });

  testWidgets('shows a trophy icon when the game is complete', (tester) async {
    await pumpTile(tester, achievedCount: 4);

    expect(find.byIcon(Icons.emoji_events), findsOneWidget);
    expect(find.byIcon(Icons.chevron_right), findsNothing);
  });

  testWidgets('is not complete when the game has no trophies at all', (
    tester,
  ) async {
    await pumpTile(
      tester,
      game: const Game(
        id: 'empty',
        title: 'Empty',
        numeral: 'O',
        coverAsset: '',
        trophyCount: 0,
      ),
    );

    expect(find.byIcon(Icons.chevron_right), findsOneWidget);
    final indicator = tester.widget<LinearProgressIndicator>(
      find.byType(LinearProgressIndicator),
    );
    expect(indicator.value, 0.0);
  });

  testWidgets('calls onTap when tapped', (tester) async {
    var taps = 0;
    await pumpTile(tester, onTap: () => taps++);

    await tester.tap(find.byType(GameTile));
    await tester.pumpAndSettle();

    expect(taps, 1);
  });
}
