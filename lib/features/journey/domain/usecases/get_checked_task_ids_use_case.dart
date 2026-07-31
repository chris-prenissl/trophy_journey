import '../repositories/journey_progress_repository.dart';

class GetCheckedTaskIdsUseCase {
  const GetCheckedTaskIdsUseCase(this._repository);

  final JourneyProgressRepository _repository;

  Future<Set<String>> call(String gameId) =>
      _repository.getCheckedTaskIds(gameId);
}
