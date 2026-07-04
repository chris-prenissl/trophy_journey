import '../../domain/entities/trophy.dart';

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

  factory TrophyModel.fromJson(Map<String, dynamic> json) {
    return TrophyModel(
      id: json['id'] as String,
      title: json['title'] as String,
      type: json['type'] as String,
      description: json['description'] as String,
      guide: json['guide'] as String,
      missable: json['missable'] as bool,
      icon: json['icon'] as String,
      order: json['order'] as int,
    );
  }

  final String id;
  final String title;
  final String type;
  final String description;
  final String guide;
  final bool missable;
  final String icon;
  final int order;

  Trophy toEntity() {
    return Trophy(
      id: id,
      title: title,
      type: TrophyType.values.byName(type),
      description: description,
      guide: guide,
      missable: missable,
      iconAsset: icon,
      order: order,
    );
  }
}
