import 'package:final_fantasy_guide/features/trophies/data/datasources/progress_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late ProgressLocalDataSource dataSource;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    dataSource = ProgressLocalDataSource(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => dataSource.close());

  test('starts with no achieved trophies', () async {
    expect(await dataSource.loadAchievedIds('ffx'), isEmpty);
    expect(await dataSource.loadAllAchievedIds(), isEmpty);
  });

  test('round-trips achieved state per game', () async {
    await dataSource.saveAchieved('ffx', 'master-linguist', true);
    await dataSource.saveAchieved('ffx', 'completion', true);
    await dataSource.saveAchieved('ff7', 'completion', true);

    expect(
      await dataSource.loadAchievedIds('ffx'),
      {'master-linguist', 'completion'},
    );
    expect(await dataSource.loadAchievedIds('ff7'), {'completion'});
    expect(await dataSource.loadAllAchievedIds(), {
      'ffx': {'master-linguist', 'completion'},
      'ff7': {'completion'},
    });
  });

  test('unchecking removes a trophy from achieved ids', () async {
    await dataSource.saveAchieved('ffx', 'completion', true);
    await dataSource.saveAchieved('ffx', 'completion', false);

    expect(await dataSource.loadAchievedIds('ffx'), isEmpty);
  });

  test('migrates v1 rows to v2 under the FFX game id', () async {
    final path =
        '${await databaseFactoryFfi.getDatabasesPath()}/migration_test.db';
    await databaseFactoryFfi.deleteDatabase(path);
    final v1 = await databaseFactoryFfi.openDatabase(
      path,
      options: OpenDatabaseOptions(
        version: 1,
        onCreate: (db, version) => db.execute('''
          CREATE TABLE progress (
            trophy_id TEXT PRIMARY KEY,
            achieved INTEGER NOT NULL,
            achieved_at TEXT
          )
        '''),
      ),
    );
    await v1.insert('progress', {
      'trophy_id': 'completion',
      'achieved': 1,
      'achieved_at': '2026-07-04T00:00:00.000',
    });
    await v1.insert('progress', {'trophy_id': 'teamwork', 'achieved': 0});
    await v1.close();

    final migrated = ProgressLocalDataSource(
      factory: databaseFactoryFfi,
      path: path,
    );
    expect(
      await migrated.loadAchievedIds('final-fantasy-x-hd'),
      {'completion'},
    );
    expect(await migrated.loadAllAchievedIds(), {
      'final-fantasy-x-hd': {'completion'},
    });

    await migrated.saveAchieved('final-fantasy-xvi', 'the-rising-tide', true);
    
    expect(
      await migrated.loadAchievedIds('final-fantasy-xvi'),
      {'the-rising-tide'},
    );
    await migrated.close();
    await databaseFactoryFfi.deleteDatabase(path);
  });
}
