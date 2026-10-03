import '../repositories/journey_progress_repository.dart';

class const GetJourneyBookmarkUseCase(
  final JourneyProgressRepository _repository,
) {
  Future<String?> call(String gameId) => _repository.getBookmark(gameId);
}
