import '../repositories/auth_repository.dart';

class LoadStoredSessionUseCase {
  const LoadStoredSessionUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call() => _repository.loadStoredSession();
}
