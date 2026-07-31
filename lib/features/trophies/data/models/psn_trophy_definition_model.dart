import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/trophy.dart';

part 'psn_trophy_definition_model.g.dart';

@JsonSerializable()
class PsnTrophyDefinitionModel {
  const PsnTrophyDefinitionModel({
    required this.trophyId,
    this.trophyName = '',
    this.trophyDetail = '',
    this.trophyType = TrophyType.bronze,
    this.trophyIconUrl = '',
    this.trophyHidden = false,
  });

  factory PsnTrophyDefinitionModel.fromJson(Map<String, dynamic> json) =>
      _$PsnTrophyDefinitionModelFromJson(json);

  final int trophyId;
  final String trophyName;
  final String trophyDetail;

  @JsonKey(unknownEnumValue: TrophyType.bronze)
  final TrophyType trophyType;

  final String trophyIconUrl;
  final bool trophyHidden;

  Map<String, dynamic> toJson() => _$PsnTrophyDefinitionModelToJson(this);
}

@JsonSerializable()
class PsnEarnedTrophyModel {
  const PsnEarnedTrophyModel({required this.trophyId, this.earned = false});

  factory PsnEarnedTrophyModel.fromJson(Map<String, dynamic> json) =>
      _$PsnEarnedTrophyModelFromJson(json);

  final int trophyId;

  @JsonKey(readValue: _readEarned)
  final bool earned;

  Map<String, dynamic> toJson() => _$PsnEarnedTrophyModelToJson(this);

  static Object? _readEarned(Map<dynamic, dynamic> json, String key) =>
      json[key] ?? json['trophyEarned'];
}
