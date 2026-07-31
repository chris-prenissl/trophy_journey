import 'dart:convert';

import 'package:http/http.dart' as http;

/// The token set Sony hands out in exchange for an authorization code.
class PsnTokens {
  const PsnTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresIn,
  });

  final String accessToken;
  final String refreshToken;
  final Duration expiresIn;
}

abstract interface class PSNRemoteDataSource {
  Future<PsnTokens> exchangeCode(String code);

  Future<PsnTokens> refreshAccessToken(String refreshToken);
}

class PSNRemoteDataSourceImpl implements PSNRemoteDataSource {
  PSNRemoteDataSourceImpl({http.Client? client, this.tokenUrl = _tokenUrl})
    : _client = client ?? http.Client();

  /// Credentials of the official PlayStation app. Sony only issues mobile
  /// tokens to this client id, so the sign in has to impersonate it.
  static const clientId = '09515159-7237-4370-9b40-3806e67c0891';
  static const clientSecret = 'ucPjka5tntB2KqsP';

  /// Sony ends a successful sign in by redirecting here with a `code` query
  /// parameter. The scheme is not loadable, so the login web view has to
  /// intercept the navigation instead of following it.
  static const redirectUri = 'com.scee.psxandroid.scecompcall://redirect';

  static const _scope = 'psn:mobile.v2.core psn:clientapp';
  static const _tokenUrl =
      'https://ca.account.sony.com/api/authz/v3/oauth/token';

  /// The sign in page the login web view opens.
  static Uri get authorizeUri => Uri.https(
    'ca.account.sony.com',
    '/api/authz/v3/oauth/authorize',
    {
      'access_type': 'offline',
      'client_id': clientId,
      'redirect_uri': redirectUri,
      'response_type': 'code',
      'scope': _scope,
    },
  );

  final http.Client _client;
  final String tokenUrl;

  @override
  Future<PsnTokens> exchangeCode(String code) => _requestTokens({
    'code': code,
    'redirect_uri': redirectUri,
    'grant_type': 'authorization_code',
    'token_format': 'jwt',
  });

  @override
  Future<PsnTokens> refreshAccessToken(String refreshToken) => _requestTokens({
    'refresh_token': refreshToken,
    'grant_type': 'refresh_token',
    'scope': _scope,
    'token_format': 'jwt',
  });

  Future<PsnTokens> _requestTokens(Map<String, String> body) async {
    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));
    final response = await _client.post(
      Uri.parse(tokenUrl),
      headers: {
        'Authorization': 'Basic $credentials',
        'Content-Type': 'application/x-www-form-urlencoded',
      },
      body: body,
    );

    if (response.statusCode != 200) {
      throw Exception(
        'PlayStation Network rejected the sign in (${response.statusCode})',
      );
    }

    final json = jsonDecode(response.body) as Map<String, dynamic>;
    return PsnTokens(
      accessToken: json['access_token'] as String,
      refreshToken: json['refresh_token'] as String,
      expiresIn: Duration(seconds: (json['expires_in'] as num).toInt()),
    );
  }
}
