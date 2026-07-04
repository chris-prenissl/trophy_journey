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

  /// Mainline numeral ("I".."XVI"), used for ordering and display.
  final String numeral;

  /// Empty when the source page had no cover image.
  final String coverAsset;
  final int trophyCount;
}
