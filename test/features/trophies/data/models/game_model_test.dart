import 'package:flutter_test/flutter_test.dart';
import 'package:trophy_journey/features/trophies/data/models/game_model.dart';

const gameJson = <String, dynamic>{
  'id': 'ffx',
  'title': 'Final Fantasy X',
  'numeral': 'X',
  'cover': 'assets/covers/ffx.png',
  'trophyCount': 36,
};

void main() {
  group('toEntity', () {
    test('maps cover onto coverAsset', () {
      final game = GameModel.fromJson(gameJson).toEntity();

      expect(game.id, 'ffx');
      expect(game.title, 'Final Fantasy X');
      expect(game.numeral, 'X');
      expect(game.coverAsset, 'assets/covers/ffx.png');
      expect(game.trophyCount, 36);
    });
  });
}
