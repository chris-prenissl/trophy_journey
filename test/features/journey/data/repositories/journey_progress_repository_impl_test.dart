import 'package:trophy_journey/features/journey/data/datasources/journey_local_data_source.dart';
import 'package:trophy_journey/features/journey/data/repositories/journey_progress_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late JourneyLocalDataSource dataSource;
  late JourneyProgressRepositoryImpl repository;

  setUp(() {
    dataSource = JourneyLocalDataSource(
      factory: databaseFactoryFfi,
      databasePath: inMemoryDatabasePath,
    );
    repository = JourneyProgressRepositoryImpl(dataSource);
  });

  tearDown(() => dataSource.close());

  test('round-trips checked task ids', () async {
    await repository.setTaskChecked('ffx', 't1', true);
    await repository.setTaskChecked('ffx', 't2', true);
    await repository.setTaskChecked('ffx', 't2', false);

    expect(await repository.getCheckedTaskIds('ffx'), {'t1'});
  });

  test('round-trips the bookmark, including clearing it', () async {
    await repository.setBookmark('ffx', 's2');
    expect(await repository.getBookmark('ffx'), 's2');

    await repository.setBookmark('ffx', null);
    expect(await repository.getBookmark('ffx'), isNull);
  });
}
