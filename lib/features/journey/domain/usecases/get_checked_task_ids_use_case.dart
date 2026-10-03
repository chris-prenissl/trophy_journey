import '../repositories/journey_progress_repository.dart';

class const GetCheckedTaskIdsUseCase(
  final JourneyProgressRepository _repository,
) {
  Future<Set<String>> call(String gameId) =>
      _repository.getCheckedTaskIds(gameId);
}
