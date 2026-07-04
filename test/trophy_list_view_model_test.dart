import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_achieved_trophy_ids.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:flutter_test/flutter_test.dart';

Trophy _trophy(String id, int order, {bool missable = false}) => Trophy(
      id: id,
      title: id,
      type: TrophyType.bronze,
      description: 'desc $id',
      guide: 'guide $id',
      missable: missable,
      iconAsset: 'assets/icons/ffx/$id.jpg',
      order: order,
    );

class _FakeTrophyRepository implements TrophyRepository {
  _FakeTrophyRepository(this.trophies);

  final List<Trophy> trophies;

  @override
  Future<List<Trophy>> getTrophies() async => trophies;
}

class _FakeProgressRepository implements TrophyProgressRepository {
  final Set<String> achieved = {};

  @override
  Future<Set<String>> getAchievedIds() async => {...achieved};

  @override
  Future<void> setAchieved(String trophyId, bool value) async {
    value ? achieved.add(trophyId) : achieved.remove(trophyId);
  }
}

void main() {
  final trophies = [
    _trophy('a', 0),
    _trophy('b', 1, missable: true),
    _trophy('c', 2),
  ];

  late _FakeProgressRepository progressRepository;
  late TrophyListViewModel viewModel;

  setUp(() async {
    progressRepository = _FakeProgressRepository();
    viewModel = TrophyListViewModel(
      GetTrophies(_FakeTrophyRepository(trophies)),
      GetAchievedTrophyIds(progressRepository),
      SetTrophyAchieved(progressRepository),
    );
    await viewModel.load();
  });

  test('loads all trophies in guide order', () {
    expect(viewModel.loading, isFalse);
    expect(viewModel.visibleTrophies.map((t) => t.id), ['a', 'b', 'c']);
    expect(viewModel.totalCount, 3);
    expect(viewModel.achievedCount, 0);
  });

  test('toggling a trophy moves it to the bottom and updates progress', () async {
    await viewModel.toggleAchieved('a');

    expect(viewModel.visibleTrophies.map((t) => t.id), ['b', 'c', 'a']);
    expect(viewModel.isAchieved('a'), isTrue);
    expect(viewModel.achievedCount, 1);
    expect(viewModel.progress, closeTo(1 / 3, 1e-9));
  });

  test('toggling twice restores original order', () async {
    await viewModel.toggleAchieved('a');
    await viewModel.toggleAchieved('a');

    expect(viewModel.visibleTrophies.map((t) => t.id), ['a', 'b', 'c']);
    expect(viewModel.achievedCount, 0);
  });

  test('missables-only filter shows only missable trophies', () {
    viewModel.setMissablesOnly(true);

    expect(viewModel.visibleTrophies.map((t) => t.id), ['b']);
  });

  test('hide-achieved filter removes achieved trophies', () async {
    await viewModel.toggleAchieved('b');
    viewModel.setHideAchieved(true);

    expect(viewModel.visibleTrophies.map((t) => t.id), ['a', 'c']);
  });

  test('persists achieved state through the repository', () async {
    await viewModel.toggleAchieved('c');

    expect(progressRepository.achieved, {'c'});

    final reloaded = TrophyListViewModel(
      GetTrophies(_FakeTrophyRepository(trophies)),
      GetAchievedTrophyIds(progressRepository),
      SetTrophyAchieved(progressRepository),
    );
    await reloaded.load();

    expect(reloaded.isAchieved('c'), isTrue);
    expect(reloaded.visibleTrophies.map((t) => t.id), ['a', 'b', 'c'].where((id) => id != 'c').followedBy(['c']));
  });
}
