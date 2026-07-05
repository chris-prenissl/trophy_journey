class Game {
  const Game({
    required this.id,
    required this.title,
    required this.numeral,
    required this.coverAsset,
    required this.trophyCount,
  });

  final String id;
  final String title;
  final String numeral;
  final String coverAsset;
  final int trophyCount;
}
