import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/journey.dart';

part 'journey_model.g.dart';

@JsonSerializable(explicitToJson: true)
class const JourneyModel({
  required final String gameId,
  required final List<JourneyStepModel> steps,
}) {
  factory JourneyModel.fromJson(Map<String, dynamic> json) =>
      _$JourneyModelFromJson(json);

  Map<String, dynamic> toJson() => _$JourneyModelToJson(this);

  Journey toEntity() {
    return Journey(
      gameId: gameId,
      steps: steps.map((s) => s.toEntity()).toList(),
    );
  }
}

@JsonSerializable(explicitToJson: true)
class const JourneyStepModel({
  required final String id,
  required final String title,
  required final String instructions,
  required final List<JourneyTaskModel> tasks,
}) {
  factory JourneyStepModel.fromJson(Map<String, dynamic> json) =>
      _$JourneyStepModelFromJson(json);

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
