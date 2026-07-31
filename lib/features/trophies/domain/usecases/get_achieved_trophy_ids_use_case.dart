import '../repositories/trophy_progress_repository.dart';

class GetAchievedTrophyIdsUseCase {
  const GetAchievedTrophyIdsUseCase(this._repository);

  final TrophyProgressRepository _repository;

  Future<Set<String>> call(String gameId) => _repository.getAchievedIds(gameId);
}
