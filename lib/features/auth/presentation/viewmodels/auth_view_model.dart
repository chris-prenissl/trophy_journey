import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/load_stored_session_use_case.dart';
import '../../domain/usecases/sign_in_with_authorization_code_use_case.dart';
import '../../domain/usecases/sign_out_use_case.dart';
import '../../domain/usecases/watch_auth_session_use_case.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required WatchAuthSessionUseCase watchSession,
    required this._loadStoredSessionUseCase,
    required this._signInWithAuthorizationCodeUseCase,
    required this._signOutUseCase,
  }) : _authSession = watchSession() {
    _authSession.addListener(notifyListeners);
  }

  final ValueListenable<AuthSession?> _authSession;
  final LoadStoredSessionUseCase _loadStoredSessionUseCase;
  final SignInWithAuthorizationCodeUseCase _signInWithAuthorizationCodeUseCase;
  final SignOutUseCase _signOutUseCase;

  bool _loading = false;
  String? _error;

  AuthSession? get session => _authSession.value;

  bool get isAuthenticated => _authSession.value?.isValid == true;

  bool get loading => _loading;

  String? get error => _error;

  Future<void> loadStoredSession() async {
    try {
      await _loadStoredSessionUseCase();
    } catch (e) {
      _error = e.toString();
      notifyListeners();
    }
  }

  Future<void> signInWithAuthorizationCode(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      await _signInWithAuthorizationCodeUseCase(code);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> signOut() async {
    try {
      await _signOutUseCase();
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
