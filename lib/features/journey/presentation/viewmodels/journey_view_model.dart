import 'package:flutter/foundation.dart';

import '../../../trophies/domain/entities/trophy.dart';
import '../../../trophies/domain/usecases/get_trophies_use_case.dart';
import '../../domain/entities/journey.dart';
import '../../domain/usecases/get_checked_task_ids_use_case.dart';
import '../../domain/usecases/get_journey_bookmark_use_case.dart';
import '../../domain/usecases/get_journey_use_case.dart';
import '../../domain/usecases/set_journey_bookmark_use_case.dart';
import '../../domain/usecases/set_task_checked_use_case.dart';

class JourneyViewModel(
  final String _gameId,
  final GetJourneyUseCase _getJourney,
  final GetTrophiesUseCase _getTrophies,
  final GetCheckedTaskIdsUseCase _getCheckedTaskIds,
  final SetTaskCheckedUseCase _setTaskChecked,
  final GetJourneyBookmarkUseCase _getJourneyBookmark,
  final SetJourneyBookmarkUseCase _setJourneyBookmark,
) extends ChangeNotifier {
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

  int get checkedTaskCount => _journey == null
      ? 0
      : _journey!.allTasks.where((t) => _checkedTaskIds.contains(t.id)).length;

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
    _trophyById = Map.fromEntries(
      trophies.map((trophy) => MapEntry(trophy.id, trophy)),
    );
    _checkedTaskIds = await _getCheckedTaskIds(_gameId);
    _bookmarkedStepId = await _getJourneyBookmark(_gameId);
    _loading = false;

    notifyListeners();
  }

  Future<void> toggleTask(String taskId) async {
    if (_journey == null) return;
    final previous = _checkedTaskIds;
    final checkedTaskIds = !previous.contains(taskId);
    final updated = {...previous};
    if (checkedTaskIds) {
      updated.add(taskId);
    } else {
      updated.remove(taskId);
    }
    _checkedTaskIds = updated;

    notifyListeners();

    try {
      await _setTaskChecked(_gameId, taskId, checkedTaskIds);
    } catch (_) {
      _checkedTaskIds = previous;

      notifyListeners();
      rethrow;
    }
  }

  Future<void> toggleBookmark(String stepId) async {
    final previous = _bookmarkedStepId;
    _bookmarkedStepId = previous == stepId ? null : stepId;
    notifyListeners();

    try {
      await _setJourneyBookmark(_gameId, _bookmarkedStepId);
    } catch (_) {
      _bookmarkedStepId = previous;
      notifyListeners();
      rethrow;
    }
  }
}
