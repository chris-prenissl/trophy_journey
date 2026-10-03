import '../repositories/journey_progress_repository.dart';

class const SetJourneyBookmarkUseCase(
  final JourneyProgressRepository _repository,
) {
  Future<void> call(String gameId, String? stepId) =>
      _repository.setBookmark(gameId, stepId);
}
