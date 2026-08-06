import 'package:webview_flutter/webview_flutter.dart';

abstract interface class PsnWebSessionDataSource {
  Future<void> clear();
}

class PsnWebSessionDataSourceImpl implements PsnWebSessionDataSource {
  PsnWebSessionDataSourceImpl([WebViewCookieManager? cookieManager])
    : _cookieManager = cookieManager ?? WebViewCookieManager();

  final WebViewCookieManager _cookieManager;

  @override
  Future<void> clear() => _cookieManager.clearCookies();
}
