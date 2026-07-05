import 'package:final_fantasy_guide/features/journey/data/datasources/journey_local_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  late JourneyLocalDataSource dataSource;

  setUpAll(sqfliteFfiInit);

  setUp(() {
    dataSource = JourneyLocalDataSource(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => dataSource.close());

  test('starts with no checked tasks and no bookmark', () async {
    expect(await dataSource.loadCheckedTaskIds('ffx'), isEmpty);
    expect(await dataSource.loadBookmark('ffx'), isNull);
  });

  test('round-trips checked tasks per game', () async {
    await dataSource.saveTaskChecked('ffx', 'besaid-cloister', true);
    await dataSource.saveTaskChecked('ffx', 'ss-winno-jecht-shot', true);
    await dataSource.saveTaskChecked('ff7', 'midgar-start', true);

    expect(await dataSource.loadCheckedTaskIds('ffx'), {
      'besaid-cloister',
      'ss-winno-jecht-shot',
    });
    expect(await dataSource.loadCheckedTaskIds('ff7'), {'midgar-start'});
  });

  test('unchecking removes a task from checked ids', () async {
    await dataSource.saveTaskChecked('ffx', 'besaid-cloister', true);
    await dataSource.saveTaskChecked('ffx', 'besaid-cloister', false);

    expect(await dataSource.loadCheckedTaskIds('ffx'), isEmpty);
  });

  test('bookmark sets, moves and clears per game', () async {
    await dataSource.saveBookmark('ffx', 'besaid');
    expect(await dataSource.loadBookmark('ffx'), 'besaid');

    await dataSource.saveBookmark('ffx', 'luca');
    expect(await dataSource.loadBookmark('ffx'), 'luca');

    await dataSource.saveBookmark('ff7', 'midgar');
    expect(await dataSource.loadBookmark('ffx'), 'luca');
    expect(await dataSource.loadBookmark('ff7'), 'midgar');

    await dataSource.saveBookmark('ffx', null);
    expect(await dataSource.loadBookmark('ffx'), isNull);
    expect(await dataSource.loadBookmark('ff7'), 'midgar');
  });
}
