import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';
import '../datasources/game_asset_data_source.dart';
import '../datasources/psn_cache_data_source.dart';
import '../datasources/psn_trophy_data_source.dart';
import '../guide_matcher.dart';
import '../models/game_model.dart';
import '../models/psn_trophy_title_model.dart';

class GameRepositoryImpl implements GameRepository {
  GameRepositoryImpl({
    required this.psnTrophyDataSource,
    required this.psnCacheDataSource,
    required this.gameAssetDataSource,
  });

  final PsnTrophyDataSource psnTrophyDataSource;
  final PsnCacheDataSource psnCacheDataSource;
  final GameAssetDataSource gameAssetDataSource;

  GuideMatcher? _matcher;
  List<Game>? _games;

  @override
  Future<List<Game>> getGames() => _load(refresh: true);

  @override
  Future<Game?> getGame(String id) async {
    for (final game in await _load(refresh: false)) {
      if (game.id == id) {
        return game;
      }
    }
    return null;
  }

  Future<List<Game>> _load({required bool refresh}) async {
    final cached = _games;
    if (cached != null && !refresh) {
      return cached;
    }

    final matcher = await _guideMatcher();
    final titles = await _titles();

    final games = titles.map((title) => _toGame(title, matcher)).toList()
      ..sort((a, b) {
        final left = a.lastUpdated;
        final right = b.lastUpdated;
        if (left == null || right == null) {
          return a.title.compareTo(b.title);
        }

        return right.compareTo(left);
      });

    return _games = games;
  }

  Future<List<PsnTrophyTitleModel>> _titles() async {
    try {
      final titles = await psnTrophyDataSource.fetchTrophyTitles();
      await psnCacheDataSource.writeTitles([
        for (final t in titles) t.toJson(),
      ]);
      return titles;
    } catch (_) {
      final cached = await psnCacheDataSource.readTitles();
      if (cached == null) {
        rethrow;
      }
      return cached.map(PsnTrophyTitleModel.fromJson).toList();
    }
  }

  Game _toGame(PsnTrophyTitleModel title, GuideMatcher matcher) {
    final guide = matcher.guideForGame(title);
    return Game(
      id: guide?.id ?? title.npCommunicationId,
      title: guide?.title ?? title.trophyTitleName,
      trophyCount: title.definedTrophies.total,
      psnEarnedCount: title.earnedTrophies.total,
      numeral: guide?.numeral ?? '',
      coverAsset: guide?.cover,
      iconUrl: title.trophyTitleIconUrl,
      npCommunicationId: title.npCommunicationId,
      npServiceName: title.npServiceName,
      platform: title.trophyTitlePlatform,
      lastUpdated: title.lastUpdatedDateTime,
      guideSlug: guide?.id,
    );
  }

  Future<GuideMatcher> _guideMatcher() async {
    final matcher = _matcher;
    if (matcher != null) return matcher;

    List<GameModel> bundled;
    try {
      bundled = await gameAssetDataSource.loadGames();
    } catch (_) {
      bundled = const [];
    }
    return _matcher = GuideMatcher(bundled);
  }
}
