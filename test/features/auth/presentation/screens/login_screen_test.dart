import 'package:trophy_journey/features/auth/data/datasources/psn_remote_data_source.dart';
import 'package:trophy_journey/features/auth/domain/usecases/load_stored_session_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_in_with_authorization_code_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/sign_out_use_case.dart';
import 'package:trophy_journey/features/auth/domain/usecases/watch_auth_session_use_case.dart';
import 'package:trophy_journey/features/auth/presentation/screens/login_screen.dart';
import 'package:trophy_journey/features/auth/presentation/viewmodels/auth_view_model.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:webview_flutter_platform_interface/webview_flutter_platform_interface.dart';

import '../../../../util/fake_auth_repository.dart';
import '../../../../util/fake_webview_platform.dart';

/// The url Sony bounces to once the user has signed in.
const redirectUrl = '${PsnRemoteDataSourceImpl.redirectUri}/?code=v3.the-code';

void main() {
  late FakeAuthRepository repository;
  late AuthViewModel viewModel;
  late FakeWebViewPlatform platform;

  setUp(() {
    platform = FakeWebViewPlatform.install();
    repository = FakeAuthRepository();
    viewModel = AuthViewModel(
      watchSession: WatchAuthSessionUseCase(repository),
      loadStoredSessionUseCase: LoadStoredSessionUseCase(repository),
      signInWithAuthorizationCodeUseCase: SignInWithAuthorizationCodeUseCase(
        repository,
      ),
      signOutUseCase: SignOutUseCase(repository),
    );
  });

  tearDown(() => viewModel.dispose());

  Future<void> pumpScreen(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(home: LoginScreen(viewModel: viewModel)),
    );
    await tester.pump();

    platform.delegate.finishPage(
      PsnRemoteDataSourceImpl.authorizeUri.toString(),
    );
    await tester.pump();
  }

  group('the page it opens', () {
    testWidgets('opens the PSN sign in page, not the marketing site', (
      tester,
    ) async {
      await pumpScreen(tester);

      expect(platform.loadedUrls, [
        PsnRemoteDataSourceImpl.authorizeUri.toString(),
      ]);
      expect(platform.loadedUrls.single, contains('/oauth/authorize'));
      expect(
        platform.loadedUrls.single,
        isNot(contains('www.playstation.com')),
      );
    });
  });

  group('navigation', () {
    testWidgets('lets the sign in pages load', (tester) async {
      await pumpScreen(tester);

      final decision = await platform.delegate.navigateTo(
        'https://my.account.sony.com/sonyacct/signin/',
      );

      expect(decision, NavigationDecision.navigate);
      expect(repository.signedInCodes, isEmpty);
    });

    testWidgets('blocks the redirect the web view cannot follow', (
      tester,
    ) async {
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
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(repository.signedInCodes, ['v3.the-code']);
      expect(viewModel.session, repository.signInResult);
      expect(viewModel.isAuthenticated, isTrue);
    });

    testWidgets('exchanges the code once when the redirect repeats', (
      tester,
    ) async {
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(repository.signedInCodes, hasLength(1));
    });

    testWidgets('ignores a redirect that carries no code', (tester) async {
      await pumpScreen(tester);

      final decision = await platform.delegate.navigateTo(
        '${PsnRemoteDataSourceImpl.redirectUri}/?error=access_denied',
      );
      await tester.pumpAndSettle();

      expect(decision, NavigationDecision.prevent);
      expect(repository.signedInCodes, isEmpty);
      expect(viewModel.session, isNull);
    });
  });

  group('when the exchange fails', () {
    setUp(() => repository.signInError = StateError('invalid_grant'));

    testWidgets('stays signed out and shows the reason', (tester) async {
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(viewModel.session, isNull);
      expect(viewModel.isAuthenticated, isFalse);
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
        PsnRemoteDataSourceImpl.authorizeUri.toString(),
      );

      repository.signInError = null;
      await platform.delegate.navigateTo(redirectUrl);
      await tester.pumpAndSettle();

      expect(viewModel.session, repository.signInResult);
    });
  });

  group('load failures', () {
    testWidgets('stays quiet about the redirect it blocked itself', (
      tester,
    ) async {
      await pumpScreen(tester);

      await platform.delegate.navigateTo(redirectUrl);
      // WebKit reports the navigation the app just prevented as a failure.
      platform.delegate.failLoad(errorCode: 102, url: redirectUrl);
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('stays quiet about a cancelled load', (tester) async {
      await pumpScreen(tester);

      platform.delegate.failLoad(errorCode: -999, description: 'cancelled');
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('stays quiet about a resource outside the main frame', (
      tester,
    ) async {
      await pumpScreen(tester);

      platform.delegate.failLoad(
        errorCode: -1009,
        description: 'offline',
        isForMainFrame: false,
      );
      await tester.pumpAndSettle();

      expect(find.byType(SnackBar), findsNothing);
    });

    testWidgets('reports a sign in page that genuinely failed to load', (
      tester,
    ) async {
      await pumpScreen(tester);

      platform.delegate.failLoad(
        errorCode: -1009,
        description: 'The Internet connection appears to be offline.',
        url: 'https://my.account.sony.com/sonyacct/signin/',
      );
      await tester.pumpAndSettle();

      expect(find.textContaining('offline'), findsOneWidget);
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
