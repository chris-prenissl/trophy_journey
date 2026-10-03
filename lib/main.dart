import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:http/http.dart';
import 'package:marionette_flutter/marionette_flutter.dart';
import 'package:material_ui/material_ui.dart';

import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';
import 'features/auth/data/datasources/auth_local_data_source_impl.dart';
import 'features/auth/data/datasources/authenticated_psn_client.dart';
import 'features/auth/data/datasources/psn_browser_auth_data_source_impl.dart';
import 'features/auth/data/datasources/psn_remote_data_source_impl.dart';
import 'features/auth/data/datasources/psn_token_store.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/load_stored_session_use_case.dart';
import 'features/auth/domain/usecases/sign_in_use_case.dart';
import 'features/auth/domain/usecases/sign_out_use_case.dart';
import 'features/auth/domain/usecases/watch_auth_session_use_case.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
import 'features/journey/data/datasources/journey_asset_data_source.dart';
import 'features/journey/data/datasources/journey_local_data_source.dart';
import 'features/journey/data/repositories/journey_progress_repository_impl.dart';
import 'features/journey/data/repositories/journey_repository_impl.dart';
import 'features/journey/domain/usecases/get_checked_task_ids_use_case.dart';
import 'features/journey/domain/usecases/get_journey_bookmark_use_case.dart';
import 'features/journey/domain/usecases/get_journey_use_case.dart';
import 'features/journey/domain/usecases/has_journey_use_case.dart';
import 'features/journey/domain/usecases/set_journey_bookmark_use_case.dart';
import 'features/journey/domain/usecases/set_task_checked_use_case.dart';
import 'features/journey/presentation/viewmodels/journey_view_model.dart';
import 'features/trophies/data/datasources/game_asset_data_source.dart';
import 'features/trophies/data/datasources/progress_local_data_source.dart';
import 'features/trophies/data/datasources/psn_cache_data_source.dart';
import 'features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'features/trophies/data/repositories/game_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_progress_repository_impl.dart';
import 'features/trophies/data/repositories/trophy_repository_impl.dart';
import 'features/trophies/domain/usecases/get_all_earned_trophy_ids_use_case.dart';
import 'features/trophies/domain/usecases/get_games_use_case.dart';
import 'features/trophies/domain/usecases/get_psn_earned_trophy_ids_use_case.dart';
import 'features/trophies/domain/usecases/get_trophies_use_case.dart';
import 'features/trophies/domain/usecases/replace_earned_trophies_use_case.dart';
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

  const authLocalDataSource = AuthLocalDataSourceImpl(
    FlutterSecureStorage(
      mOptions: MacOsOptions(usesDataProtectionKeychain: false),
    ),
  );
  final authRemoteDataSource = PsnRemoteDataSourceImpl();
  final browserAuthDataSource = PsnBrowserAuthDataSourceImpl();
  final tokenStore = PsnTokenStore(
    localDataSource: authLocalDataSource,
    remoteDataSource: authRemoteDataSource,
  );
  final authRepository = AuthRepositoryImpl(
    tokenStore: tokenStore,
    browserAuthDataSource: browserAuthDataSource,
  );
  final authViewModel = AuthViewModel(
    watchSession: WatchAuthSessionUseCase(authRepository),
    loadStoredSessionUseCase: LoadStoredSessionUseCase(authRepository),
    signInUseCase: SignInUseCase(authRepository),
    signOutUseCase: SignOutUseCase(authRepository),
  );

  final psnTrophyDataSource = PsnTrophyDataSource(
    client: AuthenticatedPsnClient(
      innerClient: Client(),
      psnTokenStore: tokenStore,
    ),
  );
  final psnCacheDataSource = PsnCacheDataSource();
  final gameAssetDataSource = GameAssetDataSource(rootBundle);
  final trophyAssetDataSource = TrophyAssetDataSource(rootBundle);
  final gameRepository = GameRepositoryImpl(
    psnTrophyDataSource: psnTrophyDataSource,
    psnCacheDataSource: psnCacheDataSource,
    gameAssetDataSource: gameAssetDataSource,
  );
  final trophyRepository = TrophyRepositoryImpl(
    gameRepository: gameRepository,
    psnTrophyDataSource: psnTrophyDataSource,
    psnCacheDataSource: psnCacheDataSource,
    trophyAssetDataSource: trophyAssetDataSource,
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
    GetAllEarnedTrophyIdsUseCase(trophyProgressRepository),
    ReplaceEarnedTrophiesUseCase(trophyProgressRepository),
  )..load();

  runApp(
    TrophyJourneyApp(
      dependencies: AppDependencies(
        authViewModel: authViewModel,
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
          getPsnEarnedTrophyIds: GetPsnEarnedTrophyIdsUseCase(trophyRepository),
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

class TrophyJourneyApp extends StatefulWidget {
  const TrophyJourneyApp({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<TrophyJourneyApp> createState() => _TrophyJourneyAppState();
}

class _TrophyJourneyAppState extends State<TrophyJourneyApp> {
  late final Future<void> _authInitFuture;

  AuthViewModel get _authViewModel => widget.dependencies.authViewModel;

  @override
  void initState() {
    super.initState();
    _authInitFuture = _authViewModel.loadStoredSession();
  }

  @override
  Widget build(BuildContext context) {
    return AppScope(
      dependencies: widget.dependencies,
      child: FutureBuilder(
        future: _authInitFuture,
        builder: (context, snapshot) {
          return MaterialApp(
            title: 'Trophy Journey',
            debugShowCheckedModeBanner: false,
            theme: ThemeData(
              colorScheme: ColorScheme.fromSeed(
                seedColor: const Color(0xFF1B4B8A),
                brightness: Brightness.dark,
              ),
            ),
            home: snapshot.connectionState == ConnectionState.done
                ? ListenableBuilder(
                    listenable: _authViewModel,
                    builder: (context, _) {
                      if (_authViewModel.isAuthenticated) {
                        return const GameListScreen();
                      } else {
                        return LoginScreen(viewModel: _authViewModel);
                      }
                    },
                  )
                : const Scaffold(
                    body: Center(child: CircularProgressIndicator()),
                  ),
          );
        },
      ),
    );
  }
}
