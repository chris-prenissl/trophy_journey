import 'package:final_fantasy_guide/core/di/app_dependencies.dart';
import 'package:final_fantasy_guide/core/di/app_scope.dart';
import 'package:final_fantasy_guide/features/journey/domain/repositories/journey_repository.dart';
import 'package:final_fantasy_guide/features/journey/domain/usecases/has_journey_use_case.dart';
import 'package:final_fantasy_guide/features/journey/presentation/viewmodels/journey_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved_use_case.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'app_scope_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<TrophyProgressRepository>(),
  MockSpec<JourneyRepository>(),
  MockSpec<GameListViewModel>(),
  MockSpec<TrophyListViewModel>(),
  MockSpec<JourneyViewModel>(),
])
void main() {
  late MockTrophyProgressRepository progressRepository;
  late TrophyProgressStore store;
  late AppDependencies dependencies;

  setUp(() {
    progressRepository = MockTrophyProgressRepository();
    when(progressRepository.getAllAchievedIds()).thenAnswer((_) async => {});
    when(progressRepository.setAchieved(any, any, any))
        .thenAnswer((_) => Future.value());

    store = TrophyProgressStore(
      GetAllAchievedTrophyIdsUseCase(progressRepository),
      SetTrophyAchievedUseCase(progressRepository),
    );
    dependencies = AppDependencies(
      trophyProgressStore: store,
      hasJourneyUseCase: HasJourneyUseCase(MockJourneyRepository()),
      createGameListViewModel: MockGameListViewModel.new,
      createTrophyListViewModel: (_) => MockTrophyListViewModel(),
      createJourneyViewModel: (_) => MockJourneyViewModel(),
    );
  });

  tearDown(() => store.dispose());

  testWidgets('exposes the dependencies to descendants', (tester) async {
    late AppDependencies read;

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: Builder(
          builder: (context) {
            read = AppScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );

    expect(read, same(dependencies));
    expect(read.trophyProgressStore, same(store));
  });

  testWidgets('can be read from initState', (tester) async {
    AppDependencies? read;

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: _ReadsInInitState(onRead: (deps) => read = deps),
      ),
    );

    expect(read, same(dependencies));
  });

  testWidgets('reading dependencies does not subscribe to app state', (
    tester,
  ) async {
    var builds = 0;

    await tester.pumpWidget(
      AppScope(
        dependencies: dependencies,
        child: Builder(
          builder: (context) {
            builds++;
            AppScope.of(context);
            return const SizedBox();
          },
        ),
      ),
    );
    expect(builds, 1);

    await store.setAchieved('ffx', 't1', true);
    await tester.pump();

    expect(
      builds,
      1,
      reason: 'the DI scope must not rebuild readers when app state changes',
    );
  });

  testWidgets('asserts when no scope is above the context', (tester) async {
    await tester.pumpWidget(
      Builder(
        builder: (context) {
          AppScope.of(context);
          return const SizedBox();
        },
      ),
    );

    expect(tester.takeException(), isAssertionError);
  });
}

class _ReadsInInitState extends StatefulWidget {
  const _ReadsInInitState({required this.onRead});

  final void Function(AppDependencies) onRead;

  @override
  State<_ReadsInInitState> createState() => _ReadsInInitStateState();
}

class _ReadsInInitStateState extends State<_ReadsInInitState> {
  @override
  void initState() {
    super.initState();
    widget.onRead(AppScope.of(context));
  }

  @override
  Widget build(BuildContext context) => const SizedBox();
}
