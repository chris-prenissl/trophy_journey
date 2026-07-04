import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'core/di/app_scope.dart';
import 'features/trophies/data/datasources/game_asset_data_source.dart';
import 'features/trophies/data/datasources/progress_local_data_source.dart';
import 'features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'features/trophies/data/repositories/game_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_progress_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_repository_impl.dart';
import 'features/trophies/domain/usecases/get_achieved_trophy_ids.dart';
import 'features/trophies/domain/usecases/get_all_achieved_trophy_ids.dart';
import 'features/trophies/domain/usecases/get_games.dart';
import 'features/trophies/domain/usecases/get_trophies.dart';
import 'features/trophies/domain/usecases/set_trophy_achieved.dart';
import 'features/trophies/presentation/screens/game_list_screen.dart';
import 'features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  // Composition root: data sources -> repositories -> use cases -> view models.
  final gameRepository = GameRepositoryImpl(GameAssetDataSource(rootBundle));
  final trophyRepository =
      TrophyRepositoryImpl(TrophyAssetDataSource(rootBundle));
  final progressRepository =
      TrophyProgressRepositoryImpl(ProgressLocalDataSource());

  final gameListViewModel = GameListViewModel(
    GetGames(gameRepository),
    GetAllAchievedTrophyIds(progressRepository),
  )..load();

  TrophyListViewModel trophyListViewModelFactory(String gameId) =>
      TrophyListViewModel(
        gameId,
        GetTrophies(trophyRepository),
        GetAchievedTrophyIds(progressRepository),
        SetTrophyAchieved(progressRepository),
      );

  runApp(
    TrophyGuideApp(
      gameListViewModel: gameListViewModel,
      trophyListViewModelFactory: trophyListViewModelFactory,
    ),
  );
}

class TrophyGuideApp extends StatelessWidget {
  const TrophyGuideApp({
    super.key,
    required this.gameListViewModel,
    required this.trophyListViewModelFactory,
  });

  final GameListViewModel gameListViewModel;
  final TrophyListViewModelFactory trophyListViewModelFactory;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      gameListViewModel: gameListViewModel,
      trophyListViewModelFactory: trophyListViewModelFactory,
      child: MaterialApp(
        title: 'FF Trophy Guide',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFF1B4B8A),
            brightness: Brightness.dark,
          ),
        ),
        home: const GameListScreen(),
      ),
    );
  }
}
