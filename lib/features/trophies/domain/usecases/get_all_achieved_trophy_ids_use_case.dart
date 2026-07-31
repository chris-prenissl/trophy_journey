import '../repositories/trophy_progress_repository.dart';

class GetAllAchievedTrophyIdsUseCase {
  const GetAllAchievedTrophyIdsUseCase(this._repository);

  final TrophyProgressRepository _repository;

  Future<Map<String, Set<String>>> call() => _repository.getAllAchievedIds();
}
