import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/reward_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/bonus_models.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/reward_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/data/repositories/reward_repository_impl.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';

// ─── Mocks ─────────────────────────────────────────────────

class MockRewardDataSource extends Mock implements RewardFirestoreDataSource {}

class MockWalletDataSource extends Mock implements WalletFirestoreDataSource {}

class MockNotificationDataSource extends Mock implements NotificationFirestoreDataSource {}

class MockFirebaseFirestore extends Mock implements FirebaseFirestore {}

// ─── Constants ──────────────────────────────────────────────

const _userId = 'test-user-uid';

// ─── Helpers ────────────────────────────────────────────────

RewardRepositoryImpl _buildRepo({
  required RewardFirestoreDataSource rewardDataSource,
  required WalletFirestoreDataSource walletDataSource,
  required NotificationFirestoreDataSource notificationDataSource,
  required FirebaseFirestore firestoreInstance,
}) {
  return RewardRepositoryImpl(
    dataSource: rewardDataSource,
    walletDataSource: walletDataSource,
    notificationDataSource: notificationDataSource,
    firestoreInstance: firestoreInstance,
  );
}

DateTime _mondayOf(DateTime date) {
  final monday = date.subtract(Duration(days: date.weekday - 1));
  return DateTime(monday.year, monday.month, monday.day);
}

String _monthKey(DateTime date) {
  return '${date.year}-${date.month.toString().padLeft(2, '0')}';
}

/// Configure all stubs needed for claimDailyCheckIn to run.
/// Uses real DateTime.now() so runtime values match.
void _stubCheckInFlow(
  MockRewardDataSource reward,
  MockWalletDataSource wallet,
  MockNotificationDataSource notifications, {
  bool alreadyCheckedIn = false,
  bool hasWeeklyData = false,
  bool hasMonthlyData = false,
  List<int> weeklyDays = const [],
  List<int> monthlyDays = const [],
}) {
  final now = DateTime.now();

  // Wallet stubs
  when(() => wallet.getWallet(any())).thenAnswer((_) async => null);
  when(() => wallet.createWallet(any())).thenAnswer((_) async {});
  when(() => wallet.updateWalletBalance(
    userId: any(named: 'userId'),
    amountChange: any(named: 'amountChange'),
    earningsChange: any(named: 'earningsChange'),
    withdrawnChange: any(named: 'withdrawnChange'),
  )).thenAnswer((_) async => WalletModel(
    userId: _userId, walletBalance: 0, totalEarnings: 0,
    totalWithdrawn: 0, updatedAt: now,
  ));
  when(() => wallet.createTransaction(any())).thenAnswer((_) async {});

  // Reward config
  when(() => reward.getRewardConfig()).thenAnswer((_) async => null);

  // Check-in
  when(() => reward.getTodayCheckIn(_userId)).thenAnswer((_) async =>
      alreadyCheckedIn
          ? DailyCheckInModel(
              id: 'existing', userId: _userId, checkInDate: now,
              streakDay: 1, rewardAmount: 2.0, claimed: true)
          : null);

  // Streak
  when(() => reward.getStreak(_userId)).thenAnswer((_) async => null);
  when(() => reward.saveStreak(any())).thenAnswer((_) async {});
  when(() => reward.createCheckIn(any())).thenAnswer((_) async {});
  when(() => reward.createReward(any())).thenAnswer((_) async {});

  // Weekly bonus
  if (hasWeeklyData) {
    final weekStart = _mondayOf(now);
    when(() => reward.getWeeklyBonus(_userId))
        .thenAnswer((_) async => WeeklyBonusModel(
              userId: _userId, weekStartDate: weekStart,
              checkedDays: weeklyDays, claimed: false,
              lastUpdated: now.subtract(const Duration(hours: 1)),
            ));
  } else {
    when(() => reward.getWeeklyBonus(_userId))
        .thenAnswer((_) async => null);
  }
  when(() => reward.saveWeeklyBonus(any())).thenAnswer((_) async {});

  // Monthly bonus
  final monthKey = _monthKey(now);
  if (hasMonthlyData) {
    when(() => reward.getMonthlyBonus(_userId, monthKey))
        .thenAnswer((_) async => MonthlyBonusModel(
              userId: _userId, monthKey: monthKey,
              checkedDays: monthlyDays, claimed: false,
              lastUpdated: now.subtract(const Duration(hours: 1)),
            ));
  } else {
    when(() => reward.getMonthlyBonus(_userId, monthKey))
        .thenAnswer((_) async => null);
  }
  when(() => reward.saveMonthlyBonus(any())).thenAnswer((_) async {});

  // Notification stubs (just accept any notification)
  when(() => notifications.createNotification(any())).thenAnswer((_) async {});
}

void main() {
  late MockRewardDataSource mockRewardDataSource;
  late MockWalletDataSource mockWalletDataSource;
  late MockNotificationDataSource mockNotificationDataSource;
  late MockFirebaseFirestore mockFirestore;
  late RewardRepositoryImpl repo;

  setUpAll(() {
    final now = DateTime.now();
    registerFallbackValue(WalletModel(
      userId: '', walletBalance: 0, totalEarnings: 0, totalWithdrawn: 0, updatedAt: now,
    ));
    registerFallbackValue(TransactionModel(
      transactionId: '', userId: '', type: TransactionType.credit,
      amount: 0, source: TransactionSource.reward, status: TransactionStatus.completed, createdAt: now,
    ));
    registerFallbackValue(StreakModel(
      userId: '', lastCheckInDate: now,
    ));
    registerFallbackValue(DailyCheckInModel(
      id: '', userId: '', checkInDate: now, streakDay: 1, rewardAmount: 0, claimed: false,
    ));
    registerFallbackValue(RewardModel(
      rewardId: '', userId: '', rewardType: RewardType.dailyCheckIn,
      rewardAmount: 0, status: RewardStatus.claimed, createdAt: now,
    ));
    registerFallbackValue(WeeklyBonusModel(
      userId: '', weekStartDate: now, checkedDays: [], claimed: false, lastUpdated: now,
    ));
    registerFallbackValue(MonthlyBonusModel(
      userId: '', monthKey: '', checkedDays: [], claimed: false, lastUpdated: now,
    ));
    registerFallbackValue(NotificationModel(
      notificationId: '', userId: '', title: '', message: '',
      type: NotificationType.other, isRead: false, createdAt: now,
    ));
  });

  setUp(() {
    mockRewardDataSource = MockRewardDataSource();
    mockWalletDataSource = MockWalletDataSource();
    mockNotificationDataSource = MockNotificationDataSource();
    mockFirestore = MockFirebaseFirestore();
    repo = _buildRepo(
      rewardDataSource: mockRewardDataSource,
      walletDataSource: mockWalletDataSource,
      notificationDataSource: mockNotificationDataSource,
      firestoreInstance: mockFirestore,
    );
  });

  // ═══════════════════════════════════════════════════════════
  // WeeklyBonusModel serialization
  // ═══════════════════════════════════════════════════════════

  group('WeeklyBonusModel', () {
    test('fromFirestore / toFirestore round-trip', () {
      final ts = Timestamp.fromDate(DateTime(2024, 6, 17, 10, 30));
      final map = {
        'userId': _userId,
        'weekStartDate': ts,
        'checkedDays': [1, 2, 3],
        'claimed': false,
        'lastUpdated': ts,
      };

      final model = WeeklyBonusModel.fromFirestore(map);
      expect(model.userId, _userId);
      expect(model.weekStartDate, ts.toDate());
      expect(model.checkedDays, [1, 2, 3]);
      expect(model.claimed, false);

      final output = model.toFirestore();
      expect(output['checkedDays'], [1, 2, 3]);
      expect(output['claimed'], false);
    });

    test('handles claimed state', () {
      final ts = Timestamp.fromDate(DateTime(2024, 6, 17));
      final map = {
        'userId': _userId,
        'weekStartDate': ts,
        'checkedDays': [1, 2, 3, 4, 5, 6, 7],
        'claimed': true,
        'claimedWeekStartKey': '2024-06-17',
        'lastUpdated': ts,
      };

      final model = WeeklyBonusModel.fromFirestore(map);
      expect(model.claimed, true);
      expect(model.claimedWeekStartKey, '2024-06-17');
    });

    test('uses defaults for empty map', () {
      final model = WeeklyBonusModel.fromFirestore({});
      expect(model.userId, '');
      expect(model.checkedDays, isEmpty);
      expect(model.claimed, false);
    });

    test('copyWith is immutable', () {
      final now = DateTime(2024, 6, 17);
      final original = WeeklyBonusModel(
        userId: _userId, weekStartDate: now,
        checkedDays: [1, 2], claimed: false, lastUpdated: now,
      );
      final copied = original.copyWith(
        checkedDays: [1, 2, 3, 4, 5, 6, 7], claimed: true,
      );
      expect(copied.checkedDays.length, 7);
      expect(copied.claimed, true);
      expect(original.claimed, false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // MonthlyBonusModel serialization
  // ═══════════════════════════════════════════════════════════

  group('MonthlyBonusModel', () {
    test('fromFirestore / toFirestore round-trip', () {
      final ts = Timestamp.fromDate(DateTime(2024, 6, 15));
      final map = {
        'userId': _userId,
        'monthKey': '2024-06',
        'checkedDays': [1, 5, 10, 15],
        'claimed': false,
        'lastUpdated': ts,
      };
      final model = MonthlyBonusModel.fromFirestore(map);
      expect(model.monthKey, '2024-06');
      expect(model.checkedDays, [1, 5, 10, 15]);
    });

    test('handles claimed state', () {
      final ts = Timestamp.fromDate(DateTime(2024, 6, 30));
      final map = {
        'userId': _userId,
        'monthKey': '2024-06',
        'checkedDays': List.generate(30, (i) => i + 1),
        'claimed': true,
        'claimedMonthKey': '2024-06',
        'lastUpdated': ts,
      };
      final model = MonthlyBonusModel.fromFirestore(map);
      expect(model.claimed, true);
      expect(model.claimedMonthKey, '2024-06');
    });

    test('uses defaults for empty map', () {
      final model = MonthlyBonusModel.fromFirestore({});
      expect(model.userId, '');
      expect(model.monthKey, '');
      expect(model.checkedDays, isEmpty);
    });

    test('copyWith is immutable', () {
      final now = DateTime(2024, 6, 1);
      final original = MonthlyBonusModel(
        userId: _userId, monthKey: '2024-06',
        checkedDays: [1, 2], claimed: false, lastUpdated: now,
      );
      final copied = original.copyWith(
        checkedDays: List.generate(30, (i) => i + 1), claimed: true,
      );
      expect(copied.checkedDays.length, 30);
      expect(copied.claimed, true);
      expect(original.claimed, false);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Weekly bonus: _updateWeeklyProgress (via claimDailyCheckIn)
  // ═══════════════════════════════════════════════════════════

  group('_updateWeeklyProgress', () {
    test('creates new weekly data on first check-in', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveWeeklyBonus(any())).called(1);
    });

    test('adds current day to checkedDays', () async {
      final dayOfWeek = DateTime.now().weekday;
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.checkedDays.contains(dayOfWeek) &&
            !w.claimed)),
      )).called(1);
    });

    test('does not duplicate an already-checked day', () async {
      final dayOfWeek = DateTime.now().weekday;
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: [dayOfWeek], // Already checked today
      );

      await repo.claimDailyCheckIn(_userId);

      verifyNever(() => mockRewardDataSource.saveWeeklyBonus(any()));
    });

    test('resets when week changes', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final lastWeekStart = _mondayOf(today).subtract(const Duration(days: 7));
      final thisWeekStart = _mondayOf(today);

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: [1, 2, 3, 4, 5, 6, 7],
      );
      // Override to return last week's data
      when(() => mockRewardDataSource.getWeeklyBonus(_userId))
          .thenAnswer((_) async => WeeklyBonusModel(
                userId: _userId, weekStartDate: lastWeekStart,
                checkedDays: [1, 2, 3, 4, 5, 6, 7], claimed: false,
                lastUpdated: lastWeekStart.add(const Duration(days: 6)),
              ));

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.weekStartDate == thisWeekStart &&
            w.checkedDays.length == 1 &&
            !w.claimed)),
      )).called(1);
    });

    test('handles all 7 days correctly (consecutive chain)', () async {
      final dayOfWeek = DateTime.now().weekday;
      // Generate consecutive prior days: [1, 2, ..., dayOfWeek - 1]
      // Only on Sunday(7) does this produce a full 7-day chain
      final priorDays = List.generate(dayOfWeek - 1, (i) => i + 1);
      final isComplete = dayOfWeek == 7;

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      if (isComplete) {
        verify(() => mockRewardDataSource.saveWeeklyBonus(
          any(that: predicate<WeeklyBonusModel>((w) =>
              w.checkedDays.length == 7)),
        )).called(1);
      } else {
        // Non-Sunday: adds today to the consecutive chain
        verify(() => mockRewardDataSource.saveWeeklyBonus(
          any(that: predicate<WeeklyBonusModel>((w) =>
              w.checkedDays.length == dayOfWeek)),
        )).called(1);
      }
    });

    test('adds today to checkedDays when consecutive (no skipped day)', () async {
      final dayOfWeek = DateTime.now().weekday;
      // Monday(1): no prior day, starts fresh.
      // Tue(2)→Sun(7): prior = yesterday, so checkedDays.last+1 == today → consecutive
      final priorDays = dayOfWeek > 1 ? [dayOfWeek - 1] : <int>[];

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.checkedDays.length == priorDays.length + 1 &&
            w.checkedDays.contains(dayOfWeek))),
      )).called(1);
    });

    test('keeps existing days when a day is skipped but recovery available', () async {
      final dayOfWeek = DateTime.now().weekday;
      // Not testable on Mon(1) or Tue(2): need ≥2 prior days for a skip gap
      if (dayOfWeek <= 2) return;

      // checked [dayOfWeek - 2], skipped [dayOfWeek - 1], now [dayOfWeek]
      // Since recovery is available, existing days are kept and today is added
      final priorDays = [dayOfWeek - 2];

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      // Should keep existing days + add today (recovery available)
      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.checkedDays.length == 2 &&
            w.checkedDays.contains(dayOfWeek - 2) &&
            w.checkedDays.contains(dayOfWeek) &&
            !w.recoveryUsedThisWeek)),
      )).called(1);
    });

    test('keeps existing days when multiple days skipped but recovery available', () async {
      final dayOfWeek = DateTime.now().weekday;
      // Not testable on Mon(1)→Wed(3): need a multi-day gap
      // E.g., checked Mon(1), skipped Tue–Fri(2–5), now Sat(6)
      if (dayOfWeek <= 3) return;

      final priorDays = [1]; // Only Monday checked

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      // Should keep existing days + add today (recovery available)
      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.checkedDays.length == 2 &&
            w.checkedDays.contains(1) &&
            w.checkedDays.contains(dayOfWeek) &&
            !w.recoveryUsedThisWeek)),
      )).called(1);
    });

    test('resets checkedDays when recovery already used and another day is skipped', () async {
      final dayOfWeek = DateTime.now().weekday;
      // Not testable on Mon(1) or Tue(2): need at least a 1-day gap
      if (dayOfWeek <= 2) return;

      final priorDays = [dayOfWeek - 2];

      // Set up default stubs FIRST
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      // THEN override to return data with recovery already used.
      // Must be after _stubCheckInFlow so this override wins (last-registered stub).
      final weekStart = _mondayOf(DateTime.now());
      final now = DateTime.now();
      when(() => mockRewardDataSource.getWeeklyBonus(_userId))
          .thenAnswer((_) async => WeeklyBonusModel(
                userId: _userId,
                weekStartDate: weekStart,
                checkedDays: priorDays,
                claimed: false,
                recoveryUsedThisWeek: true,
                lastUpdated: now.subtract(const Duration(hours: 1)),
              ));

      await repo.claimDailyCheckIn(_userId);

      // Should reset to just today since recovery was already used
      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.checkedDays.length == 1 &&
            w.checkedDays.first == dayOfWeek &&
            w.recoveryUsedThisWeek)),
      )).called(1);
    });

    test('handles edge case: starts fresh on Monday with no prior week data', () async {
      // Monday is dayOfWeek 1; set priorDays empty so checkedDays.isEmpty → consecutive
      final priorDays = <int>[];

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveWeeklyBonus(
        any(that: predicate<WeeklyBonusModel>((w) =>
            w.checkedDays.length == 1)),
      )).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Monthly bonus: _updateMonthlyProgress (via claimDailyCheckIn)
  // ═══════════════════════════════════════════════════════════

  group('_updateMonthlyProgress', () {
    test('creates new monthly data on first check-in', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveMonthlyBonus(any())).called(1);
    });

    test('adds current day to checkedDays', () async {
      final dayOfMonth = DateTime.now().day;
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveMonthlyBonus(
        any(that: predicate<MonthlyBonusModel>((m) =>
            m.checkedDays.contains(dayOfMonth) &&
            !m.claimed)),
      )).called(1);
    });

    test('does not duplicate an already-checked day', () async {
      final dayOfMonth = DateTime.now().day;
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasMonthlyData: true,
        monthlyDays: [dayOfMonth], // Already checked today
      );

      await repo.claimDailyCheckIn(_userId);

      verifyNever(() => mockRewardDataSource.saveMonthlyBonus(any()));
    });

    test('resets when month changes', () async {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final monthKey = _monthKey(today);

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasMonthlyData: false,
      );
      // The datasource checks monthKey and returns null if mismatched.
      // Mock simulating that: return null so the repo creates fresh data.
      when(() => mockRewardDataSource.getMonthlyBonus(_userId, monthKey))
          .thenAnswer((_) async => null);

      await repo.claimDailyCheckIn(_userId);

      // New monthly doc for current month with just today
      verify(() => mockRewardDataSource.saveMonthlyBonus(
        any(that: predicate<MonthlyBonusModel>((m) =>
            m.monthKey == monthKey &&
            m.checkedDays.length == 1)),
      )).called(1);
    });

    test('completes all days of current month', () async {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;
      // All days except today
      final priorDays = List.generate(daysInMonth, (i) => i + 1)
          .where((d) => d != dayOfMonth)
          .toList();

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasMonthlyData: true,
        monthlyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveMonthlyBonus(
        any(that: predicate<MonthlyBonusModel>((m) =>
            m.checkedDays.length == daysInMonth)),
      )).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // claimDailyCheckIn integration
  // ═══════════════════════════════════════════════════════════

  group('claimDailyCheckIn integration', () {
    test('calls both weekly and monthly progress updates', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveWeeklyBonus(any())).called(1);
      verify(() => mockRewardDataSource.saveMonthlyBonus(any())).called(1);
    });

    test('reward is between 1 pts and 3 pts', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.createCheckIn(
        any(that: predicate<DailyCheckInModel>((c) =>
            c.rewardAmount >= 1.0 && c.rewardAmount <= 3.0)),
      )).called(1);
    });

    test('throws exception when already checked in today', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        alreadyCheckedIn: true,
      );

      expect(
        () => repo.claimDailyCheckIn(_userId),
        throwsA(isA<Exception>()),
      );
    });

    test('creates wallet transaction', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockWalletDataSource.createTransaction(any())).called(1);
    });

    test('updates streak', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
      );

      await repo.claimDailyCheckIn(_userId);

      verify(() => mockRewardDataSource.saveStreak(any())).called(1);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Notification on bonus claimable
  // ═══════════════════════════════════════════════════════════

  group('notification on bonus claimable', () {
    test('fires notification when weekly bonus becomes claimable (7th day)', () async {
      final dayOfWeek = DateTime.now().weekday;
      // The 7th day is only reached on Sunday (dayOfWeek == 7)
      // with consecutive prior days [1, 2, 3, 4, 5, 6]
      if (dayOfWeek != 7) return;

      final priorDays = [1, 2, 3, 4, 5, 6];

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: true,
        weeklyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      // Weekly bonus save + notification created
      verify(() => mockNotificationDataSource.createNotification(any())).called(1);
    });

    test('does NOT fire notification when weekly bonus not yet complete', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasWeeklyData: false,
      );

      await repo.claimDailyCheckIn(_userId);

      // First check-in, only 1 day — not claimable yet
      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });

    test('fires notification when monthly bonus becomes claimable (all days)', () async {
      final now = DateTime.now();
      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      final dayOfMonth = now.day;
      final priorDays = List.generate(daysInMonth, (i) => i + 1)
          .where((d) => d != dayOfMonth)
          .toList();

      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasMonthlyData: true,
        monthlyDays: priorDays,
      );

      await repo.claimDailyCheckIn(_userId);

      // Monthly bonus save + notification created
      verify(() => mockNotificationDataSource.createNotification(any())).called(1);
    });

    test('does NOT fire notification when monthly bonus not yet complete', () async {
      _stubCheckInFlow(
        mockRewardDataSource, mockWalletDataSource, mockNotificationDataSource,
        hasMonthlyData: false,
      );

      await repo.claimDailyCheckIn(_userId);

      verifyNever(() => mockNotificationDataSource.createNotification(any()));
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Repository lookup methods
  // ═══════════════════════════════════════════════════════════

  group('getWeeklyBonus', () {
    test('returns data from datasource', () async {
      final now = DateTime.now();
      final expected = WeeklyBonusModel(
        userId: _userId, weekStartDate: now,
        checkedDays: [1, 2, 3], claimed: false, lastUpdated: now,
      );
      when(() => mockRewardDataSource.getWeeklyBonus(_userId))
          .thenAnswer((_) async => expected);

      final result = await repo.getWeeklyBonus(_userId);
      expect(result, isNotNull);
      expect(result!.checkedDays, [1, 2, 3]);
    });

    test('returns null when datasource returns null', () async {
      when(() => mockRewardDataSource.getWeeklyBonus(_userId))
          .thenAnswer((_) async => null);
      final result = await repo.getWeeklyBonus(_userId);
      expect(result, isNull);
    });
  });

  group('getMonthlyBonus', () {
    test('returns data when month matches', () async {
      final now = DateTime.now();
      final monthKey = _monthKey(now);
      final expected = MonthlyBonusModel(
        userId: _userId, monthKey: monthKey,
        checkedDays: [1, 5, 10, 15], claimed: false, lastUpdated: now,
      );
      when(() => mockRewardDataSource.getMonthlyBonus(_userId, monthKey))
          .thenAnswer((_) async => expected);

      final result = await repo.getMonthlyBonus(_userId, monthKey);
      expect(result, isNotNull);
      expect(result!.monthKey, monthKey);
      expect(result.checkedDays, [1, 5, 10, 15]);
    });

    test('returns null when datasource returns null', () async {
      when(() => mockRewardDataSource.getMonthlyBonus(_userId, '2099-01'))
          .thenAnswer((_) async => null);
      final result = await repo.getMonthlyBonus(_userId, '2099-01');
      expect(result, isNull);
    });
  });
}
