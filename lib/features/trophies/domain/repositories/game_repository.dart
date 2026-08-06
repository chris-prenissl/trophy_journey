import '../entities/game.dart';

abstract interface class GameRepository {
  Future<List<Game>> getGames();

  Future<Game?> getGame(String id);
}
