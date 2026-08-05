import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/wallet_entity.dart';
import 'package:cashspark/domain/repositories/referral_repository.dart';
import 'package:cashspark/domain/repositories/reward_repository.dart';
import 'package:cashspark/domain/repositories/wallet_repository.dart';
import 'package:flutter/foundation.dart';

/// A data point for chart rendering — pairs a date/day label with an amount.
class EarningsDataPoint {
  final String label;
  final double amount;
  const EarningsDataPoint({required this.label, required this.amount});
}

class WalletProvider extends ChangeNotifier {
  final WalletRepository _walletRepository;
  final RewardRepository? _rewardRepository;
  final ReferralRepository? _referralRepository;
  StreamSubscription? _walletSubscription;
  StreamSubscription? _transactionsSubscription;

  WalletEntity? _wallet;
  List<TransactionEntity> _recentTransactions = [];
  bool _isLoading = false;
  String? _errorMessage;

  // Earnings breakdown — real data from Firestore
  double _projectEarnings = 0.0;
  double _referralEarnings = 0.0;
  double _spinEarnings = 0.0;
  bool _isBreakdownLoading = false;

  // ─── EARNINGS HISTORY FOR CHARTS ────────────────────────
  List<EarningsDataPoint> _dailyEarnings = [];
  List<EarningsDataPoint> _weeklyEarnings = [];
  List<EarningsDataPoint> _monthlyEarnings = [];
  Map<String, double> _rewardBreakdown = {};
  double _todayEarnings = 0.0;
  double _yesterdayEarnings = 0.0;
  double _weeklyTotal = 0.0;
  double _monthlyTotal = 0.0;
  bool _isHistoryLoading = false;

  /// Prevents notifyListeners() after dispose.
  bool _disposed = false;

  WalletProvider({
    required WalletRepository walletRepository,
    RewardRepository? rewardRepository,
    ReferralRepository? referralRepository,
  }) : _walletRepository = walletRepository,
       _rewardRepository = rewardRepository,
       _referralRepository = referralRepository;

  WalletEntity? get wallet => _wallet;
  List<TransactionEntity> get recentTransactions => _recentTransactions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  double get projectEarnings => _projectEarnings;
  double get referralEarnings => _referralEarnings;
  double get spinEarnings => _spinEarnings;
  bool get isBreakdownLoading => _isBreakdownLoading;

  // Chart data getters
  List<EarningsDataPoint> get dailyEarnings => _dailyEarnings;
  List<EarningsDataPoint> get weeklyEarnings => _weeklyEarnings;
  List<EarningsDataPoint> get monthlyEarnings => _monthlyEarnings;
  Map<String, double> get rewardBreakdown => _rewardBreakdown;
  double get todayEarnings => _todayEarnings;
  double get yesterdayEarnings => _yesterdayEarnings;
  double get weeklyTotal => _weeklyTotal;
  double get monthlyTotal => _monthlyTotal;
  bool get isHistoryLoading => _isHistoryLoading;

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  void listenToWallet(String userId) {
    if (_disposed) return;
    _walletSubscription?.cancel();
    _walletSubscription = _walletRepository.streamWallet(userId).listen(
      (wallet) {
        if (_disposed) return;
        _wallet = wallet;
        _safeNotifyListeners();
      },
      onError: (error) {
        if (_disposed) return;
        _errorMessage = error.toString();
        _safeNotifyListeners();
      },
    );

    _transactionsSubscription?.cancel();
    _transactionsSubscription =
        _walletRepository.streamRecentTransactions(userId).listen(
      (transactions) {
        if (_disposed) return;
        _recentTransactions = transactions;
        _safeNotifyListeners();
      },
      onError: (error) {
        if (_disposed) return;
        _errorMessage = error.toString();
        _safeNotifyListeners();
      },
    );
  }

  void cancelSubscriptions() {
    _walletSubscription?.cancel();
    _transactionsSubscription?.cancel();
  }

  Future<void> loadWallet(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      _wallet = await _walletRepository.getWallet(userId);
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load wallet';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadTransactions(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      _recentTransactions = await _walletRepository.getTransactions(userId);
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load transactions';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> ensureWalletExists(String userId) async {
    try {
      await _walletRepository.getWallet(userId);
      return true;
    } on FirestoreException {
      // Wallet doesn't exist yet, create it
      try {
        await _walletRepository.createWallet(
          WalletEntity(
            userId: userId,
            updatedAt: DateTime.now(),
          ),
        );
        _wallet = WalletEntity(userId: userId, updatedAt: DateTime.now());
        _safeNotifyListeners();
        return true;
      } catch (e) {
        _clearError();
        _errorMessage = 'Failed to create wallet';
        return false;
      }
    }
  }

  Future<void> addSpinReward(String userId, double amount) async {
    _setLoading(true);
    _clearError();
    try {
      await _walletRepository.addFunds(
        userId: userId,
        amount: amount,
        source: TransactionSource.bonus,
        description: 'Spin & Win reward',
      );
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to add spin reward';
    } finally {
      _setLoading(false);
    }
  }

  /// Load earnings breakdown from Firestore (projects, referrals, spin)
  Future<void> loadEarningsBreakdown(String userId) async {
    if (_disposed) return;
    _clearError();
    _isBreakdownLoading = true;
    _safeNotifyListeners();

    try {
      // 1. Projects earnings (from rewards count with taskReward type)
      final rewardRepo = _rewardRepository;
      if (rewardRepo != null) {
        try {
          _projectEarnings = await rewardRepo.getTotalRewardsByType(
            userId,
            RewardType.taskReward,
          );
        } catch (_) {
          _projectEarnings = 0.0;
        }

        // 2. Spin earnings (from SpinData)
        try {
          final spinData = await rewardRepo.getSpinData(userId);
          _spinEarnings = spinData?.totalRewardsEarned ?? 0.0;
        } catch (_) {
          _spinEarnings = 0.0;
        }
      }

      // 3. Referral earnings (combine ₹7 bonuses + 5% commissions)
      final referralRepo = _referralRepository;
      if (referralRepo != null) {
        try {
          final baseEarnings = await referralRepo.getTotalReferralEarnings(userId);
          final commissions = await referralRepo.getLifetimeProjectCommission(userId);
          _referralEarnings = baseEarnings + commissions;
        } catch (_) {
          _referralEarnings = 0.0;
        }
      }
    } finally {
      _isBreakdownLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Load full earnings history for charting (daily, weekly, monthly + breakdown)
  Future<void> loadEarningsHistory(String userId) async {
    if (_disposed) return;
    _clearError();
    _isHistoryLoading = true;
    _safeNotifyListeners();

    try {
      // Fetch all rewards for this user
      final rewardRepo = _rewardRepository;
      final rewards = rewardRepo != null
          ? await rewardRepo.getRewardHistory(userId, limit: 200)
          : <RewardEntity>[];

      final now = DateTime.now();
      final todayStart = DateTime(now.year, now.month, now.day);
      final yesterdayStart = todayStart.subtract(const Duration(days: 1));
      final weekStart = todayStart.subtract(Duration(days: now.weekday - 1));
      final monthStart = DateTime(now.year, now.month, 1);

      // ─── Group by day for the last 30 days ────────────
      final Map<int, double> dailyMap = {};
      double todayTotal = 0;
      double yesterdayTotal = 0;
      double weekTotal = 0;
      double monthTotal = 0;

      for (final reward in rewards) {
        final rDate = reward.createdAt;
        final dayKey = DateTime(rDate.year, rDate.month, rDate.day).millisecondsSinceEpoch;
        dailyMap[dayKey] = (dailyMap[dayKey] ?? 0) + reward.rewardAmount;

        if (rDate.isAfter(todayStart)) todayTotal += reward.rewardAmount;
        if (rDate.isAfter(yesterdayStart) && rDate.isBefore(todayStart)) {
          yesterdayTotal += reward.rewardAmount;
        }
        if (rDate.isAfter(weekStart)) weekTotal += reward.rewardAmount;
        if (rDate.isAfter(monthStart)) monthTotal += reward.rewardAmount;
      }

      // Build daily chart data (last 14 days)
      final List<EarningsDataPoint> dailyPoints = [];
      for (int i = 13; i >= 0; i--) {
        final day = todayStart.subtract(Duration(days: i));
        final key = DateTime(day.year, day.month, day.day).millisecondsSinceEpoch;
        final amount = dailyMap[key] ?? 0.0;
        dailyPoints.add(EarningsDataPoint(
          label: _dayLabel(day, i == 0),
          amount: amount,
        ));
      }
      _dailyEarnings = dailyPoints;

      // Build weekly chart data (last 8 weeks)
      final List<EarningsDataPoint> weeklyPoints = [];
      for (int i = 7; i >= 0; i--) {
        final weekEnd = todayStart.subtract(Duration(days: todayStart.weekday - 1 + i * 7));
        final weekEndDate = weekEnd.add(const Duration(days: 6));
        double weekAmount = 0;
        for (final reward in rewards) {
          if (reward.createdAt.isAfter(weekEnd.subtract(const Duration(days: 1))) &&
              reward.createdAt.isBefore(weekEndDate.add(const Duration(days: 1)))) {
            weekAmount += reward.rewardAmount;
          }
        }
        weeklyPoints.add(EarningsDataPoint(
          label: 'W${_weekNumber(weekEnd)}',
          amount: weekAmount,
        ));
      }
      _weeklyEarnings = weeklyPoints;

      // Build monthly chart data (last 6 months)
      final List<EarningsDataPoint> monthlyPoints = [];
      for (int i = 5; i >= 0; i--) {
        final month = DateTime(now.year, now.month - i, 1);
        final monthEnd = DateTime(month.year, month.month + 1, 0);
        double monthAmount = 0;
        for (final reward in rewards) {
          if (reward.createdAt.isAfter(month.subtract(const Duration(days: 1))) &&
              reward.createdAt.isBefore(monthEnd.add(const Duration(days: 1)))) {
            monthAmount += reward.rewardAmount;
          }
        }
        monthlyPoints.add(EarningsDataPoint(
          label: ['Jan','Feb','Mar','Apr','May','Jun','Jul','Aug','Sep','Oct','Nov','Dec'][month.month - 1],
          amount: monthAmount,
        ));
      }
      _monthlyEarnings = monthlyPoints;

      // Reward breakdown by type
      final Map<String, double> breakdown = {};
      for (final reward in rewards) {
        final typeLabel = _rewardTypeLabel(reward.rewardType);
        breakdown[typeLabel] = (breakdown[typeLabel] ?? 0) + reward.rewardAmount;
      }
      _rewardBreakdown = breakdown;

      _todayEarnings = todayTotal;
      _yesterdayEarnings = yesterdayTotal;
      _weeklyTotal = weekTotal;
      _monthlyTotal = monthTotal;
    } catch (_) {
      // Silently fail — charts will show empty state
    } finally {
      _isHistoryLoading = false;
      _safeNotifyListeners();
    }
  }

  String _dayLabel(DateTime day, bool isToday) {
    if (isToday) return 'Today';
    final weekday = ['','Mon','Tue','Wed','Thu','Fri','Sat','Sun'][day.weekday];
    return '${day.day} $weekday'.substring(0, 5);
  }

  int _weekNumber(DateTime date) {
    final startOfYear = DateTime(date.year, 1, 1);
    final diff = date.difference(startOfYear).inDays;
    return (diff / 7).ceil();
  }

  String _rewardTypeLabel(RewardType type) {
    switch (type) {
      case RewardType.adReward: return 'Ad Rewards';
      case RewardType.dailyCheckIn: return 'Check-In';
      case RewardType.streakBonus: return 'Streak Bonus';
      case RewardType.taskReward: return 'Tasks';
      case RewardType.bonus: return 'Bonuses';
      case RewardType.spinReward: return 'Spin';
    }
  }

  void clearError() {
    _clearError();
  }

  void _setLoading(bool value) {
    if (_disposed) return;
    _isLoading = value;
    _safeNotifyListeners();
  }

  void _clearError() {
    if (_disposed) return;
    _errorMessage = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    cancelSubscriptions();
    super.dispose();
  }
}

