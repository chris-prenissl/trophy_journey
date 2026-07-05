import '../repositories/journey_progress_repository.dart';

class GetJourneyBookmark {
  const GetJourneyBookmark(this._repository);

  final JourneyProgressRepository _repository;

  Future<String?> call(String gameId) => _repository.getBookmark(gameId);
}
