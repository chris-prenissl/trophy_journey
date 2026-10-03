import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/trophy.dart';

part 'trophy_model.g.dart';

@JsonSerializable()
class const TrophyModel({
  required final String id,
  required final String title,
  required final TrophyType type,
  required final String description,
  required final String guide,
  required final bool missable,
  required final String icon,
  required final int order,
}) {
  factory TrophyModel.fromJson(Map<String, dynamic> json) =>
      _$TrophyModelFromJson(json);

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

  Trophy enrichFromPsn(Trophy psnTrophy) {
    return Trophy(
      id: id,
      title: psnTrophy.title,
      type: psnTrophy.type,
      description: psnTrophy.description,
      order: psnTrophy.order,
      guide: guide,
      missable: missable,
      hidden: psnTrophy.hidden,
      iconAsset: icon,
      iconUrl: psnTrophy.iconUrl,
    );
  }
}
