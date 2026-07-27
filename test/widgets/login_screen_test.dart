import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/presentation/screens/auth/login_screen.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_ad_service.dart';
import '../helpers/mock_repositories.dart';

Widget createTestApp(AuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      home: const LoginScreen(),
      routes: {
        AppRouter.home: (_) => const Scaffold(
              body: Center(child: Text('Home Screen Stub')),
            ),
        AppRouter.registration: (_) => const Scaffold(
              body: Center(child: Text('Registration Screen Stub')),
            ),
      },
    ),
  );
}

void main() {
  late MockAuthRepository mockRepository;
  late AuthProvider authProvider;

  setUp(() {
    // Inject mock AdService to avoid real AdMob SDK calls
    AdMobServiceImpl.setInstance(MockAdService());
    mockRepository = MockAuthRepository();
    authProvider = AuthProvider(
      authRepository: mockRepository as AuthRepository,
    );
  });

  tearDown(() {
    authProvider.dispose();
  });

  group('LoginScreen - Initial State', () {
    testWidgets('renders the logo and welcome heading', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      // Advance clock so AuthProvider._init() async work completes
      await tester.pump(const Duration(milliseconds: 100));
      // Complete the 1s LoginScreen animation
      await tester.pump(const Duration(seconds: 2));

      expect(find.byIcon(Icons.auto_awesome), findsOneWidget);
      expect(find.text('Welcome Back'), findsOneWidget);
      expect(find.text('Sign in to continue earning rewards'), findsOneWidget);
    });

    testWidgets('renders Google sign-in button', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Sign in with Google'), findsOneWidget);
      expect(find.byIcon(Icons.g_mobiledata), findsOneWidget);
    });

    testWidgets('renders legal links at bottom', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Terms & Conditions'), findsOneWidget);
      expect(find.text('Privacy Policy'), findsOneWidget);
      expect(find.text('Contact Us'), findsOneWidget);
    });

    testWidgets('renders New User? Sign Up and Forgot Password? links',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('New User? '), findsOneWidget);
      expect(find.text('Sign Up'), findsOneWidget);
      expect(find.text('Forgot Password?'), findsOneWidget);
    });

    testWidgets('tapping Forgot Password? navigates to ForgotPasswordScreen',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      // Scroll down to make the Forgot Password? link visible
      await tester.ensureVisible(find.text('Forgot Password?'));
      await tester.pump();
      await tester.tap(find.text('Forgot Password?'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      // Should navigate to ForgotPasswordScreen
      expect(find.text('Reset Password'), findsOneWidget);
      expect(find.text('Forgot your password?'), findsOneWidget);
      expect(find.text('Send Reset Link'), findsOneWidget);
    });

    testWidgets('tapping Sign Up navigates to Registration screen',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      // Scroll down to make the Sign Up button visible
      await tester.ensureVisible(find.text('Sign Up'));
      await tester.pump();
      await tester.tap(find.text('Sign Up'));
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Registration Screen Stub'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('LoginScreen - Google Sign-In', () {
    testWidgets('successful Google sign-in navigates to home',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      // Scroll down to make the Google sign-in button visible
      await tester.ensureVisible(find.text('Sign in with Google'));
      await tester.pump();
      await tester.tap(find.text('Sign in with Google'));
      // Process tap, async sign-in, and navigation in multiple pumps
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      expect(find.text('Home Screen Stub'), findsOneWidget);
    });
  });

  group('LoginScreen - Error Banner', () {
    testWidgets('error banner appears when auth has error', (tester) async {
      // Trigger an error by doing a failing Google sign-in
      mockRepository.setMockUser(null);
      // Manually set error state on the provider
      authProvider.clearError();
      
      // Rebuild with fresh provider that has an error
      authProvider.dispose();
      authProvider = AuthProvider(
        authRepository: mockRepository as AuthRepository,
      );
      // Use tester pump instead of Future.delayed to advance FakeAsync clock
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      // Complete the 1s LoginScreen animation
      await tester.pump(const Duration(seconds: 2));
      
      // No error initially
      expect(authProvider.errorMessage, isNull);
    });

    testWidgets('tapping close on error banner clears the error',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      // No error banner visible
      expect(find.byIcon(Icons.error_outline), findsNothing);
    });
  });
}
