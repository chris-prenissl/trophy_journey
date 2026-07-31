import 'package:final_fantasy_guide/features/journey/domain/entities/journey.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_progress_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_checked_task_ids_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/get_journey_bookmark_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_journey_bookmark_use_case.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/set_task_checked_use_case.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/journey/presentation/widgets/journey_step_card.dart';
import 'package:final_fantasy_guide/features/journey/presentation/widgets/journey_task_row.dart';
import 'package:final_fantasy_guide/features/journey/presentation/widgets/trophy_chip.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'journey_step_card_test.mocks.dart';

const sinspawn = Trophy(
  id: 'tr1',
  title: 'Sinspawn Slayer',
  type: TrophyType.bronze,
  description: 'description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/tr1.png',
  order: 0,
);

@GenerateNiceMocks([
  MockSpec<JourneyRepository>(),
  MockSpec<JourneyProgressRepository>(),
  MockSpec<TrophyRepository>(),
])
void main() {
  late MockJourneyRepository journeyRepository;
  late MockJourneyProgressRepository progressRepository;
  late MockTrophyRepository trophyRepository;
  late JourneyViewModel viewModel;

  final journey = Journey(
    gameId: 'ffx',
    steps: const [
      JourneyStep(
        id: 's1',
        title: 'Zanarkand',
        instructions: 'Play the intro',
        tasks: [
          JourneyTask(
            id: 't1',
            title: 'Beat Sinspawn',
            note: 'Bring potions',
            trophyIds: ['tr1'],
          ),
          JourneyTask(
            id: 't2',
            title: 'Grab the chest',
            trophyIds: [],
            flag: TaskFlag.missable,
          ),
          JourneyTask(
            id: 't3',
            title: 'Talk to Auron',
            trophyIds: [],
            flag: TaskFlag.recommended,
          ),
        ],
      ),
    ],
  );

  setUp(() async {
    journeyRepository = MockJourneyRepository();
    progressRepository = MockJourneyProgressRepository();
    trophyRepository = MockTrophyRepository();

    when(journeyRepository.getJourney('ffx')).thenAnswer((_) async => journey);
    when(trophyRepository.getTrophies('ffx'))
        .thenAnswer((_) async => [sinspawn]);
    when(progressRepository.getCheckedTaskIds('ffx'))
        .thenAnswer((_) async => <String>{});
    when(progressRepository.getBookmark('ffx')).thenAnswer((_) async => null);
    when(progressRepository.setTaskChecked(any, any, any))
        .thenAnswer((_) => Future<void>.value());
    when(progressRepository.setBookmark(any, any))
        .thenAnswer((_) => Future<void>.value());

    viewModel = JourneyViewModel(
      'ffx',
      GetJourneyUseCase(journeyRepository),
      GetTrophiesUseCase(trophyRepository),
      GetCheckedTaskIdsUseCase(progressRepository),
      SetTaskCheckedUseCase(progressRepository),
      GetJourneyBookmarkUseCase(progressRepository),
      SetJourneyBookmarkUseCase(progressRepository),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> pumpCard(WidgetTester tester) async {
    await viewModel.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => SingleChildScrollView(
              child: JourneyStepCard(
                step: viewModel.steps.first,
                stepNumber: 1,
                viewModel: viewModel,
                initiallyExpanded: true,
              ),
            ),
          ),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('shows the step number, title and task count', (tester) async {
    await pumpCard(tester);

    expect(find.text('1'), findsOneWidget);
    expect(find.text('Zanarkand'), findsOneWidget);
    expect(find.text('0 / 3'), findsOneWidget);
    expect(find.text('Play the intro'), findsOneWidget);
  });

  testWidgets('renders a row per task with notes and trophy chips', (
    tester,
  ) async {
    await pumpCard(tester);

    expect(find.byType(JourneyTaskRow), findsNWidgets(3));
    expect(find.text('Bring potions'), findsOneWidget);
    expect(find.byType(TrophyChip), findsOneWidget);
    expect(find.text('Sinspawn Slayer'), findsOneWidget);
  });

  testWidgets('surfaces missable and recommended badges', (tester) async {
    await pumpCard(tester);

    expect(find.byType(MissableBadge), findsWidgets);
    expect(find.byType(RecommendedBadge), findsWidgets);
  });

  testWidgets('checking a task updates the count and shows a check mark', (
    tester,
  ) async {
    await pumpCard(tester);

    await tester.tap(find.text('Beat Sinspawn'));
    await tester.pumpAndSettle();

    expect(find.text('1 / 3'), findsOneWidget);
    expect(viewModel.isTaskChecked('t1'), isTrue);
  });

  testWidgets('shows a check icon once every task is done', (tester) async {
    when(progressRepository.getCheckedTaskIds('ffx'))
        .thenAnswer((_) async => {'t1', 't2', 't3'});

    await pumpCard(tester);

    expect(find.byIcon(Icons.check), findsOneWidget);
    expect(find.text('3 / 3'), findsOneWidget);
  });

  testWidgets('toggles the bookmark', (tester) async {
    await pumpCard(tester);

    expect(find.byIcon(Icons.bookmark_border), findsOneWidget);

    await tester.tap(find.byIcon(Icons.bookmark_border));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.bookmark), findsOneWidget);
    expect(viewModel.isBookmarked('s1'), isTrue);
  });
}
