import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/auth/data/datasources/auth_local_data_source.dart';
import 'package:trophy_journey/features/auth/data/datasources/authenticated_psn_client.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_token_store.dart';
import 'package:trophy_journey/features/auth/data/models/auth_session_model.dart';

import 'authenticated_psn_client_test.mocks.dart';

final url = Uri.parse('https://psn.test/api/trophy/v1/users/me/trophyTitles');

AuthSessionModel storedSession({
  Duration expiresIn = const Duration(hours: 1),
  String token = 'the-token',
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
  late PsnTokenStore tokens;

  setUp(() {
    localDataSource = MockAuthLocalDataSource();
    remoteDataSource = MockPsnRemoteDataSource();
    when(localDataSource.saveSession(any)).thenAnswer((_) => Future.value());
    when(localDataSource.clearSession()).thenAnswer((_) => Future.value());
    when(localDataSource.getStoredSession()).thenAnswer((_) async => null);
    tokens = PsnTokenStore(
      localDataSource: localDataSource,
      remoteDataSource: remoteDataSource,
    );
  });

  Future<void> signIn({Duration expiresIn = const Duration(hours: 1)}) async {
    when(localDataSource.getStoredSession())
        .thenAnswer((_) async => storedSession(expiresIn: expiresIn));
    await tokens.load();
  }

  AuthenticatedPsnClient clientOver(MockClientHandler handler) =>
      AuthenticatedPsnClient(
        innerClient: MockClient(handler),
        psnTokenStore: tokens,
      );

  test('signs every request with the current token', () async {
    await signIn();
    final sent = <http.Request>[];
    final client = clientOver((request) async {
      sent.add(request);
      return http.Response('{}', 200);
    });

    await client.get(url);

    expect(sent.single.headers['Authorization'], 'Bearer the-token');
  });

  test('refuses to call out when signed out', () async {
    var called = false;
    final client = clientOver((_) async {
      called = true;
      return http.Response('{}', 200);
    });

    await expectLater(
      client.get(url),
      throwsA(isA<PsnAuthRequiredException>()),
    );
    expect(called, isFalse);
  });

  test('refreshes an expired token before the request goes out', () async {
    await signIn(expiresIn: const Duration(hours: -1));
    when(remoteDataSource.refreshAccessToken('refresh')).thenAnswer(
      (_) async => const PsnTokens(
        accessToken: 'fresh-token',
        refreshToken: 'next-refresh',
        expiresIn: Duration(hours: 1),
      ),
    );
    final sent = <http.Request>[];
    final client = clientOver((request) async {
      sent.add(request);
      return http.Response('{}', 200);
    });

    await client.get(url);

    expect(sent.single.headers['Authorization'], 'Bearer fresh-token');
  });

  group('when PSN rejects the token mid flight', () {
    test('refreshes once and retries the request', () async {
      await signIn();
      when(remoteDataSource.refreshAccessToken('refresh')).thenAnswer(
        (_) async => const PsnTokens(
          accessToken: 'second-token',
          refreshToken: 'next-refresh',
          expiresIn: Duration(hours: 1),
        ),
      );
      final sent = <http.Request>[];
      final client = clientOver((request) async {
        sent.add(request);
        // Only the call carrying the stale token is refused.
        return request.headers['Authorization'] == 'Bearer the-token'
            ? http.Response('nope', 401)
            : http.Response('{"ok":true}', 200);
      });

      final response = await client.get(url);

      expect(response.statusCode, 200);
      expect(sent, hasLength(2));
      expect(sent.last.headers['Authorization'], 'Bearer second-token');
      expect(sent.last.url, url);
    });

    test('gives the 401 back when the refresh fails too', () async {
      await signIn();
      when(remoteDataSource.refreshAccessToken(any))
          .thenThrow(StateError('revoked'));
      var calls = 0;
      final client = clientOver((_) async {
        calls++;
        return http.Response('nope', 401);
      });

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(calls, 1, reason: 'there is no token left to retry with');
      expect(tokens.session.value, isNull);
    });

    test('does not retry a second time', () async {
      await signIn();
      when(remoteDataSource.refreshAccessToken(any)).thenAnswer(
        (_) async => const PsnTokens(
          accessToken: 'second-token',
          refreshToken: 'next-refresh',
          expiresIn: Duration(hours: 1),
        ),
      );
      var calls = 0;
      final client = clientOver((_) async {
        calls++;
        return http.Response('nope', 401);
      });

      final response = await client.get(url);

      expect(response.statusCode, 401);
      expect(calls, 2);
    });
  });
}
