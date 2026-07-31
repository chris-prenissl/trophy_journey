import 'package:json_annotation/json_annotation.dart';

part 'psn_trophy_title_model.g.dart';

@JsonSerializable()
class PsnTrophyCountsModel {
  const PsnTrophyCountsModel({
    this.bronze = 0,
    this.silver = 0,
    this.gold = 0,
    this.platinum = 0,
  });

  factory PsnTrophyCountsModel.fromJson(Map<String, dynamic> json) =>
      _$PsnTrophyCountsModelFromJson(json);

  final int bronze;
  final int silver;
  final int gold;
  final int platinum;

  int get total => bronze + silver + gold + platinum;

  Map<String, dynamic> toJson() => _$PsnTrophyCountsModelToJson(this);
}

@JsonSerializable()
class PsnTrophyTitleModel {
  const PsnTrophyTitleModel({
    required this.npCommunicationId,
    this.npServiceName = 'trophy',
    this.trophyTitleName = '',
    this.trophyTitleIconUrl = '',
    this.trophyTitlePlatform = '',
    this.definedTrophies = const PsnTrophyCountsModel(),
    this.earnedTrophies = const PsnTrophyCountsModel(),
    this.lastUpdatedDateTime,
  });

  factory PsnTrophyTitleModel.fromJson(Map<String, dynamic> json) =>
      _$PsnTrophyTitleModelFromJson(json);

  final String npCommunicationId;
  final String npServiceName;
  final String trophyTitleName;
  final String trophyTitleIconUrl;
  final String trophyTitlePlatform;
  final PsnTrophyCountsModel definedTrophies;
  final PsnTrophyCountsModel earnedTrophies;
  final DateTime? lastUpdatedDateTime;

  Map<String, dynamic> toJson() => _$PsnTrophyTitleModelToJson(this);
}
