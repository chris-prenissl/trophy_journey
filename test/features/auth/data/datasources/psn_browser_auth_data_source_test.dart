import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_browser_auth_data_source_impl.dart';
import 'package:trophy_journey/features/auth/data/datasources/psn_remote_data_source_impl.dart';

void main() {
  late List<({String url, String scheme})> calls;

  PsnBrowserAuthDataSourceImpl dataSource(Future<String> Function() result) {
    calls = [];
    return PsnBrowserAuthDataSourceImpl(({
      required String url,
      required String callbackUrlScheme,
    }) {
      calls.add((url: url, scheme: callbackUrlScheme));
      return result();
    });
  }

  test(
    'opens the PSN authorize page and listens for its redirect scheme',
    () async {
      final source = dataSource(
        () async => '${PsnRemoteDataSourceImpl.redirectUri}?code=v3.the-code',
      );

      await source.authorize();

      expect(calls.single.url, PsnRemoteDataSourceImpl.authorizeUri.toString());
      expect(calls.single.url, contains('/oauth/authorize'));
      expect(calls.single.scheme, 'com.scee.psxandroid.scecompcall');
    },
  );

  test('returns the code off the redirect', () async {
    final source = dataSource(
      () async => '${PsnRemoteDataSourceImpl.redirectUri}?code=v3.the-code',
    );

    expect(await source.authorize(), 'v3.the-code');
  });

  test('throws when the redirect carries no code', () async {
    final source = dataSource(
      () async => '${PsnRemoteDataSourceImpl.redirectUri}?error=access_denied',
    );

    await expectLater(source.authorize(), throwsException);
  });

  test('reports a closed browser as a cancelled sign in', () async {
    final source = dataSource(
      () async => throw PlatformException(code: 'CANCELED'),
    );

    await expectLater(
      source.authorize(),
      throwsA(isA<SignInCancelledException>()),
    );
  });

  test('passes other platform failures through', () async {
    final source = dataSource(
      () async => throw PlatformException(code: 'FAILED'),
    );

    await expectLater(source.authorize(), throwsA(isA<PlatformException>()));
  });
}
