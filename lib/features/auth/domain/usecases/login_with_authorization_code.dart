import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class LoginWithAuthorizationCodeUseCase {
  const LoginWithAuthorizationCodeUseCase(this._repository);

  final AuthRepository _repository;

  Future<AuthSession> call(String code) =>
      _repository.loginWithAuthorizationCode(code);
}
