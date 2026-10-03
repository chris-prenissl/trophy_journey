import 'package:flutter/foundation.dart';

import '../entities/auth_session.dart';
import '../repositories/auth_repository.dart';

class const WatchAuthSessionUseCase(final AuthRepository _repository) {
  ValueListenable<AuthSession?> call() => _repository.session;
}
