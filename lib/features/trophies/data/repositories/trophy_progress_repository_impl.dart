import '../../domain/repositories/trophy_progress_repository.dart';
import '../datasources/progress_local_data_source.dart';

class const TrophyProgressRepositoryImpl(
  final ProgressLocalDataSource _dataSource,
) implements TrophyProgressRepository {
  @override
  Future<Map<String, Set<String>>> getAllEarnedIds() =>
      _dataSource.loadAllEarnedIds();

  @override
  Future<void> replaceEarned(String gameId, Set<String> trophyIds) =>
      _dataSource.replaceEarned(gameId, trophyIds);
}
