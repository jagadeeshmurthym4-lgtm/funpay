import 'package:cashspark/domain/entities/user_entity.dart';
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

// ─── Test App Builder ───────────────────────────────────────

Widget _buildLoginTestApp(AuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      home: const LoginScreen(),
      routes: {
        AppRouter.completeProfile: (_) => const Scaffold(
              body: Center(child: Text('Complete Profile Stub')),
            ),
        AppRouter.home: (_) => const Scaffold(
              body: Center(child: Text('Home Screen Stub')),
            ),
      },
    ),
  );
}

void main() {
  group('LoginScreen - navigation flow', () {
    late MockAuthRepository mockRepository;
    late AuthProvider authProvider;

    setUp(() {
      AdMobServiceImpl.setInstance(MockAdService());
      mockRepository = MockAuthRepository();
      authProvider = AuthProvider(
        authRepository: mockRepository as AuthRepository,
      );
    });

    tearDown(() {
      authProvider.dispose();
    });

    testWidgets('new user navigates to /complete-profile after Google sign-in',
        (tester) async {
      mockRepository.setSimulateNewUser(true);

      await tester.pumpWidget(_buildLoginTestApp(authProvider));
      // Advance clock so AuthProvider._init() async work completes
      await tester.pump(const Duration(milliseconds: 100));
      // Let the animation (1s) and any pending frames settle
      await tester.pump(const Duration(seconds: 2));

      // Act: tap Google sign-in
      await tester.ensureVisible(find.text('Sign in with Google'));
      await tester.pump();
      await tester.tap(find.text('Sign in with Google'));
      // Process tap event + async sign-in + navigation in sequence
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Assert: navigated to complete-profile route
      expect(find.text('Complete Profile Stub'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });

    testWidgets('existing user navigates to /home after Google sign-in',
        (tester) async {
      mockRepository.setSimulateNewUser(false);

      await tester.pumpWidget(_buildLoginTestApp(authProvider));
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump(const Duration(seconds: 2));

      await tester.ensureVisible(find.text('Sign in with Google'));
      await tester.pump();
      await tester.tap(find.text('Sign in with Google'));
      // Process tap event + async sign-in + navigation in sequence
      await tester.pump();
      await tester.pump(const Duration(seconds: 2));

      // Assert: navigated to home route
      expect(find.text('Home Screen Stub'), findsOneWidget);
      expect(find.byType(LoginScreen), findsNothing);
    });
  });

  group('SplashScreen - navigation flow', () {
    /// Creates an AuthProvider with a pre-set user to simulate
    /// what happens when the app restarts with an existing session.
    /// NOTE: This replicates SplashScreen._navigateAfterAuth() navigation logic.
    /// If the real SplashScreen navigation changes, update _NavTestWrapper too.
    ({AuthProvider provider, MockAuthRepository repo}) createProviderWithUser({
      required bool profileCompleted,
    }) {
      final mockRepo = MockAuthRepository();
      final user = UserEntity(
        uid: 'test-uid',
        firstName: 'Test',
        lastName: 'User',
        fullName: 'Test User',
        email: 'test@test.com',
        referralCode: 'TEST1234',
        profileCompleted: profileCompleted,
        createdAt: DateTime.now(),
      );
      mockRepo.setMockUser(user);
      final provider = AuthProvider(
        authRepository: mockRepo as AuthRepository,
      );
      return (provider: provider, repo: mockRepo);
    }

    /// Builds a minimal app for testing SplashScreen navigation.
    /// Uses a wrapper that replicates the navigation logic without AdMob calls.
    Widget buildSplashTestApp(AuthProvider authProvider) {
      return MultiProvider(
        providers: [
          ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
        ],
        child: MaterialApp(
          home: const _NavTestWrapper(),
          routes: {
            AppRouter.completeProfile: (_) => const Scaffold(
                  body: Center(child: Text('Complete Profile Stub')),
                ),
            AppRouter.home: (_) => const Scaffold(
                  body: Center(child: Text('Home Screen Stub')),
                ),
            AppRouter.login: (_) => const Scaffold(
                  body: Center(child: Text('Login Screen Stub')),
                ),
          },
        ),
      );
    }

    testWidgets('existing user with completed profile goes to /home',
        (tester) async {
      final result = createProviderWithUser(
        profileCompleted: true,
      );

      await tester.pumpWidget(buildSplashTestApp(result.provider));
      // Advance clock so AuthProvider._init() async work completes
      await tester.pump(const Duration(milliseconds: 200));
      // Post-frame callback runs after first frame, navigation needs another pump
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Home Screen Stub'), findsOneWidget);
      expect(find.byType(_NavTestWrapper), findsNothing);

      result.provider.dispose();
    });

    testWidgets('new user with incomplete profile goes to /complete-profile',
        (tester) async {
      final result = createProviderWithUser(
        profileCompleted: false,
      );

      await tester.pumpWidget(buildSplashTestApp(result.provider));
      // Advance clock so AuthProvider._init() async work completes
      await tester.pump(const Duration(milliseconds: 200));
      // Post-frame callback runs after first frame, navigation needs another pump
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Complete Profile Stub'), findsOneWidget);
      expect(find.byType(_NavTestWrapper), findsNothing);

      result.provider.dispose();
    });

    testWidgets('unauthenticated user goes to /login', (tester) async {
      final mockRepo = MockAuthRepository();
      mockRepo.setMockUser(null);
      final authProvider = AuthProvider(
        authRepository: mockRepo as AuthRepository,
      );

      await tester.pumpWidget(buildSplashTestApp(authProvider));
      // Advance clock so AuthProvider._init() async work completes
      await tester.pump(const Duration(milliseconds: 200));
      // Post-frame callback runs after first frame, navigation needs another pump
      await tester.pump();
      await tester.pump(const Duration(seconds: 1));

      expect(find.text('Login Screen Stub'), findsOneWidget);
      expect(find.byType(_NavTestWrapper), findsNothing);

      authProvider.dispose();
    });
  });
}

/// Replicates the navigation logic from SplashScreen._navigateAfterAuth()
/// without AdMob dependencies.
class _NavTestWrapper extends StatefulWidget {
  const _NavTestWrapper();

  @override
  State<_NavTestWrapper> createState() => _NavTestWrapperState();
}

class _NavTestWrapperState extends State<_NavTestWrapper> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _navigate());
  }

  void _navigate() {
    final auth = context.read<AuthProvider>();
    if (auth.isAuthenticated) {
      if (auth.needsProfileCompletion) {
        Navigator.pushReplacementNamed(context, AppRouter.completeProfile);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } else {
      Navigator.pushReplacementNamed(context, AppRouter.login);
    }
  }

  @override
  Widget build(BuildContext context) => const SizedBox.shrink();
}
