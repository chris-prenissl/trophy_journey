import '../repositories/trophy_repository.dart';

class const GetPsnEarnedTrophyIdsUseCase(final TrophyRepository _repository) {
  Future<Set<String>> call(String gameId) =>
      _repository.getPsnEarnedTrophyIds(gameId);
}
