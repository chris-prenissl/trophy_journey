enum TrophyType { bronze, silver, gold, platinum }

class const Trophy({
  required final String id,
  required final String title,
  required final TrophyType type,
  required final String description,
  required final int order,
  final String guide = '',
  final bool missable = false,
  final bool hidden = false,
  final String? iconAsset,
  final String? iconUrl,
}) {
  bool get hasGuide => guide.isNotEmpty;
}
