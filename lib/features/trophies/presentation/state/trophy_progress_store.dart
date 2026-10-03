import 'package:flutter/foundation.dart';

import '../../domain/repositories/trophy_progress_repository.dart';

class TrophyProgressStore(final TrophyProgressRepository _repository)
    extends ChangeNotifier {
  Map<String, Set<String>> _earnedByGame = const {};
  bool _loading = true;

  bool get loading => _loading;

  Set<String> achievedFor(String gameId) =>
      _earnedByGame[gameId] ?? const <String>{};

  bool isAchieved(String gameId, String trophyId) =>
      achievedFor(gameId).contains(trophyId);

  int countFor(String gameId) => achievedFor(gameId).length;

  int get totalAchievedCount =>
      _earnedByGame.values.fold(0, (sum, ids) => sum + ids.length);

  Future<void> load() async {
    _earnedByGame = await _repository.getAllEarnedIds();
    _loading = false;
    notifyListeners();
  }

  Future<void> applyEarned(String gameId, Set<String> trophyIds) async {
    await _repository.replaceEarned(gameId, trophyIds);

    _earnedByGame = {..._earnedByGame, gameId: trophyIds};
    notifyListeners();
  }
}
