import 'package:trophy_journey/core/di/app_dependencies.dart';
import 'package:trophy_journey/core/di/app_scope.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:trophy_journey/features/journey/domain/entities/journey.dart';
import 'package:trophy_journey/features/journey/domain/repositories/journey_progress_repository.dart';
import 'package:trophy_journey/features/journey/domain/repositories/journey_repository.dart';
import 'package:trophy_journey/features/journey/domain/usecases/get_checked_task_ids_use_case.dart';
import 'package:trophy_journey/features/journey/domain/usecases/get_journey_use_case.dart';
import 'package:trophy_journey/features/journey/domain/usecases/get_journey_bookmark_use_case.dart';
import 'package:trophy_journey/features/journey/domain/usecases/has_journey_use_case.dart';
import 'package:trophy_journey/features/journey/domain/usecases/set_journey_bookmark_use_case.dart';
import 'package:trophy_journey/features/journey/domain/usecases/set_task_checked_use_case.dart';
import 'package:trophy_journey/features/journey/presentation/screens/journey_screen.dart';
import 'package:trophy_journey/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:trophy_journey/features/journey/presentation/widgets/journey_step_card.dart';
import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'journey_screen_test.mocks.dart';

const ffx = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: '',
  trophyCount: 3,
);

@GenerateNiceMocks([
  MockSpec<JourneyRepository>(),
  MockSpec<JourneyProgressRepository>(),
  MockSpec<TrophyRepository>(),
  MockSpec<TrophyProgressRepository>(),
  MockSpec<GameListViewModel>(),
  MockSpec<TrophyListViewModel>(),
  MockSpec<AuthViewModel>(),
])
void main() {
  late MockAuthViewModel authViewModel;
  late MockJourneyRepository journeyRepository;
  late MockJourneyProgressRepository journeyProgressRepository;
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late TrophyProgressStore store;

  final journey = Journey(
    gameId: 'ffx',
    steps: const [
      JourneyStep(
        id: 's1',
        title: 'Zanarkand',
        instructions: 'Play the intro',
        tasks: [
          JourneyTask(id: 't1', title: 'Beat Sinspawn', trophyIds: []),
          JourneyTask(
            id: 't2',
            title: 'Grab the chest',
            trophyIds: [],
            flag: TaskFlag.missable,
          ),
        ],
      ),
      JourneyStep(
        id: 's2',
        title: 'Besaid',
        instructions: 'Do the trials',
        tasks: [JourneyTask(id: 't3', title: 'Cloister', trophyIds: [])],
      ),
    ],
  );

  setUp(() {
    authViewModel = MockAuthViewModel();

    journeyRepository = MockJourneyRepository();
    journeyProgressRepository = MockJourneyProgressRepository();
    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();

    when(journeyRepository.getJourney('ffx')).thenAnswer((_) async => journey);
    when(trophyRepository.getTrophies('ffx')).thenAnswer((_) async => []);
    when(journeyProgressRepository.getCheckedTaskIds('ffx'))
        .thenAnswer((_) async => <String>{});
    when(journeyProgressRepository.getBookmark('ffx'))
        .thenAnswer((_) async => null);
    when(journeyProgressRepository.setTaskChecked(any, any, any))
        .thenAnswer((_) => Future.value());
    when(journeyProgressRepository.setBookmark(any, any))
        .thenAnswer((_) => Future.value());
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});

    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
    );
  });

  tearDown(() => store.dispose());

  Widget buildApp() => AppScope(
    dependencies: AppDependencies(
      authViewModel: authViewModel,
      trophyProgressStore: store,
      hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
      createGameListViewModel: MockGameListViewModel.new,
      createTrophyListViewModel: (_) => MockTrophyListViewModel(),
      createJourneyViewModel: (gameId) => JourneyViewModel(
        gameId,
        GetJourneyUseCase(journeyRepository),
        GetTrophiesUseCase(trophyRepository),
        GetCheckedTaskIdsUseCase(journeyProgressRepository),
        SetTaskCheckedUseCase(journeyProgressRepository),
        GetJourneyBookmarkUseCase(journeyProgressRepository),
        SetJourneyBookmarkUseCase(journeyProgressRepository),
      ),
    ),
    child: const MaterialApp(home: JourneyScreen(game: ffx)),
  );

  testWidgets('shows a spinner until the journey arrives', (tester) async {
    await tester.pumpWidget(buildApp());

    expect(find.byType(CircularProgressIndicator), findsOneWidget);

    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('renders a card per step with the roadmap header', (
    tester,
  ) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(find.text('Journey — Final Fantasy X'), findsOneWidget);
    expect(find.text('Single-playthrough roadmap'), findsOneWidget);
    expect(find.byType(JourneyStepCard), findsNWidgets(2));
    expect(find.text('0 / 3 tasks done'), findsOneWidget);
  });

  testWidgets('checking a task updates the roadmap progress', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.text('Beat Sinspawn'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3 tasks done'), findsOneWidget);
    verify(journeyProgressRepository.setTaskChecked('ffx', 't1', true))
        .called(1);
  });

  testWidgets('bookmarking a step persists it', (tester) async {
    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    await tester.tap(find.byIcon(Icons.bookmark_border).first);
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    verify(journeyProgressRepository.setBookmark('ffx', 's1')).called(1);
  });

  testWidgets('does not scroll during build', (tester) async {
    when(journeyProgressRepository.getCheckedTaskIds('ffx'))
        .thenAnswer((_) async => {'t1', 't2'});

    await tester.pumpWidget(buildApp());
    await tester.pumpAndSettle();

    expect(tester.takeException(), isNull);
    expect(find.byType(JourneyStepCard), findsNWidgets(2));
  });
}
