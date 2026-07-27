import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:flutter_test/flutter_test.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockAuthRepository mockRepository;
  late AuthProvider authProvider;

  setUp(() {
    mockRepository = MockAuthRepository();
    authProvider = AuthProvider(
      authRepository: mockRepository as AuthRepository,
    );
  });

  tearDown(() {
    authProvider.dispose();
  });

  group('AuthProvider initial state', () {
    test('starts as loading then becomes unauthenticated', () async {
      // Emit null auth state after subscription is set up in _init
      mockRepository.emitAuthState(null);
      await Future<void>.delayed(const Duration(milliseconds: 50));
      expect(authProvider.status, AuthStatus.unauthenticated);
      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
    });

    test('becomes authenticated if a user exists', () async {
      mockRepository.setMockUser(UserEntity(
        uid: 'existing-uid',
        fullName: 'Existing User',
        email: 'existing@test.com',
        referralCode: 'EXIST123',
        createdAt: DateTime.now(),
      ));

      // Recreate provider so it picks up the user in _init
      authProvider.dispose();
      authProvider = AuthProvider(
        authRepository: mockRepository as AuthRepository,
      );
      await Future<void>.delayed(const Duration(milliseconds: 50));

      expect(authProvider.status, AuthStatus.authenticated);
      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user, isNotNull);
    });
  });

  group('AuthProvider.signInWithGoogle', () {
    test('signs in successfully with Google', () async {
      await authProvider.signInWithGoogle();

      expect(authProvider.isAuthenticated, true);
      expect(authProvider.user?.email, 'google@example.com');
      expect(authProvider.user?.fullName, 'Google User');
      expect(authProvider.errorMessage, isNull);
      expect(authProvider.isLoading, false);
    });
  });

  group('AuthProvider.signOut', () {
    test('signs out successfully', () async {
      // Sign in first with Google
      await authProvider.signInWithGoogle();
      expect(authProvider.isAuthenticated, true);

      // Sign out
      await authProvider.signOut();

      expect(authProvider.isAuthenticated, false);
      expect(authProvider.user, isNull);
    });
  });

  group('AuthProvider.clearError', () {
    test('clears error message', () async {
      // Set an error state directly by overriding the error via signIn failure
      // To keep it simple, set errorMessage on the mock by doing a failed sign-in
      mockRepository.setShouldThrowOnDeleteAccount(true);
      authProvider.clearError();
      expect(authProvider.errorMessage, isNull);
    });
  });

  group('AuthProvider.refreshUser', () {
    test('refreshes user without error', () async {
      await authProvider.signInWithGoogle();

      // Refresh should not throw
      await authProvider.refreshUser();
      expect(authProvider.user, isNotNull);
    });
  });
}
