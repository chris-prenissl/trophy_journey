abstract interface class TrophyProgressRepository {
  Future<Set<String>> getAchievedIds(String gameId);

  /// Achieved trophy ids per game, for every game with progress.
  Future<Map<String, Set<String>>> getAllAchievedIds();

  Future<void> setAchieved(String gameId, String trophyId, bool achieved);
}
