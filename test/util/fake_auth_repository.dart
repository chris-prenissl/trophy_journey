import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:trophy_journey/features/auth/domain/entities/auth_session.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';

AuthSession fakeSession({
  Duration expiresIn = const Duration(hours: 1),
  String token = 'access',
}) => AuthSession(
  userId: 'psn_user',
  accessToken: token,
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(expiresIn),
);

class FakeAuthRepository implements AuthRepository {
  FakeAuthRepository({AuthSession? session}) {
    _session.value = session;
  }

  /// A repository that already holds a usable token.
  factory FakeAuthRepository.signedIn({String token = 'the-token'}) =>
      FakeAuthRepository(session: fakeSession(token: token));

  final _session = ValueNotifier<AuthSession?>(null);

  /// Set to make the matching call throw instead of succeeding.
  Object? loadStoredSessionError;
  Object? signInError;
  Object? signOutError;

  AuthSession? signInResult = fakeSession();
  final signedInCodes = <String>[];
  var signOutCount = 0;

  /// Complete to let a held sign in finish, for tests that need to look at the
  /// view model while the exchange is still in flight.
  Completer<void>? signInGate;

  @override
  ValueListenable<AuthSession?> get session => _session;

  @override
  bool get isAuthenticated => _session.value?.isValid ?? false;

  /// Drops a session in the way a token refresh or a stored session would.
  void emit(AuthSession? session) => _session.value = session;

  @override
  Future<void> loadStoredSession() async {
    if (loadStoredSessionError case final error?) throw error;
  }

  @override
  Future<void> signInWithAuthorizationCode(String code) async {
    signedInCodes.add(code);
    await signInGate?.future;
    if (signInError case final error?) throw error;
    _session.value = signInResult;
  }

  @override
  Future<void> signOut() async {
    signOutCount++;
    if (signOutError case final error?) throw error;
    _session.value = null;
  }
}
