import 'package:final_fantasy_guide/features/journey/data/models/journey_model.dart';
import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:flutter_test/flutter_test.dart';

const taskJson = <String, dynamic>{
  'id': 't1',
  'title': 'Beat Sinspawn',
  'note': 'Bring potions',
  'trophyIds': ['tr1', 'tr2'],
  'flag': 'missable',
};

const journeyJson = <String, dynamic>{
  'gameId': 'ffx',
  'steps': [
    {
      'id': 's1',
      'title': 'Zanarkand',
      'instructions': 'Play the intro',
      'tasks': [taskJson],
    },
  ],
};

void main() {
  group('JourneyTaskModel', () {
    test('reads every field', () {
      final task = JourneyTaskModel.fromJson(taskJson);

      expect(task.id, 't1');
      expect(task.title, 'Beat Sinspawn');
      expect(task.note, 'Bring potions');
      expect(task.trophyIds, ['tr1', 'tr2']);
      expect(task.flag, TaskFlag.missable);
    });

    test('defaults the note to an empty string when absent', () {
      final json = Map<String, dynamic>.from(taskJson)..remove('note');

      expect(JourneyTaskModel.fromJson(json).note, '');
    });

    test('defaults the note to an empty string when null', () {
      final json = Map<String, dynamic>.from(taskJson)..['note'] = null;

      expect(JourneyTaskModel.fromJson(json).note, '');
    });

    test('parses the recommended flag', () {
      final json = Map<String, dynamic>.from(taskJson)
        ..['flag'] = 'recommended';

      expect(JourneyTaskModel.fromJson(json).flag, TaskFlag.recommended);
    });

    test('falls back to no flag when absent', () {
      final json = Map<String, dynamic>.from(taskJson)..remove('flag');

      expect(JourneyTaskModel.fromJson(json).flag, TaskFlag.none);
    });

    test('falls back to no flag when unknown', () {
      final json = Map<String, dynamic>.from(taskJson)..['flag'] = 'nonsense';

      expect(JourneyTaskModel.fromJson(json).flag, TaskFlag.none);
    });

    test('maps onto the entity', () {
      final task = JourneyTaskModel.fromJson(taskJson).toEntity();

      expect(task.id, 't1');
      expect(task.title, 'Beat Sinspawn');
      expect(task.note, 'Bring potions');
      expect(task.trophyIds, ['tr1', 'tr2']);
      expect(task.isMissable, isTrue);
      expect(task.isRecommended, isFalse);
    });
  });

  group('JourneyModel', () {
    test('reads nested steps and tasks', () {
      final model = JourneyModel.fromJson(journeyJson);

      expect(model.gameId, 'ffx');
      expect(model.steps, hasLength(1));
      expect(model.steps.single.id, 's1');
      expect(model.steps.single.title, 'Zanarkand');
      expect(model.steps.single.instructions, 'Play the intro');
      expect(model.steps.single.tasks.single.id, 't1');
    });

    test('round trips nested objects back to the same map', () {
      expect(JourneyModel.fromJson(journeyJson).toJson(), journeyJson);
    });

    test('maps onto the entity tree', () {
      final journey = JourneyModel.fromJson(journeyJson).toEntity();

      expect(journey.gameId, 'ffx');
      expect(journey.totalTaskCount, 1);
      expect(journey.steps.single.tasks.single.title, 'Beat Sinspawn');
      expect(journey.steps.single.hasMissable, isTrue);
      expect(journey.taskIdsByTrophyId['tr1'], ['t1']);
    });

    test('throws when steps are missing', () {
      final json = Map<String, dynamic>.from(journeyJson)..remove('steps');

      expect(() => JourneyModel.fromJson(json), throwsA(anything));
    });
  });
}
