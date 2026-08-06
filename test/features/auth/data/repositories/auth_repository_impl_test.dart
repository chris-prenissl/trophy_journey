import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_token_store.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_web_session_data_source.dart';
import 'package:trophy_journey/features/auth/data/models/auth_session_model.dart';
import 'package:trophy_journey/features/auth/data/repositories/auth_repository_impl.dart';

import 'auth_repository_impl_test.mocks.dart';

const tokens = PsnTokens(
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresIn: Duration(hours: 2),
);

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
  MockSpec<PsnWebSessionDataSource>(),
])
void main() {
  late MockAuthLocalDataSource localDataSource;
  late MockPsnRemoteDataSource remoteDataSource;
  late MockPsnWebSessionDataSource webSessionDataSource;
  late AuthRepositoryImpl repository;

  setUp(() {
    localDataSource = MockAuthLocalDataSource();
    remoteDataSource = MockPsnRemoteDataSource();
    webSessionDataSource = MockPsnWebSessionDataSource();
    when(localDataSource.saveSession(any)).thenAnswer((_) => Future.value());
    when(localDataSource.clearSession()).thenAnswer((_) => Future.value());
    when(localDataSource.getStoredSession()).thenAnswer((_) async => null);
    when(webSessionDataSource.clear()).thenAnswer((_) => Future.value());
    repository = AuthRepositoryImpl(
      tokenStore: PsnTokenStore(
        localDataSource: localDataSource,
        remoteDataSource: remoteDataSource,
      ),
      webSessionDataSource: webSessionDataSource,
    );
  });

  group('signInWithAuthorizationCode', () {
    test('publishes the session the store signed in with', () async {
      when(remoteDataSource.exchangeCode('v3.code'))
          .thenAnswer((_) async => tokens);
      var notifications = 0;
      repository.session.addListener(() => notifications++);

      await repository.signInWithAuthorizationCode('v3.code');

      expect(repository.session.value?.accessToken, 'access');
      expect(repository.isAuthenticated, isTrue);
      expect(notifications, 1);
    });
  });

  group('loadStoredSession', () {
    test('publishes what was persisted', () async {
      final stored = storedSession();
      when(localDataSource.getStoredSession()).thenAnswer((_) async => stored);

      await repository.loadStoredSession();

      expect(repository.session.value?.accessToken, stored.accessToken);
      expect(repository.session.value?.expiresAt, stored.expiresAt);
      expect(repository.isAuthenticated, isTrue);
    });

    test('stays signed out when nothing is stored', () async {
      await repository.loadStoredSession();

      expect(repository.session.value, isNull);
      expect(repository.isAuthenticated, isFalse);
    });

    test('stays signed out when reading throws', () async {
      when(localDataSource.getStoredSession())
          .thenThrow(StateError('keychain'));

      await repository.loadStoredSession();

      expect(repository.session.value, isNull);
    });

    test('is not authenticated on an expired session', () async {
      when(localDataSource.getStoredSession()).thenAnswer(
        (_) async => storedSession(expiresIn: const Duration(hours: -1)),
      );

      await repository.loadStoredSession();

      expect(repository.session.value, isNotNull);
      expect(repository.isAuthenticated, isFalse);
    });
  });

  group('signOut', () {
    setUp(() async {
      when(localDataSource.getStoredSession())
          .thenAnswer((_) async => storedSession());
      await repository.loadStoredSession();
    });

    test('drops the session it published', () async {
      var notifications = 0;
      repository.session.addListener(() => notifications++);

      await repository.signOut();

      expect(repository.session.value, isNull);
      expect(repository.isAuthenticated, isFalse);
      expect(notifications, 1);
    });

    test('wipes the stored session', () async {
      await repository.signOut();

      verify(localDataSource.clearSession()).called(1);
    });

    test('drops the web view cookies so the login page cannot sign the user '
        'straight back in', () async {
      await repository.signOut();

      verify(webSessionDataSource.clear()).called(1);
    });
  });
}
