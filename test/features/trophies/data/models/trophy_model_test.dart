import 'package:flutter_test/flutter_test.dart';
import 'package:trophy_journey/features/trophies/data/models/trophy_model.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';

const trophyJson = <String, dynamic>{
  'id': 't1',
  'title': 'Sphere Break',
  'type': 'gold',
  'description': 'A description',
  'guide': 'A guide',
  'missable': true,
  'icon': 'assets/icons/ffx/t1.png',
  'order': 3,
};

void main() {
  group('toEntity', () {
    test('maps icon onto iconAsset and keeps the type', () {
      final trophy = TrophyModel.fromJson(trophyJson).toEntity();

      expect(trophy.id, 't1');
      expect(trophy.title, 'Sphere Break');
      expect(trophy.type, TrophyType.gold);
      expect(trophy.description, 'A description');
      expect(trophy.guide, 'A guide');
      expect(trophy.missable, isTrue);
      expect(trophy.iconAsset, 'assets/icons/ffx/t1.png');
      expect(trophy.order, 3);
    });
  });
}
