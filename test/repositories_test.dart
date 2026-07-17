import 'package:final_fantasy_guide/features/journey/data/datasources/journey_asset_data_source.dart';
import 'package:final_fantasy_guide/features/journey/data/datasources/journey_local_data_source.dart';
import 'package:final_fantasy_guide/features/journey/data/models/journey_model.dart';
import 'package:final_fantasy_guide/features/journey/data/repositories/journey_progress_repository_impl.dart';
import 'package:final_fantasy_guide/features/journey/data/repositories/journey_repository_impl.dart';
import 'package:final_fantasy_guide/features/trophies/data/datasources/game_asset_data_source.dart';
import 'package:final_fantasy_guide/features/trophies/data/datasources/progress_local_data_source.dart';
import 'package:final_fantasy_guide/features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'package:final_fantasy_guide/features/trophies/data/models/game_model.dart';
import 'package:final_fantasy_guide/features/trophies/data/models/trophy_model.dart';
import 'package:final_fantasy_guide/features/trophies/data/repositories/game_repository_impl.dart';
import 'package:final_fantasy_guide/features/trophies/data/repositories/trophy_progress_repository_impl.dart';
import 'package:final_fantasy_guide/features/trophies/data/repositories/trophy_repository_impl.dart';
import 'package:flutter/services.dart' show rootBundle;
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite/sqflite.dart';

class _NoopDatabaseFactory implements DatabaseFactory {
  const _NoopDatabaseFactory();
  @override
  dynamic noSuchMethod(Invocation invocation) => throw UnimplementedError();
}

TrophyModel _trophyModel(String id, int order) => TrophyModel(
      id: id,
      title: id,
      type: 'bronze',
      description: 'desc',
      guide: 'guide',
      missable: false,
      icon: 'icon.jpg',
      order: order,
    );

class _StubTrophyAssetDataSource extends TrophyAssetDataSource {
  _StubTrophyAssetDataSource(this._models) : super(rootBundle);
  final List<TrophyModel> _models;
  @override
  Future<List<TrophyModel>> loadTrophies(String gameId) async => _models;
}

class _StubGameAssetDataSource extends GameAssetDataSource {
  _StubGameAssetDataSource(this._models) : super(rootBundle);
  final List<GameModel> _models;
  @override
  Future<List<GameModel>> loadGames() async => _models;
}

class _StubJourneyAssetDataSource extends JourneyAssetDataSource {
  _StubJourneyAssetDataSource(this._model, this._has) : super(rootBundle);
  final JourneyModel _model;
  final bool _has;
  @override
  Future<JourneyModel> loadJourney(String gameId) async => _model;
  @override
  Future<bool> hasJourney(String gameId) async => _has;
}

class _StubProgressLocalDataSource extends ProgressLocalDataSource {
  _StubProgressLocalDataSource() : super(factory: const _NoopDatabaseFactory());

  final Map<String, Set<String>> store = {};
  final List<String> saves = [];

  @override
  Future<Set<String>> loadAchievedIds(String gameId) async =>
      {...?store[gameId]};

  @override
  Future<Map<String, Set<String>>> loadAllAchievedIds() async => store;

  @override
  Future<void> saveAchieved(String g, String t, bool v) async {
    saves.add('$g/$t/$v');
    v ? (store[g] ??= {}).add(t) : (store[g] ??= {}).remove(t);
  }
}

class _StubJourneyLocalDataSource extends JourneyLocalDataSource {
  _StubJourneyLocalDataSource() : super(factory: const _NoopDatabaseFactory());

  final Map<String, Set<String>> checked = {};
  final Map<String, String?> bookmarks = {};

  @override
  Future<Set<String>> loadCheckedTaskIds(String gameId) async =>
      {...?checked[gameId]};

  @override
  Future<void> saveTaskChecked(String g, String t, bool v) async {
    v ? (checked[g] ??= {}).add(t) : (checked[g] ??= {}).remove(t);
  }

  @override
  Future<String?> loadBookmark(String gameId) async => bookmarks[gameId];

  @override
  Future<void> saveBookmark(String gameId, String? stepId) async =>
      bookmarks[gameId] = stepId;
}

void main() {
  test('TrophyRepositoryImpl maps models to entities sorted by order', () async {
    final repo = TrophyRepositoryImpl(_StubTrophyAssetDataSource([
      _trophyModel('c', 2),
      _trophyModel('a', 0),
      _trophyModel('b', 1),
    ]));

    final trophies = await repo.getTrophies('any');

    expect(trophies.map((t) => t.id), ['a', 'b', 'c']);
    expect(trophies.first, isNotNull);
  });

  test('GameRepositoryImpl maps game models to entities', () async {
    final repo = GameRepositoryImpl(_StubGameAssetDataSource([
      const GameModel(
        id: 'ffx',
        title: 'FFX',
        numeral: 'X',
        cover: 'c.jpg',
        trophyCount: 34,
      ),
    ]));

    final games = await repo.getGames();

    expect(games, hasLength(1));
    expect(games.single.id, 'ffx');
    expect(games.single.coverAsset, 'c.jpg');
  });

  test('JourneyRepositoryImpl delegates to its data source', () async {
    final model = JourneyModel.fromJson(const {
      'gameId': 'ffx',
      'steps': [
        {
          'id': 's1',
          'title': 'Step',
          'instructions': 'go',
          'tasks': [
            {
              'id': 't1',
              'title': 'task',
              'trophyIds': ['x'],
            }
          ],
        }
      ],
    });
    final repo = JourneyRepositoryImpl(_StubJourneyAssetDataSource(model, true));

    final journey = await repo.getJourney('ffx');
    expect(journey.gameId, 'ffx');
    expect(journey.allTasks.single.id, 't1');
    expect(await repo.hasJourney('ffx'), isTrue);
  });

  test('TrophyProgressRepositoryImpl delegates reads and writes', () async {
    final ds = _StubProgressLocalDataSource();
    final repo = TrophyProgressRepositoryImpl(ds);

    await repo.setAchieved('ffx', 'striker', true);
    expect(ds.saves, ['ffx/striker/true']);
    expect(await repo.getAchievedIds('ffx'), {'striker'});
    expect(await repo.getAllAchievedIds(), {
      'ffx': {'striker'}
    });

    await repo.setAchieved('ffx', 'striker', false);
    expect(await repo.getAchievedIds('ffx'), isEmpty);
  });

  test('JourneyProgressRepositoryImpl delegates tasks and bookmarks', () async {
    final ds = _StubJourneyLocalDataSource();
    final repo = JourneyProgressRepositoryImpl(ds);

    await repo.setTaskChecked('ffx', 't1', true);
    expect(await repo.getCheckedTaskIds('ffx'), {'t1'});

    await repo.setBookmark('ffx', 's2');
    expect(await repo.getBookmark('ffx'), 's2');

    await repo.setBookmark('ffx', null);
    expect(await repo.getBookmark('ffx'), isNull);

    await repo.setTaskChecked('ffx', 't1', false);
    expect(await repo.getCheckedTaskIds('ffx'), isEmpty);
  });
}
