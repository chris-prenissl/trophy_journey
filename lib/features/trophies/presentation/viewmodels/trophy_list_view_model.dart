import 'package:flutter/foundation.dart';

import '../../domain/entities/trophy.dart';
import '../../domain/usecases/get_achieved_trophy_ids.dart';
import '../../domain/usecases/get_trophies.dart';
import '../../domain/usecases/set_trophy_achieved.dart';

class TrophyListViewModel extends ChangeNotifier {
  TrophyListViewModel(
    this._gameId,
    this._getTrophies,
    this._getAchievedTrophyIds,
    this._setTrophyAchieved,
  );

  final String _gameId;
  final GetTrophies _getTrophies;
  final GetAchievedTrophyIds _getAchievedTrophyIds;
  final SetTrophyAchieved _setTrophyAchieved;

  List<Trophy> _trophies = const [];
  Set<String> _achievedIds = {};
  bool _missablesOnly = false;
  bool _hideAchieved = false;
  bool _loading = true;

  String get gameId => _gameId;
  bool get loading => _loading;
  bool get missablesOnly => _missablesOnly;
  bool get hideAchieved => _hideAchieved;
  bool get hasMissables => _trophies.any((t) => t.missable);
  int get totalCount => _trophies.length;
  int get achievedCount =>
      _trophies.where((t) => _achievedIds.contains(t.id)).length;
  double get progress => totalCount == 0 ? 0 : achievedCount / totalCount;

  bool isAchieved(String trophyId) => _achievedIds.contains(trophyId);

  List<Trophy> get visibleTrophies {
    final filtered = _trophies.where((t) {
      if (_missablesOnly && !t.missable) return false;
      if (_hideAchieved && isAchieved(t.id)) return false;
      return true;
    });
    
    return [
      for (final t in filtered) if (!isAchieved(t.id)) t,
      for (final t in filtered) if (isAchieved(t.id)) t,
    ];
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _trophies = await _getTrophies(_gameId);
    _achievedIds = await _getAchievedTrophyIds(_gameId);
    _loading = false;
    notifyListeners();
  }

  Future<void> refreshProgress() async {
    _achievedIds = await _getAchievedTrophyIds(_gameId);
    notifyListeners();
  }

  Future<void> toggleAchieved(String trophyId) async {
    final achieved = !_achievedIds.contains(trophyId);
    if (achieved) {
      _achievedIds.add(trophyId);
    } else {
      _achievedIds.remove(trophyId);
    }
    notifyListeners();
    await _setTrophyAchieved(_gameId, trophyId, achieved);
  }

  void setMissablesOnly(bool value) {
    _missablesOnly = value;
    notifyListeners();
  }

  void setHideAchieved(bool value) {
    _hideAchieved = value;
    notifyListeners();
  }
}
