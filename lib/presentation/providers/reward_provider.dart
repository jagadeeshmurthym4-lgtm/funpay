import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/models/bonus_models.dart';
import 'package:cashspark/data/models/spin_data_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/repositories/reward_repository.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class RewardProvider extends ChangeNotifier {
  final RewardRepository _rewardRepository;
  StreamSubscription? _streakSubscription;
  StreamSubscription? _weeklyBonusSubscription;
  StreamSubscription? _monthlyBonusSubscription;

  RewardConfigEntity? _rewardConfig;
  StreakEntity? _streak;
  List<RewardEntity> _recentRewards = [];
  int _todayAdCount = 0;
  double _todayAdEarnings = 0.0;
  int _lifetimeAdCount = 0;
  double _lifetimeAdEarnings = 0.0;
  List<RewardEntity> _adRewardHistory = [];
  DateTime? _lastAdWatchTime;
  double? _lastAdEarnedAmount;
  DailyCheckInEntity? _todayCheckIn;
  bool _isLoading = false;
  bool _isClaimingReward = false;
  String? _errorMessage;

  // Weekly Bonus
  WeeklyBonusModel? _weeklyBonus;
  bool _isClaimingWeekly = false;

  // Monthly Bonus
  MonthlyBonusModel? _monthlyBonus;
  bool _isClaimingMonthly = false;

  // Streak Recovery
  bool _isRecoveringWeekly = false;
  bool _isRecoveringMonthly = false;

  RewardProvider({
    required RewardRepository rewardRepository,
  }) : _rewardRepository = rewardRepository;

  RewardConfigEntity? get rewardConfig => _rewardConfig;
  StreakEntity? get streak => _streak;
  List<RewardEntity> get recentRewards => _recentRewards;
  int get todayAdCount => _todayAdCount;
  double get todayAdEarnings => _todayAdEarnings;
  int get lifetimeAdCount => _lifetimeAdCount;
  double get lifetimeAdEarnings => _lifetimeAdEarnings;
  List<RewardEntity> get adRewardHistory => _adRewardHistory;
  double? get lastAdEarnedAmount => _lastAdEarnedAmount;
  DateTime? get lastAdWatchTime => _lastAdWatchTime;
  DailyCheckInEntity? get todayCheckIn => _todayCheckIn;
  bool get isLoading => _isLoading;
  bool get isClaimingReward => _isClaimingReward;
  String? get errorMessage => _errorMessage;
  bool get hasCheckedInToday => _todayCheckIn?.claimed ?? false;
  bool get canWatchAd => true;
  int get remainingAds => 999999;

  // Weekly Bonus
  WeeklyBonusModel? get weeklyBonus => _weeklyBonus;
  bool get isClaimingWeekly => _isClaimingWeekly;
  bool get canClaimWeekly {
    if (_weeklyBonus == null || _weeklyBonus!.claimed) return false;
    return _weeklyBonus!.checkedDays.length >= 7;
  }
  int get weeklyProgress => _weeklyBonus?.checkedDays.length ?? 0;

  // Monthly Bonus
  MonthlyBonusModel? get monthlyBonus => _monthlyBonus;
  bool get isClaimingMonthly => _isClaimingMonthly;
  bool get canClaimMonthly {
    if (_monthlyBonus == null || _monthlyBonus!.claimed) return false;
    final now = DateTime.now();
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    return _monthlyBonus!.checkedDays.length >= daysInMonth;
  }
  int get monthlyProgress => _monthlyBonus?.checkedDays.length ?? 0;
  int get daysInCurrentMonth => DateTime(DateTime.now().year, DateTime.now().month + 1, 0).day;

  // Streak Recovery
  bool get isRecoveringWeekly => _isRecoveringWeekly;
  bool get isRecoveringMonthly => _isRecoveringMonthly;
  /// Whether the user can recover their weekly streak
  bool get canRecoverWeekly {
    if (_weeklyBonus == null || _weeklyBonus!.claimed) return false;
    if (_weeklyBonus!.recoveryUsedThisWeek) return false;
    if (_weeklyBonus!.checkedDays.length >= 7) return false;
    if (_weeklyBonus!.checkedDays.isEmpty) return false;
    final todayWeekday = DateTime.now().weekday;
    // If fewer days checked than today's weekday number, there's a gap
    return _weeklyBonus!.checkedDays.length < todayWeekday;
  }
  /// Whether the user can recover their monthly streak
  bool get canRecoverMonthly {
    if (_monthlyBonus == null || _monthlyBonus!.claimed) return false;
    if (_monthlyBonus!.recoveryUsedThisMonth) return false;
    final daysInMonth = DateTime.now().day;
    if (_monthlyBonus!.checkedDays.length >= daysInMonth) return false;
    // There must be at least one missing day before today
    if (_monthlyBonus!.checkedDays.isEmpty) return false;
    return _monthlyBonus!.checkedDays.length < DateTime.now().day;
  }

  Future<void> initialize(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      _rewardConfig = await _rewardRepository.getRewardConfig();
      _todayCheckIn = await _rewardRepository.getTodayCheckIn(userId);
      _recentRewards = await _rewardRepository.getRewardHistory(userId, limit: 10);

      _listenToStreak(userId);
      _listenToWeeklyBonus(userId);
      _listenToMonthlyBonus(userId);
      await _loadAdStats(userId);
    } catch (e) {
      _errorMessage = 'Failed to initialize rewards';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> _loadAdStats(String userId) async {
    try {
      _todayAdCount = await _rewardRepository.getTodayAdCount(userId);
      _lastAdWatchTime = await _rewardRepository.getLastAdWatchTime(userId);
      _todayAdEarnings = await _rewardRepository.getTodayAdEarnings(userId);
      _lifetimeAdCount = await _rewardRepository.getLifetimeAdCount(userId);
      _lifetimeAdEarnings =
          await _rewardRepository.getTotalRewardsByType(userId, RewardType.adReward);
      _adRewardHistory = await _rewardRepository.getAdRewardHistory(userId);
    } catch (e) {
      debugPrint('loadAdStats error: $e');
    }
  }

  Future<void> loadAdStats(String userId) async {
    await _loadAdStats(userId);
    notifyListeners();
  }

  void _listenToStreak(String userId) {
    _streakSubscription?.cancel();
    _streakSubscription = _rewardRepository.streamStreak(userId).listen(
      (streak) {
        _streak = streak;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = error.toString();
        notifyListeners();
      },
    );
  }

  Future<void> claimDailyCheckIn(String userId) async {
    _setClaiming(true);
    _clearError();
    try {
      final checkIn = await _rewardRepository.claimDailyCheckIn(userId);
      _todayCheckIn = checkIn;
      _streak = await _rewardRepository.getStreak(userId);
      // Refresh weekly/monthly bonus data after check-in
      _weeklyBonus = await _rewardRepository.getWeeklyBonus(userId);
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      _monthlyBonus = await _rewardRepository.getMonthlyBonus(userId, monthKey);
      notifyListeners();
    } on RewardsException catch (e) {
      _errorMessage = e.message;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to claim daily reward';
    } finally {
      _setClaiming(false);
    }
  }

  Future<double?> claimAdReward(String userId) async {
    _setClaiming(true);
    _clearError();
    try {
      final reward = await _rewardRepository.claimAdReward(userId);
      _lastAdEarnedAmount = reward.rewardAmount;
      await _loadAdStats(userId);
      notifyListeners();
      return _lastAdEarnedAmount;
    } on RewardsException catch (e) {
      _errorMessage = e.message;
      return null;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return null;
    } catch (e) {
      _errorMessage = 'Failed to claim ad reward';
      return null;
    } finally {
      _setClaiming(false);
    }
  }

  // ─── Weekly Bonus ─────────────────────────────────────

  Future<bool> claimWeeklyBonus(String userId) async {
    if (_isClaimingWeekly || !canClaimWeekly) return false;
    _isClaimingWeekly = true;
    notifyListeners();
    try {
      final rewardAmount = 15.0;

      // Credit wallet
      await _creditWalletForBonus(userId, rewardAmount, 'Weekly Bonus reward');

      // Mark weekly bonus as claimed
      final now = DateTime.now();
      final weekStart = _getWeekStart(now);
      final weekStartKey = '${weekStart.year}-${weekStart.month.toString().padLeft(2, '0')}-${weekStart.day.toString().padLeft(2, '0')}';

      if (_weeklyBonus != null) {
        final updated = _weeklyBonus!.copyWith(
          claimed: true,
          claimedWeekStartKey: weekStartKey,
          lastUpdated: now,
        );
        await _rewardRepository.saveWeeklyBonus(updated);
        // Reset checked days for next week
        final nextWeekStart = weekStart.add(const Duration(days: 7));
        final freshWeekly = WeeklyBonusModel(
          userId: userId,
          weekStartDate: nextWeekStart,
          checkedDays: [],
          claimed: false,
          lastUpdated: now,
        );
        await _rewardRepository.saveWeeklyBonus(freshWeekly);
        _weeklyBonus = freshWeekly;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to claim weekly bonus';
      notifyListeners();
      return false;
    } finally {
      _isClaimingWeekly = false;
      notifyListeners();
    }
  }

  // ─── Monthly Bonus ────────────────────────────────────

  Future<bool> claimMonthlyBonus(String userId) async {
    if (_isClaimingMonthly || !canClaimMonthly) return false;
    _isClaimingMonthly = true;
    notifyListeners();
    try {
      final rewardAmount = 40.0;

      await _creditWalletForBonus(userId, rewardAmount, 'Monthly Bonus reward');

      // Mark monthly bonus as claimed
      final now = DateTime.now();
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      if (_monthlyBonus != null) {
        final updated = _monthlyBonus!.copyWith(
          claimed: true,
          claimedMonthKey: monthKey,
          lastUpdated: now,
        );
        await _rewardRepository.saveMonthlyBonus(updated);
        _monthlyBonus = updated;
      }

      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to claim monthly bonus';
      notifyListeners();
      return false;
    } finally {
      _isClaimingMonthly = false;
      notifyListeners();
    }
  }

  // ─── Streak Recovery ──────────────────────────────────

  /// Recover weekly streak by restoring the missed day after watching an ad.
  Future<bool> recoverWeeklyStreak(String userId) async {
    if (_isRecoveringWeekly || !canRecoverWeekly) return false;
    _isRecoveringWeekly = true;
    notifyListeners();
    try {
      final success = await _rewardRepository.recoverWeeklyStreak(userId);
      if (success) {
        // Refresh weekly bonus data
        _weeklyBonus = await _rewardRepository.getWeeklyBonus(userId);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to recover streak';
      return false;
    } finally {
      _isRecoveringWeekly = false;
      notifyListeners();
    }
  }

  /// Recover monthly streak by restoring the missed day after watching an ad.
  Future<bool> recoverMonthlyStreak(String userId) async {
    if (_isRecoveringMonthly || !canRecoverMonthly) return false;
    _isRecoveringMonthly = true;
    notifyListeners();
    try {
      final success = await _rewardRepository.recoverMonthlyStreak(userId);
      if (success) {
        // Refresh monthly bonus data
        final now = DateTime.now();
        final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
        _monthlyBonus = await _rewardRepository.getMonthlyBonus(userId, monthKey);
      }
      return success;
    } catch (e) {
      _errorMessage = 'Failed to recover streak';
      return false;
    } finally {
      _isRecoveringMonthly = false;
      notifyListeners();
    }
  }

  // ─── Spin Data ────────────────────────────────────────

  Future<SpinDataEntity?> getSpinData(String userId) async {
    try {
      return await _rewardRepository.getSpinData(userId);
    } catch (e) {
      return null;
    }
  }

  Future<void> saveSpinData(SpinDataEntity data) async {
    _clearError();
    try {
      await _rewardRepository.saveSpinData(data);
    } catch (e) {
      _errorMessage = 'Failed to save spin data';
      notifyListeners();
    }
  }

  /// Stream real-time spin data updates from Firestore.
  Stream<SpinDataEntity?> streamSpinData(String userId) {
    return _rewardRepository.streamSpinData(userId);
  }

  void _listenToWeeklyBonus(String userId) {
    _weeklyBonusSubscription?.cancel();
    _weeklyBonusSubscription = _rewardRepository.streamWeeklyBonus(userId).listen(
      (bonus) {
        _weeklyBonus = bonus;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Weekly bonus stream error: $error');
      },
    );
  }

  void _listenToMonthlyBonus(String userId) {
    _monthlyBonusSubscription?.cancel();
    _monthlyBonusSubscription = _rewardRepository.streamMonthlyBonus(userId).listen(
      (bonus) {
        _monthlyBonus = bonus;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('Monthly bonus stream error: $error');
      },
    );
  }

  void cancelSubscriptions() {
    _streakSubscription?.cancel();
    _weeklyBonusSubscription?.cancel();
    _monthlyBonusSubscription?.cancel();
  }

  // ─── Helpers ──────────────────────────────────────────

  Future<void> _creditWalletForBonus(String userId, double amount, String description) async {
    try {
      final walletRef = FirebaseFirestore.instance
          .collection(AppConstants.walletsCollection)
          .doc(userId);

      await FirebaseFirestore.instance.runTransaction((transaction) async {
        final snapshot = await transaction.get(walletRef);
        if (!snapshot.exists) return;

        final currentBalance = (snapshot.data()?['walletBalance'] as num?)?.toDouble() ?? 0.0;
        final currentEarnings = (snapshot.data()?['totalEarnings'] as num?)?.toDouble() ?? 0.0;

        transaction.update(walletRef, {
          'walletBalance': currentBalance + amount,
          'totalEarnings': currentEarnings + amount,
          'updatedAt': DateTime.now(),
        });
      });

      final uuid = const Uuid();
      final transactionDoc = TransactionModel(
        transactionId: uuid.v4(),
        userId: userId,
        type: TransactionType.credit,
        amount: amount,
        source: TransactionSource.reward,
        status: TransactionStatus.completed,
        description: description,
        createdAt: DateTime.now(),
      );
      await FirebaseFirestore.instance
          .collection(AppConstants.transactionsCollection)
          .doc(transactionDoc.transactionId)
          .set(transactionDoc.toFirestore());
    } catch (e) {
      debugPrint('_creditWalletForBonus error: $e');
      rethrow;
    }
  }

  DateTime _getWeekStart(DateTime date) {
    final monday = date.subtract(Duration(days: date.weekday - 1));
    return DateTime(monday.year, monday.month, monday.day);
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _setClaiming(bool value) {
    _isClaimingReward = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    cancelSubscriptions();
    super.dispose();
  }
}
