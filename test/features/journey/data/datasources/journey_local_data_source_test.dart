import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';
import 'package:trophy_journey/features/journey/data/datasources/journey_local_data_source.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late JourneyLocalDataSource dataSource;

  setUp(() {
    dataSource = JourneyLocalDataSource(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
  });

  tearDown(() => dataSource.close());

  group('task progress', () {
    test('starts with no checked tasks', () async {
      expect(await dataSource.loadCheckedTaskIds('ffx'), isEmpty);
    });

    test('remembers checked tasks per game', () async {
      await dataSource.saveTaskChecked('ffx', 't1', true);
      await dataSource.saveTaskChecked('ffx', 't2', true);
      await dataSource.saveTaskChecked('ffvii', 't9', true);

      expect(await dataSource.loadCheckedTaskIds('ffx'), {'t1', 't2'});
      expect(await dataSource.loadCheckedTaskIds('ffvii'), {'t9'});
    });

    test('unchecking removes the task from the checked set', () async {
      await dataSource.saveTaskChecked('ffx', 't1', true);
      await dataSource.saveTaskChecked('ffx', 't1', false);

      expect(await dataSource.loadCheckedTaskIds('ffx'), isEmpty);
    });

    test('checking a task twice keeps a single entry', () async {
      await dataSource.saveTaskChecked('ffx', 't1', true);
      await dataSource.saveTaskChecked('ffx', 't1', true);

      expect(await dataSource.loadCheckedTaskIds('ffx'), {'t1'});
    });
  });

  group('bookmark', () {
    test('is absent until saved', () async {
      expect(await dataSource.loadBookmark('ffx'), isNull);
    });

    test('stores one bookmark per game', () async {
      await dataSource.saveBookmark('ffx', 's2');
      await dataSource.saveBookmark('ffvii', 's5');

      expect(await dataSource.loadBookmark('ffx'), 's2');
      expect(await dataSource.loadBookmark('ffvii'), 's5');
    });

    test('saving again replaces the bookmark', () async {
      await dataSource.saveBookmark('ffx', 's2');
      await dataSource.saveBookmark('ffx', 's3');

      expect(await dataSource.loadBookmark('ffx'), 's3');
    });

    test('saving null clears the bookmark', () async {
      await dataSource.saveBookmark('ffx', 's2');
      await dataSource.saveBookmark('ffx', null);

      expect(await dataSource.loadBookmark('ffx'), isNull);
    });
  });
}
