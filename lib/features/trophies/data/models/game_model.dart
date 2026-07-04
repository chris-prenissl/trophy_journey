import '../../domain/entities/game.dart';

class GameModel {
  const GameModel({
    required this.id,
    required this.title,
    required this.numeral,
    required this.cover,
    required this.trophyCount,
  });

  factory GameModel.fromJson(Map<String, dynamic> json) {
    return GameModel(
      id: json['id'] as String,
      title: json['title'] as String,
      numeral: json['numeral'] as String,
      cover: json['cover'] as String,
      trophyCount: json['trophyCount'] as int,
    );
  }

  final String id;
  final String title;
  final String numeral;
  final String cover;
  final int trophyCount;

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
