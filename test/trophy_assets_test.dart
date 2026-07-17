import 'dart:convert';
import 'dart:io';

import 'package:final_fantasy_guide/features/trophies/data/models/game_model.dart';
import 'package:final_fantasy_guide/features/trophies/data/models/trophy_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';

List<TrophyModel> _loadTrophies(String gameId) {
  final raw = File('assets/data/trophies/$gameId.json').readAsStringSync();
  return (json.decode(raw) as List<dynamic>)
      .map((e) => TrophyModel.fromJson(e as Map<String, dynamic>))
      .toList();
}

void main() {
  final games = (json.decode(
    File('assets/data/games.json').readAsStringSync(),
  ) as List<dynamic>)
      .map((e) => GameModel.fromJson(e as Map<String, dynamic>))
      .toList();

  test('covers all mainline games except XI (never had trophies)', () {
    final numerals = games.map((g) => g.numeral).toList();
    expect(numerals, [
      'I', 'II', 'III', 'IV', 'V', 'VI', 'VII', 'VIII', 'IX', 'X',
      'XII', 'XIII', 'XIV', 'XV', 'XVI',
    ]);
  });

  test('every game has parseable trophies matching its declared count', () {
    for (final game in games) {
      final trophies = _loadTrophies(game.id);
      expect(trophies, isNotEmpty, reason: game.id);
      expect(trophies.length, game.trophyCount, reason: game.id);

      final ids = trophies.map((t) => t.id).toSet();
      expect(ids, hasLength(trophies.length),
          reason: 'duplicate trophy ids in ${game.id}');
      for (final t in trophies) {
        expect(t.title, isNotEmpty, reason: '${game.id}/${t.id}');
        expect(t.guide, isNotEmpty, reason: '${game.id}/${t.id}');
        expect(File(t.icon).existsSync(), isTrue,
            reason: 'missing icon ${t.icon}');
        expect(TrophyType.values, contains(t.toEntity().type));
      }
      if (game.cover.isNotEmpty) {
        expect(File(game.cover).existsSync(), isTrue,
            reason: 'missing cover ${game.cover}');
      }
    }
  });

  test('GameModel maps every field onto its domain entity', () {
    final game = games.firstWhere((g) => g.id == 'final-fantasy-x-hd');
    final entity = game.toEntity();

    expect(entity.id, game.id);
    expect(entity.title, game.title);
    expect(entity.numeral, game.numeral);
    expect(entity.coverAsset, game.cover);
    expect(entity.trophyCount, game.trophyCount);
  });

  test('FFX data is unchanged: 34 trophies, Master Linguist missable', () {
    final ffx = _loadTrophies('final-fantasy-x-hd');
    expect(ffx, hasLength(34));
    expect(
      ffx.where((t) => t.missable).map((t) => t.id),
      ['master-linguist'],
    );
  });
}
