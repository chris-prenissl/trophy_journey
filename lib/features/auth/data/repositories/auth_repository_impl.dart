import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../datasources/psn_browser_auth_data_source.dart';
import '../datasources/psn_token_store.dart';

class const AuthRepositoryImpl({
  required final PsnTokenStore _tokenStore,
  required final PsnBrowserAuthDataSource _browserAuthDataSource,
}) implements AuthRepository {
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
