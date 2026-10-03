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
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

import 'app_scope_test.mocks.dart';

@GenerateNiceMocks([
  MockSpec<TrophyProgressRepository>(),
  MockSpec<JourneyRepository>(),
  MockSpec<GameListViewModel>(),
  MockSpec<TrophyListViewModel>(),
  MockSpec<JourneyViewModel>(),
  MockSpec<AuthViewModel>(),
])
void main() {
  late MockTrophyProgressRepository progressRepository;
  late TrophyProgressStore store;
  late AppDependencies dependencies;

  setUp(() {
    progressRepository = MockTrophyProgressRepository();
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});

    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
    );
    dependencies = AppDependencies(
      authViewModel: MockAuthViewModel(),
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

    await store.applyEarned('ffx', {'t1'});
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

  test('updateShouldNotify compares dependencies by identity', () {
    final other = AppDependencies(
      authViewModel: MockAuthViewModel(),
      trophyProgressStore: store,
      hasJourneyUseCase: HasJourneyUseCase(MockJourneyRepository()),
      createGameListViewModel: MockGameListViewModel.new,
      createTrophyListViewModel: (_) => MockTrophyListViewModel(),
      createJourneyViewModel: (_) => MockJourneyViewModel(),
    );

    final widget = AppScope(
      dependencies: dependencies,
      child: const SizedBox(),
    );

    expect(
      widget.updateShouldNotify(
        AppScope(dependencies: other, child: const SizedBox()),
      ),
      isTrue,
    );
    expect(
      widget.updateShouldNotify(
        AppScope(dependencies: dependencies, child: const SizedBox()),
      ),
      isFalse,
    );
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
