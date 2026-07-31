import 'dart:convert';

import 'package:trophy_journey/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

const tokenUrl = 'https://example.test/token';

const tokenResponse = '{"access_token":"access","refresh_token":"refresh",'
    '"expires_in":3600,"token_type":"bearer"}';

({PSNRemoteDataSourceImpl dataSource, List<http.Request> requests})
buildDataSource({
  String body = tokenResponse,
  int statusCode = 200,
}) {
  final requests = <http.Request>[];
  final client = MockClient((request) async {
    requests.add(request);
    return http.Response(body, statusCode);
  });
  return (
    dataSource: PSNRemoteDataSourceImpl(client: client, tokenUrl: tokenUrl),
    requests: requests,
  );
}

void main() {
  group('authorizeUri', () {
    test('points at the PSN sign in page', () {
      final uri = PSNRemoteDataSourceImpl.authorizeUri;

      expect(uri.host, 'ca.account.sony.com');
      expect(uri.path, '/api/authz/v3/oauth/authorize');
    });

    test('asks for a code for the mobile client', () {
      final query = PSNRemoteDataSourceImpl.authorizeUri.queryParameters;

      expect(query['response_type'], 'code');
      expect(query['client_id'], PSNRemoteDataSourceImpl.clientId);
      expect(query['redirect_uri'], PSNRemoteDataSourceImpl.redirectUri);
      expect(query['access_type'], 'offline');
    });
  });

  group('exchangeCode', () {
    test('posts the code as an authorization code grant', () async {
      final (:dataSource, :requests) = buildDataSource();

      await dataSource.exchangeCode('v3.code');

      final body = Uri.splitQueryString(requests.single.body);
      expect(body['code'], 'v3.code');
      expect(body['grant_type'], 'authorization_code');
      expect(body['redirect_uri'], PSNRemoteDataSourceImpl.redirectUri);
      expect(requests.single.url.toString(), tokenUrl);
    });

    test('authenticates as the official app', () async {
      final (:dataSource, :requests) = buildDataSource();

      await dataSource.exchangeCode('v3.code');

      final expected = base64Encode(
        utf8.encode(
          '${PSNRemoteDataSourceImpl.clientId}:'
          '${PSNRemoteDataSourceImpl.clientSecret}',
        ),
      );
      expect(requests.single.headers['Authorization'], 'Basic $expected');
    });

    test('reads the tokens and lifetime off the response', () async {
      final (:dataSource, requests: _) = buildDataSource();

      final tokens = await dataSource.exchangeCode('v3.code');

      expect(tokens.accessToken, 'access');
      expect(tokens.refreshToken, 'refresh');
      expect(tokens.expiresIn, const Duration(seconds: 3600));
    });

    test('throws when Sony rejects the code', () async {
      final (:dataSource, requests: _) = buildDataSource(
        body: '{"error":"invalid_grant"}',
        statusCode: 400,
      );

      await expectLater(
        dataSource.exchangeCode('v3.code'),
        throwsA(isA<Exception>()),
      );
    });
  });

  group('refreshAccessToken', () {
    test('posts a refresh token grant', () async {
      final (:dataSource, :requests) = buildDataSource();

      await dataSource.refreshAccessToken('old-refresh');

      final body = Uri.splitQueryString(requests.single.body);
      expect(body['refresh_token'], 'old-refresh');
      expect(body['grant_type'], 'refresh_token');
      expect(body['scope'], 'psn:mobile.v2.core psn:clientapp');
    });

    test('throws when the refresh token is no longer good', () async {
      final (:dataSource, requests: _) = buildDataSource(
        body: '{"error":"invalid_grant"}',
        statusCode: 400,
      );

      await expectLater(
        dataSource.refreshAccessToken('old-refresh'),
        throwsA(isA<Exception>()),
      );
    });
  });
}
