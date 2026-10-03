import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trophy_journey/features/trophies/data/datasources/progress_local_data_source.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late ProgressLocalDataSource dataSource;

  setUp(() {
    dataSource = ProgressLocalDataSource(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
  });

  tearDown(() => dataSource.close());

  test('records the earned ids for a game', () async {
    await dataSource.replaceEarned('ffx', {'t1', 't2'});

    expect(await dataSource.loadAllEarnedIds(), {
      'ffx': {'t1', 't2'},
    });
  });

  test('a later sync replaces the earlier set for that game', () async {
    await dataSource.replaceEarned('ffx', {'t1', 't2'});
    await dataSource.replaceEarned('ffx', {'t1'});

    expect(await dataSource.loadAllEarnedIds(), {
      'ffx': {'t1'},
    });
  });

  test('syncing one game leaves another game alone', () async {
    await dataSource.replaceEarned('ffx', {'t1'});
    await dataSource.replaceEarned('ffvii', {'t9'});

    expect(await dataSource.loadAllEarnedIds(), {
      'ffx': {'t1'},
      'ffvii': {'t9'},
    });
  });

  test('clearing a game to an empty set removes its rows', () async {
    await dataSource.replaceEarned('ffx', {'t1'});

    await dataSource.replaceEarned('ffx', <String>{});

    expect(await dataSource.loadAllEarnedIds(), isEmpty);
  });
}
