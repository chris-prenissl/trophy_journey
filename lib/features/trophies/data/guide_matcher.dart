import 'models/game_model.dart';
import 'models/psn_trophy_definition_model.dart';
import 'models/psn_trophy_title_model.dart';
import 'models/trophy_model.dart';

const _romanNumerals = {
  'Ⅰ': 'I',
  'Ⅱ': 'II',
  'Ⅲ': 'III',
  'Ⅳ': 'IV',
  'Ⅴ': 'V',
  'Ⅵ': 'VI',
  'Ⅶ': 'VII',
  'Ⅷ': 'VIII',
  'Ⅸ': 'IX',
  'Ⅹ': 'X',
  'Ⅺ': 'XI',
  'Ⅻ': 'XII',
  'ⅰ': 'i',
  'ⅱ': 'ii',
  'ⅲ': 'iii',
  'ⅳ': 'iv',
  'ⅴ': 'v',
  'ⅵ': 'vi',
  'ⅶ': 'vii',
  'ⅷ': 'viii',
  'ⅸ': 'ix',
  'ⅹ': 'x',
  'ⅺ': 'xi',
  'ⅻ': 'xii',
};

String slugify(String value) {
  final expanded = value.splitMapJoin(
    RegExp('[Ⅰ-Ⅻⅰ-ⅻ]'),
    onMatch: (match) => _romanNumerals[match[0]] ?? match[0]!,
  );
  return expanded
      .toLowerCase()
      .replaceAll(RegExp('[^a-z0-9]+'), '-')
      .replaceAll(RegExp(r'^-+|-+$'), '');
}

class GuideMatcher(List<GameModel> games) {
  this
    : _gamesByName = {
        for (final game in games) ...{
          slugify(game.title): game,
          for (final alias in game.psnNames) slugify(alias): game,
        },
      };

  final Map<String, GameModel> _gamesByName;

  GameModel? guideForGame(PsnTrophyTitleModel title) =>
      _gamesByName[slugify(title.trophyTitleName)];

  static Map<String, TrophyModel> indexTrophies(List<TrophyModel> guides) => {
    for (final guide in guides) guide.id: guide,
  };

  static TrophyModel? guideForTrophy(
    Map<String, TrophyModel> guidesBySlug,
    PsnTrophyDefinitionModel definition,
  ) => guidesBySlug[slugify(definition.trophyName)];
}
