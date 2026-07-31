import 'dart:async';

import 'package:final_fantasy_guide/core/auth_store.dart';
import 'package:final_fantasy_guide/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:final_fantasy_guide/features/auth/domain/entities/auth_session.dart';
import 'package:final_fantasy_guide/features/auth/domain/repositories/auth_repository.dart';
import 'package:final_fantasy_guide/features/auth/domain/usecases/get_current_session.dart';
import 'package:final_fantasy_guide/features/auth/domain/usecases/login_with_authorization_code.dart';
import 'package:final_fantasy_guide/features/auth/domain/usecases/logout.dart';
import 'package:final_fantasy_guide/features/auth/presentation/screens/login_screen.dart';
import 'package:final_fantasy_guide/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/annotations.dart';
import 'package:mockito/mockito.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../../../util/fake_webview_platform.dart';
import 'login_screen_test.mocks.dart';

final session = AuthSession(
  userId: 'psn_user',
  accessToken: 'access',
  refreshToken: 'refresh',
  expiresAt: DateTime.now().add(const Duration(hours: 1)),
);

/// The url Sony bounces to once the user has signed in.
const redirectUrl =
    '${PSNRemoteDataSourceImpl.redirectUri}/?code=v3.the-code';

@GenerateNiceMocks([MockSpec<AuthRepository>()])
void main() {
  late MockAuthRepository repository;
  late AuthStore store;
  late AuthViewModel viewModel;
  late FakeWebViewPlatform platform;

  setUp(() {
    platform = FakeWebViewPlatform.install();
    repository = MockAuthRepository();
    when(repository.getStoredSession()).thenAnswer((_) async => null);
    when(repository.saveSession(any)).thenAnswer((_) => Future.value());
    when(repository.logout()).thenAnswer((_) => Future.value());
    store = AuthStore(repository: repository);
    viewModel = AuthViewModel(
      loginWithAuthorizationCode: LoginWithAuthorizationCodeUseCase(repository),
      logout: LogoutUseCase(repository),
      getCurrentSession: GetCurrentSessionUseCase(repository),
    );
  });

  tearDown(() {
    viewModel.dispose();
    store.dispose();
  });

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(viewModel: viewModel, authStore: store)),
    );
    await tester.pump();

    platform.delegate.finishPage(
      PSNRemoteDataSourceImpl.authorizeUri.toString(),
    );
    await tester.pump();
  }

  group('the page it opens', () {
    testWidgets('opens the PSN sign in page, not the marketing site', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(platform.loadedUrls, [
        PSNRemoteDataSourceImpl.authorizeUri.toString(),
      ]);
      expect(platform.loadedUrls.single, contains('/oauth/authorize'));
      expect(platform.loadedUrls.single, isNot(contains('www.playstation.com')));
    });
  });

  group('navigation', () {
    testWidgets('lets the sign in pages load', (tester) async {
      await pumpScreen(tester);

      final decision = await platform.delegate.navigateTo(
        'https://my.account.sony.com/sonyacct/signin/',
      );

      expect(decision, NavigationDecision.navigate);
      verifyNever(repository.loginWithAuthorizationCode(any));
    });

    testWidgets('blocks the redirect the web view cannot follow', (
      tester,
    ) async {
      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) async => session);
      await pumpScreen(tester);

      final decision = await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(decision, NavigationDecision.prevent);
    });
  });

  group('completing the login', () {
    testWidgets('trades the code off the redirect for a session', (
      tester,
    ) async {
      when(repository.loginWithAuthorizationCode('v3.the-code'))
          .thenAnswer((_) async => session);
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      verify(repository.loginWithAuthorizationCode('v3.the-code')).called(1);
      expect(store.currentSession, session);
      expect(store.isAuthenticated, isTrue);
    });

    testWidgets('exchanges the code once when the redirect repeats', (
      tester,
    ) async {
      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) async => session);
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      verify(repository.loginWithAuthorizationCode(any)).called(1);
    });

    testWidgets('ignores a redirect that carries no code', (tester) async {
      await pumpScreen(tester);

      final decision = await platform.delegate.navigateTo(
        '${PSNRemoteDataSourceImpl.redirectUri}/?error=access_denied',
      );
      await tester.pumpAndSettle();

      expect(decision, NavigationDecision.prevent);
      verifyNever(repository.loginWithAuthorizationCode(any));
      expect(store.currentSession, isNull);
    });
  });

  group('when the exchange fails', () {
    setUp(() {
      when(repository.loginWithAuthorizationCode(any))
          .thenThrow(StateError('invalid_grant'));
    });

    testWidgets('stays signed out and shows the reason', (tester) async {
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(store.currentSession, isNull);
      expect(store.isAuthenticated, isFalse);
      expect(find.textContaining('invalid_grant'), findsOneWidget);
    });

    testWidgets('reopens the sign in page so it can be retried', (
      tester,
    ) async {
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(platform.loadedUrls, hasLength(2));
      expect(
        platform.loadedUrls.last,
        PSNRemoteDataSourceImpl.authorizeUri.toString(),
      );

      when(repository.loginWithAuthorizationCode(any))
          .thenAnswer((_) async => session);
      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(store.currentSession, session);
    });
  });

  group('progress', () {
    testWidgets('shows a spinner while a page is loading', (tester) async {
      await pumpScreen(tester);

      platform.delegate.startPage('https://my.account.sony.com/');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsOneWidget);

      platform.delegate.finishPage('https://my.account.sony.com/');
      await tester.pump();

      expect(find.byType(CircularProgressIndicator), findsNothing);
    });
  });
}
