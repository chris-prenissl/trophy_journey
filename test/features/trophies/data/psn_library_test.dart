import 'dart:convert';

import 'package:trophy_journey/features/trophies/data/datasources/game_asset_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_cache_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'package:trophy_journey/features/trophies/data/psn_library.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../util/fake_asset_bundle.dart';

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
});

Map<String, dynamic> title(
  String npCommId,
  String name, {
  required String updated,
  int earned = 0,
}) => {
  'npCommunicationId': npCommId,
  'npServiceName': 'trophy',
  'trophyTitleName': name,
  'trophyTitleIconUrl': 'https://img/$npCommId.png',
  'trophyTitlePlatform': 'PS4',
  'definedTrophies': {'bronze': 2, 'silver': 0, 'gold': 0, 'platinum': 0},
  'earnedTrophies': {'bronze': earned, 'silver': 0, 'gold': 0, 'platinum': 0},
  'lastUpdatedDateTime': updated,
};

PsnLibrary buildLibrary(
  MockClientHandler handler, {
  required PsnCacheDataSource cache,
}) {
  return PsnLibrary(
    psn: PsnTrophyDataSource(
      accessToken: () async => 'token',
      client: MockClient(handler),
      baseUrl: 'https://psn.test',
    ),
    cache: cache,
    guides: GameAssetDataSource(bundle),
  );
}

PsnCacheDataSource memoryCache() => PsnCacheDataSource(
  factory: databaseFactoryFfi,
  path: inMemoryDatabasePath,
);

void main() {
  setUpAll(sqfliteFfiInit);

  test('enriches the matching game with its bundled guide', () async {
    final cache = memoryCache();
    addTearDown(cache.close);
    final library = buildLibrary(
      (_) async => http.Response(
        jsonEncode({
          'trophyTitles': [
            title('NPWR1', 'FINAL FANTASY X HD Remaster', updated: '2026-01-01T00:00:00Z'),
          ],
        }),
        200,
      ),
      cache: cache,
    );

    final games = await library.games();

    final game = games.single;
    expect(game.id, 'final-fantasy-x-hd');
    expect(game.title, 'Final Fantasy X HD');
    expect(game.coverAsset, 'assets/covers/ffx.png');
    expect(game.numeral, 'X');
    expect(game.hasGuide, isTrue);
  });

  test('keeps unguided games under their PSN identity', () async {
    final cache = memoryCache();
    addTearDown(cache.close);
    final library = buildLibrary(
      (_) async => http.Response(
        jsonEncode({
          'trophyTitles': [
            title('NPWR9', 'Some Other Game', updated: '2026-01-01T00:00:00Z'),
          ],
        }),
        200,
      ),
      cache: cache,
    );

    final game = (await library.games()).single;

    expect(game.id, 'NPWR9');
    expect(game.title, 'Some Other Game');
    expect(game.coverAsset, isNull);
    expect(game.iconUrl, 'https://img/NPWR9.png');
    expect(game.hasGuide, isFalse);
  });

  test('sorts the library by most recently played', () async {
    final cache = memoryCache();
    addTearDown(cache.close);
    final library = buildLibrary(
      (_) async => http.Response(
        jsonEncode({
          'trophyTitles': [
            title('NPWR_OLD', 'Older', updated: '2026-01-01T00:00:00Z'),
            title('NPWR_NEW', 'Newer', updated: '2026-06-01T00:00:00Z'),
          ],
        }),
        200,
      ),
      cache: cache,
    );

    final games = await library.games();

    expect(games.map((g) => g.title), ['Newer', 'Older']);
  });

  test('serves the cached library when PSN cannot be reached', () async {
    final cache = memoryCache();
    addTearDown(cache.close);
    // Prime the cache from a good response.
    await buildLibrary(
      (_) async => http.Response(
        jsonEncode({
          'trophyTitles': [
            title('NPWR1', 'FINAL FANTASY X HD Remaster', updated: '2026-01-01T00:00:00Z'),
          ],
        }),
        200,
      ),
      cache: cache,
    ).games();

    final offline = buildLibrary(
      (_) async => http.Response('down', 503),
      cache: cache,
    );

    final games = await offline.games();

    expect(games.single.title, 'Final Fantasy X HD');
  });
}
