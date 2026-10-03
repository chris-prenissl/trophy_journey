import '../../features/auth/presentation/viewmodels/auth_view_model.dart';
import '../../features/journey/domain/usecases/has_journey_use_case.dart';
import '../../features/journey/presentation/viewmodels/journey_view_model.dart';
import '../../features/trophies/presentation/state/trophy_progress_store.dart';
import '../../features/trophies/presentation/viewmodels/game_list_view_model.dart';
import '../../features/trophies/presentation/viewmodels/trophy_list_view_model.dart';

class const AppDependencies({
  required final AuthViewModel authViewModel,
  required final TrophyProgressStore trophyProgressStore,
  required final HasJourneyUseCase hasJourneyUseCase,
  required final GameListViewModel Function() createGameListViewModel,
  required final TrophyListViewModel Function(String gameId)
  createTrophyListViewModel,
  required final JourneyViewModel Function(String gameId)
  createJourneyViewModel,
});
