abstract interface class TrophyProgressRepository {
  Future<Set<String>> getAchievedIds(String gameId);

  Future<Map<String, Set<String>>> getAllAchievedIds();

  Future<void> setAchieved(String gameId, String trophyId, bool achieved);
}
