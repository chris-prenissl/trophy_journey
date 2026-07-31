import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:marionette_flutter/marionette_flutter.dart';

import 'core/auth_store.dart';
import 'core/di/app_dependencies.dart';
import 'core/di/app_scope.dart';
import 'features/auth/data/datasources/auth_local_data_source.dart';
import 'features/auth/data/datasources/psn_remote_data_source.dart';
import 'features/auth/data/repositories/auth_repository_impl.dart';
import 'features/auth/domain/usecases/get_current_session.dart';
import 'features/auth/domain/usecases/login_with_authorization_code.dart';
import 'features/auth/domain/usecases/logout.dart';
import 'features/auth/presentation/screens/login_screen.dart';
import 'features/auth/presentation/viewmodels/auth_view_model.dart';
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
import 'features/trophies/data/datasources/psn_cache_data_source.dart';
import 'features/trophies/data/datasources/psn_trophy_data_source.dart';
import 'features/trophies/data/datasources/trophy_asset_data_source.dart';
import 'features/trophies/data/psn_library.dart';
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

  // Auth setup
  final authLocalDataSource = AuthLocalDataSourceImpl(
    const FlutterSecureStorage(),
  );
  final authRemoteDataSource = PSNRemoteDataSourceImpl();
  final authRepository = AuthRepositoryImpl(
    localDataSource: authLocalDataSource,
    remoteDataSource: authRemoteDataSource,
  );
  final authStore = AuthStore(repository: authRepository);

  final psnTrophyDataSource = PsnTrophyDataSource(
    accessToken: () async {
      await authStore.refreshTokenIfNeeded();
      return authStore.currentSession?.accessToken;
    },
  );
  final psnCache = PsnCacheDataSource();
  final gameGuides = GameAssetDataSource(rootBundle);
  final trophyGuides = TrophyAssetDataSource(rootBundle);

  final psnLibrary = PsnLibrary(
    psn: psnTrophyDataSource,
    cache: psnCache,
    guides: gameGuides,
  );

  final gameRepository = GameRepositoryImpl(psnLibrary);
  final trophyRepository = TrophyRepositoryImpl(
    library: psnLibrary,
    psn: psnTrophyDataSource,
    cache: psnCache,
    guides: trophyGuides,
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
      authStore: authStore,
      dependencies: AppDependencies(
        authStore: authStore,
        trophyProgressStore: trophyProgressStore,
        hasJourneyUseCase: HasJourneyUseCase(journeyRepository),
        createAuthViewModel: () => AuthViewModel(
          loginWithAuthorizationCode: LoginWithAuthorizationCodeUseCase(
            authRepository,
          ),
          logout: LogoutUseCase(authRepository),
          getCurrentSession: GetCurrentSessionUseCase(authRepository),
        ),
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
  const TrophyJourneyApp({
    super.key,
    required this.authStore,
    required this.dependencies,
  });

  final AuthStore authStore;
  final AppDependencies dependencies;

  @override
  State<TrophyJourneyApp> createState() => _TrophyJourneyAppState();
}

class _TrophyJourneyAppState extends State<TrophyJourneyApp> {
  late final Future<void> _authInitFuture;
  late final AuthViewModel _authViewModel;

  @override
  void initState() {
    super.initState();
    _authViewModel = widget.dependencies.createAuthViewModel();
    _authInitFuture = widget.authStore.loadSession();
  }

  @override
  void dispose() {
    _authViewModel.dispose();
    super.dispose();
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
                    listenable: widget.authStore,
                    builder: (context, _) {
                      if (widget.authStore.isAuthenticated) {
                        return const GameListScreen();
                      } else {
                        return LoginScreen(
                          viewModel: _authViewModel,
                          authStore: widget.authStore,
                        );
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
