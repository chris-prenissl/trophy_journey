import 'package:material_ui/material_ui.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../data/datasources/psn_remote_data_source.dart';
import '../viewmodels/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key, required this.viewModel});

  final AuthViewModel viewModel;

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  late final WebViewController _webViewController;
  bool _isLoading = true;
  bool _exchangingCode = false;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _webViewController = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onNavigationRequest: _onNavigationRequest,
          onPageStarted: (_) => setState(() => _isLoading = true),
          onPageFinished: (_) => setState(() => _isLoading = false),
          onWebResourceError: (error) {
            if (!mounted || _isSelfInflicted(error)) {
              return;
            }
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(PsnRemoteDataSourceImpl.authorizeUri);
  }

  static const _cancellationCodes = {-999, 102};

  bool _isSelfInflicted(WebResourceError error) =>
      error.isForMainFrame == false ||
      _cancellationCodes.contains(error.errorCode) ||
      (error.url?.startsWith(PsnRemoteDataSourceImpl.redirectUri) == true);

  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.url.startsWith(PsnRemoteDataSourceImpl.redirectUri)) {
      return .navigate;
    }

    final code = Uri.tryParse(request.url)?.queryParameters['code'];
    if (code != null && code.isNotEmpty && !_exchangingCode) {
      _exchangingCode = true;
      _tryLogin(code);
    }
    return .prevent;
  }

  Future<void> _tryLogin(String code) async {
    await widget.viewModel.signInWithAuthorizationCode(code);
    if (!mounted || widget.viewModel.session != null) {
      return;
    }

    _exchangingCode = false;
    _webViewController.loadRequest(PsnRemoteDataSourceImpl.authorizeUri);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('PlayStation Network Login'),
        centerTitle: true,
      ),
      body: ListenableBuilder(
        listenable: widget.viewModel,
        builder: (context, _) {
          final error = widget.viewModel.error;
          return Stack(
            children: [
              WebViewWidget(controller: _webViewController),
              if (_isLoading || widget.viewModel.loading)
                const Center(child: CircularProgressIndicator()),
              if (error != null)
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Container(
                    color: Colors.red,
                    padding: const .all(16),
                    child: Text(
                      'Error: $error',
                      style: const TextStyle(color: Colors.white),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }
}
