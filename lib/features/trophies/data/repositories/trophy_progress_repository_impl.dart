import '../../domain/repositories/trophy_progress_repository.dart';
import '../datasources/progress_local_data_source.dart';

class TrophyProgressRepositoryImpl implements TrophyProgressRepository {
  const TrophyProgressRepositoryImpl(this._dataSource);

  final ProgressLocalDataSource _dataSource;

  @override
  Future<Set<String>> getAchievedIds(String gameId) =>
      _dataSource.loadAchievedIds(gameId);

  @override
  Future<Map<String, Set<String>>> getAllAchievedIds() =>
      _dataSource.loadAllAchievedIds();

  @override
  Future<void> setAchieved(String gameId, String trophyId, bool achieved) =>
      _dataSource.saveAchieved(gameId, trophyId, achieved);
}
