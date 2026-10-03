import '../repositories/journey_progress_repository.dart';

class const SetTaskCheckedUseCase(final JourneyProgressRepository _repository) {
  Future<void> call(String gameId, String taskId, bool checked) =>
      _repository.setTaskChecked(gameId, taskId, checked);
}
