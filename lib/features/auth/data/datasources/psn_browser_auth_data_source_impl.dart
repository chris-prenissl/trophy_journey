import 'package:flutter/services.dart';
import 'package:flutter_web_auth_2/flutter_web_auth_2.dart';

import '../../domain/repositories/auth_repository.dart';
import 'psn_browser_auth_data_source.dart';
import 'psn_remote_data_source_impl.dart';

typedef BrowserAuthenticate = Future<String> Function({
  required String url,
  required String callbackUrlScheme,
});

class PsnBrowserAuthDataSourceImpl([BrowserAuthenticate? authenticate])
    implements PsnBrowserAuthDataSource {
  final BrowserAuthenticate _authenticate = authenticate ?? _systemBrowser;

  static Future<String> _systemBrowser({
    required String url,
    required String callbackUrlScheme,
  }) => FlutterWebAuth2.authenticate(
    url: url,
    callbackUrlScheme: callbackUrlScheme,
  );

  @override
  Future<String> authorize() async {
    final String redirect;
    try {
      redirect = await _authenticate(
        url: PsnRemoteDataSourceImpl.authorizeUri.toString(),
        callbackUrlScheme: Uri.parse(PsnRemoteDataSourceImpl.redirectUri)
            .scheme,
      );
    } on PlatformException catch (e) {
      if (e.code == 'CANCELED') {
        throw const SignInCancelledException();
      }
      rethrow;
    }

    final code = Uri.tryParse(redirect)?.queryParameters['code'];
    if (code == null || code.isEmpty) {
      throw Exception('PlayStation Network did not return a sign in code');
    }
    return code;
  }
}
