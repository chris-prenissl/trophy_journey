enum TrophyType { bronze, silver, gold, platinum }

class Trophy {
  const Trophy({
    required this.id,
    required this.title,
    required this.type,
    required this.description,
    required this.order,
    this.guide = '',
    this.missable = false,
    this.hidden = false,
    this.iconAsset,
    this.iconUrl,
  });

  final String id;
  final String title;
  final TrophyType type;
  final String description;
  final int order;
  final String guide;
  final bool missable;
  final bool hidden;
  final String? iconAsset;
  final String? iconUrl;

  bool get hasGuide => guide.isNotEmpty;
}
