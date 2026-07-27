import 'package:cashspark/data/datasources/affiliate_project_firestore_datasource.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/datasources/scratch_card_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/affiliate_project_model.dart';
import 'package:cashspark/data/models/admin_model.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/data/repositories/affiliate_project_repository_impl.dart';
import 'package:cashspark/data/repositories/admin_repository_impl.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mock Data Sources ────────────────────────────────────

class MockNotificationFirestoreDataSource extends Mock
    implements NotificationFirestoreDataSource {}

class MockAffiliateProjectFirestoreDataSource extends Mock
    implements AffiliateProjectFirestoreDataSource {}

class MockWalletFirestoreDataSource extends Mock
    implements WalletFirestoreDataSource {}

class MockAdminFirestoreDataSource extends Mock
    implements AdminFirestoreDataSource {}

class MockScratchCardFirestoreDataSource extends Mock
    implements ScratchCardFirestoreDataSource {}

class MockReferralFirestoreDataSource extends Mock
    implements ReferralFirestoreDataSource {}

// ─── Fixtures ─────────────────────────────────────────────

ProjectParticipationModel createParticipation({
  String id = 'part-1',
  String projectId = 'proj-1',
  String projectTitle = 'Test Project',
  String userId = 'user-1',
  String userName = 'Test User',
  double rewardAmount = 50.0,
  String status = 'pendingReview',
  String? rejectionReason,
  String? reviewedBy,
  bool rewardCredited = false,
}) {
  return ProjectParticipationModel(
    participationId: id,
    projectId: projectId,
    projectTitle: projectTitle,
    userId: userId,
    userName: userName,
    rewardAmount: rewardAmount,
    status: status,
    startedAt: DateTime(2026, 7, 1),
    submittedAt: DateTime(2026, 7, 2),
    rejectionReason: rejectionReason,
    reviewedBy: reviewedBy,
    rewardCredited: rewardCredited,
  );
}

UserModel createUser({
  String uid = 'user-1',
  String? email,
}) {
  return UserModel(
    uid: uid,
    email: email ?? '$uid@test.com',
    fullName: 'Test User',
    referralCode: '',
    createdAt: DateTime(2026, 7, 1),
  );
}

void main() {
  late MockNotificationFirestoreDataSource mockNotificationDataSource;
  late MockAffiliateProjectFirestoreDataSource mockProjectDataSource;
  late MockWalletFirestoreDataSource mockWalletDataSource;
  late MockAdminFirestoreDataSource mockAdminDataSource;
  late MockScratchCardFirestoreDataSource mockScratchCardDataSource;
  late MockReferralFirestoreDataSource mockReferralDataSource;
  late AffiliateProjectRepositoryImpl affiliateRepo;
  late AdminRepositoryImpl adminRepo;

  setUpAll(() {
    registerFallbackValue(NotificationModel(
      notificationId: 'dummy',
      userId: 'dummy',
      title: '',
      message: '',
      type: NotificationType.other,
      createdAt: DateTime(2020),
    ));
    registerFallbackValue(TransactionModel(
      transactionId: 'dummy',
      userId: 'dummy',
      type: TransactionType.credit,
      amount: 0,
      source: TransactionSource.reward,
      status: TransactionStatus.completed,
      description: '',
      createdAt: DateTime(2020),
    ));
    registerFallbackValue(AppSettingsModel(
      id: 'dummy',
      updatedAt: DateTime(2020),
    ));
    registerFallbackValue(ScratchCardModel(
      scratchCardId: '', userId: '', submissionId: '',
      createdAt: DateTime(2020),
    ));
    registerFallbackValue(ReferralModel(
      referralId: '', referrerUserId: '', referredUserId: '',
      referralCode: '', createdAt: DateTime(2020),
    ));
  });

  setUp(() {
    mockNotificationDataSource = MockNotificationFirestoreDataSource();
    mockProjectDataSource = MockAffiliateProjectFirestoreDataSource();
    mockWalletDataSource = MockWalletFirestoreDataSource();
    mockAdminDataSource = MockAdminFirestoreDataSource();
    mockScratchCardDataSource = MockScratchCardFirestoreDataSource();
    mockReferralDataSource = MockReferralFirestoreDataSource();

    affiliateRepo = AffiliateProjectRepositoryImpl(
      dataSource: mockProjectDataSource,
      walletDataSource: mockWalletDataSource,
      notificationDataSource: mockNotificationDataSource,
      adminDataSource: mockAdminDataSource,
      scratchCardDataSource: mockScratchCardDataSource,
      referralDataSource: mockReferralDataSource,
    );

    adminRepo = AdminRepositoryImpl(
      dataSource: mockAdminDataSource,
      walletDataSource: mockWalletDataSource,
      notificationDataSource: mockNotificationDataSource,
    );
  });

  // ═══════════════════════════════════════════════════════════
  // AffiliateProjectRepositoryImpl — Notification Tests
  // ═══════════════════════════════════════════════════════════

  group('AffiliateProjectRepositoryImpl notification creation', () {
    test(
        'approveParticipation sends "Reward Approved 🎉" notification '
        'with correct title, message, and type', () async {
      final participation = createParticipation();

      when(() => mockProjectDataSource.getParticipationById('part-1'))
          .thenAnswer((_) async => participation);
      when(() => mockProjectDataSource.updateParticipationStatus(
            'part-1',
            'approved',
            reviewedBy: any(named: 'reviewedBy'),
          )).thenAnswer((_) async {});
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});

      await affiliateRepo.approveParticipation('part-1', reviewedBy: 'admin-1');

      final captured = verify(() =>
              mockNotificationDataSource.createNotification(captureAny()))
          .captured;
      final notification = captured.last as NotificationModel;

      expect(notification.title, 'Reward Approved 🎉');
      expect(notification.message, contains('Test Project'));
      expect(notification.message, contains('approved'));
      expect(notification.type, NotificationType.reward);
      expect(notification.userId, 'user-1');
    });

    test(
        'approveParticipation does not fail if notification creation throws',
        () async {
      final participation = createParticipation();

      when(() => mockProjectDataSource.getParticipationById('part-1'))
          .thenAnswer((_) async => participation);
      when(() => mockProjectDataSource.updateParticipationStatus(
            'part-1',
            'approved',
            reviewedBy: any(named: 'reviewedBy'),
          )).thenAnswer((_) async {});
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenThrow(Exception('Network error'));

      // Should not throw despite notification failure
      await affiliateRepo.approveParticipation('part-1');
      // Verify upstream status update still happened
      verify(() => mockProjectDataSource.updateParticipationStatus(
            'part-1',
            'approved',
            reviewedBy: any(named: 'reviewedBy'),
          )).called(1);
    });

    test(
        'rejectParticipation sends "❌ Submission Rejected" notification '
        'with rejection reason', () async {
      final participation = createParticipation(rejectionReason: null);

      when(() => mockProjectDataSource.getParticipationById('part-1'))
          .thenAnswer((_) async => participation);
      when(() => mockProjectDataSource.updateParticipationPartial(
            'part-1',
            any(),
          )).thenAnswer((_) async {});
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});

      await affiliateRepo.rejectParticipation('part-1', 'Invalid screenshot');

      final captured = verify(() =>
              mockNotificationDataSource.createNotification(captureAny()))
          .captured;
      final notification = captured.last as NotificationModel;

      expect(notification.title, '❌ Submission Rejected');
      expect(notification.message, contains('Test Project'));
      expect(notification.message, contains('Invalid screenshot'));
      expect(notification.type, NotificationType.reward);
      expect(notification.userId, 'user-1');
    });

    test(
        'rejectParticipation does not send notification if participation '
        'not found', () async {
      when(() => mockProjectDataSource.getParticipationById('part-1'))
          .thenAnswer((_) async => null);
      when(() => mockProjectDataSource.updateParticipationPartial(
            'part-1',
            any(),
          )).thenAnswer((_) async {});

      await affiliateRepo.rejectParticipation('part-1', 'Not found');

      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });

    test(
        'creditReward sends "Reward Credited 💰" notification '
        'with reward amount', () async {
      final participation = createParticipation(
        rewardAmount: 75.0,
        rewardCredited: false,
      );

      when(() => mockProjectDataSource.getParticipationById('part-1'))
          .thenAnswer((_) async => participation);
      when(() => mockWalletDataSource.updateWalletBalance(
            userId: any(named: 'userId'),
            amountChange: any(named: 'amountChange'),
            earningsChange: any(named: 'earningsChange'),
            withdrawnChange: any(named: 'withdrawnChange'),
          )).thenAnswer((_) async {
        return WalletModel(
          userId: 'user-1',
          walletBalance: 175.0,
          totalEarnings: 175.0,
          totalWithdrawn: 0,
          updatedAt: DateTime.now(),
        );
      });
      when(() => mockWalletDataSource.createTransaction(any()))
          .thenAnswer((_) async {});
      when(() => mockProjectDataSource.markRewardCredited('part-1'))
          .thenAnswer((_) async {});
      when(() => mockProjectDataSource.incrementCompletedCount('proj-1'))
          .thenAnswer((_) async {});
      when(() => mockProjectDataSource.incrementTotalRewardsPaid(
            'proj-1',
            75.0,
          )).thenAnswer((_) async {});
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});
      // Stub scratch card and referral datasources (used inside creditReward)
      when(() => mockScratchCardDataSource.hasScratchCardForSubmission(any()))
          .thenAnswer((_) async => false);
      when(() => mockScratchCardDataSource.createScratchCard(any()))
          .thenAnswer((_) async {});
      when(() => mockReferralDataSource.getReferralByReferredUser(any()))
          .thenAnswer((_) async => null);

      final result = await affiliateRepo.creditReward('part-1', 'user-1');

      expect(result, true);

      final captured = verify(() =>
              mockNotificationDataSource.createNotification(captureAny()))
          .captured;
      final notifications = captured.cast<NotificationModel>();
      // The reward credited notification is sent BEFORE the scratch card one
      final notification = notifications.firstWhere(
        (n) => n.title == 'Reward Credited 💰');

      expect(notification.title, 'Reward Credited 💰');
      expect(notification.message, contains('75.00'));
      expect(notification.message, contains('Test Project'));
      expect(notification.message, contains('credited'));
      expect(notification.type, NotificationType.reward);
      expect(notification.userId, 'user-1');
    });

    test(
        'creditReward does not send notification if already credited',
        () async {
      final participation = createParticipation(rewardCredited: true);

      when(() => mockProjectDataSource.getParticipationById('part-1'))
          .thenAnswer((_) async => participation);

      final result = await affiliateRepo.creditReward('part-1', 'user-1');

      expect(result, false);
      verifyNever(() => mockWalletDataSource.updateWalletBalance(
            userId: any(named: 'userId'),
            amountChange: any(named: 'amountChange'),
            earningsChange: any(named: 'earningsChange'),
            withdrawnChange: any(named: 'withdrawnChange'),
          ));
      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });

    test(
        'notifyProjectExpired sends "Project Expired ⏰" notification '
        'only for inProgress and pendingReview participations', () async {
      final inProgressParticipation = createParticipation(
        id: 'part-1',
        userId: 'user-1',
        status: 'inProgress',
      );
      final pendingParticipation = createParticipation(
        id: 'part-2',
        userId: 'user-2',
        status: 'pendingReview',
      );
      final completedParticipation = createParticipation(
        id: 'part-3',
        userId: 'user-3',
        status: 'completed',
      );
      final allParticipations = [
        inProgressParticipation,
        pendingParticipation,
        completedParticipation,
      ];

      when(() => mockProjectDataSource.getParticipations('proj-1'))
          .thenAnswer((_) async => allParticipations);
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});

      await affiliateRepo.notifyProjectExpired('proj-1', 'Test Project');

      // Should have been called exactly twice (for inProgress + pendingReview)
      final captured = verify(() =>
              mockNotificationDataSource.createNotification(captureAny()))
          .captured;
      expect(captured.length, 2,
          reason: 'Should notify inProgress and pendingReview only');
      final notifications = captured.cast<NotificationModel>();

      for (final n in notifications) {
        expect(n.title, 'Project Expired ⏰');
        expect(n.message, contains('expired'));
        expect(n.message, contains('support'));
        expect(n.type, NotificationType.reward);
      }

      // Completed participation should NOT get a notification
      final notifiedUserIds =
          notifications.map((n) => n.userId).toSet();
      expect(notifiedUserIds, contains('user-1'));
      expect(notifiedUserIds, contains('user-2'));
      expect(notifiedUserIds, isNot(contains('user-3')));
    });

    test(
        'notifyProjectExpired handles no participations gracefully',
        () async {
      when(() => mockProjectDataSource.getParticipations('proj-1'))
          .thenAnswer((_) async => []);

      await affiliateRepo.notifyProjectExpired('proj-1', 'Test Project');

      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });

    test(
        'notifyNewProject sends "🆕 New Project Available" notification '
        'to all users', () async {
      final users = [
        createUser(uid: 'user-1', email: 'user1@test.com'),
        createUser(uid: 'user-2', email: 'user2@test.com'),
        createUser(uid: 'user-3', email: 'user3@test.com'),
      ];

      when(() => mockAdminDataSource.getAllUsers(limit: 1000))
          .thenAnswer((_) async => users);
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});

      await affiliateRepo.notifyNewProject('New Cool Project', 'admin-1');

      // Should have been called 3 times (once per user)
      final captured = verify(() =>
              mockNotificationDataSource.createNotification(captureAny()))
          .captured;
      expect(captured.length, 3,
          reason: 'Should notify all 3 users');
      final notifications = captured.cast<NotificationModel>();

      for (final n in notifications) {
        expect(n.title, '🆕 New Project Available');
        expect(n.message, contains('New Cool Project'));
        expect(n.type, NotificationType.announcement);
      }

      final notifiedUserIds =
          notifications.map((n) => n.userId).toSet();
      expect(notifiedUserIds, contains('user-1'));
      expect(notifiedUserIds, contains('user-2'));
      expect(notifiedUserIds, contains('user-3'));
    });

    test(
        'notifyNewProject handles zero users gracefully', () async {
      when(() => mockAdminDataSource.getAllUsers(limit: 1000))
          .thenAnswer((_) async => []);

      await affiliateRepo.notifyNewProject('New Project', 'admin-1');

      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // AdminRepositoryImpl — Notification Tests
  // ═══════════════════════════════════════════════════════════

  group('AdminRepositoryImpl notification creation', () {
    test(
        'sendAnnouncement broadcasts "📢 New Announcement" notification '
        'to all users', () async {
      final settings = AppSettingsModel(
        id: 'settings',
        updatedAt: DateTime(2026, 7, 1),
      );
      final users = [
        createUser(uid: 'user-1'),
        createUser(uid: 'user-2'),
      ];

      when(() => mockAdminDataSource.getAppSettings())
          .thenAnswer((_) async => settings);
      when(() => mockAdminDataSource.saveAppSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockAdminDataSource.getAllUsers(limit: 1000))
          .thenAnswer((_) async => users);
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});

      await adminRepo.sendAnnouncement('System maintenance tonight!');

      // Should have been called 2 times (once per user)
      final captured = verify(() =>
              mockNotificationDataSource.createNotification(captureAny()))
          .captured;
      expect(captured.length, 2,
          reason: 'Should notify all users');
      final notifications = captured.cast<NotificationModel>();

      for (final n in notifications) {
        expect(n.title, '📢 New Announcement');
        expect(n.message, 'System maintenance tonight!');
        expect(n.type, NotificationType.announcement);
      }

      final notifiedUserIds =
          notifications.map((n) => n.userId).toSet();
      expect(notifiedUserIds, contains('user-1'));
      expect(notifiedUserIds, contains('user-2'));
    });

    test(
        'sendAnnouncement does not fail if app settings not found',
        () async {
      final users = [
        createUser(uid: 'user-1'),
      ];

      when(() => mockAdminDataSource.getAppSettings())
          .thenAnswer((_) async => null);
      when(() => mockAdminDataSource.saveAppSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockAdminDataSource.getAllUsers(limit: 1000))
          .thenAnswer((_) async => users);
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenAnswer((_) async {});

      // Should not throw even if getAppSettings returns null
      await adminRepo.sendAnnouncement('Important message');

      verify(() => mockNotificationDataSource.createNotification(any()))
          .called(1);
    });

    test(
        'sendAnnouncement does not fail if getAllUsers returns empty',
        () async {
      final settings = AppSettingsModel(
        id: 'settings',
        updatedAt: DateTime(2026, 7, 1),
      );

      when(() => mockAdminDataSource.getAppSettings())
          .thenAnswer((_) async => settings);
      when(() => mockAdminDataSource.saveAppSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockAdminDataSource.getAllUsers(limit: 1000))
          .thenAnswer((_) async => []);

      await adminRepo.sendAnnouncement('Test');

      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });

    test(
        'sendAnnouncement does not fail if notification creation throws',
        () async {
      final settings = AppSettingsModel(
        id: 'settings',
        updatedAt: DateTime(2026, 7, 1),
      );
      final users = [createUser(uid: 'user-1')];

      when(() => mockAdminDataSource.getAppSettings())
          .thenAnswer((_) async => settings);
      when(() => mockAdminDataSource.saveAppSettings(any()))
          .thenAnswer((_) async {});
      when(() => mockAdminDataSource.getAllUsers(limit: 1000))
          .thenAnswer((_) async => users);
      when(() => mockNotificationDataSource.createNotification(any()))
          .thenThrow(Exception('DB error'));

      // Should not throw despite notification failure
      await adminRepo.sendAnnouncement('Test');
      // Verify settings still got saved
      verify(() => mockAdminDataSource.saveAppSettings(any())).called(1);
    });
  });
}
