import '../repositories/journey_repository.dart';

class HasJourneyUseCase {
  const HasJourneyUseCase(this._repository);

  final JourneyRepository _repository;

  Future<bool> call(String gameId) => _repository.hasJourney(gameId);
}
