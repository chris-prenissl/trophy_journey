import '../repositories/journey_progress_repository.dart';

class SetJourneyBookmarkUseCase {
  const SetJourneyBookmarkUseCase(this._repository);

  final JourneyProgressRepository _repository;

  Future<void> call(String gameId, String? stepId) =>
      _repository.setBookmark(gameId, stepId);
}
