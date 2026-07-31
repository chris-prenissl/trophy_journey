import '../domain/entities/game.dart';
import 'datasources/game_asset_data_source.dart';
import 'datasources/psn_cache_data_source.dart';
import 'datasources/psn_trophy_data_source.dart';
import 'guide_matcher.dart';
import 'models/game_model.dart';
import 'models/psn_trophy_title_model.dart';

class PsnLibrary {
  PsnLibrary({
    required this._psn,
    required this._cache,
    required this._guides,
  });

  final PsnTrophyDataSource _psn;
  final PsnCacheDataSource _cache;
  final GameAssetDataSource _guides;

  GuideMatcher? _matcher;
  List<Game>? _games;

  Future<List<Game>> games({bool refresh = false}) async {
    final cached = _games;
    if (cached != null && !refresh) return cached;

    final matcher = await _guideMatcher();
    final titles = await _titles(refresh: refresh);

    final games = titles.map((title) => _toGame(title, matcher)).toList()
      ..sort((a, b) {
        final left = a.lastUpdated;
        final right = b.lastUpdated;
        if (left == null || right == null) return a.title.compareTo(b.title);
        return right.compareTo(left);
      });

    return _games = games;
  }

  Future<Game?> gameById(String id) async {
    for (final game in await games()) {
      if (game.id == id) return game;
    }
    return null;
  }

  Future<List<PsnTrophyTitleModel>> _titles({required bool refresh}) async {
    try {
      final titles = await _psn.fetchTrophyTitles();
      await _cache.writeTitles([for (final t in titles) t.toJson()]);
      return titles;
    } catch (_) {
      final cached = await _cache.readTitles();
      if (cached == null) rethrow;
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
      bundled = await _guides.loadGames();
    } catch (_) {
      bundled = const [];
    }
    return _matcher = GuideMatcher(bundled);
  }
}
