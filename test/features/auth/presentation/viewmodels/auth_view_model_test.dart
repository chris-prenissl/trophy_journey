import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/auth/domain/entities/auth_session.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';
import 'package:trophy_journey/features/auth/domain/usecases/load_stored_session_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/watch_auth_session_use_case.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';

import 'auth_view_model_test.mocks.dart';

AuthSession fakeSession({
  Duration expiresIn = const Duration(hours: 1),
  String token = 'access',
}) => AuthSession(
  userId: 'psn_user',
  accessToken: token,
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(expiresIn),
);

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  late MockAuthRepository repository;
  late ValueNotifier<AuthSession?> session;
  late AuthSession signedIn;
  late AuthViewModel viewModel;

  setUp(() {
    repository = MockAuthRepository();
    session = ValueNotifier(null);
    signedIn = fakeSession();
    when(repository.session).thenReturn(session);
    when(repository.isAuthenticated)
        .thenAnswer((_) => session.value?.isValid ?? false);
    when(repository.loadStoredSession()).thenAnswer((_) async {});
    when(repository.signIn()).thenAnswer((_) async => session.value = signedIn);
    when(repository.signOut()).thenAnswer((_) async => session.value = null);
    viewModel = AuthViewModel(
      watchSession: WatchAuthSessionUseCase(repository),
      loadStoredSessionUseCase: LoadStoredSessionUseCase(repository),
      signInUseCase: SignInUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
    );
  });

  tearDown(() {
    viewModel.dispose();
    session.dispose();
  });

  group('the session it reports', () {
    test('starts empty', () {
      expect(viewModel.session, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
    });

    test('follows the repository without being asked', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      final restored = fakeSession();

      session.value = restored;

      expect(viewModel.session, restored);
      expect(viewModel.isAuthenticated, isTrue);
      expect(notifications, 1);
    });

    test('is not authenticated once the session has expired', () {
      session.value = fakeSession(expiresIn: const Duration(hours: -1));

      expect(viewModel.session, isNotNull);
      expect(viewModel.isAuthenticated, isFalse);
    });
  });

  group('signIn', () {
    test('signs in and picks up the session', () async {
      await viewModel.signIn();

      verify(repository.signIn()).called(1);
      expect(viewModel.session, signedIn);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
    });

    test('reports loading while the exchange is in flight', () async {
      final gate = Completer<void>();
      when(repository.signIn()).thenAnswer((_) async {
        await gate.future;
        session.value = signedIn;
      });
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      final pending = viewModel.signIn();
      await pumpEventQueue();

      expect(viewModel.loading, isTrue);
      expect(viewModel.session, isNull);

      gate.complete();
      await pending;

      expect(viewModel.loading, isFalse);
      expect(viewModel.session, isNotNull);
      const loadingOnSessionInLoadingOff = 3;
      expect(notifications, loadingOnSessionInLoadingOff);
    });

    test('surfaces the failure and stays signed out', () async {
      when(repository.signIn()).thenThrow(StateError('invalid_grant'));

      await viewModel.signIn();

      expect(viewModel.session, isNull);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, contains('invalid_grant'));
    });

    test('stays quiet when the user cancels', () async {
      when(repository.signIn()).thenThrow(const SignInCancelledException());

      await viewModel.signIn();

      expect(viewModel.session, isNull);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
    });

    test('clears an earlier error when retried', () async {
      when(repository.signIn()).thenThrow(StateError('invalid_grant'));
      await viewModel.signIn();

      when(repository.signIn())
          .thenAnswer((_) async => session.value = signedIn);
      await viewModel.signIn();

      expect(viewModel.error, isNull);
      expect(viewModel.session, isNotNull);
    });
  });

  group('signOut', () {
    test('drops the session', () async {
      await viewModel.signIn();

      await viewModel.signOut();

      verify(repository.signOut()).called(1);
      expect(viewModel.session, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.error, isNull);
    });

    test('reports a sign out that failed', () async {
      await viewModel.signIn();
      when(repository.signOut()).thenThrow(StateError('keychain'));

      await viewModel.signOut();

      expect(viewModel.error, contains('keychain'));
    });
  });

  group('loadStoredSession', () {
    test('picks up whatever the repository restored', () async {
      await viewModel.loadStoredSession();
      final stored = fakeSession();
      session.value = stored;

      expect(viewModel.session, stored);
    });

    test('records the failure when storage throws', () async {
      when(repository.loadStoredSession()).thenThrow(StateError('keychain'));

      await viewModel.loadStoredSession();

      expect(viewModel.session, isNull);
      expect(viewModel.error, contains('keychain'));
    });
  });
}
