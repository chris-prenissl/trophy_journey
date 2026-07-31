import '../entities/trophy.dart';

abstract interface class TrophyRepository {
  Future<List<Trophy>> getTrophies(String gameId);

  Future<Set<String>> getPsnEarnedTrophyIds(String gameId);
}
