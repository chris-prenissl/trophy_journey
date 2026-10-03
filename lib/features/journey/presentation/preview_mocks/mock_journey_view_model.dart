import 'package:flutter/foundation.dart';

import '../../../trophies/domain/entities/trophy.dart';
import '../../domain/entities/journey.dart';
import '../viewmodels/journey_view_model.dart';

class MockJourneyViewModel extends ChangeNotifier implements JourneyViewModel {
  @override
  String get gameId => 'preview';

  @override
  bool get loading => false;

  @override
  List<JourneyStep> get steps => const [];

  @override
  String? get bookmarkedStepId => null;

  @override
  int get totalTaskCount => 3;

  @override
  int get checkedTaskCount => 2;

  @override
  double get progress => 2 / 3;

  @override
  bool isTaskChecked(String taskId) => taskId == 'task_1' || taskId == 'task_2';

  @override
  int checkedCountOf(JourneyStep step) => 2;

  @override
  bool isStepComplete(JourneyStep step) => false;

  @override
  bool isBookmarked(String stepId) => false;

  @override
  Trophy? trophyById(String trophyId) => null;

  @override
  int get initialStepIndex => 0;

  @override
  Future<void> load() async {}

  @override
  Future<void> toggleTask(String taskId) async {}

  @override
  Future<void> toggleBookmark(String stepId) async {}
}
