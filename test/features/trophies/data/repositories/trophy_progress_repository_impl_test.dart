import 'package:trophy_journey/features/trophies/data/datasources/progress_local_data_source.dart';
import 'package:trophy_journey/features/trophies/data/repositories/trophy_progress_repository_impl.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(sqfliteFfiInit);

  late ProgressLocalDataSource dataSource;
  late TrophyProgressRepositoryImpl repository;

  setUp(() {
    dataSource = ProgressLocalDataSource(
      factory: databaseFactoryFfi,
      path: inMemoryDatabasePath,
    );
    repository = TrophyProgressRepositoryImpl(dataSource);
  });

  tearDown(() => dataSource.close());

  test('round-trips earned ids per game', () async {
    await repository.replaceEarned('ffx', {'t1', 't2'});
    await repository.replaceEarned('ffvii', {'t9'});

    expect(await repository.getAllEarnedIds(), {
      'ffx': {'t1', 't2'},
      'ffvii': {'t9'},
    });
  });

  test('replacing with an empty set clears the game', () async {
    await repository.replaceEarned('ffx', {'t1'});
    await repository.replaceEarned('ffx', <String>{});

    expect(await repository.getAllEarnedIds(), isEmpty);
  });
}
