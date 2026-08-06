import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/psn_token_store.dart';
import '../datasources/psn_web_session_data_source.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._tokenStore,
    required this._webSessionDataSource,
  });

  final PsnTokenStore _tokenStore;
  final PsnWebSessionDataSource _webSessionDataSource;

  @override
  ValueListenable<AuthSession?> get session => _tokenStore.session;

  @override
  bool get isAuthenticated => _tokenStore.session.value?.isValid == true;

  @override
  Future<void> loadStoredSession() => _tokenStore.load();

  @override
  Future<void> signInWithAuthorizationCode(String code) =>
      _tokenStore.signIn(code);

  @override
  Future<void> signOut() async {
    await _tokenStore.clear();
    await _webSessionDataSource.clear();
  }
}
