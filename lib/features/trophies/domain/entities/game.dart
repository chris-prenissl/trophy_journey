class Game {
  const Game({
    required this.id,
    required this.title,
    required this.trophyCount,
    this.psnEarnedCount = 0,
    this.numeral = '',
    this.coverAsset,
    this.iconUrl,
    this.npCommunicationId,
    this.npServiceName,
    this.platform = '',
    this.lastUpdated,
    this.guideSlug,
  });

  final String id;
  final String title;
  final int trophyCount;
  final int psnEarnedCount;
  final String numeral;
  final String? coverAsset;
  final String? iconUrl;
  final String? npCommunicationId;
  final String? npServiceName;
  final String platform;
  final DateTime? lastUpdated;
  final String? guideSlug;

  bool get hasGuide => guideSlug != null;
}
