import '../../domain/repositories/journey_progress_repository.dart';
import '../datasources/journey_local_data_source.dart';

class const JourneyProgressRepositoryImpl(
  final JourneyLocalDataSource _dataSource,
) implements JourneyProgressRepository {
  @override
  Future<Set<String>> getCheckedTaskIds(String gameId) =>
      _dataSource.loadCheckedTaskIds(gameId);

  @override
  Future<void> setTaskChecked(String gameId, String taskId, bool checked) =>
      _dataSource.saveTaskChecked(gameId, taskId, checked);

  @override
  Future<String?> getBookmark(String gameId) =>
      _dataSource.loadBookmark(gameId);

  @override
  Future<void> setBookmark(String gameId, String? stepId) =>
      _dataSource.saveBookmark(gameId, stepId);
}
