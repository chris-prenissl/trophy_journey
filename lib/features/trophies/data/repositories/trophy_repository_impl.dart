import '../../domain/entities/game.dart';
import '../../domain/entities/trophy.dart';
import '../../domain/repositories/trophy_repository.dart';
import '../datasources/psn_cache_data_source.dart';
import '../datasources/psn_trophy_data_source.dart';
import '../datasources/trophy_asset_data_source.dart';
import '../guide_matcher.dart';
import '../models/psn_trophy_definition_model.dart';
import '../models/trophy_model.dart';
import '../psn_library.dart';

class TrophyRepositoryImpl implements TrophyRepository {
  const TrophyRepositoryImpl({
    required this._library,
    required this._psn,
    required this._cache,
    required this._guides,
  });

  final PsnLibrary _library;
  final PsnTrophyDataSource _psn;
  final PsnCacheDataSource _cache;
  final TrophyAssetDataSource _guides;

  @override
  Future<List<Trophy>> getTrophies(String gameId) async {
    final game = await _library.gameById(gameId);
    if (game?.npCommunicationId == null) {
      return _bundledTrophies(gameId);
    }

    final definitions = await _definitions(game!);
    final guides = GuideMatcher.indexTrophies(
      await _bundledGuides(game.guideSlug),
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
    final game = await _library.gameById(gameId);
    final npCommunicationId = game?.npCommunicationId;
    if (npCommunicationId == null) return const {};

    final earnedIds = await _earnedIds(game!, npCommunicationId);
    if (earnedIds.isEmpty) return const {};

    final definitions = await _definitions(game);
    final guides = GuideMatcher.indexTrophies(
      await _bundledGuides(game.guideSlug),
    );

    return {
      for (final definition in definitions)
        if (earnedIds.contains(definition.trophyId))
          GuideMatcher.guideForTrophy(guides, definition)?.id ??
              'psn-${definition.trophyId}',
    };
  }

  Future<Set<int>> _earnedIds(Game game, String npCommunicationId) async {
    try {
      final earned = await _psn.fetchEarnedTrophyIds(
        npCommunicationId: npCommunicationId,
        npServiceName: game.npServiceName ?? 'trophy',
      );
      await _cache.writeEarned(npCommunicationId, earned);
      return earned;
    } catch (_) {
      return await _cache.readEarned(npCommunicationId) ?? const {};
    }
  }

  Future<List<PsnTrophyDefinitionModel>> _definitions(Game game) async {
    final npCommunicationId = game.npCommunicationId!;
    try {
      final definitions = await _psn.fetchTrophyDefinitions(
        npCommunicationId: npCommunicationId,
        npServiceName: game.npServiceName ?? 'trophy',
      );
      await _cache.writeTrophies(npCommunicationId, [
        for (final definition in definitions) definition.toJson(),
      ]);
      return definitions;
    } catch (_) {
      final cached = await _cache.readTrophies(npCommunicationId);
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

  Future<List<TrophyModel>> _bundledGuides(String? guideSlug) async {
    if (guideSlug == null) return const [];
    try {
      return await _guides.loadTrophies(guideSlug);
    } catch (_) {
      return const [];
    }
  }

  Future<List<Trophy>> _bundledTrophies(String gameId) async {
    final models = await _guides.loadTrophies(gameId);
    return models.map((m) => m.toEntity()).toList()
      ..sort((a, b) => a.order.compareTo(b.order));
  }
}
