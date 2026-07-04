import '../entities/game.dart';
import '../repositories/game_repository.dart';

class GetGames {
  const GetGames(this._repository);

  final GameRepository _repository;

  Future<List<Game>> call() => _repository.getGames();
}
