import 'package:flutter/foundation.dart';

import '../entities/auth_session.dart';

abstract interface class AuthRepository {
  ValueListenable<AuthSession?> get session;

  bool get isAuthenticated;

  Future<void> loadStoredSession();

  Future<void> signInWithAuthorizationCode(String code);

  Future<void> signOut();
}
