import 'dart:convert';

import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../models/auth_session_model.dart';

abstract interface class AuthLocalDataSource {
  Future<AuthSessionModel?> getStoredSession();
  Future<void> saveSession(AuthSessionModel session);
  Future<void> clearSession();
}

class AuthLocalDataSourceImpl implements AuthLocalDataSource {
  const AuthLocalDataSourceImpl(this._storage);

  final FlutterSecureStorage _storage;

  static const String _sessionKey = 'auth_session';

  @override
  Future<AuthSessionModel?> getStoredSession() async {
    try {
      final json = await _storage.read(key: _sessionKey);
      if (json == null) return null;
      
      return AuthSessionModel.fromJson(jsonDecode(json) as Map<String, dynamic>);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> saveSession(AuthSessionModel session) async {
    await _storage.write(
      key: _sessionKey,
      value: jsonEncode(session.toJson()),
    );
  }

  @override
  Future<void> clearSession() async {
    await _storage.delete(key: _sessionKey);
  }
}
