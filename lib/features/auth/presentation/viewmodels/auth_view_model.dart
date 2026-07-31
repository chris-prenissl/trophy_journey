import 'package:flutter/foundation.dart';

import '../../domain/entities/auth_session.dart';
import '../../domain/usecases/get_current_session.dart';
import '../../domain/usecases/login_with_authorization_code.dart';
import '../../domain/usecases/logout.dart';

class AuthViewModel extends ChangeNotifier {
  AuthViewModel({
    required this._loginWithAuthorizationCode,
    required this._logout,
    required this._getCurrentSession,
  });

  final LoginWithAuthorizationCodeUseCase _loginWithAuthorizationCode;
  final LogoutUseCase _logout;
  final GetCurrentSessionUseCase _getCurrentSession;

  AuthSession? _session;
  bool _loading = false;
  String? _error;

  AuthSession? get session => _session;
  bool get loading => _loading;
  String? get error => _error;

  Future<void> loginWithAuthorizationCode(String code) async {
    _loading = true;
    _error = null;
    notifyListeners();

    try {
      _session = await _loginWithAuthorizationCode(code);
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    _loading = true;
    notifyListeners();

    try {
      await _logout();
      _session = null;
      _error = null;
    } catch (e) {
      _error = e.toString();
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<void> loadStoredSession() async {
    try {
      _session = await _getCurrentSession();
    } catch (e) {
      _error = e.toString();
    }
    notifyListeners();
  }
}
