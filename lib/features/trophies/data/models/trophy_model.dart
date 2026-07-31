import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/trophy.dart';

part 'trophy_model.g.dart';

@JsonSerializable()
class TrophyModel {
  const TrophyModel({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.guide,
    required this.missable,
    required this.icon,
    required this.order,
  });

  factory TrophyModel.fromJson(Map<String, dynamic> json) =>
      _$TrophyModelFromJson(json);

  final String id;
  final String title;
  final TrophyType type;
  final String description;
  final String guide;
  final bool missable;
  final String icon;
  final int order;

  Map<String, dynamic> toJson() => _$TrophyModelToJson(this);

  Trophy toEntity() {
    return Trophy(
      id: id,
      title: title,
      type: type,
      description: description,
      guide: guide,
      missable: missable,
      iconAsset: icon,
      order: order,
    );
  }
}
