import '../repositories/trophy_progress_repository.dart';

class const GetAllEarnedTrophyIdsUseCase(
  final TrophyProgressRepository _repository,
) {
  Future<Map<String, Set<String>>> call() => _repository.getAllEarnedIds();
}
