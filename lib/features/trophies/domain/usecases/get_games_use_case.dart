import '../entities/game.dart';
import '../repositories/game_repository.dart';

class const GetGamesUseCase(final GameRepository _repository) {
  Future<List<Game>> call() => _repository.getGames();
}
