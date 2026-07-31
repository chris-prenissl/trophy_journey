import 'package:json_annotation/json_annotation.dart';

import '../../domain/entities/game.dart';

part 'game_model.g.dart';

@JsonSerializable()
class GameModel {
  const GameModel({
    required this.id,
    required this.title,
    required this.numeral,
    required this.cover,
    required this.trophyCount,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) =>
      _$GameModelFromJson(json);

  final String id;
  final String title;
  final String numeral;
  final String cover;
  final int trophyCount;

  Map<String, dynamic> toJson() => _$GameModelToJson(this);

  Game toEntity() {
    return Game(
      id: id,
      title: title,
      numeral: numeral,
      coverAsset: cover,
      trophyCount: trophyCount,
    );
  }
}
