import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/repositories/admin_repository.dart';
import 'package:cashspark/domain/repositories/support_ticket_repository.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

import '../helpers/mock_repositories.dart';

class _MockAdminFirestoreDataSource extends Mock
    implements AdminFirestoreDataSource {}

class _MockReferralFirestoreDataSource extends Mock
    implements ReferralFirestoreDataSource {}

class _MockSupportTicketRepository extends Mock
    implements SupportTicketRepository {}

ReferralEntity _createReferral({
  required String referralId,
  required String referrerUserId,
  double rewardAmount = 0.0,
  bool firstProjectRewarded = false,
}) {
  return ReferralEntity(
    referralId: referralId,
    referrerUserId: referrerUserId,
    referredUserId: 'referred-1',
    referralCode: 'REF123',
    rewardAmount: rewardAmount,
    status: ReferralStatus.completed,
    createdAt: DateTime.now(),
    firstProjectRewarded: firstProjectRewarded,
  );
}

void main() {
  late MockAdminRepository mockRepository;
  late _MockAdminFirestoreDataSource mockAdminDataSource;
  late _MockReferralFirestoreDataSource mockReferralDataSource;
  late _MockSupportTicketRepository mockSupportTicketRepository;
  late AdminProvider adminProvider;

  setUp(() {
    mockRepository = MockAdminRepository();
    mockAdminDataSource = _MockAdminFirestoreDataSource();
    mockReferralDataSource = _MockReferralFirestoreDataSource();
    mockSupportTicketRepository = _MockSupportTicketRepository();
    adminProvider = AdminProvider(
      adminRepository: mockRepository as AdminRepository,
      adminDataSource: mockAdminDataSource,
      referralDataSource: mockReferralDataSource,
      supportTicketRepository: mockSupportTicketRepository,
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

  // ─── InsightItem ───────────────────────────────────────────
  group('InsightItem', () {
    test('constructor assigns all fields', () {
      const item = InsightItem(
        icon: Icons.trending_up_rounded,
        title: 'User growth trending up',
        subtitle: '10% increase this week',
        color: Color(0xFF22C55E),
      );
      expect(item.icon, Icons.trending_up_rounded);
      expect(item.title, 'User growth trending up');
      expect(item.subtitle, '10% increase this week');
      expect(item.color, const Color(0xFF22C55E));
    });

    test('fields are typed and immutable', () {
      const item = InsightItem(
        icon: Icons.star,
        title: 'Title',
        subtitle: 'Subtitle',
        color: Colors.green,
      );
      expect(item.icon, isA<IconData>());
      expect(item.title, isA<String>());
      expect(item.subtitle, isA<String>());
      expect(item.color, isA<Color>());
    });

    test('const constructor canonicalizes equal instances', () {
      const a = InsightItem(
        icon: Icons.star,
        title: 'Title',
        subtitle: 'Subtitle',
        color: Colors.green,
      );
      const b = InsightItem(
        icon: Icons.star,
        title: 'Title',
        subtitle: 'Subtitle',
        color: Colors.green,
      );
      expect(identical(a, b), isTrue);
    });
  });

  // ─── creditReferralBonus ───────────────────────────────────
  group('AdminProvider.creditReferralBonus', () {
    setUp(() {
      when(() => mockReferralDataSource.updateReferralReward(any(), any()))
          .thenAnswer((_) async {});
    });

    test('credits wallet and marks referral as rewarded on success', () async {
      // Pre-populate the local referrals list
      mockRepository.setReferrals([
        _createReferral(referralId: 'ref-1', referrerUserId: 'user-1'),
      ]);
      await adminProvider.loadReferrals();

      final result = await adminProvider.creditReferralBonus(
        referralId: 'ref-1',
        referrerUserId: 'user-1',
        referredUserName: 'Test User',
      );

      expect(result, isTrue);
      expect(adminProvider.successMessage, contains('Credited'));

      // Wallet credited with default 7 pts and default description
      expect(mockRepository.creditCalls, hasLength(1));
      expect(mockRepository.creditCalls.first['userId'], 'user-1');
      expect(mockRepository.creditCalls.first['amount'], 7.0);
      expect(mockRepository.creditCalls.first['description'], contains('Test User'));

      // Referral record updated with reward flags
      verify(() => mockReferralDataSource.updateReferralReward(
        'ref-1',
        any(that: predicate<Map<String, dynamic>>((m) =>
            m['firstProjectRewarded'] == true && m['rewardAmount'] == 7.0)),
      )).called(1);

      // Local state updated
      expect(adminProvider.referrals.single.firstProjectRewarded, isTrue);
      expect(adminProvider.referrals.single.rewardAmount, 7.0);
    });

    test('uses custom amount and notes as description', () async {
      final result = await adminProvider.creditReferralBonus(
        referralId: 'ref-1',
        referrerUserId: 'user-1',
        referredUserName: 'Test User',
        amount: 15.0,
        notes: 'Special bonus',
      );

      expect(result, isTrue);
      expect(mockRepository.creditCalls.single['amount'], 15.0);
      expect(mockRepository.creditCalls.single['description'], 'Special bonus');
      expect(adminProvider.successMessage, contains('15.00'));

      verify(() => mockReferralDataSource.updateReferralReward(
        'ref-1',
        any(that: predicate<Map<String, dynamic>>((m) =>
            m['rewardAmount'] == 15.0)),
      )).called(1);
    });

    test('returns false and sets error when wallet credit fails', () async {
      mockRepository.setShouldThrow(true);

      final result = await adminProvider.creditReferralBonus(
        referralId: 'ref-1',
        referrerUserId: 'user-1',
        referredUserName: 'Test User',
      );

      expect(result, isFalse);
      expect(adminProvider.errorMessage,
          contains('Failed to credit referral bonus'));
      // No referral record update should happen on failure
      verifyNever(() => mockReferralDataSource.updateReferralReward(any(), any()));
    });

    test('returns false and sets error when referral record update fails',
        () async {
      when(() => mockReferralDataSource.updateReferralReward(any(), any()))
          .thenThrow(Exception('Firestore write failed'));

      final result = await adminProvider.creditReferralBonus(
        referralId: 'ref-1',
        referrerUserId: 'user-1',
        referredUserName: 'Test User',
      );

      expect(result, isFalse);
      expect(adminProvider.errorMessage,
          contains('Failed to credit referral bonus'));
    });

    test('does not modify local state when referral not in list', () async {
      final result = await adminProvider.creditReferralBonus(
        referralId: 'unknown-ref',
        referrerUserId: 'user-1',
        referredUserName: 'Test User',
      );

      expect(result, isTrue);
      expect(adminProvider.referrals, isEmpty);
    });
  });

  // ─── bulkCreditReferralBonuses ─────────────────────────────
  group('AdminProvider.bulkCreditReferralBonuses', () {
    setUp(() {
      when(() => mockReferralDataSource.updateReferralReward(any(), any()))
          .thenAnswer((_) async {});
    });

    test('credits all pending referrals and reports progress', () async {
      final progressCalls = <(int, int)>[];

      final result = await adminProvider.bulkCreditReferralBonuses(
        pendingReferrals: [
          {'referralId': 'ref-1', 'referrerUserId': 'user-1'},
          {'referralId': 'ref-2', 'referrerUserId': 'user-2'},
          {'referralId': 'ref-3', 'referrerUserId': 'user-3'},
        ],
        amount: 7.0,
        notes: '',
        onProgress: (credited, total) => progressCalls.add((credited, total)),
      );

      expect(result['successCount'], 3);
      expect(result['failCount'], 0);
      expect(result['total'], 3);
      expect(mockRepository.creditCalls, hasLength(3));
      expect(progressCalls, [(1, 3), (2, 3), (3, 3)]);
      expect(adminProvider.successMessage, contains('Bulk credited 3/3'));
    });

    test('uses notes as description when provided', () async {
      await adminProvider.bulkCreditReferralBonuses(
        pendingReferrals: [
          {'referralId': 'ref-1', 'referrerUserId': 'user-1'},
        ],
        amount: 10.0,
        notes: 'Bulk campaign bonus',
        onProgress: (_, __) {},
      );

      expect(mockRepository.creditCalls.single['description'],
          'Bulk campaign bonus');
      expect(mockRepository.creditCalls.single['amount'], 10.0);
    });

    test('counts failures when some operations throw', () async {
      // Fail the reward update for the second referral only
      when(() => mockReferralDataSource.updateReferralReward('ref-2', any()))
          .thenThrow(Exception('write failed'));

      final result = await adminProvider.bulkCreditReferralBonuses(
        pendingReferrals: [
          {'referralId': 'ref-1', 'referrerUserId': 'user-1'},
          {'referralId': 'ref-2', 'referrerUserId': 'user-2'},
          {'referralId': 'ref-3', 'referrerUserId': 'user-3'},
        ],
        amount: 7.0,
        notes: '',
        onProgress: (_, __) {},
      );

      expect(result['successCount'], 2);
      expect(result['failCount'], 1);
      expect(result['total'], 3);
      expect(adminProvider.successMessage, contains('Bulk credited 2/3'));
    });

    test('handles empty list gracefully', () async {
      final result = await adminProvider.bulkCreditReferralBonuses(
        pendingReferrals: [],
        amount: 7.0,
        notes: '',
        onProgress: (_, __) {},
      );

      expect(result['successCount'], 0);
      expect(result['failCount'], 0);
      expect(result['total'], 0);
      expect(mockRepository.creditCalls, isEmpty);
    });

    test('updates local referral state for matched referrals', () async {
      mockRepository.setReferrals([
        _createReferral(referralId: 'ref-1', referrerUserId: 'user-1'),
      ]);
      await adminProvider.loadReferrals();

      await adminProvider.bulkCreditReferralBonuses(
        pendingReferrals: [
          {'referralId': 'ref-1', 'referrerUserId': 'user-1'},
          {'referralId': 'ref-2', 'referrerUserId': 'user-2'},
        ],
        amount: 7.0,
        notes: '',
        onProgress: (_, __) {},
      );

      expect(adminProvider.referrals.single.firstProjectRewarded, isTrue);
      expect(adminProvider.referrals.single.rewardAmount, 7.0);
    });
  });
}
