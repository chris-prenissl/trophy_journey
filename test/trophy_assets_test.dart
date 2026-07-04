import 'dart:convert';
import 'dart:io';

import 'package:final_fantasy_guide/features/trophies/data/models/trophy_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final raw = File('assets/data/ffx_trophies.json').readAsStringSync();
  final models = (json.decode(raw) as List<dynamic>)
      .map((e) => TrophyModel.fromJson(e as Map<String, dynamic>))
      .toList();

  test('contains all 34 FFX trophies', () {
    expect(models, hasLength(34));

    final byType = <TrophyType, int>{};
    for (final trophy in models.map((m) => m.toEntity())) {
      byType[trophy.type] = (byType[trophy.type] ?? 0) + 1;
    }
    expect(byType[TrophyType.platinum], 1);
    expect(byType[TrophyType.gold], 5);
    expect(byType[TrophyType.silver], 8);
    expect(byType[TrophyType.bronze], 20);
  });

  test('Master Linguist is the only missable trophy', () {
    final missables = models.where((m) => m.missable).toList();
    expect(missables.map((m) => m.id), ['master-linguist']);
  });

  test('every trophy has non-empty content and a unique id', () {
    final ids = models.map((m) => m.id).toSet();
    expect(ids, hasLength(models.length));
    for (final model in models) {
      expect(model.title, isNotEmpty);
      expect(model.description, isNotEmpty);
      expect(model.guide, isNotEmpty);
    }
  });

  test('every referenced icon asset exists', () {
    for (final model in models) {
      expect(
        File(model.icon).existsSync(),
        isTrue,
        reason: 'missing icon for ${model.id}: ${model.icon}',
      );
    }
  });
}
