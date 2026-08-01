import 'package:cashspark/data/datasources/affiliate_project_firestore_datasource.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/datasources/scratch_card_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/affiliate_project_model.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/data/repositories/affiliate_project_repository_impl.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ─────────────────────────────────────────────────

class MockAffiliateProjectDataSource extends Mock
    implements AffiliateProjectFirestoreDataSource {}

class MockWalletDataSource extends Mock implements WalletFirestoreDataSource {}

class MockNotificationDataSource extends Mock
    implements NotificationFirestoreDataSource {}

class MockAdminDataSource extends Mock implements AdminFirestoreDataSource {}

class MockScratchCardDataSource extends Mock
    implements ScratchCardFirestoreDataSource {}

class MockReferralDataSource extends Mock
    implements ReferralFirestoreDataSource {}

// Predicate to match a scratch card notification message
Matcher _isScratchCardNotification() => predicate<NotificationModel>((n) =>
    n.title.contains('Scratch Card'));

// ─── Constants ──────────────────────────────────────────────

const _userId = 'test-user-uid';
const _participationId = 'test-participation-id';
const _projectId = 'test-project-id';
const _rewardAmount = 25.0;

// ─── Helpers ────────────────────────────────────────────────

AffiliateProjectRepositoryImpl _buildRepo({
  required AffiliateProjectFirestoreDataSource dataSource,
  required WalletFirestoreDataSource walletDataSource,
  required NotificationFirestoreDataSource notificationDataSource,
  AdminFirestoreDataSource? adminDataSource,
  ScratchCardFirestoreDataSource? scratchCardDataSource,
  ReferralFirestoreDataSource? referralDataSource,
}) {
  return AffiliateProjectRepositoryImpl(
    dataSource: dataSource,
    walletDataSource: walletDataSource,
    notificationDataSource: notificationDataSource,
    adminDataSource: adminDataSource,
    scratchCardDataSource: scratchCardDataSource,
    referralDataSource: referralDataSource,
  );
}

/// Stub all datasources needed for creditReward to run.
/// Configures the flow so that:
/// - Participation exists, not yet credited
/// - Wallet operations succeed
/// - Notifications are accepted
/// - Scratch card does NOT already exist (unless `scratchCardAlreadyExists` is true)
/// - No referral record exists (unless `hasReferral` is true)
void _stubCreditRewardFlow(
  MockAffiliateProjectDataSource affiliate,
  MockWalletDataSource wallet,
  MockNotificationDataSource notifications,
  MockScratchCardDataSource scratchCard,
  MockReferralDataSource referral, {
  bool rewardAlreadyCredited = false,
  bool scratchCardAlreadyExists = false,
  bool scratchCardThrows = false,
}) {
  final now = DateTime.now();

  // Participation lookup
  when(() => affiliate.getParticipationById(_participationId)).thenAnswer(
    (_) async => ProjectParticipationModel(
      participationId: _participationId,
      projectId: _projectId,
      projectTitle: 'Test Project',
      userId: _userId,
      userName: 'Test User',
      rewardAmount: _rewardAmount,
      status: 'approved',
      startedAt: now.subtract(const Duration(days: 2)),
      rewardCredited: rewardAlreadyCredited,
    ),
  );

  // Wallet stubs
  when(() => wallet.updateWalletBalance(
    userId: any(named: 'userId'),
    amountChange: any(named: 'amountChange'),
    earningsChange: any(named: 'earningsChange'),
    withdrawnChange: any(named: 'withdrawnChange'),
  )).thenAnswer((_) async => WalletModel(
    userId: _userId, walletBalance: _rewardAmount, totalEarnings: _rewardAmount,
    totalWithdrawn: 0, updatedAt: now,
  ));
  when(() => wallet.createTransaction(any())).thenAnswer((_) async {});
  // In case wallet creation is needed
  when(() => wallet.createWallet(any())).thenAnswer((_) async {});

  // Mark reward credited + increment counters
  when(() => affiliate.markRewardCredited(_participationId))
      .thenAnswer((_) async {});
  when(() => affiliate.incrementCompletedCount(_projectId))
      .thenAnswer((_) async {});
  when(() => affiliate.incrementTotalRewardsPaid(_projectId, _rewardAmount))
      .thenAnswer((_) async {});

  // Notification stubs
  when(() => notifications.createNotification(any())).thenAnswer((_) async {});

  // Update participation partial (for referralProcessed flag)
  when(() => affiliate.updateParticipationPartial(any(), any()))
      .thenAnswer((_) async {});

  // Referral: no referrer by default
  when(() => referral.getReferralByReferredUser(any()))
      .thenAnswer((_) async => null);

  // Stub updateReferralReward to succeed (default for when referrals are processed)
  when(() => referral.updateReferralReward(any(), any()))
      .thenAnswer((_) async {});

  // Scratch card stubs
  when(() => scratchCard.hasScratchCardForSubmission(_participationId))
      .thenAnswer((_) async => scratchCardAlreadyExists);
  if (scratchCardThrows) {
    when(() => scratchCard.createScratchCard(any()))
        .thenThrow(Exception('Firestore write failed'));
  } else {
    when(() => scratchCard.createScratchCard(any())).thenAnswer((_) async {});
  }

  // — No referral data by default (referrerRecord is null) —
  // The test helper doesn't stub ReferralFirestoreDataSource;
  // if a mock is provided, the default stub behavior applies.
}

/// Create the participation doc returned by Firestore for full-flow seeding.
ProjectParticipationModel _createParticipation({
  double rewardAmount = _rewardAmount,
  bool rewardCredited = false,
}) {
  final now = DateTime.now();
  return ProjectParticipationModel(
    participationId: _participationId,
    projectId: _projectId,
    projectTitle: 'Test Project',
    userId: _userId,
    userName: 'Test User',
    rewardAmount: rewardAmount,
    status: 'approved',
    startedAt: now.subtract(const Duration(days: 2)),
    rewardCredited: rewardCredited,
  );
}

void main() {
  late MockAffiliateProjectDataSource mockAffiliate;
  late MockWalletDataSource mockWallet;
  late MockNotificationDataSource mockNotification;
  late MockAdminDataSource mockAdmin;
  late MockScratchCardDataSource mockScratchCard;
  late MockReferralDataSource mockReferral;
  late AffiliateProjectRepositoryImpl repo;

  setUpAll(() {
    final now = DateTime.now();
    registerFallbackValue(WalletModel(
      userId: '', walletBalance: 0, totalEarnings: 0, totalWithdrawn: 0,
      updatedAt: now,
    ));
    registerFallbackValue(TransactionModel(
      transactionId: '', userId: '', type: TransactionType.credit,
      amount: 0, source: TransactionSource.reward,
      status: TransactionStatus.completed, createdAt: now,
    ));
    registerFallbackValue(NotificationModel(
      notificationId: '', userId: '', title: '', message: '',
      type: NotificationType.other, isRead: false, createdAt: now,
    ));
    registerFallbackValue(ScratchCardModel(
      scratchCardId: '', userId: '', submissionId: '',
      rewardAmount: 0.0, isUsed: false, createdAt: now,
    ));
    registerFallbackValue(ReferralModel(
      referralId: '', referrerUserId: '', referredUserId: '',
      referralCode: '', createdAt: now,
    ));
  });

  setUp(() {
    mockAffiliate = MockAffiliateProjectDataSource();
    mockWallet = MockWalletDataSource();
    mockNotification = MockNotificationDataSource();
    mockAdmin = MockAdminDataSource();
    mockScratchCard = MockScratchCardDataSource();
    mockReferral = MockReferralDataSource();
    repo = _buildRepo(
      dataSource: mockAffiliate,
      walletDataSource: mockWallet,
      notificationDataSource: mockNotification,
      adminDataSource: mockAdmin,
      scratchCardDataSource: mockScratchCard,
      referralDataSource: mockReferral,
    );
  });

  // ═══════════════════════════════════════════════════════════
  // ScratchCardModel serialization
  // ═══════════════════════════════════════════════════════════

  group('ScratchCardModel', () {
    test('fromFirestore / toFirestore round-trip', () {
      final ts = Timestamp.fromDate(DateTime(2024, 6, 17, 10, 30));
      final usedAt = Timestamp.fromDate(DateTime(2024, 6, 18, 14, 0));
      final map = {
        'scratchCardId': 'card-123',
        'userId': _userId,
        'submissionId': _participationId,
        'rewardAmount': 5.0,
        'isUsed': true,
        'createdAt': ts,
        'usedAt': usedAt,
      };

      final model = ScratchCardModel.fromFirestore(map);
      expect(model.scratchCardId, 'card-123');
      expect(model.userId, _userId);
      expect(model.submissionId, _participationId);
      expect(model.rewardAmount, 5.0);
      expect(model.isUsed, true);
      expect(model.createdAt, ts.toDate());
      expect(model.usedAt, usedAt.toDate());

      final output = model.toFirestore();
      expect(output['scratchCardId'], 'card-123');
      expect(output['rewardAmount'], 5.0);
      expect(output['isUsed'], true);
      expect(output['submissionId'], _participationId);
    });

    test('uses defaults for empty map', () {
      final model = ScratchCardModel.fromFirestore({});
      expect(model.scratchCardId, '');
      expect(model.userId, '');
      expect(model.submissionId, '');
      expect(model.rewardAmount, 0.0);
      expect(model.isUsed, false);
      expect(model.usedAt, isNull);
    });

    test('handles unused card correctly', () {
      final now = DateTime.now();
      final model = ScratchCardModel(
        scratchCardId: 'card-456',
        userId: _userId,
        submissionId: _participationId,
        rewardAmount: 0.0,
        isUsed: false,
        createdAt: now,
      );
      expect(model.isUsed, false);
      expect(model.rewardAmount, 0.0);
      expect(model.usedAt, isNull);
    });

    test('copyWith is immutable', () {
      final now = DateTime.now();
      final original = ScratchCardModel(
        scratchCardId: 'card-1', userId: _userId,
        submissionId: _participationId, rewardAmount: 0.0,
        isUsed: false, createdAt: now,
      );
      final copied = original.copyWith(
        rewardAmount: 5.0, isUsed: true, usedAt: now,
      );
      expect(copied.rewardAmount, 5.0);
      expect(copied.isUsed, true);
      expect(original.rewardAmount, 0.0);
      expect(original.isUsed, false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // creditReward scratch card generation
  // ═══════════════════════════════════════════════════════════

  group('creditReward scratch card generation', () {
    test('creates a scratch card after successful reward credit', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );

      final result = await repo.creditReward(_participationId, _userId);

      expect(result, isTrue);
      verify(() => mockScratchCard.hasScratchCardForSubmission(
        _participationId,
      )).called(1);
      verify(() => mockScratchCard.createScratchCard(
        any(that: predicate<ScratchCardModel>((card) =>
            card.userId == _userId &&
            card.submissionId == _participationId &&
            card.rewardAmount == 0.0 &&
            !card.isUsed)),
      )).called(1);
    });

    test('does not create scratch card if reward already credited', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
        rewardAlreadyCredited: true,
      );

      final result = await repo.creditReward(_participationId, _userId);

      expect(result, isFalse);
      verifyNever(() => mockScratchCard.hasScratchCardForSubmission(any()));
      verifyNever(() => mockScratchCard.createScratchCard(any()));
    });

    test('does not create duplicate scratch card if one already exists', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
        scratchCardAlreadyExists: true,
      );

      final result = await repo.creditReward(_participationId, _userId);

      expect(result, isTrue);
      verify(() => mockScratchCard.hasScratchCardForSubmission(
        _participationId,
      )).called(1);
      verifyNever(() => mockScratchCard.createScratchCard(any()));
    });

    test('still returns true when scratch card creation throws', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
        scratchCardThrows: true,
      );

      final result = await repo.creditReward(_participationId, _userId);

      // Even if scratch card creation fails, the reward credit itself succeeded
      expect(result, isTrue);
      verify(() => mockScratchCard.createScratchCard(any())).called(1);
    });

    test('reward credit operations happen before scratch card check', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );

      await repo.creditReward(_participationId, _userId);

      // All reward credit operations were called
      verify(() => mockWallet.updateWalletBalance(
        userId: _userId,
        amountChange: _rewardAmount,
        earningsChange: _rewardAmount,
        withdrawnChange: 0,
      )).called(1);
      verify(() => mockWallet.createTransaction(any())).called(1);
      verify(() => mockAffiliate.markRewardCredited(_participationId)).called(1);
      verify(() => mockAffiliate.incrementCompletedCount(_projectId)).called(1);

      // Scratch card check also happened
      verify(() => mockScratchCard.hasScratchCardForSubmission(
        _participationId,
      )).called(1);
    });

    test('does not check for scratch card if participation is null', () async {
      when(() => mockAffiliate.getParticipationById(_participationId))
          .thenAnswer((_) async => null);

      final result = await repo.creditReward(_participationId, _userId);

      expect(result, isFalse);
      verifyNever(() => mockScratchCard.hasScratchCardForSubmission(any()));
      verifyNever(() => mockScratchCard.createScratchCard(any()));
    });

    test('does not check for scratch card if wallet operations fail', () async {
      when(() => mockAffiliate.getParticipationById(_participationId))
          .thenAnswer((_) async => _createParticipation());

      // Make wallet update fail even after wallet creation
      when(() => mockWallet.updateWalletBalance(
        userId: any(named: 'userId'),
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      )).thenThrow(Exception('Wallet error'));
      when(() => mockWallet.createWallet(any())).thenAnswer((_) async {});
      // Still fails
      when(() => mockWallet.updateWalletBalance(
        userId: any(named: 'userId'),
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      )).thenThrow(Exception('Wallet error'));

      final result = await repo.creditReward(_participationId, _userId);

      expect(result, isFalse);
      verifyNever(() => mockScratchCard.hasScratchCardForSubmission(any()));
      verifyNever(() => mockScratchCard.createScratchCard(any()));
    });

    test('scratch card is created with the participationId as submissionId', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );

      await repo.creditReward(_participationId, _userId);

      verify(() => mockScratchCard.createScratchCard(
        any(that: predicate<ScratchCardModel>((card) =>
            card.submissionId == _participationId)),
      )).called(1);
    });

    test('scratch card is created for the correct user', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );

      await repo.creditReward(_participationId, _userId);

      verify(() => mockScratchCard.createScratchCard(
        any(that: predicate<ScratchCardModel>((card) =>
            card.userId == _userId)),
      )).called(1);
    });

    test('sends notification when scratch card is created', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );

      await repo.creditReward(_participationId, _userId);

      // Verify a notification was sent for the scratch card
      verify(() => mockNotification.createNotification(
        any(that: _isScratchCardNotification()),
      )).called(1);
    });

    test('does not send scratch card notification when card already exists', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
        scratchCardAlreadyExists: true,
      );

      await repo.creditReward(_participationId, _userId);

      // No scratch card notification since card already existed
      verifyNever(() => mockNotification.createNotification(
        any(that: _isScratchCardNotification()),
      ));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // creditReward referral reward logic
  // ═══════════════════════════════════════════════════════════

  group('creditReward referral reward logic', () {
    const referrerId = 'referrer-user-uid';
    const referralId = 'referral-record-id';

    /// Create a base referral record with the given properties.
    ReferralModel createReferralRecord({
      bool firstProjectRewarded = false,
      List<String> rewardedProjectIds = const [],
      int approvedProjectCount = 0,
      double rewardAmount = 0.0,
      double lifetimeProjectCommission = 0.0,
    }) {
      return ReferralModel(
        referralId: referralId,
        referrerUserId: referrerId,
        referredUserId: _userId,
        referralCode: 'REF123',
        rewardAmount: rewardAmount,
        status: ReferralStatus.completed,
        createdAt: DateTime.now().subtract(const Duration(days: 30)),
        firstProjectRewarded: firstProjectRewarded,
        firstProjectId: null,
        firstProjectRewardDate: null,
        lifetimeProjectCommission: lifetimeProjectCommission,
        rewardedProjectIds: rewardedProjectIds,
        approvedProjectCount: approvedProjectCount,
      );
    }

    /// Stub the referral datasource for tests that need a referrer record.
    void stubReferrerRecord(ReferralModel record) {
      when(() => mockReferral.getReferralByReferredUser(_userId))
          .thenAnswer((_) async => record);
    }

    /// Predicate matcher for referral notification (first project bonus).
    Matcher isFirstProjectBonusNotification() =>
        predicate<NotificationModel>((n) => n.title == '🎉 First Project Referral Bonus');

    /// Predicate matcher for referral commission notification.
    Matcher isCommissionNotification() =>
        predicate<NotificationModel>((n) => n.title == '💰 Referral Commission Earned');

    setUp(() {
      // Reset referral stub to no-referrer for each test in this group
      // Tests that need a referrer override this in the test body
      when(() => mockReferral.getReferralByReferredUser(any()))
          .thenAnswer((_) async => null);
    });

    test('skips referral when no referrer record exists', () async {
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );

      await repo.creditReward(_participationId, _userId);

      // getReferralByReferredUser was called
      verify(() => mockReferral.getReferralByReferredUser(_userId)).called(1);
      // No referral wallet credit or referral transaction should happen
      verifyNever(() => mockWallet.updateWalletBalance(
        userId: referrerId,
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      ));
      verifyNever(() => mockReferral.updateReferralReward(any(), any()));
    });

    test('credits 7 pts bonus to referrer on first approved project', () async {
      final referralRecord = createReferralRecord(firstProjectRewarded: false);
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      final result = await repo.creditReward(_participationId, _userId);

      expect(result, isTrue);

      // Referrer's wallet credited with 7 pts
      verify(() => mockWallet.updateWalletBalance(
        userId: referrerId,
        amountChange: 7.0,
        earningsChange: 7.0,
        withdrawnChange: 0,
      )).called(1);

      // Referral transaction created
      verify(() => mockWallet.createTransaction(
        any(that: predicate<TransactionModel>((t) =>
            t.userId == referrerId &&
            t.amount == 7.0 &&
            t.source == TransactionSource.referral &&
            t.description.contains('first-project referral bonus'))),
      )).called(1);

      // Notification sent to referrer
      verify(() => mockNotification.createNotification(
        any(that: isFirstProjectBonusNotification()),
      )).called(1);

      // Referral record updated
      verify(() => mockReferral.updateReferralReward(
        referralId,
        any(that: predicate<Map<String, dynamic>>((updates) =>
            updates['firstProjectRewarded'] == true &&
            updates['firstProjectId'] == _projectId &&
            updates['approvedProjectCount'] == 1 &&
            (updates['rewardAmount'] as double) == 7.0 &&
            (updates['lifetimeProjectCommission'] as double) == 7.0 &&
            (updates['rewardedProjectIds'] as List).contains(_participationId))),
      )).called(1);
    });

    test('credits 5% commission on subsequent approved projects', () async {
      const previousProjectId = 'previous-project-id';
      final referralRecord = createReferralRecord(
        firstProjectRewarded: true,
        rewardedProjectIds: [previousProjectId],
        approvedProjectCount: 1,
        rewardAmount: 7.0,
        lifetimeProjectCommission: 7.0,
      );
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      await repo.creditReward(_participationId, _userId);

      final expectedCommission = _rewardAmount * 0.05; // 25.0 * 0.05 = 1.25

      // Referrer's wallet credited with 5% commission
      verify(() => mockWallet.updateWalletBalance(
        userId: referrerId,
        amountChange: expectedCommission,
        earningsChange: expectedCommission,
        withdrawnChange: 0,
      )).called(1);

      // Referral transaction created with commission description
      verify(() => mockWallet.createTransaction(
        any(that: predicate<TransactionModel>((t) =>
            t.userId == referrerId &&
            t.amount == expectedCommission &&
            t.source == TransactionSource.referral &&
            t.description.contains('commission'))),
      )).called(1);

      // Commission notification sent
      verify(() => mockNotification.createNotification(
        any(that: isCommissionNotification()),
      )).called(1);

      // Referral record updated with commission — should NOT include firstProject fields
      verify(() => mockReferral.updateReferralReward(
        referralId,
        any(that: predicate<Map<String, dynamic>>((updates) =>
            !updates.containsKey('firstProjectRewarded') &&
            !updates.containsKey('firstProjectId') &&
            updates['approvedProjectCount'] == 2 &&
            (updates['lifetimeProjectCommission'] as double) ==
                7.0 + expectedCommission &&
            (updates['rewardedProjectIds'] as List).contains(_participationId))),
      )).called(1);
    });

    test('skips duplicate referral reward for already-rewarded project', () async {
      final referralRecord = createReferralRecord(
        firstProjectRewarded: true,
        rewardedProjectIds: [_participationId], // already rewarded for this participation
        approvedProjectCount: 1,
        lifetimeProjectCommission: 7.0,
      );
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      await repo.creditReward(_participationId, _userId);

      // No additional wallet credit or referral record update
      verifyNever(() => mockWallet.updateWalletBalance(
        userId: referrerId,
        amountChange: any(named: 'amountChange'),
        earningsChange: any(named: 'earningsChange'),
        withdrawnChange: any(named: 'withdrawnChange'),
      ));
      verifyNever(() => mockReferral.updateReferralReward(any(), any()));
    });

    test('still returns true when referral reward processing throws', () async {
      final referralRecord = createReferralRecord(firstProjectRewarded: false);
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      // Make the referrer wallet update throw
      when(() => mockWallet.updateWalletBalance(
        userId: referrerId,
        amountChange: 7.0,
        earningsChange: 7.0,
        withdrawnChange: 0,
      )).thenThrow(Exception('Referral wallet error'));

      final result = await repo.creditReward(_participationId, _userId);

      // Even though referral processing failed, creditReward still returns true
      expect(result, isTrue);
    });

    test('sends notification to referrer about first project bonus', () async {
      final referralRecord = createReferralRecord(firstProjectRewarded: false);
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      await repo.creditReward(_participationId, _userId);

      verify(() => mockNotification.createNotification(
        any(that: isFirstProjectBonusNotification()),
      )).called(1);
    });

    test('sends notification to referrer about commission earned', () async {
      final referralRecord = createReferralRecord(
        firstProjectRewarded: true,
        rewardedProjectIds: ['prev-project'],
        approvedProjectCount: 1,
        rewardAmount: 7.0,
        lifetimeProjectCommission: 7.0,
      );
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      await repo.creditReward(_participationId, _userId);

      verify(() => mockNotification.createNotification(
        any(that: isCommissionNotification()),
      )).called(1);
    });

    test('referral transaction uses TransactionSource.referral', () async {
      final referralRecord = createReferralRecord(firstProjectRewarded: false);
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      await repo.creditReward(_participationId, _userId);

      // Verify the referral transaction uses the correct source
      verify(() => mockWallet.createTransaction(
        any(that: predicate<TransactionModel>((t) =>
            t.userId == referrerId &&
            t.source == TransactionSource.referral)),
      )).called(1);
    });

    test('referral notification uses NotificationType.referral', () async {
      final referralRecord = createReferralRecord(firstProjectRewarded: false);
      _stubCreditRewardFlow(
        mockAffiliate, mockWallet, mockNotification, mockScratchCard, mockReferral,
      );
      stubReferrerRecord(referralRecord);

      await repo.creditReward(_participationId, _userId);

      verify(() => mockNotification.createNotification(
        any(that: predicate<NotificationModel>((n) =>
            n.type == NotificationType.referral)),
      )).called(1);
    });
  });
}
