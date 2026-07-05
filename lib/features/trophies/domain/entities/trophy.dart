enum TrophyType { bronze, silver, gold, platinum }

class Trophy {
  const Trophy({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.guide,
    required this.missable,
    required this.iconAsset,
    required this.order,
  });

  final String id;
  final String title;
  final TrophyType type;
  final String description;
  final String guide;
  final bool missable;
  final String iconAsset;
  final int order;
}
