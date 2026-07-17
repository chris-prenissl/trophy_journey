import 'dart:convert';

import 'package:final_fantasy_guide/core/di/app_scope.dart';
import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_progress_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_checked_task_ids.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_bookmark.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/has_journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_journey_bookmark.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_task_checked.dart';
import 'package:final_fantasy_guide/features/journey/presentation/screens/journey_screen.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/game_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_achieved_trophy_ids.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_games.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/screens/game_list_screen.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/screens/trophy_detail_screen.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/screens/trophy_list_screen.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

const _game = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: 'assets/covers/x.jpg',
  trophyCount: 2,
);

Trophy _trophy(String id, int order, {bool missable = false}) => Trophy(
      id: id,
      title: id,
      type: TrophyType.bronze,
      description: 'desc $id',
      guide: 'guide $id',
      missable: missable,
      iconAsset: 'assets/icons/$id.jpg',
      order: order,
    );

final _journey = Journey(gameId: 'ffx', steps: [
  JourneyStep(
    id: 's1',
    title: 'Step one',
    instructions: 'do a',
    tasks: const [JourneyTask(id: 't1', title: 'a', trophyIds: ['striker'])],
  ),
  JourneyStep(
    id: 's2',
    title: 'Step two',
    instructions: 'do b',
    tasks: const [JourneyTask(id: 't2', title: 'b', trophyIds: ['striker'])],
  ),
]);

class _FakeGameRepo implements GameRepository {
  @override
  Future<List<Game>> getGames() async => [_game];
}

class _FakeTrophyRepo implements TrophyRepository {
  @override
  Future<List<Trophy>> getTrophies(String gameId) async =>
      [_trophy('striker', 0), _trophy('anima', 1, missable: true)];
}

class _FakeTrophyProgressRepo implements TrophyProgressRepository {
  final Map<String, Set<String>> achieved;
  _FakeTrophyProgressRepo([this.achieved = const {}]);
  @override
  Future<Set<String>> getAchievedIds(String g) async => {...?achieved[g]};
  @override
  Future<Map<String, Set<String>>> getAllAchievedIds() async => achieved;
  @override
  Future<void> setAchieved(String g, String t, bool v) async {}
}

class _FakeJourneyRepo implements JourneyRepository {
  @override
  Future<Journey> getJourney(String gameId) async => _journey;
  @override
  Future<bool> hasJourney(String gameId) async => true;
}

class _FakeJourneyProgressRepo implements JourneyProgressRepository {
  final String? bookmark;
  _FakeJourneyProgressRepo([this.bookmark]);
  @override
  Future<Set<String>> getCheckedTaskIds(String g) async => {};
  @override
  Future<void> setTaskChecked(String g, String t, bool v) async {}
  @override
  Future<String?> getBookmark(String g) async => bookmark;
  @override
  Future<void> setBookmark(String g, String? s) async {}
}

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _ImageBundle extends CachingAssetBundle {
  final ByteData _emptyManifest =
      const StandardMessageCodec().encodeMessage(<String, Object>{})!;
  @override
  Future<ByteData> load(String key) async => key == 'AssetManifest.bin'
      ? _emptyManifest
      : ByteData.view(Uint8List.fromList(_pngBytes).buffer);
  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';
}

Widget _app({
  required Widget home,
  required GameListViewModel gameVm,
  _FakeTrophyProgressRepo? trophyProgress,
  String? journeyBookmark,
}) {
  final trophyRepo = _FakeTrophyRepo();
  final progress = trophyProgress ?? _FakeTrophyProgressRepo();
  final journeyRepo = _FakeJourneyRepo();
  final journeyProgress = _FakeJourneyProgressRepo(journeyBookmark);

  return AppScope(
    gameListViewModel: gameVm,
    trophyListViewModelFactory: (id) => TrophyListViewModel(
      id,
      GetTrophies(trophyRepo),
      GetAchievedTrophyIds(progress),
      SetTrophyAchieved(progress),
    ),
    journeyViewModelFactory: (id) => JourneyViewModel(
      id,
      GetJourney(journeyRepo),
      GetTrophies(trophyRepo),
      GetCheckedTaskIds(journeyProgress),
      SetTaskChecked(journeyProgress),
      GetJourneyBookmark(journeyProgress),
      SetJourneyBookmark(journeyProgress),
    ),
    hasJourney: HasJourney(journeyRepo),
    child: DefaultAssetBundle(
      bundle: _ImageBundle(),
      child: MaterialApp(home: home),
    ),
  );
}

Future<GameListViewModel> _loadedGameVm() async {
  final vm = GameListViewModel(
    GetGames(_FakeGameRepo()),
    GetAllAchievedTrophyIds(_FakeTrophyProgressRepo(const {
      'ffx': {'striker'},
    })),
  );
  await vm.load();
  return vm;
}

void main() {
  testWidgets('GameListScreen lists games with an aggregate count',
      (tester) async {
    final gameVm = await _loadedGameVm();
    await tester.pumpWidget(_app(home: const GameListScreen(), gameVm: gameVm));
    await tester.pumpAndSettle();

    expect(find.text('Final Fantasy X'), findsOneWidget);
    expect(find.text('1 / 2'), findsOneWidget);
  });

  testWidgets('GameListScreen shows a spinner while loading', (tester) async {
    final gameVm = GameListViewModel(
      GetGames(_FakeGameRepo()),
      GetAllAchievedTrophyIds(_FakeTrophyProgressRepo()),
    );
    await tester.pumpWidget(_app(home: const GameListScreen(), gameVm: gameVm));

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('TrophyListScreen renders trophies, filters and a Journey FAB',
      (tester) async {
    final gameVm = await _loadedGameVm();
    await tester.pumpWidget(
        _app(home: const TrophyListScreen(game: _game), gameVm: gameVm));
    await tester.pumpAndSettle();

    expect(find.text('Final Fantasy X'), findsOneWidget);
    expect(find.text('striker'), findsOneWidget);
    expect(find.text('Missables'), findsOneWidget);
    expect(find.widgetWithText(FloatingActionButton, 'Journey'), findsOneWidget);
  });

  testWidgets('TrophyDetailScreen shows the guide and toggles achieved',
      (tester) async {
    final vm = TrophyListViewModel(
      'ffx',
      GetTrophies(_FakeTrophyRepo()),
      GetAchievedTrophyIds(_FakeTrophyProgressRepo()),
      SetTrophyAchieved(_FakeTrophyProgressRepo()),
    );
    await vm.load();
    final trophy = _trophy('anima', 1, missable: true);

    await tester.pumpWidget(MaterialApp(
      home: DefaultAssetBundle(
        bundle: _ImageBundle(),
        child: TrophyDetailScreen(trophy: trophy, viewModel: vm),
      ),
    ));
    await tester.pumpAndSettle();

    expect(find.text('How to achieve'), findsOneWidget);
    expect(find.text('guide anima'), findsOneWidget);

    await tester.tap(find.byType(SwitchListTile));
    await tester.pump();
    expect(vm.isAchieved('anima'), isTrue);
  });

  testWidgets('JourneyScreen renders the roadmap and step cards',
      (tester) async {
    final gameVm = await _loadedGameVm();
    await tester.pumpWidget(_app(
      home: const JourneyScreen(game: _game),
      gameVm: gameVm,
      journeyBookmark: 's2',
    ));
    await tester.pumpAndSettle();

    expect(find.textContaining('Journey'), findsWidgets);
    expect(find.text('Single-playthrough roadmap'), findsOneWidget);
    expect(find.text('Step one'), findsOneWidget);
    expect(find.text('Step two'), findsOneWidget);
  });
}
