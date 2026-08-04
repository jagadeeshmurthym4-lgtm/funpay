import 'dart:math';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/reward_firestore_datasource.dart';
import 'package:cashspark/data/datasources/streak_multiplier_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/bonus_models.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/reward_model.dart';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/data/models/spin_data_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/repositories/reward_repository.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

class RewardRepositoryImpl implements RewardRepository {
  final RewardFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final NotificationFirestoreDataSource _notificationDataSource;
  StreakMultiplierFirestoreDataSource? _streakMultiplierDs;
  final FirebaseFirestore _firestore;
  final Uuid _uuid;

  RewardRepositoryImpl({
    required RewardFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    required NotificationFirestoreDataSource notificationDataSource,
    StreakMultiplierFirestoreDataSource? streakMultiplierDataSource,
    FirebaseFirestore? firestoreInstance,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _notificationDataSource = notificationDataSource,
        _streakMultiplierDs = streakMultiplierDataSource,
        _firestore = firestoreInstance ?? FirebaseFirestore.instance,
        _uuid = uuid ?? const Uuid();

  /// Lazily initializes the streak multiplier data source if not provided.
  StreakMultiplierFirestoreDataSource get _streakMultiplierDataSource {
    _streakMultiplierDs ??= StreakMultiplierFirestoreDataSource();
    return _streakMultiplierDs!;
  }

  @override
  Future<RewardConfigEntity> getRewardConfig() async {
    try {
      final config = await _dataSource.getRewardConfig();
      if (config == null) {
        return const RewardConfigEntity(id: 'config');
      }
      return config;
    } catch (e) {
      throw FirestoreException('Failed to get reward config: $e');
    }
  }

  @override
  Future<RewardEntity> claimAdReward(String userId) async {
    try {
      final config = await getRewardConfig();
      if (!config.isActive) {
        throw RewardsException('Rewards system is disabled');
      }

      final lastAdTime = await _dataSource.getLastAdWatchTime(userId);
      if (lastAdTime != null) {
        final elapsed = DateTime.now().difference(lastAdTime).inSeconds;
        if (elapsed < config.adCooldownSeconds) {
          final remaining = config.adCooldownSeconds - elapsed;
          throw RewardsException('Please wait $remaining seconds');
        }
      }

      await _ensureWalletExists(userId);
      // Weighted random reward: most of the time gives lower amount
      // Range: ₹0.80 - ₹2.00, biased toward lower end
      final roll = Random().nextInt(100);
      double rewardAmount;
      if (roll < 60) {
        // 60% chance: ₹0.80 - ₹1.20
        rewardAmount = 0.80 + Random().nextDouble() * 0.40;
      } else if (roll < 90) {
        // 30% chance: ₹1.20 - ₹1.60
        rewardAmount = 1.20 + Random().nextDouble() * 0.40;
      } else {
        // 10% chance: ₹1.60 - ₹2.00
        rewardAmount = 1.60 + Random().nextDouble() * 0.40;
      }
      rewardAmount = (rewardAmount * 100).roundToDouble() / 100; // round to 2 decimals

      await _walletDataSource.updateWalletBalance(
        userId: userId,
        amountChange: rewardAmount,
        earningsChange: rewardAmount,
        withdrawnChange: 0,
      );

      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.credit,
        amount: rewardAmount,
        source: TransactionSource.reward,
        status: TransactionStatus.completed,
        description: 'Rewarded ad watch bonus',
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);

      final reward = RewardModel(
        rewardId: _uuid.v4(),
        userId: userId,
        rewardType: RewardType.adReward,
        rewardAmount: rewardAmount,
        status: RewardStatus.claimed,
        createdAt: DateTime.now(),
        claimedAt: DateTime.now(),
      );
      await _dataSource.createReward(reward);

      // Also generate a scratch card for completing a rewarded ad
      await addScratchCardFromAd(userId, reward.rewardId);

      return reward;
    } on RewardsException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to claim ad reward: $e');
    }
  }

  @override
  Future<int> getTodayAdCount(String userId) async {
    try {
      return await _dataSource.getTodayAdCount(userId);
    } catch (e) {
      throw FirestoreException('Failed to get ad count: $e');
    }
  }

  @override
  Future<DateTime?> getLastAdWatchTime(String userId) async {
    try {
      return await _dataSource.getLastAdWatchTime(userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<RewardEntity>> getAdRewardHistory(String userId) async {
    try {
      return await _dataSource.getRewardsByType(userId, RewardType.adReward);
    } catch (e) {
      throw FirestoreException('Failed to get ad history: $e');
    }
  }

  @override
  Future<DailyCheckInEntity> claimDailyCheckIn(String userId) async {
    try {
      final config = await getRewardConfig();
      if (!config.isActive) {
        throw RewardsException('Rewards system is disabled');
      }

      final todayCheckIn = await _dataSource.getTodayCheckIn(userId);
      if (todayCheckIn != null && todayCheckIn.claimed) {
        throw RewardsException('Already checked in today');
      }

      var streak = await _dataSource.getStreak(userId);
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);

      int newStreakCount = 1;
      DateTime? streakStart = today;

      if (streak != null) {
        final lastCheckIn = DateTime(
          streak.lastCheckInDate.year,
          streak.lastCheckInDate.month,
          streak.lastCheckInDate.day,
        );
        final diff = today.difference(lastCheckIn).inDays;

        if (diff == 1) {
          newStreakCount = streak.currentStreak + 1;
          streakStart = streak.streakStartDate ?? lastCheckIn;
        } else if (diff > 1) {
          newStreakCount = 1;
          streakStart = today;
        }
      }

      // Random base reward: ₹1, ₹2, or ₹3
      final baseAmount = [1.0, 2.0, 3.0][Random().nextInt(3)];

      // ─── Apply Streak Multiplier ────────────────────────────
      double finalRewardAmount = baseAmount;
      try {
        final multiplierConfig = await _streakMultiplierDataSource.getConfig();
        if (multiplierConfig != null && multiplierConfig.isEnabled) {
          final multiplier =
              multiplierConfig.getMultiplierForStreak(newStreakCount);
          finalRewardAmount = (baseAmount * multiplier * 100).roundToDouble() / 100;
          if (multiplier > 1.0) {
            debugPrint(
              'Streak multiplier applied: $newStreakCount-day streak → ${multiplier}x, ₹$baseAmount → ₹$finalRewardAmount',
            );
          }
        }
      } catch (e) {
        // Silently fall back to base amount if multiplier config fails
        debugPrint('Failed to apply streak multiplier: $e');
      }

      final rewardAmount = finalRewardAmount;

      await _ensureWalletExists(userId);

      await _walletDataSource.updateWalletBalance(
        userId: userId,
        amountChange: rewardAmount,
        earningsChange: rewardAmount,
        withdrawnChange: 0,
      );

      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.credit,
        amount: rewardAmount,
        source: TransactionSource.reward,
        status: TransactionStatus.completed,
        description: newStreakCount >= 7 && rewardAmount > baseAmount
            ? 'Day $newStreakCount check-in + streak bonus'
            : 'Day $newStreakCount check-in reward',
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);

      final newStreak = StreakModel(
        userId: userId,
        currentStreak: newStreakCount,
        longestStreak: newStreakCount > (streak?.longestStreak ?? 0)
            ? newStreakCount
            : (streak?.longestStreak ?? 0),
        lastCheckInDate: now,
        streakStartDate: streakStart,
      );
      await _dataSource.saveStreak(newStreak);

      final checkIn = DailyCheckInModel(
        id: _uuid.v4(),
        userId: userId,
        checkInDate: now,
        streakDay: newStreakCount,
        rewardAmount: rewardAmount,
        claimed: true,
      );
      await _dataSource.createCheckIn(checkIn);

      final reward = RewardModel(
        rewardId: _uuid.v4(),
        userId: userId,
        rewardType: RewardType.dailyCheckIn,
        rewardAmount: rewardAmount,
        status: RewardStatus.claimed,
        createdAt: DateTime.now(),
        claimedAt: DateTime.now(),
      );
      await _dataSource.createReward(reward);

      // ─── Update Weekly Bonus Progress ──────────────
      await _updateWeeklyProgress(userId, now);

      // ─── Update Monthly Bonus Progress ─────────────
      await _updateMonthlyProgress(userId, now);

      return checkIn;
    } on RewardsException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to claim daily check-in: $e');
    }
  }

  @override
  Future<StreakEntity> getStreak(String userId) async {
    try {
      final streak = await _dataSource.getStreak(userId);
      return streak ?? StreakModel(userId: userId, lastCheckInDate: DateTime.now());
    } catch (e) {
      throw FirestoreException('Failed to get streak: $e');
    }
  }

  @override
  Future<DailyCheckInEntity?> getTodayCheckIn(String userId) async {
    try {
      return await _dataSource.getTodayCheckIn(userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<List<DailyCheckInEntity>> getCheckInHistory(String userId,
      {int limit = 30}) async {
    try {
      return await _dataSource.getCheckInHistory(userId, limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get check-in history: $e');
    }
  }

  @override
  Stream<StreakEntity?> streamStreak(String userId) {
    return _dataSource.streamStreak(userId);
  }

  @override
  Future<List<TaskEntity>> getTodaysTasks(String userId) async {
    try {
      return await _dataSource.getTodaysTasks(userId);
    } catch (e) {
      throw FirestoreException('Failed to get tasks: $e');
    }
  }

  @override
  Future<TaskEntity> updateTaskProgress(String taskId, int increment) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw FirestoreException('Task not found');
      }

      final task = TaskModel.fromFirestore(doc.data()!);
      final newProgress = (task.progressCount + increment).clamp(0, task.requiredCount);
      final newStatus = newProgress >= task.requiredCount
          ? TaskStatus.completed
          : TaskStatus.inProgress;

      final updated = task.copyWith(
        progressCount: newProgress,
        status: newStatus,
        completedAt: newStatus == TaskStatus.completed ? DateTime.now() : null,
      );

      await _dataSource.updateTask(TaskModel.fromEntity(updated));
      return updated;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to update task: $e');
    }
  }

  @override
  Future<RewardEntity> claimTaskReward(String taskId) async {
    try {
      final config = await getRewardConfig();
      if (!config.isActive) {
        throw RewardsException('Rewards system is disabled');
      }

      final doc = await _firestore
          .collection(AppConstants.tasksCollection)
          .doc(taskId)
          .get();
      if (!doc.exists || doc.data() == null) {
        throw FirestoreException('Task not found');
      }

      final task = TaskModel.fromFirestore(doc.data()!);
      if (task.status != TaskStatus.completed) {
        throw RewardsException('Task is not yet completed');
      }
      if (task.status == TaskStatus.claimed) {
        throw RewardsException('Task reward already claimed');
      }

      await _ensureWalletExists(task.userId);

      await _walletDataSource.updateWalletBalance(
        userId: task.userId,
        amountChange: task.rewardAmount,
        earningsChange: task.rewardAmount,
        withdrawnChange: 0,
      );

      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: task.userId,
        type: TransactionType.credit,
        amount: task.rewardAmount,
        source: TransactionSource.reward,
        status: TransactionStatus.completed,
        description: 'Task reward: ${task.title}',
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);

      final updatedTask = task.copyWith(
        status: TaskStatus.claimed,
        completedAt: DateTime.now(),
      );
      await _dataSource.updateTask(TaskModel.fromEntity(updatedTask));

      final reward = RewardModel(
        rewardId: _uuid.v4(),
        userId: task.userId,
        rewardType: RewardType.taskReward,
        rewardAmount: task.rewardAmount,
        status: RewardStatus.claimed,
        createdAt: DateTime.now(),
        claimedAt: DateTime.now(),
      );
      await _dataSource.createReward(reward);

      return reward;
    } on RewardsException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to claim task reward: $e');
    }
  }

  @override
  Stream<List<TaskEntity>> streamTasks(String userId) {
    return _dataSource.streamTodaysTasks(userId);
  }

  // --- Spin Data ---

  @override
  Future<SpinDataEntity?> getSpinData(String userId) async {
    try {
      return await _dataSource.getSpinData(userId);
    } catch (e) {
      throw FirestoreException('Failed to get spin data: $e');
    }
  }

  @override
  Future<void> saveSpinData(SpinDataEntity data) async {
    try {
      await _dataSource.saveSpinData(SpinDataModel.fromEntity(data));
    } catch (e) {
      throw FirestoreException('Failed to save spin data: $e');
    }
  }

  @override
  Stream<SpinDataEntity?> streamSpinData(String userId) {
    return _dataSource.streamSpinData(userId);
  }

  @override
  Future<List<RewardEntity>> getRewardHistory(String userId,
      {RewardType? type, int limit = 50}) async {
    try {
      if (type != null) {
        return await _dataSource.getRewardsByType(userId, type, limit: limit);
      }
      return await _dataSource.getRewardHistory(userId, limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get reward history: $e');
    }
  }

  @override
  Future<double> getTodayAdEarnings(String userId) async {
    try {
      return await _dataSource.getTodayAdEarnings(userId);
    } catch (e) {
      throw FirestoreException('Failed to get today ad earnings: $e');
    }
  }

  @override
  Future<int> getLifetimeAdCount(String userId) async {
    try {
      return await _dataSource.getLifetimeAdCount(userId);
    } catch (e) {
      throw FirestoreException('Failed to get lifetime ad count: $e');
    }
  }

  @override
  Future<double> getTotalRewardsByType(String userId, RewardType type) async {
    try {
      return await _dataSource.getTotalRewardAmountByType(userId, type);
    } catch (e) {
      throw FirestoreException('Failed to get total rewards: $e');
    }
  }

  // ─── Weekly Bonus ───────────────────────────────────

  @override
  Future<WeeklyBonusModel?> getWeeklyBonus(String userId) async {
    try {
      return await _dataSource.getWeeklyBonus(userId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveWeeklyBonus(WeeklyBonusModel bonus) async {
    await _dataSource.saveWeeklyBonus(bonus);
  }

  @override
  Stream<WeeklyBonusModel?> streamWeeklyBonus(String userId) {
    return _dataSource.streamWeeklyBonus(userId);
  }

  /// Update the weekly bonus progress after a daily check-in.
  /// Now supports streak recovery: if a day is missed and recovery hasn't been
  /// used yet, keep the existing days instead of resetting.
  Future<void> _updateWeeklyProgress(String userId, DateTime now) async {
    try {
      final weekStart = _getWeekStart(now);
      var weekly = await _dataSource.getWeeklyBonus(userId);

      if (weekly != null) {
        // If the stored week doesn't match current week, reset
        final storedWeekStart = DateTime(
          weekly.weekStartDate.year,
          weekly.weekStartDate.month,
          weekly.weekStartDate.day,
        );
        if (storedWeekStart != weekStart) {
          weekly = WeeklyBonusModel(
            userId: userId,
            weekStartDate: weekStart,
            checkedDays: [],
            claimed: false,
            lastUpdated: now,
          );
        }
      }

      weekly ??= WeeklyBonusModel(
        userId: userId,
        weekStartDate: weekStart,
        checkedDays: [],
        claimed: false,
        lastUpdated: now,
      );

      // Add today's day-of-week if not already present
      // DateTime.monday = 1, sunday = 7 — we use 1=Mon ... 7=Sun
      final dayOfWeek = now.weekday;
      if (!weekly.checkedDays.contains(dayOfWeek)) {
        // Check consecutive: if last checked day + 1 == today, it's consecutive
        final consecutive = weekly.checkedDays.isEmpty ||
            (weekly.checkedDays.last + 1 == dayOfWeek);

        final List<int> newCheckedDays;
        if (consecutive) {
          // Normal consecutive check-in
          newCheckedDays = [...weekly.checkedDays, dayOfWeek];
        } else if (!weekly.recoveryUsedThisWeek) {
          // Day was missed but recovery available — still add today's check-in
          // The gap (missed day) will be filled by the recovery flow
          newCheckedDays = [...weekly.checkedDays, dayOfWeek];
        } else {
          // Recovery already used and another day missed — reset
          newCheckedDays = [dayOfWeek];
        }
        newCheckedDays.sort();

        final wasClaimableBefore = weekly.checkedDays.length >= 7;
        final isClaimableNow = newCheckedDays.length >= 7;

        weekly = weekly.copyWith(
          checkedDays: newCheckedDays,
          lastUpdated: now,
        );
        await _dataSource.saveWeeklyBonus(weekly);

        // Send notification when bonus first becomes claimable
        if (!wasClaimableBefore && isClaimableNow && !weekly.claimed) {
          await _createNotification(
            userId: userId,
            title: '🎯 Weekly Bonus Ready!',
            message: 'You have checked in all 7 days this week! Claim your ₹15 reward now.',
            type: NotificationType.reward,
          );
          await _sendFcmTargetedPush(
            userId: userId,
            title: '🎯 Weekly Bonus Ready!',
            message: 'You have checked in all 7 days this week! Claim your ₹15 reward now.',
          );
        }
      }
    } catch (e) {
      debugPrint('_updateWeeklyProgress error: $e');
    }
  }

  // ─── Streak Recovery ─────────────────────────────────

  @override
  Future<bool> recoverWeeklyStreak(String userId) async {
    try {
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      var weekly = await _dataSource.getWeeklyBonus(userId);

      if (weekly == null || weekly.recoveryUsedThisWeek) return false;

      // The week must match
      final storedStart = DateTime(
        weekly.weekStartDate.year,
        weekly.weekStartDate.month,
        weekly.weekStartDate.day,
      );
      if (storedStart != weekStart) return false;

      // Find the first missed day before today
      final dayOfWeek = now.weekday;
      int missedDay = 1;
      bool found = false;
      for (int d = 1; d < dayOfWeek; d++) {
        if (!weekly.checkedDays.contains(d)) {
          missedDay = d;
          found = true;
          break;
        }
      }
      // If no gap found (all days up to today checked), nothing to recover
      if (!found) return false;

      // Add the missed day (today is already in checkedDays if user checked in today)
      final recoveredDays = {...weekly.checkedDays, missedDay}.toList()..sort();

      final updated = weekly.copyWith(
        checkedDays: recoveredDays,
        recoveryUsedThisWeek: true,
        lastUpdated: now,
      );
      await _dataSource.saveWeeklyBonus(updated);

      // Notify if now claimable
      if (recoveredDays.length >= 7 && !weekly.claimed) {
        await _createNotification(
          userId: userId,
          title: '🎯 Weekly Bonus Ready!',
          message: 'You have checked in all 7 days this week! Claim your ₹15 reward now.',
          type: NotificationType.reward,
        );
      }

      return true;
    } catch (e) {
      debugPrint('recoverWeeklyStreak error: $e');
      return false;
    }
  }

  @override
  Future<bool> recoverMonthlyStreak(String userId) async {
    try {
      final now = DateTime.now();
      final monthKey = _formatMonthKey(now);
      var monthly = await _dataSource.getMonthlyBonus(userId, monthKey);

      if (monthly == null || monthly.recoveryUsedThisMonth) return false;

      // Find a missing day in the month that is on or before today
      final todayDay = now.day;
      int? missedDay;
      for (int d = 1; d <= todayDay; d++) {
        if (!monthly.checkedDays.contains(d)) {
          missedDay = d;
          break;
        }
      }

      if (missedDay == null) return false;

      // Recover the missed day and today
      final recoveredDays = [...monthly.checkedDays, missedDay, todayDay]
        ..toSet()
        ..toList()
        ..sort();

      final updated = monthly.copyWith(
        checkedDays: recoveredDays,
        recoveryUsedThisMonth: true,
        lastUpdated: now,
      );
      await _dataSource.saveMonthlyBonus(updated);

      final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
      if (recoveredDays.length >= daysInMonth && !monthly.claimed) {
        await _createNotification(
          userId: userId,
          title: '🎯 Monthly Bonus Ready!',
          message: 'You have checked in every day this month! Claim your ₹40 reward now.',
          type: NotificationType.reward,
        );
      }

      return true;
    } catch (e) {
      debugPrint('recoverMonthlyStreak error: $e');
      return false;
    }
  }

  @override
  Future<void> addScratchCardFromAd(String userId, String sourceId) async {
    try {
      // Prevent duplicate scratch cards for the same source
      final existing = await _firestore
          .collection(AppConstants.scratchCardsCollection)
          .where('userId', isEqualTo: userId)
          .where('submissionId', isEqualTo: sourceId)
          .limit(1)
          .get();
      if (existing.docs.isNotEmpty) return;

      final card = ScratchCardModel(
        scratchCardId: _uuid.v4(),
        userId: userId,
        submissionId: sourceId,
        rewardAmount: 0.0,
        isUsed: false,
        createdAt: DateTime.now(),
      );
      await _firestore
          .collection(AppConstants.scratchCardsCollection)
          .doc(card.scratchCardId)
          .set(card.toFirestore());
    } catch (e) {
      debugPrint('addScratchCardFromAd error: $e');
    }
  }

  // ─── Monthly Bonus ───────────────────────────────────

  @override
  Future<MonthlyBonusModel?> getMonthlyBonus(String userId, String monthKey) async {
    try {
      return await _dataSource.getMonthlyBonus(userId, monthKey);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> saveMonthlyBonus(MonthlyBonusModel bonus) async {
    await _dataSource.saveMonthlyBonus(bonus);
  }

  @override
  Stream<MonthlyBonusModel?> streamMonthlyBonus(String userId) {
    return _dataSource.streamMonthlyBonus(userId);
  }

  /// Update the monthly bonus progress after a daily check-in.
  Future<void> _updateMonthlyProgress(String userId, DateTime now) async {
    try {
      final monthKey = _formatMonthKey(now);
      var monthly = await _dataSource.getMonthlyBonus(userId, monthKey);

      monthly ??= MonthlyBonusModel(
        userId: userId,
        monthKey: monthKey,
        checkedDays: [],
        claimed: false,
        lastUpdated: now,
      );

      // Add today's day number if not already present
      final dayNum = now.day;
      if (!monthly.checkedDays.contains(dayNum)) {
        final newCheckedDays = [...monthly.checkedDays, dayNum]..sort();
        final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
        final wasClaimableBefore = monthly.checkedDays.length >= daysInMonth;
        final isClaimableNow = newCheckedDays.length >= daysInMonth;

        monthly = monthly.copyWith(
          checkedDays: newCheckedDays,
          lastUpdated: now,
        );
        await _dataSource.saveMonthlyBonus(monthly);

        // Send notification when bonus first becomes claimable
        if (!wasClaimableBefore && isClaimableNow && !monthly.claimed) {
          await _createNotification(
            userId: userId,
            title: '🎯 Monthly Bonus Ready!',
            message: 'You have checked in every day this month! Claim your ₹40 reward now.',
            type: NotificationType.reward,
          );
          // Send FCM push notification for the targeted user
          await _sendFcmTargetedPush(
            userId: userId,
            title: '🎯 Monthly Bonus Ready!',
            message: 'You have checked in every day this month! Claim your ₹40 reward now.',
          );
        }
      }
    } catch (e) {
      debugPrint('_updateMonthlyProgress error: $e');
    }
  }

  // ─── Helpers ──────────────────────────────────────────

  /// Get the Monday of the current week.
  DateTime _getWeekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  String _formatMonthKey(DateTime date) {
    return '${date.year}-${date.month.toString().padLeft(2, '0')}';
  }

  Future<void> _ensureWalletExists(String userId) async {
    try {
      final wallet = await _walletDataSource.getWallet(userId);
      if (wallet != null) return;
    } catch (_) {
      // getWallet failed — will attempt to create below
    }
    try {
      await _walletDataSource.createWallet(
        WalletModel(
          userId: userId,
          walletBalance: 0.0,
          totalEarnings: 0.0,
          totalWithdrawn: 0.0,
          updatedAt: DateTime.now(),
        ),
      );
    } catch (_) {}
  }

  // ─── Notification Helper ─────────────────────────────

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: _uuid.v4(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _notificationDataSource.createNotification(notification);
    } catch (e) {
      debugPrint('Failed to create notification: $e');
    }
  }

  /// Send an FCM push notification to the targeted user.
  /// Calls the sendTargetedPush Cloud Function which pushes to user_{userId} topic.
  /// FcmService.sendTargetedPush() already handles errors internally;
  /// the parent methods also catch and log exceptions from this call.
  Future<void> _sendFcmTargetedPush({
    required String userId,
    required String title,
    required String message,
  }) async {
    await FcmService.sendTargetedPush(
      userId: userId,
      title: title,
      message: message,
      type: 'reward',
    );
  }
}
