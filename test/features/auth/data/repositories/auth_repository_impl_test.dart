import 'package:final_fantasy_guide/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:final_fantasy_guide/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:final_fantasy_guide/features/auth/data/models/auth_session_model.dart';
import 'package:final_fantasy_guide/features/auth/data/repositories/auth_repository_impl.dart';
import 'package:final_fantasy_guide/features/auth/domain/entities/auth_session.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';

import 'auth_repository_impl_test.mocks.dart';

const tokens = PsnTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: Duration(hours: 2),
);

@GenerateNiceMocks([
  MockSpec<AuthLocalDataSource>(),
  MockSpec<PSNRemoteDataSource>(),
])
void main() {
  late MockAuthLocalDataSource localDataSource;
  late MockPSNRemoteDataSource remoteDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    localDataSource = MockAuthLocalDataSource();
    remoteDataSource = MockPSNRemoteDataSource();
    when(localDataSource.saveSession(any)).thenAnswer((_) => Future.value());
    when(localDataSource.clearSession()).thenAnswer((_) => Future.value());
    repository = AuthRepositoryImpl(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
  });

  group('loginWithAuthorizationCode', () {
    test('trades the code for a session', () async {
      when(remoteDataSource.exchangeCode('v3.code'))
          .thenAnswer((_) async => tokens);

      final session = await repository.loginWithAuthorizationCode('v3.code');

      expect(session.accessToken, 'access');
      expect(session.refreshToken, 'refresh');
      verify(remoteDataSource.exchangeCode('v3.code')).called(1);
    });

    test('dates the expiry from the lifetime Sony reported', () async {
      when(remoteDataSource.exchangeCode(any)).thenAnswer((_) async => tokens);
      final before = DateTime.now();

      final session = await repository.loginWithAuthorizationCode('v3.code');

      expect(
        session.expiresAt.isAfter(before.add(const Duration(hours: 2)) //
            .subtract(const Duration(seconds: 5))),
        isTrue,
      );
      expect(
        session.expiresAt.isBefore(
          before.add(const Duration(hours: 2, seconds: 5)),
        ),
        isTrue,
      );
    });

    test('persists the session it hands back', () async {
      when(remoteDataSource.exchangeCode(any)).thenAnswer((_) async => tokens);

      final session = await repository.loginWithAuthorizationCode('v3.code');

      final saved = verify(localDataSource.saveSession(captureAny))
          .captured
          .single as AuthSessionModel;
      expect(saved.accessToken, session.accessToken);
      expect(saved.refreshToken, session.refreshToken);
      expect(saved.expiresAt, session.expiresAt);
    });

    test('does not persist anything when the exchange fails', () async {
      when(remoteDataSource.exchangeCode(any)).thenThrow(StateError('bad code'));

      await expectLater(
        repository.loginWithAuthorizationCode('v3.code'),
        throwsStateError,
      );

      verifyNever(localDataSource.saveSession(any));
    });
  });

  group('refreshToken', () {
    test('exchanges the refresh token and persists the result', () async {
      when(remoteDataSource.refreshAccessToken('refresh')).thenAnswer(
        (_) async => const PsnTokens(
          accessToken: 'next-access',
          refreshToken: 'next-refresh',
          expiresIn: Duration(hours: 1),
        ),
      );

      final session = await repository.refreshToken('refresh');

      expect(session.accessToken, 'next-access');
      expect(session.refreshToken, 'next-refresh');
      verify(localDataSource.saveSession(any)).called(1);
    });
  });

  group('getStoredSession', () {
    test('maps the stored model to an entity', () async {
      final expiresAt = DateTime.now().add(const Duration(hours: 1));
      when(localDataSource.getStoredSession()).thenAnswer(
        (_) async => AuthSessionModel(
          userId: 'psn_user',
          accessToken: 'access',
          refreshToken: 'refresh',
          expiresAt: expiresAt,
        ),
      );

      final session = await repository.getStoredSession();

      expect(session, isA<AuthSession>());
      expect(session!.accessToken, 'access');
      expect(session.expiresAt, expiresAt);
    });

    test('is null when nothing is stored', () async {
      when(localDataSource.getStoredSession()).thenAnswer((_) async => null);

      expect(await repository.getStoredSession(), isNull);
    });
  });

  group('logout', () {
    test('wipes the stored session', () async {
      await repository.logout();

      verify(localDataSource.clearSession()).called(1);
    });
  });
}
