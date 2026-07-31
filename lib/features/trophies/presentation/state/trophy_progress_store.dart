import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import '../../domain/usecases/replace_earned_trophies_use_case.dart';

class TrophyProgressStore extends ChangeNotifier {
  TrophyProgressStore(this._getAllEarnedTrophyIds, this._replaceEarnedTrophies);

  final GetAllEarnedTrophyIdsUseCase _getAllEarnedTrophyIds;
  final ReplaceEarnedTrophiesUseCase _replaceEarnedTrophies;

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
    _earnedByGame = await _getAllEarnedTrophyIds();
    _loading = false;
    notifyListeners();
  }

  Future<void> applyEarned(String gameId, Set<String> trophyIds) async {
    await _replaceEarnedTrophies(gameId, trophyIds);

    _earnedByGame = {..._earnedByGame, gameId: trophyIds};
    notifyListeners();
  }
}
