import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy_progress.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('Game carries its fields', () {
    const game = Game(
      id: 'final-fantasy-x-hd',
      title: 'Final Fantasy X',
      numeral: 'X',
      coverAsset: 'assets/covers/x.jpg',
      trophyCount: 34,
    );

    expect(game.id, 'final-fantasy-x-hd');
    expect(game.title, 'Final Fantasy X');
    expect(game.numeral, 'X');
    expect(game.coverAsset, 'assets/covers/x.jpg');
    expect(game.trophyCount, 34);
  });

  test('Trophy carries its fields', () {
    const trophy = Trophy(
      id: 'striker',
      title: 'Striker',
      type: TrophyType.bronze,
      description: 'Learn the Jecht Shot',
      guide: 'guide text',
      missable: false,
      iconAsset: 'assets/icons/striker.jpg',
      order: 8,
    );

    expect(trophy.id, 'striker');
    expect(trophy.type, TrophyType.bronze);
    expect(trophy.missable, isFalse);
    expect(trophy.order, 8);
    expect(TrophyType.values, hasLength(4));
  });

  test('TrophyProgress defaults achievedAt to null and keeps it when set', () {
    const pending = TrophyProgress(trophyId: 'striker', achieved: false);
    expect(pending.achieved, isFalse);
    expect(pending.achievedAt, isNull);

    final at = DateTime(2026, 7, 5);
    final done = TrophyProgress(
      trophyId: 'striker',
      achieved: true,
      achievedAt: at,
    );
    expect(done.achieved, isTrue);
    expect(done.achievedAt, at);
  });
}
