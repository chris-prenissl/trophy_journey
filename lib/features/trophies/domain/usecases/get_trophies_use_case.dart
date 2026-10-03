import '../entities/trophy.dart';
import '../repositories/trophy_repository.dart';

class const GetTrophiesUseCase(final TrophyRepository _repository) {
  Future<List<Trophy>> call(String gameId) => _repository.getTrophies(gameId);
}
