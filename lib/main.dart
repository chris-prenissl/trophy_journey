import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';
import 'features/journey/data/datasources/journey_asset_data_source.dart';
import 'features/journey/data/datasources/journey_local_data_source.dart';
import 'features/journey/data/repositories/journey_progress_repository_impl.dart';
import 'features/journey/data/repositories/journey_repository_impl.dart';
import 'features/journey/domain/usecases/get_checked_task_ids_use_case.dart';
import 'features/journey/domain/usecases/get_journey_use_case.dart';
import 'features/journey/domain/usecases/get_journey_bookmark_use_case.dart';
import 'features/journey/domain/usecases/has_journey_use_case.dart';
import 'features/journey/domain/usecases/set_journey_bookmark_use_case.dart';
import 'features/journey/domain/usecases/set_task_checked_use_case.dart';
import 'features/journey/presentation/viewmodels/journey_view_model.dart';
import 'features/trophies/data/datasources/game_asset_data_source.dart';
import 'features/trophies/data/datasources/progress_local_data_source.dart';
import 'features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'features/trophies/data/repositories/game_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_progress_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_repository_impl.dart';
import 'features/trophies/domain/usecases/get_all_achieved_trophy_ids_use_case.dart';
import 'features/trophies/domain/usecases/get_games_use_case.dart';
import 'features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'features/trophies/domain/usecases/set_trophy_achieved_use_case.dart';
import 'features/trophies/presentation/screens/game_list_screen.dart';
import 'features/trophies/presentation/state/trophy_progress_store.dart';
import 'features/trophies/presentation/viewmodels/game_list_view_model.dart';
import 'features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

void main() {
  if (kDebugMode) {
    MarionetteBinding.ensureInitialized();
  } else {
    WidgetsFlutterBinding.ensureInitialized();
  }

  final gameRepository = GameRepositoryImpl(GameAssetDataSource(rootBundle));
  final trophyRepository = TrophyRepositoryImpl(
    TrophyAssetDataSource(rootBundle),
  );
  final trophyProgressRepository = TrophyProgressRepositoryImpl(
    ProgressLocalDataSource(),
  );
  final journeyRepository = JourneyRepositoryImpl(
    JourneyAssetDataSource(rootBundle),
  );
  final journeyProgressRepository = JourneyProgressRepositoryImpl(
    JourneyLocalDataSource(),
  );

  final trophyProgressStore = TrophyProgressStore(
    GetAllAchievedTrophyIdsUseCase(trophyProgressRepository),
    SetTrophyAchievedUseCase(trophyProgressRepository),
  )..load();

  runApp(
    TrophyGuideApp(
      dependencies: AppDependencies(
        trophyProgressStore: trophyProgressStore,
        hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
        createGameListViewModel: () => GameListViewModel(
          GetGamesUseCase(gameRepository),
          trophyProgressStore,
        ),
        createTrophyListViewModel: (gameId) => TrophyListViewModel(
          gameId,
          GetTrophiesUseCase(trophyRepository),
          trophyProgressStore,
        ),
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
    ),
  );
}

class TrophyGuideApp extends StatelessWidget {
  const TrophyGuideApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: dependencies,
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
