import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../models/auth_session_model.dart';
import 'auth_local_data_source.dart';
import 'psn_remote_data_source.dart';

class PsnTokenStore({
  required final AuthLocalDataSource localDataSource,
  required final PsnRemoteDataSource remoteDataSource,
}) {
  final _session = ValueNotifier<AuthSession?>(null);

  ValueListenable<AuthSession?> get session => _session;

  Future<void> load() async {
    try {
      final stored = await localDataSource.getStoredSession();
      _session.value = stored?.toEntity();
    } catch (_) {
      _session.value = null;
    }
  }

  Future<void> signIn(String code) async {
    _session.value = await _persist(await remoteDataSource.exchangeCode(code));
  }

  Future<void> clear() async {
    _session.value = null;
    await localDataSource.clearSession();
  }

  Future<String?> accessToken() async {
    final current = _session.value;
    if (current == null) {
      return null;
    }

    if (current.isValid) {
      return current.accessToken;
    }

    return refresh();
  }

  Future<String?> refresh() async {
    final current = _session.value;
    if (current == null) {
      return null;
    }

    try {
      _session.value = await _persist(
        await remoteDataSource.refreshAccessToken(current.refreshToken),
      );
    } catch (_) {
      await clear();
    }

    return _session.value?.accessToken;
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
}
