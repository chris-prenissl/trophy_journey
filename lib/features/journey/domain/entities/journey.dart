class JourneyTask {
  const JourneyTask({
    required this.id,
    required this.title,
    this.note = '',
    required this.trophyIds,
    this.missable = false,
  });

  final String id;
  final String title;
  final String note;
  final List<String> trophyIds;
  final bool missable;
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

  bool get hasMissable => tasks.any((t) => t.missable);
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
