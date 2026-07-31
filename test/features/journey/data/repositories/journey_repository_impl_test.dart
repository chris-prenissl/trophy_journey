import 'dart:convert';

import 'package:trophy_journey/features/journey/data/datasources/journey_asset_data_source.dart';
import 'package:trophy_journey/features/journey/data/repositories/journey_repository_impl.dart';
import 'package:trophy_journey/features/journey/domain/entities/journey.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import '../../../../util/fake_asset_bundle.dart';

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
        },
      ],
    },
  ],
};

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('hasJourney delegates to the asset manifest', () async {
    final repository = JourneyRepositoryImpl(
      JourneyAssetDataSource(
        _ManifestAssetBundle(const {}, ['assets/data/journeys/ffx.json']),
      ),
    );

    expect(await repository.hasJourney('ffx'), isTrue);
    expect(await repository.hasJourney('ffvii'), isFalse);
  });

  test('getJourney maps the asset to a domain entity', () async {
    final repository = JourneyRepositoryImpl(
      JourneyAssetDataSource(
        FakeAssetBundle({
          'assets/data/journeys/ffx.json': jsonEncode(journeyJson),
        }),
      ),
    );

    final journey = await repository.getJourney('ffx');

    expect(journey, isA<Journey>());
    expect(journey.gameId, 'ffx');
    expect(journey.steps.single.tasks.single.id, 't1');
  });
}
