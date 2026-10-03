import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trophy_journey/features/trophies/data/datasources/game_asset_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_cache_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'package:trophy_journey/features/trophies/data/repositories/game_repository_impl.dart';

import '../../../../util/fake_asset_bundle.dart';

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

GameRepositoryImpl buildRepository(
  MockClientHandler handler, {
  required PsnCacheDataSource cache,
}) => GameRepositoryImpl(
  psnTrophyDataSource: PsnTrophyDataSource(
    client: MockClient(handler),
    baseUrl: 'https://psn.test',
  ),
  psnCacheDataSource: cache,
  gameAssetDataSource: GameAssetDataSource(bundle),
);

PsnCacheDataSource memoryCache() =>
    PsnCacheDataSource(factory: databaseFactoryFfi, path: inMemoryDatabasePath);

MockClientHandler respondWith(List<Map<String, dynamic>> titles) =>
    (_) async => http.Response(jsonEncode({'trophyTitles': titles}), 200);

void main() {
  setUpAll(sqfliteFfiInit);

  late PsnCacheDataSource cache;

  setUp(() {
    cache = memoryCache();
    addTearDown(cache.close);
  });

  group('getGames', () {
    test('returns the freshly fetched PSN library', () async {
      final repository = buildRepository(
        respondWith([
          title(
            'NPWR1',
            'Some Other Game',
            updated: '2026-01-01T00:00:00Z',
            earned: 1,
          ),
        ]),
        cache: cache,
      );

      final games = await repository.getGames();

      expect(games, hasLength(1));
      expect(games.single.title, 'Some Other Game');
      expect(games.single.trophyCount, 2);
      expect(games.single.psnEarnedCount, 1);
    });

    test('enriches the matching game with its bundled guide', () async {
      final repository = buildRepository(
        respondWith([
          title(
            'NPWR1',
            'FINAL FANTASY X HD Remaster',
            updated: '2026-01-01T00:00:00Z',
          ),
        ]),
        cache: cache,
      );

      final game = (await repository.getGames()).single;

      expect(game.id, 'final-fantasy-x-hd');
      expect(game.title, 'Final Fantasy X HD');
      expect(game.coverAsset, 'assets/covers/ffx.png');
      expect(game.numeral, 'X');
      expect(game.guideSlug, 'final-fantasy-x-hd');
    });

    test('keeps unguided games under their PSN identity', () async {
      final repository = buildRepository(
        respondWith([
          title('NPWR9', 'Some Other Game', updated: '2026-01-01T00:00:00Z'),
        ]),
        cache: cache,
      );

      final game = (await repository.getGames()).single;

      expect(game.id, 'NPWR9');
      expect(game.title, 'Some Other Game');
      expect(game.coverAsset, isNull);
      expect(game.iconUrl, 'https://img/NPWR9.png');
      expect(game.guideSlug, isNull);
    });

    test('sorts the library by most recently played', () async {
      final repository = buildRepository(
        respondWith([
          title('NPWR_OLD', 'Older', updated: '2026-01-01T00:00:00Z'),
          title('NPWR_NEW', 'Newer', updated: '2026-06-01T00:00:00Z'),
        ]),
        cache: cache,
      );

      final games = await repository.getGames();

      expect(games.map((g) => g.title), ['Newer', 'Older']);
    });

    test('serves the cached library when PSN cannot be reached', () async {
      final onlineRepositoryFillingCache = buildRepository(
        respondWith([
          title(
            'NPWR1',
            'FINAL FANTASY X HD Remaster',
            updated: '2026-01-01T00:00:00Z',
          ),
        ]),
        cache: cache,
      );
      await onlineRepositoryFillingCache.getGames();

      final offline = buildRepository(
        (_) async => http.Response('down', 503),
        cache: cache,
      );

      final games = await offline.getGames();

      expect(games.single.title, 'Final Fantasy X HD');
    });

    test('refetches every time it is asked', () async {
      var calls = 0;
      final repository = buildRepository((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'trophyTitles': [
              title('NPWR1', 'Game $calls', updated: '2026-01-01T00:00:00Z'),
            ],
          }),
          200,
        );
      }, cache: cache);

      await repository.getGames();
      final second = await repository.getGames();

      expect(calls, 2);
      expect(second.single.title, 'Game 2');
    });
  });

  group('getGame', () {
    test('finds the game by id', () async {
      final repository = buildRepository(
        respondWith([
          title('NPWR_A', 'Alpha', updated: '2026-01-01T00:00:00Z'),
          title('NPWR_B', 'Beta', updated: '2026-06-01T00:00:00Z'),
        ]),
        cache: cache,
      );

      expect((await repository.getGame('NPWR_A'))?.title, 'Alpha');
    });

    test('is null for an id the library does not carry', () async {
      final repository = buildRepository(
        respondWith([
          title('NPWR_A', 'Alpha', updated: '2026-01-01T00:00:00Z'),
        ]),
        cache: cache,
      );

      expect(await repository.getGame('nope'), isNull);
    });

    test('reuses the library already in memory', () async {
      var calls = 0;
      final repository = buildRepository((_) async {
        calls++;
        return http.Response(
          jsonEncode({
            'trophyTitles': [
              title('NPWR_A', 'Alpha', updated: '2026-01-01T00:00:00Z'),
            ],
          }),
          200,
        );
      }, cache: cache);

      await repository.getGames();
      await repository.getGame('NPWR_A');
      await repository.getGame('NPWR_A');

      expect(calls, 1, reason: 'opening a game must not call Sony again');
    });
  });
}
