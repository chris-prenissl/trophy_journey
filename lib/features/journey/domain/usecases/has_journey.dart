import '../repositories/journey_repository.dart';

class HasJourney {
  const HasJourney(this._repository);

  final JourneyRepository _repository;

  Future<bool> call(String gameId) => _repository.hasJourney(gameId);
}
