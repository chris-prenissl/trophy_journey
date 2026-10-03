enum TaskFlag {
  none,
  recommended,
  missable;

  static TaskFlag fromJson(String? value) => switch (value) {
    'missable' => TaskFlag.missable,
    'recommended' => TaskFlag.recommended,
    _ => TaskFlag.none,
  };
}

class const JourneyTask({
  required final String id,
  required final String title,
  final String note = '',
  required final List<String> trophyIds,
  final TaskFlag flag = TaskFlag.none,
}) {
  bool get isMissable => flag == TaskFlag.missable;
  bool get isRecommended => flag == TaskFlag.recommended;
}

class const JourneyStep({
  required final String id,
  required final String title,
  required final String instructions,
  required final List<JourneyTask> tasks,
}) {
  bool get hasMissable => tasks.any((t) => t.isMissable);
  bool get hasRecommended => tasks.any((t) => t.isRecommended);
}

class Journey({
  required final String gameId,
  required final List<JourneyStep> steps,
}) {
  late final List<JourneyTask> allTasks = [
    for (final step in steps) ...step.tasks,
  ];

  int get totalTaskCount => allTasks.length;

  late final Map<String, List<String>> taskIdsByTrophyId = () {
    final result = <String, List<String>>{};
    for (final task in allTasks) {
      for (final trophyId in task.trophyIds) {
        result.putIfAbsent(trophyId, () => []).add(task.id);
      }
    }
    return result;
  }();
}
