import '../entities/journey.dart';
import '../repositories/journey_repository.dart';

class GetJourney {
  const GetJourney(this._repository);

  final JourneyRepository _repository;

  Future<Journey> call(String gameId) => _repository.getJourney(gameId);
}
