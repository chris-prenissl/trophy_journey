import '../repositories/trophy_progress_repository.dart';

class SetTrophyAchieved {
  const SetTrophyAchieved(this._repository);

  final TrophyProgressRepository _repository;

  Future<void> call(String trophyId, bool achieved) =>
      _repository.setAchieved(trophyId, achieved);
}
