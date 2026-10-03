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

abstract interface class PsnRemoteDataSource {
  Future<PsnTokens> exchangeCode(String code);

  Future<PsnTokens> refreshAccessToken(String refreshToken);
}
