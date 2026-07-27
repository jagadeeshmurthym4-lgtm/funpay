import 'dart:async';

import 'package:cashspark/data/repositories/notification_repository_impl.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ────────────────────────────────────────────────

class MockNotificationRepository extends Mock
    implements NotificationRepositoryImpl {}

class MockFcmService extends Mock implements FcmService {}

// ─── Test Fixtures ────────────────────────────────────────

NotificationEntity createNotification({
  String id = 'notif-1',
  String userId = 'user-1',
  String title = 'Test Title',
  String message = 'Test message',
  NotificationType type = NotificationType.reward,
  bool isRead = false,
  DateTime? createdAt,
}) {
  return NotificationEntity(
    notificationId: id,
    userId: userId,
    title: title,
    message: message,
    type: type,
    isRead: isRead,
    createdAt: createdAt ?? DateTime(2026, 7, 1),
  );
}

void main() {
  late MockNotificationRepository mockRepo;
  late MockFcmService mockFcm;
  late NotificationProvider provider;
  late StreamController<List<NotificationEntity>> streamController;

  setUp(() {
    mockRepo = MockNotificationRepository();
    mockFcm = MockFcmService();
    streamController = StreamController<List<NotificationEntity>>.broadcast();

    // Stub FcmService to succeed without real Firebase
    // FcmService.initialize() returns Future<String?>
    when(() => mockFcm.initialize()).thenAnswer((_) async => null);
    when(() => mockFcm.getToken()).thenAnswer((_) async => 'test-token');
    when(() => mockFcm.setUserIdForToken(any())).thenAnswer((_) async {});

    // Stub NotificationRepositoryImpl FCM token saving
    when(() => mockRepo.saveFcmToken(any(), any())).thenAnswer((_) async {});

    // Stub streamNotifications to return our controlled stream
    when(() => mockRepo.streamNotifications(any()))
        .thenAnswer((_) => streamController.stream);

    provider = NotificationProvider(
      notificationRepository: mockRepo,
      fcmService: mockFcm,
    );
  });

  tearDown(() async {
    provider.dispose();
    await streamController.close();
  });

  // ═══════════════════════════════════════════════════════════
  // Initialisation helper
  // ═══════════════════════════════════════════════════════════

  /// Initialises the provider (sets up FCM + starts listening), then emits
  /// [notifications] through the mock stream and waits for the listener to
  /// process them.
  Future<void> withNotifications(
      List<NotificationEntity> notifications) async {
    await provider.initialize('test-user');
    // Let the microtask queue flush so the stream listener is registered
    await Future<void>.delayed(Duration.zero);
    streamController.add(notifications);
    // Let the listener process the emission
    await Future<void>.delayed(Duration.zero);
  }

  // ═══════════════════════════════════════════════════════════
  // Tests
  // ═══════════════════════════════════════════════════════════

  group('NotificationProvider.groupedNotifications', () {
    test('returns empty list when there are no notifications', () async {
      await provider.initialize('test-user');
      await Future<void>.delayed(Duration.zero);

      expect(provider.groupedNotifications, isEmpty);
    });

    test('returns a single group for a single notification', () async {
      final notif = createNotification(
        type: NotificationType.reward,
        isRead: false,
      );

      await withNotifications([notif]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 1);

      final group = groups.first;
      expect(group.type, NotificationType.reward);
      expect(group.notifications, [notif]);
      expect(group.unreadCount, 1);
    });

    test('groups notifications of the same type together', () async {
      final notif1 = createNotification(
        id: 'n1',
        type: NotificationType.reward,
        isRead: false,
      );
      final notif2 = createNotification(
        id: 'n2',
        type: NotificationType.reward,
        isRead: true,
      );

      await withNotifications([notif1, notif2]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 1);

      final group = groups.first;
      expect(group.type, NotificationType.reward);
      expect(group.notifications.length, 2);
      // Unread count counts only unread
      expect(group.unreadCount, 1);
    });

    test('separates notifications of different types into different groups',
        () async {
      final rewardNotif = createNotification(
        id: 'n1',
        type: NotificationType.reward,
      );
      final referralNotif = createNotification(
        id: 'n2',
        type: NotificationType.referral,
      );

      await withNotifications([rewardNotif, referralNotif]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 2);

      final types = groups.map((g) => g.type).toSet();
      expect(types, contains(NotificationType.reward));
      expect(types, contains(NotificationType.referral));
    });

    test('sorts groups with unread notifications before read-only groups',
        () async {
      // Rewards have 1 unread, referrals have 0 unread
      final baseDate = DateTime(2026, 7, 1);
      final rewardUnread = createNotification(
        id: 'n1',
        type: NotificationType.reward,
        isRead: false,
        createdAt: baseDate,
      );
      final referralRead = createNotification(
        id: 'n2',
        type: NotificationType.referral,
        isRead: true,
        createdAt: baseDate.subtract(const Duration(hours: 1)),
      );

      await withNotifications([referralRead, rewardUnread]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 2);

      // First group should be the one with unread (Reward)
      expect(groups[0].type, NotificationType.reward);
      expect(groups[0].unreadCount, greaterThan(0));

      // Second group should have no unread
      expect(groups[1].type, NotificationType.referral);
      expect(groups[1].unreadCount, 0);
    });

    test(
        'sorts groups within same unread status by latest message (newest first)',
        () async {
      // Both groups have unread — the one with the newer latest message comes first
      final yesterday = DateTime(2026, 7, 1);
      final twoDaysAgo = DateTime(2026, 6, 30);

      // Reward group: latest message is yesterday
      final rewardUnread1 = createNotification(
        id: 'n1',
        type: NotificationType.reward,
        isRead: false,
        createdAt: yesterday,
      );
      final rewardUnread2 = createNotification(
        id: 'n2',
        type: NotificationType.reward,
        isRead: false,
        createdAt: twoDaysAgo,
      );

      // Referral group: latest message is even older
      final referralUnread = createNotification(
        id: 'n3',
        type: NotificationType.referral,
        isRead: false,
        createdAt: DateTime(2026, 6, 28),
      );

      await withNotifications([
        referralUnread,
        rewardUnread1,
        rewardUnread2,
      ]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 2);

      // Reward group has the newer latestAt, so it should come first
      expect(groups[0].type, NotificationType.reward);
      expect(groups[0].latestAt, yesterday);

      // Referral group has older latestAt
      expect(groups[1].type, NotificationType.referral);
    });

    test('sorts notifications within each group by createdAt (newest first)',
        () async {
      final oldest = DateTime(2026, 7, 1);
      final middle = DateTime(2026, 7, 3);
      final newest = DateTime(2026, 7, 5);

      final notif1 = createNotification(
        id: 'n1',
        type: NotificationType.reward,
        createdAt: oldest,
      );
      final notif2 = createNotification(
        id: 'n2',
        type: NotificationType.reward,
        createdAt: newest,
      );
      final notif3 = createNotification(
        id: 'n3',
        type: NotificationType.reward,
        createdAt: middle,
      );

      await withNotifications([notif1, notif2, notif3]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 1);

      final groupNotifications = groups.first.notifications;
      expect(groupNotifications[0].notificationId, 'n2'); // newest
      expect(groupNotifications[1].notificationId, 'n3'); // middle
      expect(groupNotifications[2].notificationId, 'n1'); // oldest
    });

    test('unreadCount is zero when all notifications in a group are read',
        () async {
      final notif1 = createNotification(
        id: 'n1',
        type: NotificationType.announcement,
        isRead: true,
      );
      final notif2 = createNotification(
        id: 'n2',
        type: NotificationType.announcement,
        isRead: true,
      );

      await withNotifications([notif1, notif2]);

      final groups = provider.groupedNotifications;
      expect(groups.length, 1);
      expect(groups.first.unreadCount, 0);
    });

    test('handles multiple types with mixed read/unread status correctly',
        () async {
      final base = DateTime(2026, 7, 1);

      // Withdrawal: 2 unread, 1 read (total 3) — newest unread is at `base`
      final withdraw1 = createNotification(
        id: 'w1',
        type: NotificationType.withdrawal,
        isRead: false,
        createdAt: base,
      );
      final withdraw2 = createNotification(
        id: 'w2',
        type: NotificationType.withdrawal,
        isRead: false,
        createdAt: base.subtract(const Duration(hours: 1)),
      );
      final withdraw3 = createNotification(
        id: 'w3',
        type: NotificationType.withdrawal,
        isRead: true,
        createdAt: base.subtract(const Duration(hours: 2)),
      );
      // Reward: 1 unread — latestAt older than withdrawal
      final reward1 = createNotification(
        id: 'r1',
        type: NotificationType.reward,
        isRead: false,
        createdAt: base.subtract(const Duration(hours: 3)),
      );
      // Announcement: all read
      final announce1 = createNotification(
        id: 'a1',
        type: NotificationType.announcement,
        isRead: true,
        createdAt: base.subtract(const Duration(hours: 4)),
      );

      await withNotifications([
        announce1,
        reward1,
        withdraw1,
        withdraw2,
        withdraw3,
      ]);

      final groups = provider.groupedNotifications;
      // Should have 3 groups: reward + withdrawal + announcement
      expect(groups.length, 3);

      // Withdrawal has 2 unread → should be first
      expect(groups[0].type, NotificationType.withdrawal);
      expect(groups[0].unreadCount, 2);
      expect(groups[0].notifications.length, 3);

      // Reward has 1 unread → should be second
      expect(groups[1].type, NotificationType.reward);
      expect(groups[1].unreadCount, 1);

      // Announcement has 0 unread → should be last
      expect(groups[2].type, NotificationType.announcement);
      expect(groups[2].unreadCount, 0);
    });

    test('does not mutate the original _notifications list', () async {
      final notif1 = createNotification(
        id: 'n1',
        type: NotificationType.reward,
      );
      final notif2 = createNotification(
        id: 'n2',
        type: NotificationType.referral,
      );

      await withNotifications([notif1, notif2]);

      // Call groupedNotifications once
      final firstCall = provider.groupedNotifications;
      expect(firstCall.length, 2);

      // Call it again — should return groups in the same order
      final secondCall = provider.groupedNotifications;
      expect(secondCall.length, 2);
      expect(secondCall[0].type, firstCall[0].type);
      expect(secondCall[1].type, firstCall[1].type);
    });
  });
}
