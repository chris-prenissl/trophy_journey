import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';
import '../psn_library.dart';

class GameRepositoryImpl implements GameRepository {
  const GameRepositoryImpl(this._library);

  final PsnLibrary _library;

  @override
  Future<List<Game>> getGames() => _library.games(refresh: true);
}
