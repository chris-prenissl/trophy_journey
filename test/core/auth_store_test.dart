import 'package:trophy_journey/core/auth_store.dart';
import 'package:trophy_journey/features/auth/domain/entities/auth_session.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_store_test.mocks.dart';

AuthSession sessionExpiring(Duration fromNow, {String token = 'access'}) =>
    AuthSession(
      userId: 'psn_user',
      accessToken: token,
      refreshToken: 'refresh',
      expiresAt: DateTime.now().add(fromNow),
    );

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  late MockAuthRepository repository;
  late AuthStore store;

  setUp(() {
    repository = MockAuthRepository();
    when(repository.getStoredSession()).thenAnswer((_) async => null);
    when(repository.saveSession(any)).thenAnswer((_) => Future.value());
    when(repository.clearSession()).thenAnswer((_) => Future.value());
    store = AuthStore(repository: repository);
  });

  group('isAuthenticated', () {
    test('is false before a session is loaded', () {
      expect(store.isAuthenticated, isFalse);
      expect(store.currentSession, isNull);
    });

    test('is false for an expired session', () async {
      when(repository.getStoredSession())
          .thenAnswer((_) async => sessionExpiring(const Duration(hours: -1)));

      await store.loadSession();

      expect(store.currentSession, isNotNull);
      expect(store.isAuthenticated, isFalse);
    });
  });

  group('loadSession', () {
    test('publishes a stored session and notifies', () async {
      final stored = sessionExpiring(const Duration(hours: 1));
      when(repository.getStoredSession()).thenAnswer((_) async => stored);
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.loadSession();

      expect(store.currentSession, stored);
      expect(store.isAuthenticated, isTrue);
      expect(notifications, 1);
    });

    test('stays signed out when reading the session throws', () async {
      when(repository.getStoredSession()).thenThrow(StateError('keychain'));
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.loadSession();

      expect(store.currentSession, isNull);
      expect(store.isAuthenticated, isFalse);
      expect(notifications, 1);
    });
  });

  group('setSession', () {
    test('publishes the session and persists it', () async {
      final session = sessionExpiring(const Duration(hours: 1));
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.setSession(session);

      expect(store.currentSession, session);
      expect(store.isAuthenticated, isTrue);
      expect(notifications, 1);
      verify(repository.saveSession(session)).called(1);
    });
  });

  group('clearSession', () {
    test('drops the session and wipes storage', () async {
      await store.setSession(sessionExpiring(const Duration(hours: 1)));
      var notifications = 0;
      store.addListener(() => notifications++);

      await store.clearSession();

      expect(store.currentSession, isNull);
      expect(store.isAuthenticated, isFalse);
      expect(notifications, 1);
      verify(repository.clearSession()).called(1);
    });
  });

  group('refreshTokenIfNeeded', () {
    test('does nothing without a session', () async {
      await store.refreshTokenIfNeeded();

      verifyNever(repository.refreshToken(any));
    });

    test('leaves a still valid session alone', () async {
      await store.setSession(sessionExpiring(const Duration(hours: 1)));

      await store.refreshTokenIfNeeded();

      verifyNever(repository.refreshToken(any));
    });

    test('swaps in a fresh session once the old one expired', () async {
      await store.setSession(sessionExpiring(const Duration(hours: -1)));
      final refreshed = sessionExpiring(
        const Duration(hours: 1),
        token: 'new-access',
      );
      when(repository.refreshToken('refresh'))
          .thenAnswer((_) async => refreshed);

      await store.refreshTokenIfNeeded();

      expect(store.currentSession, refreshed);
      expect(store.isAuthenticated, isTrue);
    });

    test('signs out when the refresh fails', () async {
      await store.setSession(sessionExpiring(const Duration(hours: -1)));
      when(repository.refreshToken(any)).thenThrow(StateError('revoked'));

      await store.refreshTokenIfNeeded();

      expect(store.currentSession, isNull);
      expect(store.isAuthenticated, isFalse);
      verify(repository.clearSession()).called(1);
    });
  });
}
