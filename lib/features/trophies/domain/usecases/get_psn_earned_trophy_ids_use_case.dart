import '../repositories/trophy_repository.dart';

class GetPsnEarnedTrophyIdsUseCase {
  const GetPsnEarnedTrophyIdsUseCase(this._repository);

  final TrophyRepository _repository;

  Future<Set<String>> call(String gameId) =>
      _repository.getPsnEarnedTrophyIds(gameId);
}
