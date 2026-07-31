import 'dart:async';

import 'package:trophy_journey/features/auth/domain/entities/auth_session.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';
import 'package:trophy_journey/features/auth/domain/usecases/get_current_session.dart';
import 'package:trophy_journey/features/auth/domain/usecases/login_with_authorization_code.dart';
import 'package:trophy_journey/features/auth/domain/usecases/logout.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_view_model_test.mocks.dart';

final session = AuthSession(
  userId: 'psn_user',
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
);

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  late MockAuthRepository repository;
  late AuthViewModel viewModel;

  setUp(() {
    repository = MockAuthRepository();
    when(repository.logout()).thenAnswer((_) => Future.value());
    viewModel = AuthViewModel(
      loginWithAuthorizationCode: LoginWithAuthorizationCodeUseCase(repository),
      logout: LogoutUseCase(repository),
      getCurrentSession: GetCurrentSessionUseCase(repository),
    );
  });

  tearDown(() => viewModel.dispose());

  group('loginWithAuthorizationCode', () {
    test('starts with no session', () {
      expect(viewModel.session, isNull);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
    });

    test('exposes the session once the exchange finishes', () async {
      when(repository.loginWithAuthorizationCode('v3.code'))
          .thenAnswer((_) async => session);

      await viewModel.loginWithAuthorizationCode('v3.code');

      expect(viewModel.session, session);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, isNull);
    });

    test('reports loading while the exchange is in flight', () async {
      final gate = Completer<AuthSession>();
      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) => gate.future);
      var notifications = 0;
      viewModel.addListener(() => notifications++);

      final pending = viewModel.loginWithAuthorizationCode('v3.code');
      await pumpEventQueue();

      expect(viewModel.loading, isTrue);
      expect(viewModel.session, isNull);
      expect(notifications, 1);

      gate.complete(session);
      await pending;

      expect(viewModel.loading, isFalse);
      expect(viewModel.session, session);
      expect(notifications, 2);
    });

    test('surfaces the failure and leaves the session empty', () async {
      when(repository.loginWithAuthorizationCode(any))
          .thenThrow(StateError('invalid_grant'));

      await viewModel.loginWithAuthorizationCode('v3.code');

      expect(viewModel.session, isNull);
      expect(viewModel.loading, isFalse);
      expect(viewModel.error, contains('invalid_grant'));
    });

    test('clears an earlier error when retried', () async {
      when(repository.loginWithAuthorizationCode(any))
          .thenThrow(StateError('invalid_grant'));
      await viewModel.loginWithAuthorizationCode('v3.code');

      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) async => session);
      await viewModel.loginWithAuthorizationCode('v3.code');

      expect(viewModel.error, isNull);
      expect(viewModel.session, session);
    });
  });

  group('logout', () {
    test('drops the session', () async {
      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) async => session);
      await viewModel.loginWithAuthorizationCode('v3.code');

      await viewModel.logout();

      expect(viewModel.session, isNull);
      expect(viewModel.error, isNull);
      verify(repository.logout()).called(1);
    });

    test('keeps the session when signing out fails', () async {
      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) async => session);
      await viewModel.loginWithAuthorizationCode('v3.code');
      when(repository.logout()).thenThrow(StateError('offline'));

      await viewModel.logout();

      expect(viewModel.session, session);
      expect(viewModel.error, contains('offline'));
    });
  });

  group('loadStoredSession', () {
    test('picks up whatever was persisted', () async {
      when(repository.getStoredSession()).thenAnswer((_) async => session);

      await viewModel.loadStoredSession();

      expect(viewModel.session, session);
    });

    test('records the failure when storage throws', () async {
      when(repository.getStoredSession()).thenThrow(StateError('keychain'));

      await viewModel.loadStoredSession();

      expect(viewModel.session, isNull);
      expect(viewModel.error, contains('keychain'));
    });
  });
}
