import 'package:flutter/foundation.dart';

import '../../domain/entities/game.dart';
import '../../domain/repositories/game_repository.dart';
import '../state/trophy_progress_store.dart';

enum GameSort {
  recentlyPlayed('Recently played'),
  title('Title'),
  completion('Completion %');

  const GameSort(this.label);

  final String label;
}

enum GameStatusFilter { all, notStarted, inProgress, completed }

class GameListViewModel(
  final GameRepository _gameRepository,
  final TrophyProgressStore _progress,
) extends ChangeNotifier {
  this {
    _progress.addListener(_onProgressChanged);
  }

  List<Game> _games = const [];
  List<Game>? _visibleGames;
  GameSort _sort = GameSort.recentlyPlayed;
  GameStatusFilter _statusFilter = GameStatusFilter.all;
  Set<String> _selectedPlatforms = const {};
  String _query = '';
  bool _loading = true;

  bool get loading => _loading;

  List<Game> get games => _games;

  List<Game> get visibleGames => _visibleGames ??= _computeVisible();

  GameSort get sort => _sort;

  GameStatusFilter get statusFilter => _statusFilter;

  Set<String> get selectedPlatforms => _selectedPlatforms;

  String get query => _query;

  List<String> get platforms {
    final seen = <String>{for (final g in _games) ..._platformsOf(g)};
    return seen.toList()..sort();
  }

  int get totalTrophyCount => _games.fold(0, (sum, g) => sum + g.trophyCount);

  int get totalAchievedCount =>
      _games.fold(0, (sum, g) => sum + achievedCountFor(g.id));

  int achievedCountFor(String gameId) {
    final stored = _progress.countFor(gameId);
    final reported = _psnEarnedCountFor(gameId);
    return stored > reported ? stored : reported;
  }

  double completionFor(Game game) => game.completion(achievedCountFor(game.id));

  int _psnEarnedCountFor(String gameId) {
    for (final game in _games) {
      if (game.id == gameId) return game.psnEarnedCount;
    }
    return 0;
  }

  Future<void> load() async {
    _games = await _gameRepository.getGames();
    _loading = false;
    _invalidate();
  }

  void setSort(GameSort value) {
    if (_sort == value) return;

    _sort = value;
    _invalidate();
  }

  void setStatusFilter(GameStatusFilter value) {
    if (_statusFilter == value) return;

    _statusFilter = value;
    _invalidate();
  }

  void togglePlatform(String platform) {
    final next = {..._selectedPlatforms};
    if (!next.add(platform)) next.remove(platform);
    _selectedPlatforms = next;
    _invalidate();
  }

  void setQuery(String value) {
    if (_query == value) return;

    _query = value;
    _invalidate();
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() => _invalidate();

  void _invalidate() {
    _visibleGames = null;
    notifyListeners();
  }

  List<String> _platformsOf(Game game) => [
    for (final p in game.platform.split(','))
      if (p.trim().isNotEmpty) p.trim(),
  ];

  GameStatusFilter _statusOf(Game game) {
    final achieved = achievedCountFor(game.id);
    if (achieved == 0) return GameStatusFilter.notStarted;
    if (achieved >= game.trophyCount && game.trophyCount > 0) {
      return GameStatusFilter.completed;
    }
    return GameStatusFilter.inProgress;
  }

  List<Game> _computeVisible() {
    final query = _query.trim().toLowerCase();

    final visible = _games.where((game) {
      if (query.isNotEmpty && !game.title.toLowerCase().contains(query)) {
        return false;
      }
      if (_statusFilter != GameStatusFilter.all &&
          _statusOf(game) != _statusFilter) {
        return false;
      }
      if (_selectedPlatforms.isNotEmpty &&
          !_platformsOf(game).any(_selectedPlatforms.contains)) {
        return false;
      }
      return true;
    }).toList();

    switch (_sort) {
      case GameSort.recentlyPlayed:
        break;
      case GameSort.title:
        visible.sort((a, b) => a.title.compareTo(b.title));
      case GameSort.completion:
        visible.sort((a, b) {
          final byCompletion = completionFor(b).compareTo(completionFor(a));
          return byCompletion != 0 ? byCompletion : a.title.compareTo(b.title);
        });
    }

    return visible;
  }
}
