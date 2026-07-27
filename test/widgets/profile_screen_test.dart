import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/presentation/screens/profile/profile_screen.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:cashspark/domain/repositories/wallet_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_repositories.dart';

Widget createTestApp(AuthProvider authProvider, WalletProvider walletProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<WalletProvider>.value(value: walletProvider),
    ],
    child: MaterialApp(
      home: const ProfileScreen(),
      routes: {
        AppRouter.login: (_) => const Scaffold(
              body: Center(child: Text('Login Screen Stub')),
            ),
        AppRouter.profile: (_) => const Scaffold(
              body: Center(child: Text('Profile Stub')),
            ),
        AppRouter.appSettings: (_) => const Scaffold(
              body: Center(child: Text('Settings Stub')),
            ),
        AppRouter.editProfile: (_) => const Scaffold(
              body: Center(child: Text('Edit Profile Stub')),
            ),
        AppRouter.wallet: (_) => const Scaffold(
              body: Center(child: Text('Wallet Stub')),
            ),
      },
    ),
  );
}

void main() {
  late MockAuthRepository mockRepository;
  late MockWalletRepository mockWalletRepository;
  late AuthProvider authProvider;
  late WalletProvider walletProvider;

  setUp(() async {
    mockRepository = MockAuthRepository();
    mockRepository.setMockUser(UserEntity(
      uid: 'test-uid',
      fullName: 'Test User',
      email: 'test@example.com',
      referralCode: 'TEST1234',
      createdAt: DateTime.now(),
    ));
    authProvider = AuthProvider(
      authRepository: mockRepository as AuthRepository,
    );
    // Wait for _init() to complete
    await Future<void>.delayed(const Duration(milliseconds: 100));

    mockWalletRepository = MockWalletRepository();
    walletProvider = WalletProvider(
      walletRepository: mockWalletRepository as WalletRepository,
    );
  });

  tearDown(() {
    authProvider.dispose();
    walletProvider.dispose();
  });

  group('ProfileScreen - Delete Account', () {
    testWidgets('shows the Delete Account tile in the Account section',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider, walletProvider));
      await tester.pumpAndSettle();

      // Scroll down to the Account section
      await tester.scrollUntilVisible(
        find.text('Delete Account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
    });

    testWidgets('tapping Delete Account opens the confirmation dialog',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider, walletProvider));
      await tester.pumpAndSettle();

      // Scroll down to the Delete Account tile
      await tester.scrollUntilVisible(
        find.text('Delete Account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Dialog should be visible
      expect(find.text('This action is permanent. All your data will be deleted.'),
          findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
    });

    testWidgets('cancelling the dialog does not delete the account',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider, walletProvider));
      await tester.pumpAndSettle();

      // Scroll to Delete Account
      await tester.scrollUntilVisible(
        find.text('Delete Account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // User should still be authenticated
      expect(authProvider.isAuthenticated, true);
      // Dialog should be gone
      expect(find.text('This action is permanent. All your data will be deleted.'),
          findsNothing);
    });

    testWidgets('confirming deletion deletes account and navigates to login',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider, walletProvider));
      await tester.pumpAndSettle();

      // Scroll to Delete Account
      await tester.scrollUntilVisible(
        find.text('Delete Account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Delete in the dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should navigate to login screen
      expect(find.text('Login Screen Stub'), findsOneWidget);
      // Auth state should be unauthenticated
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
    });

    testWidgets('shows an error snackbar when deletion fails',
        (tester) async {
      mockRepository.setShouldThrowOnDeleteAccount(true);

      await tester.pumpWidget(createTestApp(authProvider, walletProvider));
      await tester.pumpAndSettle();

      // Scroll to Delete Account
      await tester.scrollUntilVisible(
        find.text('Delete Account'),
        200,
        scrollable: find.byType(Scrollable).first,
      );
      await tester.pumpAndSettle();

      // Tap Delete Account
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Delete in the dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should stay on the same screen and show an error snackbar
      expect(find.textContaining('Failed:'), findsOneWidget);
      // User should still be authenticated since deletion failed
      expect(authProvider.isAuthenticated, true);
    });
  });
}
