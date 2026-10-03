import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/repositories/auth_repository.dart';

class AuthViewModel({required final AuthRepository _authRepository})
    extends ChangeNotifier {
  this {
    _authSession.addListener(notifyListeners);
  }

  final ValueListenable<AuthSession?> _authSession = _authRepository.session;
  bool _loading = false;
  String? _error;

  AuthSession? get session => _authSession.value;

  bool get isAuthenticated => _authSession.value?.isValid == true;

  bool get loading => _loading;

  String? get error => _error;

  Future<void> loadStoredSession() async {
    try {
      await _authRepository.loadStoredSession();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> signIn() async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _authRepository.signIn();
    } on SignInCancelledException {
      debugPrint('Sign in cancelled by the user');
    } catch (e, stackTrace) {
      debugPrint('Sign in failed: $e\n$stackTrace');
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _authRepository.signOut();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _authSession.removeListener(notifyListeners);
    super.dispose();
  }
}
