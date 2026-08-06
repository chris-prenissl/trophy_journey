import 'dart:convert';

import 'package:trophy_journey/features/trophies/data/datasources/game_asset_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_cache_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'package:trophy_journey/features/trophies/data/repositories/game_repository_impl.dart';
import 'package:trophy_journey/features/trophies/data/repositories/trophy_repository_impl.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../util/fake_asset_bundle.dart';

const npCommId = 'NPWR05698_00';

final bundle = FakeAssetBundle({
  'assets/data/games.json': jsonEncode([
    {
      'id': 'final-fantasy-x-hd',
      'title': 'Final Fantasy X HD',
      'numeral': 'X',
      'cover': 'assets/covers/ffx.png',
      'trophyCount': 2,
      'psnNames': ['FINAL FANTASY X HD Remaster'],
    },
  ]),
  'assets/data/trophies/final-fantasy-x-hd.json': jsonEncode([
    {
      'id': 'completion',
      'title': 'Completion',
      'type': 'platinum',
      'description': 'bundled description',
      'guide': 'Earn every other trophy.',
      'missable': false,
      'icon': 'assets/icons/completion.png',
      'order': 0,
    },
  ]),
});

List<Map<String, dynamic>> get psnDefinitions => [
  {
    'trophyId': 0,
    'trophyName': 'Completion',
    'trophyDetail': 'Obtain all available trophies',
    'trophyType': 'platinum',
    'trophyIconUrl': 'https://img/plat.png',
    'trophyHidden': false,
  },
  {
    'trophyId': 1,
    'trophyName': 'Sphere Master',
    'trophyDetail': 'Fill the Sphere Grid',
    'trophyType': 'gold',
    'trophyIconUrl': 'https://img/gold.png',
    'trophyHidden': false,
  },
];

Map<String, dynamic> get psnTitle => {
  'npCommunicationId': npCommId,
  'npServiceName': 'trophy',
  'trophyTitleName': 'FINAL FANTASY X HD Remaster',
  'trophyTitleIconUrl': 'https://img/ffx.png',
  'trophyTitlePlatform': 'PS4',
  'definedTrophies': {'bronze': 0, 'silver': 0, 'gold': 1, 'platinum': 1},
  'earnedTrophies': {'bronze': 0, 'silver': 0, 'gold': 0, 'platinum': 0},
  'lastUpdatedDateTime': '2026-07-30T12:00:00Z',
};

({TrophyRepositoryImpl repository, PsnCacheDataSource cache}) buildRepository(
  MockClientHandler handler,
) {
  final client = MockClient(handler);
  final psn = PsnTrophyDataSource(client: client, baseUrl: 'https://psn.test');
  final cache = PsnCacheDataSource(
    factory: databaseFactoryFfi,
    path: inMemoryDatabasePath,
  );
  final guides = TrophyAssetDataSource(bundle);
  final games = GameRepositoryImpl(
    psnTrophyDataSource: psn,
    psnCacheDataSource: cache,
    gameAssetDataSource: GameAssetDataSource(bundle),
  );
  return (
    repository: TrophyRepositoryImpl(
      gameRepository: games,
      psnTrophyDataSource: psn,
      psnCacheDataSource: cache,
      trophyAssetDataSource: guides,
    ),
    cache: cache,
  );
}

http.Response jsonFor(http.Request request) {
  final path = request.url.path;
  if (path.endsWith('/trophyTitles')) {
    return http.Response(
      jsonEncode({
        'trophyTitles': [psnTitle],
      }),
      200,
    );
  }
  if (path.startsWith('/api/trophy/v1/users/me/npCommunicationIds')) {
    return http.Response(
      jsonEncode({
        'trophies': [
          {'trophyId': 1, 'earned': true},
          {'trophyId': 0, 'earned': false},
        ],
      }),
      200,
    );
  }
  return http.Response(jsonEncode({'trophies': psnDefinitions}), 200);
}

void main() {
  setUpAll(sqfliteFfiInit);

  group('getTrophies', () {
    test('merges PSN trophies with the bundled guide', () async {
      final (:repository, :cache) = buildRepository((r) async => jsonFor(r));
      addTearDown(cache.close);

      final trophies = await repository.getTrophies('final-fantasy-x-hd');

      expect(trophies, hasLength(2));
      final completion = trophies.firstWhere((t) => t.title == 'Completion');
      // Sony's title and description win; the bundled guide is layered on.
      expect(completion.description, 'Obtain all available trophies');
      expect(completion.guide, 'Earn every other trophy.');
      expect(completion.id, 'completion');
      expect(completion.iconAsset, 'assets/icons/completion.png');
      expect(completion.iconUrl, 'https://img/plat.png');
    });

    test('keeps PSN trophies with no guide, keyed by their PSN id', () async {
      final (:repository, :cache) = buildRepository((r) async => jsonFor(r));
      addTearDown(cache.close);

      final trophies = await repository.getTrophies('final-fantasy-x-hd');

      final sphere = trophies.firstWhere((t) => t.title == 'Sphere Master');
      expect(sphere.id, 'psn-1');
      expect(sphere.guide, isEmpty);
      expect(sphere.iconAsset, isNull);
      expect(sphere.iconUrl, 'https://img/gold.png');
      expect(sphere.type, TrophyType.gold);
    });

    test('falls back to the cached list when PSN is unreachable', () async {
      // Prime the cache with a good response.
      final (repository: primed, :cache) = buildRepository(
        (r) async => jsonFor(r),
      );
      addTearDown(cache.close);
      await primed.getTrophies('final-fantasy-x-hd');

      // A second repository sharing the cache, but offline for definitions.
      final offline = TrophyRepositoryImpl(
        gameRepository: GameRepositoryImpl(
          psnTrophyDataSource: PsnTrophyDataSource(
            client: MockClient((r) async => jsonFor(r)),
            baseUrl: 'https://psn.test',
          ),
          psnCacheDataSource: cache,
          gameAssetDataSource: GameAssetDataSource(bundle),
        ),
        psnTrophyDataSource: PsnTrophyDataSource(
          client: MockClient((_) async => http.Response('nope', 503)),
          baseUrl: 'https://psn.test',
        ),
        psnCacheDataSource: cache,
        trophyAssetDataSource: TrophyAssetDataSource(bundle),
      );

      final trophies = await offline.getTrophies('final-fantasy-x-hd');

      expect(trophies, hasLength(2));
      expect(trophies.map((t) => t.title), contains('Completion'));
    });
  });

  group('getPsnEarnedTrophyIds', () {
    test('maps earned PSN ids to the ids the app uses', () async {
      final (:repository, :cache) = buildRepository((r) async => jsonFor(r));
      addTearDown(cache.close);

      final earned = await repository.getPsnEarnedTrophyIds(
        'final-fantasy-x-hd',
      );

      expect(earned, {'psn-1'});
    });
  });
}
