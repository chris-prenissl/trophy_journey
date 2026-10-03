import '../repositories/trophy_progress_repository.dart';

class const ReplaceEarnedTrophiesUseCase(
  final TrophyProgressRepository _repository,
) {
  Future<void> call(String gameId, Set<String> trophyIds) =>
      _repository.replaceEarned(gameId, trophyIds);
}
