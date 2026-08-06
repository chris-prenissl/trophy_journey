import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/journey/domain/usecases/has_journey_use_case.dart';
import '../../features/journey/presentation/viewmodels/journey_view_model.dart';
import '../../features/trophies/presentation/state/trophy_progress_store.dart';
import '../../features/trophies/presentation/viewmodels/game_list_view_model.dart';
import '../../features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

class AppDependencies {
  const AppDependencies({
    required this.authViewModel,
    required this.trophyProgressStore,
    required this.hasJourneyUseCase,
    required this.createGameListViewModel,
    required this.createTrophyListViewModel,
    required this.createJourneyViewModel,
  });

  final AuthViewModel authViewModel;
  final TrophyProgressStore trophyProgressStore;

  final HasJourneyUseCase hasJourneyUseCase;

  final GameListViewModel Function() createGameListViewModel;
  final TrophyListViewModel Function(String gameId) createTrophyListViewModel;
  final JourneyViewModel Function(String gameId) createJourneyViewModel;
}
