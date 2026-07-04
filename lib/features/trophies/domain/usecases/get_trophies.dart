import '../entities/trophy.dart';
import '../repositories/trophy_repository.dart';

class GetTrophies {
  const GetTrophies(this._repository);

  final TrophyRepository _repository;

  Future<List<Trophy>> call() => _repository.getTrophies();
}
