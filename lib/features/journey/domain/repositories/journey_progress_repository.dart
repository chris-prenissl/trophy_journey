abstract interface class JourneyProgressRepository {
  Future<Set<String>> getCheckedTaskIds(String gameId);

  Future<void> setTaskChecked(String gameId, String taskId, bool checked);

  Future<String?> getBookmark(String gameId);

  Future<void> setBookmark(String gameId, String? stepId);
}
