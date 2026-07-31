import '../entities/game.dart';
import '../repositories/game_repository.dart';

class GetGamesUseCase {
  const GetGamesUseCase(this._repository);

  final GameRepository _repository;

  Future<List<Game>> call() => _repository.getGames();
}
