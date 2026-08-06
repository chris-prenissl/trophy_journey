import 'package:flutter/widgets.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

class FakeWebViewPlatform extends WebViewPlatform {
  FakeWebViewPlatform._();

  factory FakeWebViewPlatform.install() {
    final platform = FakeWebViewPlatform._();
    WebViewPlatform.instance = platform;
    return platform;
  }

  late FakeWebViewController controller;
  late FakeNavigationDelegate delegate;

  List<String> get loadedUrls => controller.loadedUrls;

  @override
  PlatformWebViewController createPlatformWebViewController(
    PlatformWebViewControllerCreationParams params,
  ) => controller = FakeWebViewController(params);

  @override
  PlatformNavigationDelegate createPlatformNavigationDelegate(
    PlatformNavigationDelegateCreationParams params,
  ) => delegate = FakeNavigationDelegate(params);

  @override
  PlatformWebViewWidget createPlatformWebViewWidget(
    PlatformWebViewWidgetCreationParams params,
  ) => FakeWebViewWidget(params);
}

class FakeWebViewController extends PlatformWebViewController {
  FakeWebViewController(super.params) : super.implementation();

  final loadedUrls = <String>[];

  @override
  Future<void> loadRequest(LoadRequestParams params) async {
    loadedUrls.add(params.uri.toString());
  }

  @override
  Future<void> setJavaScriptMode(JavaScriptMode javaScriptMode) async {}

  @override
  Future<void> setPlatformNavigationDelegate(
    PlatformNavigationDelegate handler,
  ) async {}
}

class FakeNavigationDelegate extends PlatformNavigationDelegate {
  FakeNavigationDelegate(super.params) : super.implementation();

  NavigationRequestCallback? _onNavigationRequest;
  PageEventCallback? _onPageStarted;
  PageEventCallback? _onPageFinished;
  WebResourceErrorCallback? _onWebResourceError;

  Future<NavigationDecision> navigateTo(String url) async {
    return _onNavigationRequest!(
      NavigationRequest(url: url, isMainFrame: true),
    );
  }

  void startPage(String url) => _onPageStarted?.call(url);

  void finishPage(String url) => _onPageFinished?.call(url);

  void failLoad({
    required int errorCode,
    String description = 'Loading frame',
    bool isForMainFrame = true,
    String? url,
  }) => _onWebResourceError?.call(
    WebResourceError(
      errorCode: errorCode,
      description: description,
      isForMainFrame: isForMainFrame,
      url: url,
    ),
  );

  @override
  Future<void> setOnNavigationRequest(
    NavigationRequestCallback onNavigationRequest,
  ) async {
    _onNavigationRequest = onNavigationRequest;
  }

  @override
  Future<void> setOnPageStarted(PageEventCallback onPageStarted) async {
    _onPageStarted = onPageStarted;
  }

  @override
  Future<void> setOnPageFinished(PageEventCallback onPageFinished) async {
    _onPageFinished = onPageFinished;
  }

  @override
  Future<void> setOnWebResourceError(
    WebResourceErrorCallback onWebResourceError,
  ) async {
    _onWebResourceError = onWebResourceError;
  }
}

class FakeWebViewWidget extends PlatformWebViewWidget {
  FakeWebViewWidget(super.params) : super.implementation();

  @override
  Widget build(BuildContext context) => const SizedBox.expand();
}
