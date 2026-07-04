import '../repositories/trophy_progress_repository.dart';

class GetAllAchievedTrophyIds {
  const GetAllAchievedTrophyIds(this._repository);

  final TrophyProgressRepository _repository;

  Future<Map<String, Set<String>>> call() => _repository.getAllAchievedIds();
}
