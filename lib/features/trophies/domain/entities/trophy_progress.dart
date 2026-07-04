class TrophyProgress {
  const TrophyProgress({
    required this.trophyId,
    required this.achieved,
    this.achievedAt,
  });

  final String trophyId;
  final bool achieved;
  final DateTime? achievedAt;
}
