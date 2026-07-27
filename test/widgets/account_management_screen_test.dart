import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/presentation/screens/account/account_management_screen.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

import '../helpers/mock_repositories.dart';

Widget createTestApp(AuthProvider authProvider) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
    ],
    child: MaterialApp(
      home: const AccountManagementScreen(),
      routes: {
        AppRouter.login: (_) => const Scaffold(
              body: Center(child: Text('Login Screen Stub')),
            ),
        AppRouter.appSettings: (_) => const Scaffold(
              body: Center(child: Text('Settings Stub')),
            ),
      },
    ),
  );
}

void main() {
  late MockAuthRepository mockRepository;
  late AuthProvider authProvider;

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
  });

  tearDown(() {
    authProvider.dispose();
  });

  group('AccountManagementScreen - Delete Account', () {
    testWidgets('shows the Delete Account tile and description', (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      expect(find.text('Delete Account'), findsOneWidget);
      expect(
        find.text('Permanently delete your account and all data'),
        findsOneWidget,
      );
    });

    testWidgets('tapping Delete Account opens the confirmation dialog',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Tap the Delete Account tile
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Dialog should show the warning text and buttons
      expect(find.text('Are you absolutely sure?'), findsOneWidget);
      expect(find.text('Cancel'), findsOneWidget);
      // "Delete" appears as the dialog button — the tile title is "Delete Account"
      expect(find.text('Delete'), findsNWidgets(1));
    });

    testWidgets('cancelling the dialog does not delete the account',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Tap the Delete Account tile
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Cancel
      await tester.tap(find.text('Cancel'));
      await tester.pumpAndSettle();

      // User should still be authenticated and on the same screen
      expect(authProvider.isAuthenticated, true);
      expect(find.text('Account Management'), findsOneWidget);
      // Dialog should be gone
      expect(find.text('Are you absolutely sure?'), findsNothing);
    });

    testWidgets('confirming deletion deletes account and navigates to login',
        (tester) async {
      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Tap the Delete Account tile
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
      // Make the deleteAccount throw
      mockRepository.setShouldThrowOnDeleteAccount(true);

      await tester.pumpWidget(createTestApp(authProvider));
      await tester.pumpAndSettle();

      // Tap the Delete Account tile
      await tester.tap(find.text('Delete Account'));
      await tester.pumpAndSettle();

      // Tap Delete in the dialog
      await tester.tap(find.text('Delete'));
      await tester.pumpAndSettle();

      // Should stay on the same screen and show an error snackbar
      expect(find.text('Account Management'), findsOneWidget);
      // The snackbar should mention failure
      expect(
        find.textContaining('Failed to delete account'),
        findsOneWidget,
      );
    });
  });
}
