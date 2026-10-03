import '../repositories/auth_repository.dart';

class const SignInUseCase(final AuthRepository _repository) {
  Future<void> call() => _repository.signIn();
}
