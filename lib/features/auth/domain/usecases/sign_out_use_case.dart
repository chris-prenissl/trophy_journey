import '../repositories/auth_repository.dart';

class const SignOutUseCase(final AuthRepository _repository) {
  Future<void> call() => _repository.signOut();
}
