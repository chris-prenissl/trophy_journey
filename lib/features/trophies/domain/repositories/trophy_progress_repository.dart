abstract interface class TrophyProgressRepository {
  Future<Set<String>> getAchievedIds();

  Future<void> setAchieved(String trophyId, bool achieved);
}
