import 'package:flutter/foundation.dart';

import '../entities/auth_session.dart';

class const SignInCancelledException() implements Exception;

abstract interface class AuthRepository {
  ValueListenable<AuthSession?> get session;

  bool get isAuthenticated;

  Future<void> loadStoredSession();

  Future<void> signIn();

  Future<void> signOut();
}
