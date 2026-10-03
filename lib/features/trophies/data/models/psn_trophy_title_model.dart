import 'package:json_annotation/json_annotation.dart';

part 'psn_trophy_title_model.g.dart';

@JsonSerializable()
class const PsnTrophyCountsModel({
  final int bronze = 0,
  final int silver = 0,
  final int gold = 0,
  final int platinum = 0,
}) {
  factory PsnTrophyCountsModel.fromJson(Map<String, dynamic> json) =>
      _$PsnTrophyCountsModelFromJson(json);

  int get total => bronze + silver + gold + platinum;

  Map<String, dynamic> toJson() => _$PsnTrophyCountsModelToJson(this);
}

@JsonSerializable()
class const PsnTrophyTitleModel({
  required final String npCommunicationId,
  final String npServiceName = 'trophy',
  final String trophyTitleName = '',
  final String trophyTitleIconUrl = '',
  final String trophyTitlePlatform = '',
  final PsnTrophyCountsModel definedTrophies = const PsnTrophyCountsModel(),
  final PsnTrophyCountsModel earnedTrophies = const PsnTrophyCountsModel(),
  final DateTime? lastUpdatedDateTime,
}) {
  factory PsnTrophyTitleModel.fromJson(Map<String, dynamic> json) =>
      _$PsnTrophyTitleModelFromJson(json);

  Map<String, dynamic> toJson() => _$PsnTrophyTitleModelToJson(this);
}
