import 'package:flutter/foundation.dart';

import '../../domain/entities/game.dart';
import '../../domain/usecases/get_games_use_case.dart';
import '../state/trophy_progress_store.dart';

class GameListViewModel extends ChangeNotifier {
  GameListViewModel(this._getGames, this._progress) {
    _progress.addListener(_onProgressChanged);
  }

  final GetGamesUseCase _getGames;
  final TrophyProgressStore _progress;

  List<Game> _games = const [];
  bool _loading = true;

  bool get loading => _loading;
  List<Game> get games => _games;

  int get totalTrophyCount => _games.fold(0, (sum, g) => sum + g.trophyCount);

  int get totalAchievedCount =>
      _games.fold(0, (sum, g) => sum + achievedCountFor(g.id));

  int achievedCountFor(String gameId) {
    final stored = _progress.countFor(gameId);
    final reported = _psnEarnedCountFor(gameId);
    return stored > reported ? stored : reported;
  }

  int _psnEarnedCountFor(String gameId) {
    for (final game in _games) {
      if (game.id == gameId) return game.psnEarnedCount;
    }
    return 0;
  }

  Future<void> load() async {
    _games = await _getGames();
    _loading = false;
    notifyListeners();
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() => notifyListeners();
}
