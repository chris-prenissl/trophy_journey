import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_token_store.dart';
import 'package:trophy_journey/features/auth/data/models/auth_session_model.dart';

import 'psn_token_store_test.mocks.dart';

AuthSessionModel storedSession({
  Duration expiresIn = const Duration(hours: 1),
  String token = 'access',
}) => AuthSessionModel(
  userId: 'psn_user',
  accessToken: token,
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(expiresIn),
);

@GenerateNiceMocks([
  MockSpec<AuthLocalDataSource>(),
  MockSpec<PsnRemoteDataSource>(),
])
void main() {
  late MockAuthLocalDataSource localDataSource;
  late MockPsnRemoteDataSource remoteDataSource;
  late PsnTokenStore store;

  setUp(() {
    localDataSource = MockAuthLocalDataSource();
    remoteDataSource = MockPsnRemoteDataSource();
    when(localDataSource.saveSession(any)).thenAnswer((_) => Future.value());
    when(localDataSource.clearSession()).thenAnswer((_) => Future.value());
    when(localDataSource.getStoredSession()).thenAnswer((_) async => null);
    store = PsnTokenStore(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
  });

  Future<void> signedInWith(AuthSessionModel session) async {
    when(localDataSource.getStoredSession()).thenAnswer((_) async => session);
    await store.load();
  }

  group('signIn', () {
    const tokens = PsnTokens(
      accessToken: 'access',
      refreshToken: 'refresh',
      expiresIn: Duration(hours: 2),
    );

    test('trades the code for a session and publishes it', () async {
      when(
        remoteDataSource.exchangeCode('v3.code'),
      ).thenAnswer((_) async => tokens);
      var notifications = 0;
      store.session.addListener(() => notifications++);

      await store.signIn('v3.code');

      expect(store.session.value?.accessToken, 'access');
      expect(store.session.value?.refreshToken, 'refresh');
      expect(notifications, 1);
      verify(remoteDataSource.exchangeCode('v3.code')).called(1);
    });

    test('dates the expiry from the lifetime Sony reported', () async {
      when(remoteDataSource.exchangeCode(any)).thenAnswer((_) async => tokens);
      final before = DateTime.now();

      await store.signIn('v3.code');

      final expiresAt = store.session.value!.expiresAt;
      expect(
        expiresAt.isAfter(
          before
              .add(const Duration(hours: 2))
              .subtract(const Duration(seconds: 5)),
        ),
        isTrue,
      );
      expect(
        expiresAt.isBefore(before.add(const Duration(hours: 2, seconds: 5))),
        isTrue,
      );
    });

    test('persists the session it published', () async {
      when(remoteDataSource.exchangeCode(any)).thenAnswer((_) async => tokens);

      await store.signIn('v3.code');

      final saved =
          verify(localDataSource.saveSession(captureAny)).captured.single
              as AuthSessionModel;
      expect(saved.accessToken, store.session.value!.accessToken);
      expect(saved.expiresAt, store.session.value!.expiresAt);
    });

    test('does not persist anything when the exchange fails', () async {
      when(remoteDataSource.exchangeCode(any)).thenThrow(StateError('bad code'));

      await expectLater(store.signIn('v3.code'), throwsStateError);

      verifyNever(localDataSource.saveSession(any));
      expect(store.session.value, isNull);
    });
  });

  group('accessToken', () {
    test('is null without a session', () async {
      expect(await store.accessToken(), isNull);
      verifyNever(remoteDataSource.refreshAccessToken(any));
    });

    test('hands back a token that is still good', () async {
      await signedInWith(storedSession(token: 'stored-access'));

      expect(await store.accessToken(), 'stored-access');
      verifyNever(remoteDataSource.refreshAccessToken(any));
    });

    test('refreshes a token that expired', () async {
      await signedInWith(storedSession(expiresIn: const Duration(hours: -1)));
      when(remoteDataSource.refreshAccessToken('refresh')).thenAnswer(
        (_) async => const PsnTokens(
          accessToken: 'next-access',
          refreshToken: 'next-refresh',
          expiresIn: Duration(hours: 1),
        ),
      );

      expect(await store.accessToken(), 'next-access');
      expect(store.session.value?.refreshToken, 'next-refresh');
      verify(localDataSource.saveSession(any)).called(1);
    });
  });

  group('refresh', () {
    test('is null without a session', () async {
      expect(await store.refresh(), isNull);
      verifyNever(remoteDataSource.refreshAccessToken(any));
    });

    test('swaps in the new pair even when the old one had not expired', () async {
      await signedInWith(storedSession(token: 'stored-access'));
      when(remoteDataSource.refreshAccessToken('refresh')).thenAnswer(
        (_) async => const PsnTokens(
          accessToken: 'next-access',
          refreshToken: 'next-refresh',
          expiresIn: Duration(hours: 1),
        ),
      );

      expect(await store.refresh(), 'next-access');
    });

    test('clears the session when Sony refuses', () async {
      await signedInWith(storedSession(expiresIn: const Duration(hours: -1)));
      when(
        remoteDataSource.refreshAccessToken(any),
      ).thenThrow(StateError('revoked'));

      expect(await store.refresh(), isNull);
      expect(store.session.value, isNull);
      verify(localDataSource.clearSession()).called(1);
    });
  });

  group('load', () {
    test('publishes what was persisted', () async {
      final stored = storedSession();
      var notifications = 0;
      store.session.addListener(() => notifications++);

      await signedInWith(stored);

      expect(store.session.value?.accessToken, stored.accessToken);
      expect(notifications, 1);
    });

    test('stays empty when reading throws', () async {
      when(localDataSource.getStoredSession()).thenThrow(StateError('keychain'));

      await store.load();

      expect(store.session.value, isNull);
    });
  });

  group('clear', () {
    test('drops the session and wipes storage', () async {
      await signedInWith(storedSession());

      await store.clear();

      expect(store.session.value, isNull);
      verify(localDataSource.clearSession()).called(1);
    });
  });
}
