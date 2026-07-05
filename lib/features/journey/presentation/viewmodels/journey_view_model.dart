import 'package:flutter/foundation.dart';

import '../../../trophies/domain/entities/trophy.dart';
import '../../../trophies/domain/usecases/get_trophies.dart';
import '../../domain/entities/journey.dart';
import '../../domain/usecases/get_checked_task_ids.dart';
import '../../domain/usecases/get_journey.dart';
import '../../domain/usecases/get_journey_bookmark.dart';
import '../../domain/usecases/set_journey_bookmark.dart';
import '../../domain/usecases/set_task_checked.dart';

class JourneyViewModel extends ChangeNotifier {
  JourneyViewModel(
    this._gameId,
    this._getJourney,
    this._getTrophies,
    this._getCheckedTaskIds,
    this._setTaskChecked,
    this._getJourneyBookmark,
    this._setJourneyBookmark,
  );

  final String _gameId;
  final GetJourney _getJourney;
  final GetTrophies _getTrophies;
  final GetCheckedTaskIds _getCheckedTaskIds;
  final SetTaskChecked _setTaskChecked;
  final GetJourneyBookmark _getJourneyBookmark;
  final SetJourneyBookmark _setJourneyBookmark;

  Journey? _journey;
  Map<String, Trophy> _trophyById = const {};
  Set<String> _checkedTaskIds = {};
  String? _bookmarkedStepId;
  bool _loading = true;

  String get gameId => _gameId;
  bool get loading => _loading;
  List<JourneyStep> get steps => _journey?.steps ?? const [];
  String? get bookmarkedStepId => _bookmarkedStepId;
  int get totalTaskCount => _journey?.totalTaskCount ?? 0;
  int get checkedTaskCount =>
      _journey == null
          ? 0
          : _journey!.allTasks
                .where((t) => _checkedTaskIds.contains(t.id))
                .length;
  double get progress =>
      totalTaskCount == 0 ? 0 : checkedTaskCount / totalTaskCount;

  bool isTaskChecked(String taskId) => _checkedTaskIds.contains(taskId);

  int checkedCountOf(JourneyStep step) =>
      step.tasks.where((t) => _checkedTaskIds.contains(t.id)).length;

  bool isStepComplete(JourneyStep step) =>
      step.tasks.isNotEmpty && checkedCountOf(step) == step.tasks.length;

  bool isBookmarked(String stepId) => _bookmarkedStepId == stepId;

  Trophy? trophyById(String trophyId) => _trophyById[trophyId];

  int get initialStepIndex {
    final bookmarked = steps.indexWhere((s) => s.id == _bookmarkedStepId);
    if (bookmarked != -1) return bookmarked;
    final firstIncomplete = steps.indexWhere((s) => !isStepComplete(s));
    return firstIncomplete == -1 ? 0 : firstIncomplete;
  }

  Future<void> load() async {
    _loading = true;
    notifyListeners();
    _journey = await _getJourney(_gameId);
    final trophies = await _getTrophies(_gameId);
    _trophyById = {for (final trophy in trophies) trophy.id: trophy};
    _checkedTaskIds = await _getCheckedTaskIds(_gameId);
    _bookmarkedStepId = await _getJourneyBookmark(_gameId);
    _loading = false;
    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    final journey = _journey;
    if (journey == null) return;
    final checked = !_checkedTaskIds.contains(taskId);
    if (checked) {
      _checkedTaskIds.add(taskId);
    } else {
      _checkedTaskIds.remove(taskId);
    }
    notifyListeners();
    await _setTaskChecked(_gameId, taskId, checked);
  }

  Future<void> toggleBookmark(String stepId) async {
    _bookmarkedStepId = _bookmarkedStepId == stepId ? null : stepId;
    notifyListeners();
    await _setJourneyBookmark(_gameId, _bookmarkedStepId);
  }
}
