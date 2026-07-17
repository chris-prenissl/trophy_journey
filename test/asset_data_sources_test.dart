import 'package:final_fantasy_guide/features/journey/data/datasources/journey_asset_data_source.dart';
import 'package:final_fantasy_guide/features/trophies/data/datasources/game_asset_data_source.dart';
import 'package:final_fantasy_guide/features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

class _FakeAssetBundle extends CachingAssetBundle {
  _FakeAssetBundle(this._strings, {List<String> manifestAssets = const []})
      : _manifest = const StandardMessageCodec()
            .encodeMessage({for (final a in manifestAssets) a: <Object?>[]})!;

  final Map<String, String> _strings;
  final ByteData _manifest;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') return _manifest;
    throw FlutterError('unexpected binary asset: $key');
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async {
    final value = _strings[key];
    if (value == null) throw FlutterError('missing asset: $key');
    return value;
  }
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('GameAssetDataSource parses the games list', () async {
    final bundle = _FakeAssetBundle({
      GameAssetDataSource.assetPath:
          '[{"id":"ffx","title":"FFX","numeral":"X","cover":"c.jpg","trophyCount":34}]',
    });

    final games = await GameAssetDataSource(bundle).loadGames();

    expect(games, hasLength(1));
    expect(games.single.id, 'ffx');
    expect(games.single.trophyCount, 34);
  });

  test('TrophyAssetDataSource parses a game\'s trophies', () async {
    final bundle = _FakeAssetBundle({
      TrophyAssetDataSource.assetPathFor('ffx'):
          '[{"id":"striker","title":"Striker","type":"bronze","description":"d","guide":"g","missable":false,"icon":"i.jpg","order":8}]',
    });

    final trophies = await TrophyAssetDataSource(bundle).loadTrophies('ffx');

    expect(trophies.single.id, 'striker');
    expect(trophies.single.order, 8);
  });

  test('JourneyAssetDataSource parses a journey', () async {
    final bundle = _FakeAssetBundle({
      JourneyAssetDataSource.assetPathFor('ffx'):
          '{"gameId":"ffx","steps":[{"id":"s1","title":"S","instructions":"go","tasks":[{"id":"t1","title":"t","trophyIds":["x"],"flag":"missable"}]}]}',
    });

    final model = await JourneyAssetDataSource(bundle).loadJourney('ffx');
    final journey = model.toEntity();

    expect(journey.gameId, 'ffx');
    expect(journey.allTasks.single.isMissable, isTrue);
  });

  test('JourneyAssetDataSource.hasJourney consults the asset manifest',
      () async {
    final bundle = _FakeAssetBundle(
      const {},
      manifestAssets: [JourneyAssetDataSource.assetPathFor('ffx')],
    );
    final dataSource = JourneyAssetDataSource(bundle);

    expect(await dataSource.hasJourney('ffx'), isTrue);
    expect(await dataSource.hasJourney('final-fantasy-vii'), isFalse);
  });

  test('assetPathFor builds the conventional asset locations', () {
    expect(JourneyAssetDataSource.assetPathFor('ffx'),
        'assets/data/journeys/ffx.json');
    expect(TrophyAssetDataSource.assetPathFor('ffx'),
        'assets/data/trophies/ffx.json');
    expect(GameAssetDataSource.assetPath, 'assets/data/games.json');
  });
}
