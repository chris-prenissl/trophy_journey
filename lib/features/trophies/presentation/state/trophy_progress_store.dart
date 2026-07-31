import 'package:flutter/foundation.dart';

import '../../domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import '../../domain/usecases/set_trophy_achieved_use_case.dart';

class TrophyProgressStore extends ChangeNotifier {
  TrophyProgressStore(this._getAllAchievedTrophyIds, this._setTrophyAchieved);

  final GetAllAchievedTrophyIdsUseCase _getAllAchievedTrophyIds;
  final SetTrophyAchievedUseCase _setTrophyAchieved;

  Map<String, Set<String>> _achievedByGame = const {};
  bool _loading = true;

  bool get loading => _loading;

  Set<String> achievedFor(String gameId) =>
      _achievedByGame[gameId] ?? const <String>{};

  bool isAchieved(String gameId, String trophyId) =>
      achievedFor(gameId).contains(trophyId);

  int countFor(String gameId) => achievedFor(gameId).length;

  int get totalAchievedCount =>
      _achievedByGame.values.fold(0, (sum, ids) => sum + ids.length);

  Future<void> load() async {
    _achievedByGame = await _getAllAchievedTrophyIds();
    _loading = false;
    notifyListeners();
  }

  Future<void> toggle(String gameId, String trophyId) =>
      setAchieved(gameId, trophyId, !isAchieved(gameId, trophyId));

  Future<void> setAchieved(
    String gameId,
    String trophyId,
    bool achieved,
  ) async {
    final previous = _achievedByGame;
    _achievedByGame = _copyWith(gameId, trophyId, achieved);
    notifyListeners();
    
    try {
      await _setTrophyAchieved(gameId, trophyId, achieved);
    } catch (_) {
      _achievedByGame = previous;
      notifyListeners();
      rethrow;
    }
  }

  Map<String, Set<String>> _copyWith(
    String gameId,
    String trophyId,
    bool achieved,
  ) {
    final ids = {...achievedFor(gameId)};
    if (achieved) {
      ids.add(trophyId);
    } else {
      ids.remove(trophyId);
    }
    return {..._achievedByGame, gameId: ids};
  }
}
