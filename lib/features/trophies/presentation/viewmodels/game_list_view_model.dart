import 'package:flutter/foundation.dart';

import '../../domain/entities/game.dart';
import '../../domain/usecases/get_all_achieved_trophy_ids.dart';
import '../../domain/usecases/get_games.dart';

class GameListViewModel extends ChangeNotifier {
  GameListViewModel(this._getGames, this._getAllAchievedTrophyIds);

  final GetGames _getGames;
  final GetAllAchievedTrophyIds _getAllAchievedTrophyIds;

  List<Game> _games = const [];
  Map<String, Set<String>> _achievedByGame = const {};
  bool _loading = true;

  bool get loading => _loading;
  List<Game> get games => _games;

  int get totalTrophyCount =>
      _games.fold(0, (sum, g) => sum + g.trophyCount);
  int get totalAchievedCount =>
      _games.fold(0, (sum, g) => sum + achievedCountFor(g.id));

  int achievedCountFor(String gameId) => _achievedByGame[gameId]?.length ?? 0;

  Future<void> load() async {
    _games = await _getGames();
    _achievedByGame = await _getAllAchievedTrophyIds();
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshProgress() async {
    _achievedByGame = await _getAllAchievedTrophyIds();
    notifyListeners();
  }
}
