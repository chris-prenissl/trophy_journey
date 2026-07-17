import 'dart:convert';

import 'package:final_fantasy_guide/features/journey/presentation/widgets/trophy_chip.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/game.dart';
import 'package:final_fantasy_guide/features/trophies/domain/entities/trophy.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_progress_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/repositories/trophy_repository.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_achieved_trophy_ids.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/get_trophies.dart';
import 'package:final_fantasy_guide/features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/viewmodels/trophy_list_view_model.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/game_tile.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/progress_circle.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_badges.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_filter_chips.dart';
import 'package:final_fantasy_guide/features/trophies/presentation/widgets/trophy_tile.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

final _pngBytes = base64Decode(
  'iVBORw0KGgoAAAANSUhEUgAAAAEAAAABCAQAAAC1HAwCAAAAC0lEQVR42mNk'
  '+M9QDwADhgGAWjR9awAAAABJRU5ErkJggg==',
);

class _ImageBundle extends CachingAssetBundle {
  final ByteData _emptyManifest =
      const StandardMessageCodec().encodeMessage(<String, Object>{})!;

  @override
  Future<ByteData> load(String key) async {
    if (key == 'AssetManifest.bin') return _emptyManifest;
    return ByteData.view(Uint8List.fromList(_pngBytes).buffer);
  }

  @override
  Future<String> loadString(String key, {bool cache = true}) async => '';
}

Widget _host(Widget child) => MaterialApp(
      home: DefaultAssetBundle(
        bundle: _ImageBundle(),
        child: Scaffold(body: child),
      ),
    );

Trophy _trophy({bool missable = false}) => Trophy(
      id: 'striker',
      title: 'Striker',
      type: TrophyType.bronze,
      description: 'Learn the Jecht Shot',
      guide: 'g',
      missable: missable,
      iconAsset: 'assets/icons/striker.jpg',
      order: 0,
    );

const _game = Game(
  id: 'ffx',
  title: 'Final Fantasy X',
  numeral: 'X',
  coverAsset: 'assets/covers/x.jpg',
  trophyCount: 4,
);

class _FakeTrophyRepo implements TrophyRepository {
  @override
  Future<List<Trophy>> getTrophies(String gameId) async => [_trophy(missable: true)];
}

class _FakeProgressRepo implements TrophyProgressRepository {
  final Map<String, Set<String>> achieved = {};
  @override
  Future<Set<String>> getAchievedIds(String g) async => {...?achieved[g]};
  @override
  Future<Map<String, Set<String>>> getAllAchievedIds() async => achieved;
  @override
  Future<void> setAchieved(String g, String t, bool v) async =>
      v ? (achieved[g] ??= {}).add(t) : (achieved[g] ??= {}).remove(t);
}

void main() {
  group('GameTile', () {
    testWidgets('shows progress text and reports taps', (tester) async {
      var taps = 0;
      await tester.pumpWidget(_host(GameTile(
        game: _game,
        achievedCount: 2,
        onTap: () => taps++,
      )));

      expect(find.text('Final Fantasy X'), findsOneWidget);
      expect(find.text('2 / 4 trophies'), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsOneWidget);

      await tester.tap(find.byType(InkWell));
      expect(taps, 1);
    });

    testWidgets('shows a trophy icon when complete', (tester) async {
      await tester.pumpWidget(_host(const GameTile(
        game: _game,
        achievedCount: 4,
        onTap: _noop,
      )));

      expect(find.byIcon(Icons.emoji_events), findsOneWidget);
      expect(find.byIcon(Icons.chevron_right), findsNothing);
    });

    testWidgets('falls back to a placeholder when there is no cover',
        (tester) async {
      await tester.pumpWidget(_host(const GameTile(
        game: Game(
          id: 'x',
          title: 'No Cover',
          numeral: 'X',
          coverAsset: '',
          trophyCount: 0,
        ),
        achievedCount: 0,
        onTap: _noop,
      )));

      expect(find.byIcon(Icons.videogame_asset), findsOneWidget);
    });
  });

  group('ProgressCircle', () {
    testWidgets('renders the ratio and percentage', (tester) async {
      await tester.pumpWidget(_host(const ProgressCircle(achieved: 1, total: 4)));
      await tester.pumpAndSettle();

      expect(find.text('1 / 4'), findsOneWidget);
      expect(find.text('25%'), findsOneWidget);
    });

    testWidgets('handles an empty trophy set without dividing by zero',
        (tester) async {
      await tester.pumpWidget(_host(const ProgressCircle(achieved: 0, total: 0)));
      await tester.pumpAndSettle();

      expect(find.text('0 / 0'), findsOneWidget);
      expect(find.text('0%'), findsOneWidget);
    });
  });

  group('TrophyTile', () {
    testWidgets('renders badges and toggles', (tester) async {
      var toggles = 0;
      var taps = 0;
      await tester.pumpWidget(_host(TrophyTile(
        trophy: _trophy(missable: true),
        achieved: false,
        onToggle: () => toggles++,
        onTap: () => taps++,
      )));

      expect(find.text('Striker'), findsOneWidget);
      expect(find.byType(TrophyTypeBadge), findsOneWidget);
      expect(find.byType(MissableBadge), findsOneWidget);

      await tester.tap(find.byType(Checkbox));
      expect(toggles, 1);
    });

    testWidgets('hides the missable badge for non-missable trophies',
        (tester) async {
      await tester.pumpWidget(_host(TrophyTile(
        trophy: _trophy(),
        achieved: true,
        onToggle: _noop,
        onTap: _noop,
      )));

      expect(find.byType(MissableBadge), findsNothing);
      expect(find.byType(TrophyTypeBadge), findsOneWidget);
    });
  });

  testWidgets('TrophyChip renders its trophy title', (tester) async {
    await tester.pumpWidget(_host(TrophyChip(trophy: _trophy())));
    expect(find.text('Striker'), findsOneWidget);
  });

  group('TrophyFilterChips', () {
    Future<TrophyListViewModel> buildVm(_FakeProgressRepo progress) async {
      final vm = TrophyListViewModel(
        'ffx',
        GetTrophies(_FakeTrophyRepo()),
        GetAchievedTrophyIds(progress),
        SetTrophyAchieved(progress),
      );
      await vm.load();
      return vm;
    }

    testWidgets('shows both chips and toggles the filters', (tester) async {
      final vm = await buildVm(_FakeProgressRepo());
      await tester.pumpWidget(_host(
        AnimatedBuilder(
          animation: vm,
          builder: (context, _) => TrophyFilterChips(viewModel: vm),
        ),
      ));

      expect(find.text('Missables'), findsOneWidget);
      expect(find.text('Hide achieved'), findsOneWidget);

      await tester.tap(find.text('Missables'));
      await tester.pump();
      expect(vm.missablesOnly, isTrue);

      await tester.tap(find.text('Hide achieved'));
      await tester.pump();
      expect(vm.hideAchieved, isTrue);
    });
  });
}

void _noop() {}
