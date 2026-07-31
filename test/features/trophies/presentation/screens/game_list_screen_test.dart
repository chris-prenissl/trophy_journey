import 'package:final_fantasy_guide/core/di/app_dependencies.dart';
import 'package:final_fantasy_guide/core/di/app_scope.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/has_journey_use_case.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/game_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_games_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/screens/game_list_screen.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/game_tile.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'game_list_screen_test.mocks.dart';

const ffx = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: '',
  trophyCount: 2,
);

const ffvii = Game(
  id: 'ffvii',
  title: 'Final Fantasy VII',
  numeral: 'VII',
  coverAsset: '',
  trophyCount: 1,
);

const sphereBreak = Trophy(
  id: 't1',
  title: 'Sphere Break',
  type: TrophyType.bronze,
  description: 'description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/final-fantasy-xvi/fistful-of-steel.png',
  order: 0,
);

const blitzball = Trophy(
  id: 't2',
  title: 'Blitzball',
  type: TrophyType.silver,
  description: 'description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/final-fantasy-xvi/every-damn-sinew.png',
  order: 1,
);

@GenerateNiceMocks([
  MockSpec<GameRepository>(),
  MockSpec<TrophyRepository>(),
  MockSpec<TrophyProgressRepository>(),
  MockSpec<JourneyRepository>(),
  MockSpec<JourneyViewModel>(),
])
void main() {
  late MockGameRepository gameRepository;
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late MockJourneyRepository journeyRepository;
  late TrophyProgressStore store;

  setUp(() {
    gameRepository = MockGameRepository();
    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();
    journeyRepository = MockJourneyRepository();

    when(gameRepository.getGames()).thenAnswer((_) async => [ffx, ffvii]);
    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [sphereBreak, blitzball]);
    when(progressRepository.getAllAchievedIds()).thenAnswer((_) async => {});
    when(progressRepository.setAchieved(any, any, any))
        .thenAnswer((_) => Future<void>.value());
    when(journeyRepository.hasJourney(any)).thenAnswer((_) async => false);

    store = TrophyProgressStore(
      GetAllAchievedTrophyIdsUseCase(progressRepository),
      SetTrophyAchievedUseCase(progressRepository),
    );
  });

  tearDown(() => store.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await store.load();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: () =>
              GameListViewModel(GetGamesUseCase(gameRepository), store),
          createTrophyListViewModel: (gameId) => TrophyListViewModel(
            gameId,
            GetTrophiesUseCase(trophyRepository),
            store,
          ),
          createJourneyViewModel: (_) => MockJourneyViewModel(),
        ),
        child: const MaterialApp(home: GameListScreen()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows a tile per game', (tester) async {
    await pumpApp(tester);

    expect(find.byType(GameTile), findsNWidgets(2));
    expect(find.text('Final Fantasy X'), findsOneWidget);
    expect(find.text('Final Fantasy VII'), findsOneWidget);
  });

  testWidgets('shows a spinner until the games arrive', (tester) async {
    await store.load();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: () =>
              GameListViewModel(GetGamesUseCase(gameRepository), store),
          createTrophyListViewModel: (gameId) => TrophyListViewModel(
            gameId,
            GetTrophiesUseCase(trophyRepository),
            store,
          ),
          createJourneyViewModel: (_) => MockJourneyViewModel(),
        ),
        child: const MaterialApp(home: GameListScreen()),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the overall trophy count', (tester) async {
    when(progressRepository.getAllAchievedIds()).thenAnswer(
      (_) async => {
        'ffx': {'t1'},
      },
    );

    await pumpApp(tester);

    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('reflects progress changed elsewhere without an explicit '
      'refresh', (tester) async {
    await pumpApp(tester);
    expect(find.text('0 / 3'), findsOneWidget);

    await store.setAchieved('ffx', 't1', true);
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('updates counts after toggling a trophy on the trophy list', (
    tester,
  ) async {
    await pumpApp(tester);
    expect(find.text('0 / 3'), findsOneWidget);

    await tester.tap(find.text('Final Fantasy X'));
    await tester.pumpAndSettle();
    expect(find.byType(TrophyTile), findsNWidgets(2));

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('1 / 2 trophies'), findsOneWidget);
  });
}
