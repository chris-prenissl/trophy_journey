import '../entities/journey.dart';
import '../repositories/journey_repository.dart';

class const GetJourneyUseCase(final JourneyRepository _repository) {
  Future<Journey> call(String gameId) => _repository.getJourney(gameId);
}
