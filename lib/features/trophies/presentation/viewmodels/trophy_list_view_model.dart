import 'package:flutter/foundation.dart';

import '../../domain/entities/trophy.dart';
import '../../domain/usecases/get_trophies_use_case.dart';
import '../state/trophy_progress_store.dart';

class TrophyListViewModel extends ChangeNotifier {
  TrophyListViewModel(this._gameId, this._getTrophies, this._progress) {
    _progress.addListener(_onProgressChanged);
  }

  final String _gameId;
  final GetTrophiesUseCase _getTrophies;
  final TrophyProgressStore _progress;

  List<Trophy> _trophies = const [];
  List<Trophy>? _visibleTrophies;
  bool _missablesOnly = false;
  bool _hideAchieved = false;
  bool _loading = true;

  String get gameId => _gameId;

  bool get loading => _loading;

  bool get missablesOnly => _missablesOnly;

  bool get hideAchieved => _hideAchieved;

  bool get hasMissables => _trophies.any((t) => t.missable);

  int get totalCount => _trophies.length;

  int get achievedCount => _trophies.where((t) => isAchieved(t.id)).length;

  double get progress => totalCount == 0 ? 0 : achievedCount / totalCount;

  bool isAchieved(String trophyId) => _progress.isAchieved(_gameId, trophyId);

  List<Trophy> get visibleTrophies => _visibleTrophies ??= _computeVisible();

  Future<void> load() async {
    _loading = true;
    _invalidate();

    _trophies = await _getTrophies(_gameId);
    _loading = false;
    _invalidate();
  }

  Future<void> toggleAchieved(String trophyId) =>
      _progress.toggle(_gameId, trophyId);

  void setMissablesOnly(bool value) {
    if (_missablesOnly == value) return;

    _missablesOnly = value;
    _invalidate();
  }

  void setHideAchieved(bool value) {
    if (_hideAchieved == value) return;
    
    _hideAchieved = value;
    _invalidate();
  }

  @override
  void dispose() {
    _progress.removeListener(_onProgressChanged);
    super.dispose();
  }

  void _onProgressChanged() => _invalidate();

  void _invalidate() {
    _visibleTrophies = null;
    notifyListeners();
  }

  List<Trophy> _computeVisible() {
    final filtered = _trophies.where((t) {
      if (_missablesOnly && !t.missable) return false;
      if (_hideAchieved && isAchieved(t.id)) return false;
      return true;
    });

    return [
      for (final t in filtered)
        if (!isAchieved(t.id)) t,
      for (final t in filtered)
        if (isAchieved(t.id)) t,
    ];
  }
}
