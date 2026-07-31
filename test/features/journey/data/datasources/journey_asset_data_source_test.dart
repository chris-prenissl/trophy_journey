import 'dart:convert';

import 'package:trophy_journey/features/journey/data/datasources/journey_asset_data_source.dart';
import 'package:trophy_journey/features/journey/domain/entities/journey.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../util/fake_asset_bundle.dart';

const journeyJson = <String, dynamic>{
  'gameId': 'ffx',
  'steps': [
    {
      'id': 's1',
      'title': 'Zanarkand',
      'instructions': 'Play the intro',
      'tasks': [
        {
          'id': 't1',
          'title': 'Beat Sinspawn',
          'trophyIds': ['tr1'],
          'flag': 'missable',
        },
      ],
    },
  ],
};

class _ManifestAssetBundle extends FakeAssetBundle {
  _ManifestAssetBundle(super.assets, Iterable<String> manifestKeys)
    : _manifest = const StandardMessageCodec().encodeMessage(<Object?, Object?>{
        for (final key in manifestKeys) key: <Object?>[],
      })!;

  final ByteData _manifest;

  @override
  Future<ByteData> load(String key) async =>
      key == 'AssetManifest.bin' ? _manifest : super.load(key);
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  final bundle = _ManifestAssetBundle({
    'assets/data/journeys/ffx.json': jsonEncode(journeyJson),
  }, [
    'assets/data/journeys/ffx.json',
  ]);

  test('loads and parses the journey asset for a game', () async {
    final dataSource = JourneyAssetDataSource(bundle);

    final journey = await dataSource.loadJourney('ffx');

    expect(journey.gameId, 'ffx');
    expect(journey.steps, hasLength(1));
    expect(journey.steps.first.tasks.first.flag, TaskFlag.missable);
  });

  test('throws when the game has no journey asset', () async {
    final dataSource = JourneyAssetDataSource(bundle);

    expect(dataSource.loadJourney('ffvii'), throwsFlutterError);
  });

  test('hasJourney reflects the asset manifest', () async {
    final dataSource = JourneyAssetDataSource(bundle);

    expect(await dataSource.hasJourney('ffx'), isTrue);
    expect(await dataSource.hasJourney('ffvii'), isFalse);
  });
}
