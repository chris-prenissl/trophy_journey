import '../../domain/entities/game.dart';
import '../../domain/entities/trophy.dart';
import '../../domain/repositories/game_repository.dart';
import '../../domain/repositories/trophy_repository.dart';
import '../datasources/psn_cache_data_source.dart';
import '../datasources/psn_trophy_data_source.dart';
import '../datasources/trophy_asset_data_source.dart';
import '../guide_matcher.dart';
import '../models/psn_trophy_definition_model.dart';
import '../models/trophy_model.dart';

class TrophyRepositoryImpl implements TrophyRepository {
  const TrophyRepositoryImpl({
    required this._gameRepository,
    required this._psnTrophyDataSource,
    required this._psnCacheDataSource,
    required this._trophyAssetDataSource,
  });

  final GameRepository _gameRepository;
  final PsnTrophyDataSource _psnTrophyDataSource;
  final PsnCacheDataSource _psnCacheDataSource;
  final TrophyAssetDataSource _trophyAssetDataSource;

  @override
  Future<List<Trophy>> getTrophies(String gameId) async {
    final game = await _gameRepository.getGame(gameId);
    if (game?.npCommunicationId == null) {
      return _getBundledTrophies(gameId);
    }

    final definitions = await _getGameDefinitions(game!);
    final guides = GuideMatcher.indexTrophies(
      await _getBundledGuides(game.guideSlug),
    );

    return [
      for (final (index, definition) in definitions.indexed)
        _toTrophy(
          definition,
          index,
          GuideMatcher.guideForTrophy(guides, definition),
        ),
    ];
  }

  @override
  Future<Set<String>> getPsnEarnedTrophyIds(String gameId) async {
    final game = await _gameRepository.getGame(gameId);
    final npCommunicationId = game?.npCommunicationId;
    if (npCommunicationId == null) return const {};

    final earnedIds = await _getGameEarnedIds(game!, npCommunicationId);
    if (earnedIds.isEmpty) {
      return const {};
    }

    final definitions = await _getGameDefinitions(game);
    final guides = GuideMatcher.indexTrophies(
      await _getBundledGuides(game.guideSlug),
    );

    return {
      for (final definition in definitions)
        if (earnedIds.contains(definition.trophyId))
          GuideMatcher.guideForTrophy(guides, definition)?.id ??
              'psn-${definition.trophyId}',
    };
  }

  Future<Set<int>> _getGameEarnedIds(Game game, String npCommunicationId) async {
    try {
      final earned = await _psnTrophyDataSource.fetchEarnedTrophyIds(
        npCommunicationId: npCommunicationId,
        npServiceName: game.npServiceName ?? 'trophy',
      );
      await _psnCacheDataSource.writeEarned(npCommunicationId, earned);
      return earned;
    } catch (_) {
      return await _psnCacheDataSource.readEarned(npCommunicationId) ??
          const {};
    }
  }

  Future<List<PsnTrophyDefinitionModel>> _getGameDefinitions(Game game) async {
    final npCommunicationId = game.npCommunicationId!;
    try {
      final definitions = await _psnTrophyDataSource.fetchTrophyDefinitions(
        npCommunicationId: npCommunicationId,
        npServiceName: game.npServiceName ?? 'trophy',
      );
      await _psnCacheDataSource.writeTrophies(npCommunicationId, [
        for (final definition in definitions) definition.toJson(),
      ]);
      return definitions;
    } catch (_) {
      final cached = await _psnCacheDataSource.readTrophies(npCommunicationId);
      if (cached == null) rethrow;
      return cached.map(PsnTrophyDefinitionModel.fromJson).toList();
    }
  }

  Trophy _toTrophy(
    PsnTrophyDefinitionModel definition,
    int order,
    TrophyModel? guide,
  ) {
    final psnTrophy = Trophy(
      id: guide?.id ?? 'psn-${definition.trophyId}',
      title: definition.trophyName,
      type: definition.trophyType,
      description: definition.trophyDetail,
      order: order,
      hidden: definition.trophyHidden,
      iconUrl: definition.trophyIconUrl,
    );
    return guide?.enrichFromPsn(psnTrophy) ?? psnTrophy;
  }

  Future<List<TrophyModel>> _getBundledGuides(String? guideSlug) async {
    if (guideSlug == null) return const [];
    try {
      return await _trophyAssetDataSource.loadTrophies(guideSlug);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Trophy>> _getBundledTrophies(String gameId) async {
    final models = await _trophyAssetDataSource.loadTrophies(gameId);
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
