class const AuthSession({
  required final String userId,
  required final String accessToken,
  required final String refreshToken,
  required final DateTime expiresAt,
}) {
  bool get isExpired => DateTime.now().isAfter(expiresAt);

  bool get isValid => !isExpired;
}
