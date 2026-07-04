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
    expect(await dataSource.loadAchievedIds(), isEmpty);
  });

  test('round-trips achieved state', () async {
    await dataSource.saveAchieved('master-linguist', true);
    await dataSource.saveAchieved('completion', true);

    expect(
      await dataSource.loadAchievedIds(),
      {'master-linguist', 'completion'},
    );
  });

  test('unchecking removes a trophy from achieved ids', () async {
    await dataSource.saveAchieved('completion', true);
    await dataSource.saveAchieved('completion', false);

    expect(await dataSource.loadAchievedIds(), isEmpty);
  });
}
