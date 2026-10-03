import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';
import 'package:trophy_journey/features/auth/domain/usecases/load_stored_session_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_in_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/watch_auth_session_use_case.dart';
import 'package:trophy_journey/features/auth/presentation/screens/login_screen.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';

import '../../../../util/fake_auth_repository.dart';

void main() {
  late FakeAuthRepository repository;
  late AuthViewModel viewModel;

  setUp(() {
    repository = FakeAuthRepository();
    viewModel = AuthViewModel(
      watchSession: WatchAuthSessionUseCase(repository),
      loadStoredSessionUseCase: LoadStoredSessionUseCase(repository),
      signInUseCase: SignInUseCase(repository),
      signOutUseCase: SignOutUseCase(repository),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> pumpScreen(WidgetTester tester) =>
      tester.pumpWidget(MaterialApp(home: LoginScreen(viewModel: viewModel)));

  final signInButton = find.text('Sign in with PlayStation');

  testWidgets('offers a sign in button', (tester) async {
    await pumpScreen(tester);

    expect(signInButton, findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('signs in when the button is tapped', (tester) async {
    await pumpScreen(tester);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(repository.signInCount, 1);
    expect(viewModel.session, repository.signInResult);
  });

  testWidgets('shows a spinner and disables the button while signing in', (
    tester,
  ) async {
    final gate = Completer<void>();
    repository.signInGate = gate;
    await pumpScreen(tester);

    await tester.tap(signInButton);
    await tester.pump();

    expect(find.byType(CircularProgressIndicator), findsOneWidget);
    expect(
      tester.widget<FilledButton>(find.byType(FilledButton)).onPressed,
      isNull,
    );

    gate.complete();
    await tester.pumpAndSettle();

    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('shows the reason when sign in fails and allows a retry', (
    tester,
  ) async {
    repository.signInError = StateError('invalid_grant');
    await pumpScreen(tester);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid_grant'), findsOneWidget);
    expect(viewModel.session, isNull);

    repository.signInError = null;
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid_grant'), findsNothing);
    expect(viewModel.session, repository.signInResult);
  });

  testWidgets('shows no error when the user cancels', (tester) async {
    repository.signInError = const SignInCancelledException();
    await pumpScreen(tester);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Error'), findsNothing);
    expect(signInButton, findsOneWidget);
  });
}
