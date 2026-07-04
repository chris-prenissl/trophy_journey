import '../../domain/repositories/trophy_progress_repository.dart';
import '../datasources/progress_local_data_source.dart';

class TrophyProgressRepositoryImpl implements TrophyProgressRepository {
  const TrophyProgressRepositoryImpl(this._dataSource);

  final ProgressLocalDataSource _dataSource;

  @override
  Future<Set<String>> getAchievedIds() => _dataSource.loadAchievedIds();

  @override
  Future<void> setAchieved(String trophyId, bool achieved) =>
      _dataSource.saveAchieved(trophyId, achieved);
}
