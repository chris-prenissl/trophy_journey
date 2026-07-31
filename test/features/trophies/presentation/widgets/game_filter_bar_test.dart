import 'package:trophy_journey/features/trophies/domain/entities/game.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_games_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/game_filter_bar.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import '../viewmodels/game_list_view_model_test.mocks.dart';

const alpha = Game(
  id: 'alpha',
  title: 'Alpha',
  trophyCount: 4,
  platform: 'PS4',
  guideSlug: 'alpha',
);
const beta = Game(id: 'beta', title: 'Beta', trophyCount: 2, platform: 'PS5');

void main() {
  late TrophyProgressStore store;
  late GameListViewModel viewModel;

  setUp(() async {
    final gameRepository = MockGameRepository();
    final progressRepository = MockTrophyProgressRepository();
    when(gameRepository.getGames()).thenAnswer((_) async => [alpha, beta]);
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});

    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
    );
    await store.load();
    viewModel = GameListViewModel(GetGamesUseCase(gameRepository), store);
    await viewModel.load();
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  Future<void> pumpBar(WidgetTester tester) => tester.pumpWidget(
    MaterialApp(
      home: Scaffold(
        body: ListenableBuilder(
          listenable: viewModel,
          builder: (_, _) => GameFilterBar(viewModel: viewModel),
        ),
      ),
    ),
  );

  testWidgets('typing in the search bar updates the query', (tester) async {
    await pumpBar(tester);

    await tester.enterText(find.byType(SearchBar), 'beta');

    expect(viewModel.query, 'beta');
    expect(viewModel.visibleGames, [beta]);
  });

  testWidgets('selecting a status segment filters by status', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.text('New'));
    await tester.pump();

    expect(viewModel.statusFilter, GameStatusFilter.notStarted);
    expect(viewModel.visibleGames, [alpha, beta]);

    await tester.tap(find.text('Done'));
    await tester.pump();

    expect(viewModel.statusFilter, GameStatusFilter.completed);
    expect(viewModel.visibleGames, isEmpty);
  });

  testWidgets('platform chips toggle the platform filter', (tester) async {
    await pumpBar(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'PS5'));
    await tester.pump();

    expect(viewModel.selectedPlatforms, {'PS5'});
    expect(viewModel.visibleGames, [beta]);

    await tester.tap(find.widgetWithText(FilterChip, 'PS5'));
    await tester.pump();

    expect(viewModel.selectedPlatforms, isEmpty);
  });

  testWidgets('guide chip narrows the list to games with a guide', (
    tester,
  ) async {
    await pumpBar(tester);

    await tester.tap(find.widgetWithText(FilterChip, 'Has guide'));
    await tester.pump();

    expect(viewModel.guideOnly, isTrue);
    expect(viewModel.visibleGames, [alpha]);
  });
}
