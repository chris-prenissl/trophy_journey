import '../../domain/repositories/trophy_progress_repository.dart';
import '../datasources/progress_local_data_source.dart';

class TrophyProgressRepositoryImpl implements TrophyProgressRepository {
  const TrophyProgressRepositoryImpl(this._dataSource);

  final ProgressLocalDataSource _dataSource;

  @override
  Future<Map<String, Set<String>>> getAllEarnedIds() =>
      _dataSource.loadAllEarnedIds();

  @override
  Future<void> replaceEarned(String gameId, Set<String> trophyIds) =>
      _dataSource.replaceEarned(gameId, trophyIds);
}
