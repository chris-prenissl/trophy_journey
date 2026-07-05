import '../../domain/entities/journey.dart';
import '../../domain/repositories/journey_repository.dart';
import '../datasources/journey_asset_data_source.dart';

class JourneyRepositoryImpl implements JourneyRepository {
  const JourneyRepositoryImpl(this._dataSource);

  final JourneyAssetDataSource _dataSource;

  @override
  Future<Journey> getJourney(String gameId) async =>
      (await _dataSource.loadJourney(gameId)).toEntity();

  @override
  Future<bool> hasJourney(String gameId) => _dataSource.hasJourney(gameId);
}
