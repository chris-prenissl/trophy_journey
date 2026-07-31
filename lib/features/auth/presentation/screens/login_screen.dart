import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

import '../../../../core/auth_store.dart';
import '../../data/datasources/psn_remote_data_source.dart';
import '../viewmodels/auth_view_model.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({
    super.key,
    required this.viewModel,
    required this.authStore,
  });

  final AuthViewModel viewModel;
  final AuthStore authStore;

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
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Error: ${error.description}')),
            );
          },
        ),
      )
      ..loadRequest(PSNRemoteDataSourceImpl.authorizeUri);
  }

  /// Sony finishes the sign in by redirecting to a custom scheme the web view
  /// cannot load, so the authorization code has to be taken off the request
  /// before it is followed.
  NavigationDecision _onNavigationRequest(NavigationRequest request) {
    if (!request.url.startsWith(PSNRemoteDataSourceImpl.redirectUri)) {
      return NavigationDecision.navigate;
    }

    final code = Uri.tryParse(request.url)?.queryParameters['code'];
    if (code != null && code.isNotEmpty && !_exchangingCode) {
      _exchangingCode = true;
      _completeLogin(code);
    }
    return NavigationDecision.prevent;
  }

  Future<void> _completeLogin(String code) async {
    await widget.viewModel.loginWithAuthorizationCode(code);
    if (!mounted) return;

    final session = widget.viewModel.session;
    if (session == null) {
      _exchangingCode = false;
      _webViewController.loadRequest(PSNRemoteDataSourceImpl.authorizeUri);
      return;
    }

    await widget.authStore.setSession(session);
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
                    padding: const EdgeInsets.all(16),
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
