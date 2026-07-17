import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'core/di/app_scope.dart';
import 'features/journey/data/datasources/journey_asset_data_source.dart';
import 'features/journey/data/datasources/journey_local_data_source.dart';
import 'features/journey/data/repositories/journey_progress_repository_impl.dart';
import 'features/journey/data/repositories/journey_repository_impl.dart';
import 'features/journey/domain/usecases/get_checked_task_ids.dart';
import 'features/journey/domain/usecases/get_journey.dart';
import 'features/journey/domain/usecases/get_journey_bookmark.dart';
import 'features/journey/domain/usecases/has_journey.dart';
import 'features/journey/domain/usecases/set_journey_bookmark.dart';
import 'features/journey/domain/usecases/set_task_checked.dart';
import 'features/journey/presentation/viewmodels/journey_view_model.dart';
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

  final gameRepository = GameRepositoryImpl(GameAssetDataSource(rootBundle));
  final trophyRepository =
      TrophyRepositoryImpl(TrophyAssetDataSource(rootBundle));
  final trophyProgressRepository =
      TrophyProgressRepositoryImpl(ProgressLocalDataSource());
  final journeyRepository =
      JourneyRepositoryImpl(JourneyAssetDataSource(rootBundle));
  final journeyProgressRepository =
      JourneyProgressRepositoryImpl(JourneyLocalDataSource());

  final gameListViewModel = GameListViewModel(
    GetGames(gameRepository),
    GetAllAchievedTrophyIds(trophyProgressRepository),
  )..load();

  TrophyListViewModel trophyListViewModelFactory(String gameId) =>
      TrophyListViewModel(
        gameId,
        GetTrophies(trophyRepository),
        GetAchievedTrophyIds(trophyProgressRepository),
        SetTrophyAchieved(trophyProgressRepository),
      );

  JourneyViewModel journeyViewModelFactory(String gameId) => JourneyViewModel(
        gameId,
        GetJourney(journeyRepository),
        GetTrophies(trophyRepository),
        GetCheckedTaskIds(journeyProgressRepository),
        SetTaskChecked(journeyProgressRepository),
        GetJourneyBookmark(journeyProgressRepository),
        SetJourneyBookmark(journeyProgressRepository),
      );

  runApp(
    TrophyGuideApp(
      gameListViewModel: gameListViewModel,
      trophyListViewModelFactory: trophyListViewModelFactory,
      journeyViewModelFactory: journeyViewModelFactory,
      hasJourney: HasJourney(journeyRepository),
    ),
  );
}

class TrophyGuideApp extends StatelessWidget {
  const TrophyGuideApp({
    super.key,
    required this.gameListViewModel,
    required this.trophyListViewModelFactory,
    required this.journeyViewModelFactory,
    required this.hasJourney,
  });

  final GameListViewModel gameListViewModel;
  final TrophyListViewModelFactory trophyListViewModelFactory;
  final JourneyViewModelFactory journeyViewModelFactory;
  final HasJourney hasJourney;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      gameListViewModel: gameListViewModel,
      trophyListViewModelFactory: trophyListViewModelFactory,
      journeyViewModelFactory: journeyViewModelFactory,
      hasJourney: hasJourney,
      child: MaterialApp(
        title: 'Final Fantasy Guide',
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
