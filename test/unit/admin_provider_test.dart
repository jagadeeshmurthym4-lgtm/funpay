import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/repositories/admin_repository.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

class _MockAdminFirestoreDataSource extends Mock
    implements AdminFirestoreDataSource {}

void main() {
  late MockAdminRepository mockRepository;
  late AdminProvider adminProvider;

  setUp(() {
    mockRepository = MockAdminRepository();
    adminProvider = AdminProvider(
      adminRepository: mockRepository as AdminRepository,
      adminDataSource: _MockAdminFirestoreDataSource(),
    );
  });

  tearDown(() {
    adminProvider.dispose();
  });

  group('AdminProvider initial state', () {
    test('starts with no error or success message', () async {
      expect(adminProvider.errorMessage, isNull);
      expect(adminProvider.successMessage, isNull);
      expect(adminProvider.isLoading, false);
    });
  });

  group('AdminProvider._clearMessages (automatic clear before operations)', () {
    test('clears previous errorMessage when loadDashboard succeeds', () async {
      // Set up error state first
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();
      expect(adminProvider.errorMessage, isNotNull);

      // Now succeed — _clearMessages() should fire at the top of loadDashboard()
      mockRepository.setShouldThrow(false);
      mockRepository.setTotalUsers(42);
      await adminProvider.loadDashboard();

      expect(adminProvider.errorMessage, isNull);
      expect(adminProvider.totalUsers, 42);
    });

    test('clears previous errorMessage when creditUserWallet succeeds', () async {
      // Set up error state first (via loadDashboard)
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();
      expect(adminProvider.errorMessage, isNotNull);

      // Now credit — should clear error via _clearMessages at top of creditUserWallet
      mockRepository.setShouldThrow(false);
      final result = await adminProvider.creditUserWallet(
        userId: 'user-1',
        amount: 100.0,
        description: 'Test credit',
      );

      expect(result, true);
      expect(adminProvider.errorMessage, isNull);
      expect(adminProvider.successMessage, contains('Credited'));
    });

    test('clears previous messages when debitUserWallet succeeds', () async {
      // Set up error state first
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();
      expect(adminProvider.errorMessage, isNotNull);

      // Set success state too
      mockRepository.setShouldThrow(false);
      await adminProvider.creditUserWallet(
        userId: 'user-1',
        amount: 50.0,
        description: 'Test credit',
      );
      expect(adminProvider.successMessage, isNotNull);

      // Now debit — should clear both via _clearMessages
      mockRepository.setShouldThrow(false);
      final result = await adminProvider.debitUserWallet(
        userId: 'user-1',
        amount: 25.0,
        description: 'Test debit',
      );

      expect(result, true);
      expect(adminProvider.errorMessage, isNull);
      expect(adminProvider.successMessage, contains('Debited'));
    });

    test('clears previous errorMessage when saveSettings succeeds', () async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();
      expect(adminProvider.errorMessage, isNotNull);

      // Save settings — should clear error via _clearMessages
      mockRepository.setShouldThrow(false);
      final result = await adminProvider.saveSettings(
        AppSettingsEntity(
          id: 'settings',
          updatedAt: DateTime.now(),
        ),
      );

      expect(result, true);
      expect(adminProvider.errorMessage, isNull);
      expect(adminProvider.successMessage, isNotNull);
    });

    test('clears previous successMessage when a failing operation runs',
        () async {
      // Set up success state
      mockRepository.setShouldThrow(false);
      await adminProvider.creditUserWallet(
        userId: 'user-1',
        amount: 50.0,
        description: 'Test',
      );
      expect(adminProvider.successMessage, isNotNull);

      // Run a failing operation — should clear successMessage via _clearMessages
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();

      expect(adminProvider.successMessage, isNull);
      expect(adminProvider.errorMessage, isNotNull);
    });

    test('clears previous errorMessage when sendAnnouncement succeeds',
        () async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();
      expect(adminProvider.errorMessage, isNotNull);

      // Send announcement — should clear error via _clearMessages
      mockRepository.setShouldThrow(false);
      final result = await adminProvider.sendAnnouncement(
        'Test announcement',
      );

      expect(result, true);
      expect(adminProvider.errorMessage, isNull);
      expect(adminProvider.successMessage, isNotNull);
    });

    test('errorMessage is set on creditUserWallet failure', () async {
      // First, verify clean state
      expect(adminProvider.errorMessage, isNull);

      // Fail the credit
      mockRepository.setShouldThrow(true);
      final result = await adminProvider.creditUserWallet(
        userId: 'user-1',
        amount: 100.0,
        description: 'Failing credit',
      );

      expect(result, false);
      expect(adminProvider.errorMessage, isNotNull);
    });
  });

  group('AdminProvider.clearError / clearSuccess', () {
    test('clearError clears error message', () async {
      mockRepository.setShouldThrow(true);
      await adminProvider.loadDashboard();
      expect(adminProvider.errorMessage, isNotNull);

      adminProvider.clearError();

      expect(adminProvider.errorMessage, isNull);
    });

    test('clearSuccess clears success message', () async {
      mockRepository.setShouldThrow(false);
      await adminProvider.creditUserWallet(
        userId: 'user-1',
        amount: 50.0,
        description: 'Test',
      );
      expect(adminProvider.successMessage, isNotNull);

      adminProvider.clearSuccess();

      expect(adminProvider.successMessage, isNull);
    });
  });
}
