import 'dart:convert';
import 'dart:io';

import 'package:final_fantasy_guide/features/journey/data/models/journey_model.dart';
import 'package:final_fantasy_guide/features/trophies/data/models/trophy_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';

const _ffxId = 'final-fantasy-x-hd';

void main() {
  final journey = JourneyModel.fromJson(
    json.decode(
      File('assets/data/journeys/$_ffxId.json').readAsStringSync(),
    ) as Map<String, dynamic>,
  ).toEntity();

  final trophies = (json.decode(
    File('assets/data/trophies/$_ffxId.json').readAsStringSync(),
  ) as List<dynamic>)
      .map((e) => TrophyModel.fromJson(e as Map<String, dynamic>).toEntity())
      .toList();

  test('journey belongs to FFX and has ordered, non-empty steps', () {
    expect(journey.gameId, _ffxId);
    expect(journey.steps, isNotEmpty);
    for (final step in journey.steps) {
      expect(step.title, isNotEmpty, reason: step.id);
      expect(step.instructions, isNotEmpty, reason: step.id);
      expect(step.tasks, isNotEmpty, reason: step.id);
    }
  });

  test('step and task ids are unique game-wide', () {
    final stepIds = journey.steps.map((s) => s.id).toList();
    expect(stepIds.toSet(), hasLength(stepIds.length));

    final taskIds = journey.allTasks.map((t) => t.id).toList();
    expect(taskIds.toSet(), hasLength(taskIds.length));
  });

  test('every task references at least one existing trophy', () {
    final trophyIds = trophies.map((t) => t.id).toSet();
    for (final task in journey.allTasks) {
      expect(task.trophyIds, isNotEmpty, reason: task.id);
      for (final id in task.trophyIds) {
        expect(trophyIds, contains(id), reason: '${task.id} -> $id');
      }
    }
  });

  test('every non-platinum trophy is covered; the platinum is not', () {
    final referenced = journey.taskIdsByTrophyId.keys.toSet();
    for (final trophy in trophies) {
      if (trophy.type == TrophyType.platinum) {
        expect(referenced, isNot(contains(trophy.id)),
            reason: 'platinum must pop on its own');
      } else {
        expect(referenced, contains(trophy.id),
            reason: 'trophy ${trophy.id} has no journey task');
      }
    }
  });

  test('permanently missable pickups are flagged', () {
    final missableTaskIds =
        journey.allTasks.where((t) => t.missable).map((t) => t.id).toSet();
    expect(missableTaskIds, containsAll(['home-primers-19-21',
        'bevelle-primer-22', 'ss-winno-jecht-shot']));
  });
}
