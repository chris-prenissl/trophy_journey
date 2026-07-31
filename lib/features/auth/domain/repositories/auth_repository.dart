import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  Future<AuthSession> loginWithAuthorizationCode(String code);

  Future<void> logout();

  Future<AuthSession?> getStoredSession();

  Future<AuthSession> refreshToken(String refreshToken);

  Future<void> saveSession(AuthSession session);
  
  Future<void> clearSession();
}
