import '../entities/trophy.dart';
import '../repositories/trophy_repository.dart';

class GetTrophiesUseCase {
  const GetTrophiesUseCase(this._repository);

  final TrophyRepository _repository;

  Future<List<Trophy>> call(String gameId) => _repository.getTrophies(gameId);
}
