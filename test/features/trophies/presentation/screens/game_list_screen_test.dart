import 'package:trophy_journey/core/di/app_dependencies.dart';
import 'package:trophy_journey/core/di/app_scope.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:trophy_journey/features/journey/domain/repositories/journey_repository.dart';
import 'package:trophy_journey/features/journey/domain/usecases/has_journey_use_case.dart';
import 'package:trophy_journey/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/game_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_games_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_psn_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/screens/game_list_screen.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/game_tile.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_tile.dart';
import 'package:material_ui/material_ui.dart';
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
  MockSpec<AuthViewModel>(),
])
void main() {
  late MockAuthViewModel authViewModel;
  late MockGameRepository gameRepository;
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late MockJourneyRepository journeyRepository;
  late TrophyProgressStore store;

  setUp(() {
    authViewModel = MockAuthViewModel();

    gameRepository = MockGameRepository();
    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();
    journeyRepository = MockJourneyRepository();

    when(gameRepository.getGames()).thenAnswer((_) async => [ffx, ffvii]);
    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [sphereBreak, blitzball]);
    when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
        .thenAnswer((_) async => <String>{});
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});
    when(progressRepository.replaceEarned(any, any))
        .thenAnswer((_) => Future<void>.value());
    when(journeyRepository.hasJourney(any)).thenAnswer((_) async => false);

    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
    );
  });

  tearDown(() => store.dispose());

  Future<void> pumpApp(WidgetTester tester) async {
    await store.load();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          authViewModel: authViewModel,
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: () =>
              GameListViewModel(GetGamesUseCase(gameRepository), store),
          createTrophyListViewModel: (gameId) => TrophyListViewModel(
            gameId,
            GetTrophiesUseCase(trophyRepository),
            store,
            getPsnEarnedTrophyIds: GetPsnEarnedTrophyIdsUseCase(
              trophyRepository,
            ),
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
          authViewModel: authViewModel,
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: () =>
              GameListViewModel(GetGamesUseCase(gameRepository), store),
          createTrophyListViewModel: (gameId) => TrophyListViewModel(
            gameId,
            GetTrophiesUseCase(trophyRepository),
            store,
            getPsnEarnedTrophyIds: GetPsnEarnedTrophyIdsUseCase(
              trophyRepository,
            ),
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
    when(progressRepository.getAllEarnedIds()).thenAnswer(
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

    await store.applyEarned('ffx', {'t1'});
    await tester.pump();

    expect(find.text('1 / 3'), findsOneWidget);
  });

  testWidgets('signs out of PSN from the menu drawer', (tester) async {
    await pumpApp(tester);

    await tester.tap(find.byTooltip('Menu'));
    await tester.pumpAndSettle();

    await tester.tap(find.text('Sign out of PSN'));
    await tester.pumpAndSettle();

    verify(authViewModel.signOut()).called(1);
  });

  testWidgets('picks up PSN earned trophies after opening a game', (
    tester,
  ) async {
    // The count only becomes known once the trophy list syncs with PSN.
    when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
        .thenAnswer((_) async => {'t1'});
    await pumpApp(tester);
    expect(find.text('0 / 3'), findsOneWidget);

    await tester.tap(find.text('Final Fantasy X'));
    await tester.pumpAndSettle();
    expect(find.byType(TrophyTile), findsNWidgets(2));

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(find.text('1 / 2 trophies'), findsOneWidget);
  });
}
