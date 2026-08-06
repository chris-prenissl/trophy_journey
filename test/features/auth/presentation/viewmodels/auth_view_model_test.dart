import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:trophy_journey/features/auth/domain/usecases/load_stored_session_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_in_with_authorization_code_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/watch_auth_session_use_case.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';

import '../../../../util/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = AuthViewModel(
      watchSession: WatchAuthSessionUseCase(repository),
      loadStoredSessionUseCase: LoadStoredSessionUseCase(repository),
      signInWithAuthorizationCodeUseCase: SignInWithAuthorizationCodeUseCase(
        repository,
      ),
      signOutUseCase: SignOutUseCase(repository),
    );
  });

  tearDown(() => viewModel.dispose());

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
      final session = fakeSession();

      repository.emit(session);

      expect(viewModel.session, session);
      expect(viewModel.isAuthenticated, isTrue);
      expect(notifications, 1);
    });

    test('is not authenticated once the session has expired', () {
      repository.emit(fakeSession(expiresIn: const Duration(hours: -1)));

      expect(viewModel.session, isNotNull);
      expect(viewModel.isAuthenticated, isFalse);
    });
  });

  group('signInWithAuthorizationCode', () {
    test('hands the code over and picks up the session', () async {
      await viewModel.signInWithAuthorizationCode('v3.code');

      expect(repository.signedInCodes, ['v3.code']);
      expect(viewModel.session, repository.signInResult);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
    });

    test('reports loading while the exchange is in flight', () async {
      final gate = Completer<void>();
      repository.signInGate = gate;
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      final pending = viewModel.signInWithAuthorizationCode('v3.code');
      await pumpEventQueue();

      expect(viewModel.loading, isTrue);
      expect(viewModel.session, isNull);

      gate.complete();
      await pending;

      expect(viewModel.loading, isFalse);
      expect(viewModel.session, isNotNull);
      // Loading on, session in, loading off.
      expect(notifications, 3);
    });

    test('surfaces the failure and stays signed out', () async {
      repository.signInError = StateError('invalid_grant');

      await viewModel.signInWithAuthorizationCode('v3.code');

      expect(viewModel.session, isNull);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, contains('invalid_grant'));
    });

    test('clears an earlier error when retried', () async {
      repository.signInError = StateError('invalid_grant');
      await viewModel.signInWithAuthorizationCode('v3.code');

      repository.signInError = null;
      await viewModel.signInWithAuthorizationCode('v3.code');

      expect(viewModel.error, isNull);
      expect(viewModel.session, isNotNull);
    });
  });

  group('signOut', () {
    test('drops the session', () async {
      await viewModel.signInWithAuthorizationCode('v3.code');

      await viewModel.signOut();

      expect(repository.signOutCount, 1);
      expect(viewModel.session, isNull);
      expect(viewModel.isAuthenticated, isFalse);
      expect(viewModel.error, isNull);
    });

    test('reports a sign out that failed', () async {
      await viewModel.signInWithAuthorizationCode('v3.code');
      repository.signOutError = StateError('keychain');

      await viewModel.signOut();

      expect(viewModel.error, contains('keychain'));
    });
  });

  group('loadStoredSession', () {
    test('picks up whatever the repository restored', () async {
      await viewModel.loadStoredSession();
      final stored = fakeSession();
      repository.emit(stored);

      expect(viewModel.session, stored);
    });

    test('records the failure when storage throws', () async {
      repository.loadStoredSessionError = StateError('keychain');

      await viewModel.loadStoredSession();

      expect(viewModel.session, isNull);
      expect(viewModel.error, contains('keychain'));
    });
  });
}
