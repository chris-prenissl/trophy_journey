class const PsnTokens({
  required final String accessToken,
  required final String refreshToken,
  required final Duration expiresIn,
});

abstract interface class PsnRemoteDataSource {
  Future<PsnTokens> exchangeCode(String code);

  Future<PsnTokens> refreshAccessToken(String refreshToken);
}
