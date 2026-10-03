import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/game.dart';

part 'game_model.g.dart';

@JsonSerializable()
class const GameModel({
  required final String id,
  required final String title,
  required final String numeral,
  required final String cover,
  required final int trophyCount,
  final List<String> psnNames = const [],
}) {
  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  Map<String, dynamic> toJson() => _$GameModelToJson(this);

  Game toEntity() {
    return Game(
      id: id,
      title: title,
      numeral: numeral,
      coverAsset: cover,
      trophyCount: trophyCount,
      guideSlug: id,
    );
  }
}
