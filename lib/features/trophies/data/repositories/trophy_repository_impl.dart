import '../../domain/entities/trophy.dart';
import '../../domain/repositories/trophy_repository.dart';
import '../datasources/trophy_asset_data_source.dart';

class TrophyRepositoryImpl implements TrophyRepository {
  const TrophyRepositoryImpl(this._dataSource);

  final TrophyAssetDataSource _dataSource;

  @override
  Future<List<Trophy>> getTrophies(String gameId) async {
    final models = await _dataSource.loadTrophies(gameId);
    final trophies = models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
    return trophies;
  }
}
