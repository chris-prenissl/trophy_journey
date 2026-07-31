import 'package:final_fantasy_guide/core/di/app_dependencies.dart';
import 'package:final_fantasy_guide/core/di/app_scope.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/has_journey_use_case.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/screens/trophy_detail_screen.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/screens/trophy_list_screen.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/progress_circle.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

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
  missable: false,
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
  missable: false,
  iconAsset: 'assets/icons/final-fantasy-xvi/fistful-of-steel.png',
  order: 2,
);

@GenerateNiceMocks([
  MockSpec<TrophyRepository>(),
  MockSpec<TrophyProgressRepository>(),
  MockSpec<JourneyRepository>(),
  MockSpec<GameListViewModel>(),
  MockSpec<JourneyViewModel>(),
])
void main() {
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late MockJourneyRepository journeyRepository;
  late TrophyProgressStore store;

  setUp(() {
    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();
    journeyRepository = MockJourneyRepository();

    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [ordinary, missable, another]);
    when(progressRepository.getAllAchievedIds()).thenAnswer((_) async => {});
    when(progressRepository.setAchieved(any, any, any))
        .thenAnswer((_) => Future.value());
    when(journeyRepository.hasJourney('ffx')).thenAnswer((_) async => false);

    store = TrophyProgressStore(
      GetAllAchievedTrophyIdsUseCase(progressRepository),
      SetTrophyAchievedUseCase(progressRepository),
    );
  });

  tearDown(() => store.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await store.load();
    await tester.pumpWidget(
      AppScope(
        dependencies: AppDependencies(
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: MockGameListViewModel.new,
          createTrophyListViewModel: (gameId) => TrophyListViewModel(
            gameId,
            GetTrophiesUseCase(trophyRepository),
            store,
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
          trophyProgressStore: store,
          hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
          createGameListViewModel: MockGameListViewModel.new,
          createTrophyListViewModel: (gameId) => TrophyListViewModel(
            gameId,
            GetTrophiesUseCase(trophyRepository),
            store,
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

  testWidgets('hides achieved trophies', (tester) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
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
    await pumpScreen(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Hide achieved'));
    await tester.pumpAndSettle();

    expect(find.text('No trophies match filters'), findsOneWidget);
  });

  testWidgets('toggling a trophy writes through the shared store', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.byType(Checkbox).first);
    await tester.pumpAndSettle();

    expect(store.isAchieved('ffx', 't1'), isTrue);
    verify(progressRepository.setAchieved('ffx', 't1', true)).called(1);
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

  testWidgets('opens the detail screen and stays in sync with it', (
    tester,
  ) async {
    await pumpScreen(tester);

    await tester.tap(find.text('Ordinary'));
    await tester.pumpAndSettle();
    expect(find.byType(TrophyDetailScreen), findsOneWidget);
    expect(find.text('guide text'), findsOneWidget);

    await tester.tap(find.byType(Switch));
    await tester.pumpAndSettle();

    await tester.pageBack();
    await tester.pumpAndSettle();

    expect(store.isAchieved('ffx', 't1'), isTrue);
    final checkbox = tester.widget<Checkbox>(
      find.descendant(
        of: find.widgetWithText(TrophyTile, 'Ordinary'),
        matching: find.byType(Checkbox),
      ),
    );
    expect(checkbox.value, isTrue);
  });
}
