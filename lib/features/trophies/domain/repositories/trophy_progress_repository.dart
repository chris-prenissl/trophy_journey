abstract interface class TrophyProgressRepository {
  Future<Map<String, Set<String>>> getAllEarnedIds();

  Future<void> replaceEarned(String gameId, Set<String> trophyIds);
}
