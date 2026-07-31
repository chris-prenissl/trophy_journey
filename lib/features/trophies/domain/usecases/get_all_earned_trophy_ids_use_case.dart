import '../repositories/trophy_progress_repository.dart';

class GetAllEarnedTrophyIdsUseCase {
  const GetAllEarnedTrophyIdsUseCase(this._repository);

  final TrophyProgressRepository _repository;

  Future<Map<String, Set<String>>> call() => _repository.getAllEarnedIds();
}
