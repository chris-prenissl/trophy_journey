import 'package:flutter/foundation.dart';

import 'package:final_fantasy_guide/features/auth/domain/entities/auth_session.dart';
import 'package:final_fantasy_guide/features/auth/domain/repositories/auth_repository.dart';

class AuthStore extends ChangeNotifier {
  AuthStore({required this._repository});

  final AuthRepository _repository;

  AuthSession? _currentSession;

  AuthSession? get currentSession => _currentSession;

  bool get isAuthenticated => _currentSession != null && _currentSession!.isValid;

  Future<void> loadSession() async {
    try {
      _currentSession = await _repository.getStoredSession();
    } catch (e) {
      _currentSession = null;
    }
    notifyListeners();
  }

  Future<void> setSession(AuthSession session) async {
    _currentSession = session;
    await _repository.saveSession(session);
    notifyListeners();
  }

  Future<void> clearSession() async {
    _currentSession = null;
    await _repository.clearSession();
    notifyListeners();
  }

  Future<void> refreshTokenIfNeeded() async {
    if (_currentSession == null) return;
    
    if (_currentSession!.isValid) return;

    try {
      _currentSession = await _repository.refreshToken(_currentSession!.refreshToken);
      notifyListeners();
    } catch (_) {
      await clearSession();
    }
  }
}
