import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/auth_local_data_source.dart';
import '../datasources/psn_remote_data_source.dart';
import '../models/auth_session_model.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this.localDataSource,
    required this.remoteDataSource,
  });

  final AuthLocalDataSource localDataSource;
  final PSNRemoteDataSource remoteDataSource;

  @override
  Future<AuthSession> loginWithAuthorizationCode(String code) async {
    return _persist(await remoteDataSource.exchangeCode(code));
  }

  @override
  Future<void> logout() async {
    await localDataSource.clearSession();
  }

  @override
  Future<AuthSession?> getStoredSession() async {
    final model = await localDataSource.getStoredSession();
    return model?.toEntity();
  }

  @override
  Future<AuthSession> refreshToken(String refreshToken) async {
    return _persist(await remoteDataSource.refreshAccessToken(refreshToken));
  }

  Future<AuthSession> _persist(PsnTokens tokens) async {
    final model = AuthSessionModel(
      userId: 'psn_user',
      accessToken: tokens.accessToken,
      refreshToken: tokens.refreshToken,
      expiresAt: DateTime.now().add(tokens.expiresIn),
    );

    await localDataSource.saveSession(model);
    return model.toEntity();
  }

  @override
  Future<void> saveSession(AuthSession session) async {
    await localDataSource.saveSession(AuthSessionModel.fromEntity(session));
  }

  @override
  Future<void> clearSession() async {
    await localDataSource.clearSession();
  }
}
