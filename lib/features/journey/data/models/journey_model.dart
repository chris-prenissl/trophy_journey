import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/journey.dart';

part 'journey_model.g.dart';

@JsonSerializable(explicitToJson: true)
class JourneyModel {
  const JourneyModel({required this.gameId, required this.steps});

  factory JourneyModel.fromJson(Map<String, dynamic> json) =>
      _$JourneyModelFromJson(json);

  final String gameId;
  final List<JourneyStepModel> steps;

  Map<String, dynamic> toJson() => _$JourneyModelToJson(this);

  Journey toEntity() {
    return Journey(
      gameId: gameId,
      steps: steps.map((s) => s.toEntity()).toList(),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class JourneyStepModel {
  const JourneyStepModel({
    required this.id,
    required this.title,
    required this.instructions,
    required this.tasks,
  });

  factory JourneyStepModel.fromJson(Map<String, dynamic> json) =>
      _$JourneyStepModelFromJson(json);

  final String id;
  final String title;
  final String instructions;
  final List<JourneyTaskModel> tasks;

  Map<String, dynamic> toJson() => _$JourneyStepModelToJson(this);

  JourneyStep toEntity() {
    return JourneyStep(
      id: id,
      title: title,
      instructions: instructions,
      tasks: tasks.map((t) => t.toEntity()).toList(),
    );
  }
}

@JsonSerializable()
class JourneyTaskModel {
  const JourneyTaskModel({
    required this.id,
    required this.title,
    required this.note,
    required this.trophyIds,
    required this.flag,
  });

  factory JourneyTaskModel.fromJson(Map<String, dynamic> json) =>
      _$JourneyTaskModelFromJson(json);

  final String id;
  final String title;

  @JsonKey(defaultValue: '')
  final String note;

  final List<String> trophyIds;

  @JsonKey(defaultValue: TaskFlag.none, unknownEnumValue: TaskFlag.none)
  final TaskFlag flag;

  Map<String, dynamic> toJson() => _$JourneyTaskModelToJson(this);

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
