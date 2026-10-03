import '../repositories/auth_repository.dart';

class const LoadStoredSessionUseCase(final AuthRepository _repository) {
  Future<void> call() => _repository.loadStoredSession();
}
