import 'dart:convert';

import 'package:trophy_journey/features/trophies/data/datasources/game_asset_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_cache_data_source.dart';
import 'package:trophy_journey/features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'package:trophy_journey/features/trophies/data/psn_library.dart';
import 'package:trophy_journey/features/trophies/data/repositories/game_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

import '../../../../util/fake_asset_bundle.dart';

final bundle = FakeAssetBundle({'assets/data/games.json': jsonEncode([])});

void main() {
  setUpAll(sqfliteFfiInit);

  test('getGames returns the freshly fetched PSN library', () async {
    final cache = PsnCacheDataSource(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    addTearDown(cache.close);

    final repository = GameRepositoryImpl(
      PsnLibrary(
        psn: PsnTrophyDataSource(
          accessToken: () async => 'token',
          client: MockClient(
            (_) async => http.Response(
              jsonEncode({
                'trophyTitles': [
                  {
                    'npCommunicationId': 'NPWR1',
                    'npServiceName': 'trophy',
                    'trophyTitleName': 'FINAL FANTASY X HD Remaster',
                    'trophyTitleIconUrl': 'https://img/NPWR1.png',
                    'trophyTitlePlatform': 'PS4',
                    'definedTrophies': {
                      'bronze': 2,
                      'silver': 0,
                      'gold': 0,
                      'platinum': 0,
                    },
                    'earnedTrophies': {
                      'bronze': 1,
                      'silver': 0,
                      'gold': 0,
                      'platinum': 0,
                    },
                    'lastUpdatedDateTime': '2026-01-01T00:00:00Z',
                  },
                ],
              }),
              200,
            ),
          ),
          baseUrl: 'https://psn.test',
        ),
        cache: cache,
        guides: GameAssetDataSource(bundle),
      ),
    );

    final games = await repository.getGames();

    expect(games, hasLength(1));
    expect(games.single.title, 'FINAL FANTASY X HD Remaster');
    expect(games.single.trophyCount, 2);
    expect(games.single.psnEarnedCount, 1);
  });
}
