import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_asset_data_source.dart';

class GameRepositoryImpl implements GameRepository {
  const GameRepositoryImpl(this._dataSource);

  final GameAssetDataSource _dataSource;

  @override
  Future<List<Game>> getGames() async {
    final models = await _dataSource.loadGames();
    return models.map((m) => m.toEntity()).toList();
  }
}
