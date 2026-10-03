import '../repositories/journey_repository.dart';

class const HasJourneyUseCase(final JourneyRepository _repository) {
  Future<bool> call(String gameId) => _repository.hasJourney(gameId);
}
