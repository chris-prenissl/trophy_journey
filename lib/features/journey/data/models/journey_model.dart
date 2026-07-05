import '../../domain/entities/journey.dart';

class JourneyModel {
  const JourneyModel({required this.gameId, required this.steps});

  factory JourneyModel.fromJson(Map<String, dynamic> json) {
    return JourneyModel(
      gameId: json['gameId'] as String,
      steps: (json['steps'] as List<dynamic>)
          .map((e) => JourneyStepModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String gameId;
  final List<JourneyStepModel> steps;

  Journey toEntity() {
    return Journey(
      gameId: gameId,
      steps: steps.map((s) => s.toEntity()).toList(),
    );
  }
}

class JourneyStepModel {
  const JourneyStepModel({
    required this.id,
    required this.title,
    required this.instructions,
    required this.tasks,
  });

  factory JourneyStepModel.fromJson(Map<String, dynamic> json) {
    return JourneyStepModel(
      id: json['id'] as String,
      title: json['title'] as String,
      instructions: json['instructions'] as String,
      tasks: (json['tasks'] as List<dynamic>)
          .map((e) => JourneyTaskModel.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }

  final String id;
  final String title;
  final String instructions;
  final List<JourneyTaskModel> tasks;

  JourneyStep toEntity() {
    return JourneyStep(
      id: id,
      title: title,
      instructions: instructions,
      tasks: tasks.map((t) => t.toEntity()).toList(),
    );
  }
}

class JourneyTaskModel {
  const JourneyTaskModel({
    required this.id,
    required this.title,
    required this.note,
    required this.trophyIds,
    required this.flag,
  });

  factory JourneyTaskModel.fromJson(Map<String, dynamic> json) {
    return JourneyTaskModel(
      id: json['id'] as String,
      title: json['title'] as String,
      note: json['note'] as String? ?? '',
      trophyIds: (json['trophyIds'] as List<dynamic>).cast<String>(),
      flag: _parseFlag(json),
    );
  }

  static TaskFlag _parseFlag(Map<String, dynamic> json) {
    final raw = json['flag'];
    if (raw is String) return TaskFlag.fromJson(raw);
    return TaskFlag.none;
  }

  final String id;
  final String title;
  final String note;
  final List<String> trophyIds;
  final TaskFlag flag;

  JourneyTask toEntity() {
    return JourneyTask(
      id: id,
      title: title,
      note: note,
      trophyIds: trophyIds,
      flag: flag,
    );
  }
}
