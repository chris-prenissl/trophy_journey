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

class JourneyTask {
  const JourneyTask({
    required this.id,
    required this.title,
    this.note = '',
    required this.trophyIds,
    this.flag = TaskFlag.none,
  });

  final String id;
  final String title;
  final String note;
  final List<String> trophyIds;
  final TaskFlag flag;

  bool get isMissable => flag == TaskFlag.missable;
  bool get isRecommended => flag == TaskFlag.recommended;
}

class JourneyStep {
  const JourneyStep({
    required this.id,
    required this.title,
    required this.instructions,
    required this.tasks,
  });

  final String id;
  final String title;
  final String instructions;
  final List<JourneyTask> tasks;

  bool get hasMissable => tasks.any((t) => t.isMissable);
  bool get hasRecommended => tasks.any((t) => t.isRecommended);
}

class Journey {
  Journey({required this.gameId, required this.steps});

  final String gameId;
  final List<JourneyStep> steps;

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
