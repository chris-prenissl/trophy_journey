import 'package:flutter_test/flutter_test.dart';
import 'package:trophy_journey/features/auth/domain/entities/auth_session.dart';

AuthSession sessionExpiring(Duration fromNow) => AuthSession(
  userId: 'psn_user',
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(fromNow),
);

void main() {
  test('is valid while the expiry is in the future', () {
    final session = sessionExpiring(const Duration(hours: 1));

    expect(session.isExpired, isFalse);
    expect(session.isValid, isTrue);
  });

  test('is expired once the expiry has passed', () {
    final session = sessionExpiring(const Duration(hours: -1));

    expect(session.isExpired, isTrue);
    expect(session.isValid, isFalse);
  });
}
