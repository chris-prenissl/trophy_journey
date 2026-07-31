import '../repositories/trophy_progress_repository.dart';

class ReplaceEarnedTrophiesUseCase {
  const ReplaceEarnedTrophiesUseCase(this._repository);

  final TrophyProgressRepository _repository;

  Future<void> call(String gameId, Set<String> trophyIds) =>
      _repository.replaceEarned(gameId, trophyIds);
}
