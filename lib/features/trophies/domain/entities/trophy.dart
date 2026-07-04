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

  /// The official trophy description ("Find all 26 Al Bhed Primers").
  final String description;

  /// The full how-to-achieve text from the trophy guide.
  final String guide;
  final bool missable;
  final String iconAsset;

  /// Position in the guide's original trophy order.
  final int order;
}
