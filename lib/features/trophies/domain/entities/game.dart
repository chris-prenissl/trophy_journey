class const Game({
  required final String id,
  required final String title,
  required final int trophyCount,
  final int psnEarnedCount = 0,
  final String numeral = '',
  final String? coverAsset,
  final String? iconUrl,
  final String? npCommunicationId,
  final String? npServiceName,
  final String platform = '',
  final DateTime? lastUpdated,
  final String? guideSlug,
}) {
  bool get hasGuide => guideSlug != null;

  double completion(int achievedCount) =>
      trophyCount == 0 ? 0 : achievedCount / trophyCount;
}
