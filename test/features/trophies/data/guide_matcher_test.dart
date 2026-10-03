import 'package:flutter_test/flutter_test.dart';
import 'package:trophy_journey/features/trophies/data/guide_matcher.dart';
import 'package:trophy_journey/features/trophies/data/models/game_model.dart';
import 'package:trophy_journey/features/trophies/data/models/psn_trophy_definition_model.dart';
import 'package:trophy_journey/features/trophies/data/models/psn_trophy_title_model.dart';
import 'package:trophy_journey/features/trophies/data/models/trophy_model.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';

GameModel game(String id, String title, {List<String> psnNames = const []}) =>
    GameModel(
      id: id,
      title: title,
      numeral: '',
      cover: 'assets/covers/$id.png',
      trophyCount: 1,
      psnNames: psnNames,
    );

PsnTrophyTitleModel psnTitle(String name) => PsnTrophyTitleModel(
  npCommunicationId: 'NPWR00001_00',
  trophyTitleName: name,
);

TrophyModel guide(String id, String title) => TrophyModel(
  id: id,
  title: title,
  type: TrophyType.bronze,
  description: '',
  guide: 'guide text',
  missable: false,
  icon: 'assets/icons/$id.png',
  order: 0,
);

PsnTrophyDefinitionModel definition(String name) =>
    PsnTrophyDefinitionModel(trophyId: 0, trophyName: name);

void main() {
  group('slugify', () {
    test('lowercases and joins on anything that is not alphanumeric', () {
      expect(slugify('Final Fantasy X HD'), 'final-fantasy-x-hd');
    });

    test('treats apostrophes as separators, matching the bundled ids', () {
      expect(slugify("A Hero's Journey"), 'a-hero-s-journey');
    });

    test('trims leading and trailing separators', () {
      expect(slugify('  What\'s Your Sign?  '), 'what-s-your-sign');
    });

    test('spells out the single glyph numerals PSN uses', () {
      // Stripping these would collapse every entry onto `final-fantasy`.
      expect(slugify('FINAL FANTASY Ⅱ'), 'final-fantasy-ii');
      expect(
        slugify('FINAL FANTASY Ⅻ THE ZODIAC AGE'),
        'final-fantasy-xii-the-zodiac-age',
      );
    });

    test('keeps the single glyph numerals apart from the first game', () {
      expect(slugify('FINAL FANTASY Ⅱ'), isNot(slugify('FINAL FANTASY')));
    });
  });

  group('guideForGame', () {
    test('matches on the bundled title', () {
      final matcher = GuideMatcher([
        game('final-fantasy-ix', 'Final Fantasy IX'),
      ]);

      expect(
        matcher.guideForGame(psnTitle('FINAL FANTASY IX'))?.id,
        'final-fantasy-ix',
      );
    });

    test('matches on a listed PSN alias', () {
      final matcher = GuideMatcher([
        game(
          'final-fantasy-x-hd',
          'Final Fantasy X HD',
          psnNames: ['FINAL FANTASY X HD Remaster'],
        ),
      ]);

      expect(
        matcher.guideForGame(psnTitle('FINAL FANTASY X HD Remaster'))?.id,
        'final-fantasy-x-hd',
      );
    });

    test('does not confuse a numbered entry with the first game', () {
      final matcher = GuideMatcher([
        game('final-fantasy-1-pixel-remaster', 'Final Fantasy'),
        game('final-fantasy-ii', 'Final Fantasy II'),
      ]);

      expect(
        matcher.guideForGame(psnTitle('FINAL FANTASY Ⅱ'))?.id,
        'final-fantasy-ii',
      );
      expect(
        matcher.guideForGame(psnTitle('FINAL FANTASY'))?.id,
        'final-fantasy-1-pixel-remaster',
      );
    });

    test('is null for a game the app ships no guide for', () {
      final matcher = GuideMatcher([
        game('final-fantasy-ix', 'Final Fantasy IX'),
      ]);

      expect(matcher.guideForGame(psnTitle('LEGO® Batman™')), isNull);
    });
  });

  group('guideForTrophy', () {
    test('matches a PSN trophy to the bundled guide of the same name', () {
      final guides = GuideMatcher.indexTrophies([
        guide('a-hero-s-journey', "A Hero's Journey"),
      ]);

      expect(
        GuideMatcher.guideForTrophy(guides, definition("A Hero's Journey"))?.id,
        'a-hero-s-journey',
      );
    });

    test('is null when the app ships no guide for the trophy', () {
      final guides = GuideMatcher.indexTrophies([
        guide('blitz-ace', 'Blitz Ace'),
      ]);

      expect(
        GuideMatcher.guideForTrophy(guides, definition('Unrelated')),
        isNull,
      );
    });
  });
}
