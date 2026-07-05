import '../../../trophies/domain/usecases/set_trophy_achieved.dart';
import '../entities/journey.dart';

class SyncTrophiesWithJourney {
  const SyncTrophiesWithJourney(this._setTrophyAchieved);

  final SetTrophyAchieved _setTrophyAchieved;

  Future<void> call({
    required String gameId,
    required Journey journey,
    required Iterable<String> trophyIds,
    required Set<String> checkedBefore,
    required Set<String> checkedAfter,
  }) async {
    for (final trophyId in trophyIds) {
      final taskIds = journey.taskIdsByTrophyId[trophyId] ?? const [];
      bool covered(Set<String> checked) =>
          taskIds.isNotEmpty && taskIds.every(checked.contains);
      final before = covered(checkedBefore);
      final after = covered(checkedAfter);
      if (before != after) {
        await _setTrophyAchieved(gameId, trophyId, after);
      }
    }
  }
}
