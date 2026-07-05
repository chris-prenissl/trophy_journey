import '../entities/journey.dart';

abstract interface class JourneyRepository {
  Future<Journey> getJourney(String gameId);

  Future<bool> hasJourney(String gameId);
}
