import '../models/auth_session_model.dart';

abstract interface class AuthLocalDataSource {
  Future<AuthSessionModel?> getStoredSession();
  Future<void> saveSession(AuthSessionModel session);
  Future<void> clearSession();
}
