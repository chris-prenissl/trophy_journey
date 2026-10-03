import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/psn_browser_auth_data_source.dart';
import '../datasources/psn_token_store.dart';

class AuthRepositoryImpl implements AuthRepository {
  const AuthRepositoryImpl({
    required this._tokenStore,
    required this._browserAuthDataSource,
  });

  final PsnTokenStore _tokenStore;
  final PsnBrowserAuthDataSource _browserAuthDataSource;

  @override
  ValueListenable<AuthSession?> get session => _tokenStore.session;

  @override
  bool get isAuthenticated => _tokenStore.session.value?.isValid == true;

  @override
  Future<void> loadStoredSession() => _tokenStore.load();

  @override
  Future<void> signIn() async =>
      _tokenStore.signIn(await _browserAuthDataSource.authorize());

  @override
  Future<void> signOut() => _tokenStore.clear();
}
