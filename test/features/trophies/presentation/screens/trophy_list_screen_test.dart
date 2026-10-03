import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/core/di/app_dependencies.dart';
import 'package:trophy_journey/core/di/app_scope.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:trophy_journey/features/journey/domain/repositories/journey_repository.dart';
import 'package:trophy_journey/features/journey/domain/usecases/has_journey_use_case.dart';
import 'package:trophy_journey/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_psn_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/screens/trophy_detail_screen.dart';
import 'package:trophy_journey/features/trophies/presentation/screens/trophy_list_screen.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/progress_circle.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_tile.dart';

import 'trophy_list_screen_test.mocks.dart';

const ffx = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: '',
  trophyCount: 3,
);

const ordinary = Trophy(
  id: 't1',
  title: 'Ordinary',
  type: TrophyType.bronze,
  description: 'description',
  guide: 'guide text',
  iconAsset: 'assets/icons/final-fantasy-xvi/fistful-of-steel.png',
  order: 0,
);

const missable = Trophy(
  id: 't2',
  title: 'Missable',
  type: TrophyType.silver,
  description: 'description',
  guide: 'guide text',
  missable: true,
  iconAsset: 'assets/icons/final-fantasy-xvi/every-damn-sinew.png',
  order: 1,
);

const another = Trophy(
  id: 't3',
  title: 'Another',
  type: TrophyType.gold,
  description: 'description',
  guide: 'guide text',
  iconAsset: 'assets/icons/final-fantasy-xvi/fistful-of-steel.png',
  order: 2,
);

@GenerateNiceMocks([
  MockSpec<TrophyRepository>(),
  MockSpec<TrophyProgressRepository>(),
  MockSpec<JourneyRepository>(),
  MockSpec<GameListViewModel>(),
  MockSpec<JourneyViewModel>(),
  MockSpec<AuthViewModel>(),
])
void main() {
  late MockAuthViewModel authViewModel;
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late MockJourneyRepository journeyRepository;
  late TrophyProgressStore store;

  setUp(() {
    authViewModel = MockAuthViewModel();

    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();
    journeyRepository = MockJourneyRepository();

    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [ordinary, missable, another]);
    when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
        .thenAnswer((_) async => <String>{});
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});
    when(progressRepository.replaceEarned(any, any))
        .thenAnswer((_) => Future.value());
    when(journeyRepository.hasJourney('ffx')).thenAnswer((_) async => false);

    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
    );
  });

  tearDown(() => store.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await store.load();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          authViewModel: authViewModel,
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: MockGameListViewModel.new,
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
        child: const MaterialApp(home: TrophyListScreen(game: ffx)),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('builds its view model for the game it was given', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.text('Final Fantasy X'), findsOneWidget);
    expect(find.byType(TrophyTile), findsNWidgets(3));
    verify(trophyRepository.getTrophies('ffx')).called(1);
  });

  testWidgets('shows a spinner while trophies load', (tester) async {
    await store.load();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          authViewModel: authViewModel,
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: MockGameListViewModel.new,
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
        child: const MaterialApp(home: TrophyListScreen(game: ffx)),
      ),
    );

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(find.byType(TrophyTile), findsNothing);

    await tester.pumpAndSettle();

    expect(find.byType(TrophyTile), findsNWidgets(3));
    expect(find.byType(ProgressCircle), findsOneWidget);
  });

  testWidgets('filters to missables', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Missables'));
    await tester.pumpAndSettle();

    expect(find.byType(TrophyTile), findsOneWidget);
    expect(find.text('Missable'), findsWidgets);
  });

  testWidgets('hides trophies earned on PSN when asked', (tester) async {
    when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
        .thenAnswer((_) async => {'t1'});
    await pumpScreen(tester);

    await tester.tap(find.text('Hide achieved'));
    await tester.pumpAndSettle();

    expect(find.byType(TrophyTile), findsNWidgets(2));
    expect(find.text('Ordinary'), findsNothing);
    expect(find.text('Missable'), findsOneWidget);
    expect(find.text('Another'), findsOneWidget);
  });

  testWidgets('shows an empty message when filters match nothing', (
    tester,
  ) async {
    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [missable]);
    when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
        .thenAnswer((_) async => {'t2'});
    await pumpScreen(tester);

    await tester.tap(find.text('Hide achieved'));
    await tester.pumpAndSettle();

    expect(find.text('No trophies match filters'), findsOneWidget);
  });

  testWidgets('reflects PSN earned trophies without offering a tick', (
    tester,
  ) async {
    when(trophyRepository.getPsnEarnedTrophyIds('ffx'))
        .thenAnswer((_) async => {'t1'});
    await pumpScreen(tester);

    expect(find.byType(Checkbox), findsNothing);
    // One earned, two still to go.
    expect(find.byIcon(Icons.check_circle), findsOneWidget);
    expect(find.byIcon(Icons.circle_outlined), findsNWidgets(2));
  });

  testWidgets('hides the journey button when the game has no journey', (
    tester,
  ) async {
    await pumpScreen(tester);

    expect(find.widgetWithText(FloatingActionButton, 'Journey'), findsNothing);
  });

  testWidgets('shows the journey button when the game has a journey', (
    tester,
  ) async {
    when(journeyRepository.hasJourney('ffx')).thenAnswer((_) async => true);

    await pumpScreen(tester);

    expect(
      find.widgetWithText(FloatingActionButton, 'Journey'),
      findsOneWidget,
    );
  });

  testWidgets('opens the detail screen with the trophy guide', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Ordinary'));
    await tester.pumpAndSettle();

    expect(find.byType(TrophyDetailScreen), findsOneWidget);
    expect(find.text('guide text'), findsOneWidget);
    // The detail screen only reflects PSN state, it never offers a toggle.
    expect(find.byType(Switch), findsNothing);
  });
}
