import '../repositories/auth_repository.dart';

class SignInWithAuthorizationCodeUseCase {
  const SignInWithAuthorizationCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<void> call(String code) =>
      _repository.signInWithAuthorizationCode(code);
}
