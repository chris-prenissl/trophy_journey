import 'package:trophy_journey/features/trophies/domain/entities/trophy.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:trophy_journey/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
import 'package:trophy_journey/features/trophies/presentation/state/trophy_progress_store.dart';
import 'package:trophy_journey/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:trophy_journey/features/trophies/presentation/widgets/trophy_filter_chips.dart';
import 'package:material_ui/material_ui.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'trophy_filter_chips_test.mocks.dart';

const ordinary = Trophy(
  id: 't1',
  title: 'Ordinary',
  type: TrophyType.bronze,
  description: 'description',
  guide: 'guide',
  missable: false,
  iconAsset: 'assets/icons/t1.png',
  order: 0,
);

const missable = Trophy(
  id: 't2',
  title: 'Missable',
  type: TrophyType.silver,
  description: 'description',
  guide: 'guide',
  missable: true,
  iconAsset: 'assets/icons/t2.png',
  order: 1,
);

@GenerateNiceMocks([
  MockSpec<TrophyRepository>(),
  MockSpec<TrophyProgressRepository>(),
])
void main() {
  late MockTrophyRepository trophyRepository;
  late MockTrophyProgressRepository progressRepository;
  late TrophyProgressStore store;
  late TrophyListViewModel viewModel;

  setUp(() {
    trophyRepository = MockTrophyRepository();
    progressRepository = MockTrophyProgressRepository();
    when(progressRepository.getAllEarnedIds()).thenAnswer((_) async => {});
    store = TrophyProgressStore(
      GetAllEarnedTrophyIdsUseCase(progressRepository),
      ReplaceEarnedTrophiesUseCase(progressRepository),
    );
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  Future<void> pumpChips(WidgetTester tester, List<Trophy> trophies) async {
    when(trophyRepository.getTrophies('ffx')).thenAnswer((_) async => trophies);
    viewModel = TrophyListViewModel(
      'ffx',
      GetTrophiesUseCase(trophyRepository),
      store,
    );
    await viewModel.load();
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: ListenableBuilder(
            listenable: viewModel,
            builder: (context, _) => TrophyFilterChips(viewModel: viewModel),
          ),
        ),
      ),
    );
  }

  testWidgets('offers the missables filter only when there are missables', (
    tester,
  ) async {
    await pumpChips(tester, [ordinary]);

    expect(find.text('Missables'), findsNothing);
    expect(find.text('Hide achieved'), findsOneWidget);
  });

  testWidgets('shows both filters when the game has missables', (tester) async {
    await pumpChips(tester, [ordinary, missable]);

    expect(find.text('Missables'), findsOneWidget);
    expect(find.text('Hide achieved'), findsOneWidget);
  });

  testWidgets('selects the missables filter on tap', (tester) async {
    await pumpChips(tester, [ordinary, missable]);

    await tester.tap(find.text('Missables'));
    await tester.pumpAndSettle();

    expect(viewModel.missablesOnly, isTrue);
    final chip = tester.widget<FilterChip>(
      find.widgetWithText(FilterChip, 'Missables'),
    );
    expect(chip.selected, isTrue);
  });

  testWidgets('selects the hide achieved filter on tap', (tester) async {
    await pumpChips(tester, [ordinary, missable]);

    await tester.tap(find.text('Hide achieved'));
    await tester.pumpAndSettle();

    expect(viewModel.hideAchieved, isTrue);
  });
}
