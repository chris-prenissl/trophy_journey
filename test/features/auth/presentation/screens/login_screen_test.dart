import 'dart:async';

import 'package:flutter_test/flutter_test.dart';
import 'package:material_ui/material_ui.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:trophy_journey/features/auth/domain/entities/auth_session.dart';
import 'package:trophy_journey/features/auth/domain/repositories/auth_repository.dart';
import 'package:trophy_journey/features/auth/presentation/screens/login_screen.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';

import 'login_screen_test.mocks.dart';

AuthSession fakeSession({
  Duration expiresIn = const Duration(hours: 1),
  String token = 'access',
}) => AuthSession(
  userId: 'psn_user',
  accessToken: token,
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(expiresIn),
);

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  late MockAuthRepository repository;
  late ValueNotifier<AuthSession?> session;
  late AuthSession signedIn;
  late AuthViewModel viewModel;

  setUp(() {
    repository = MockAuthRepository();
    session = ValueNotifier(null);
    signedIn = fakeSession();
    when(repository.session).thenReturn(session);
    when(repository.isAuthenticated)
        .thenAnswer((_) => session.value?.isValid ?? false);
    when(repository.loadStoredSession()).thenAnswer((_) async {});
    when(repository.signIn()).thenAnswer((_) async => session.value = signedIn);
    when(repository.signOut()).thenAnswer((_) async => session.value = null);
    viewModel = AuthViewModel(authRepository: repository);
  });

  tearDown(() {
    viewModel.dispose();
    session.dispose();
  });

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

    verify(repository.signIn()).called(1);
    expect(viewModel.session, signedIn);
  });

  testWidgets('shows a spinner and disables the button while signing in', (
    tester,
  ) async {
    final gate = Completer<void>();
    when(repository.signIn()).thenAnswer((_) async {
      await gate.future;
      session.value = signedIn;
    });
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
    when(repository.signIn()).thenThrow(StateError('invalid_grant'));
    await pumpScreen(tester);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid_grant'), findsOneWidget);
    expect(viewModel.session, isNull);

    when(repository.signIn()).thenAnswer((_) async => session.value = signedIn);
    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('invalid_grant'), findsNothing);
    expect(viewModel.session, signedIn);
  });

  testWidgets('shows no error when the user cancels', (tester) async {
    when(repository.signIn()).thenThrow(const SignInCancelledException());
    await pumpScreen(tester);

    await tester.tap(signInButton);
    await tester.pumpAndSettle();

    expect(find.textContaining('Error'), findsNothing);
    expect(signInButton, findsOneWidget);
  });
}
