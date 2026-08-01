import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/domain/repositories/referral_repository.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/referral_reward_config_entity.dart';
import 'package:flutter/foundation.dart';

class ReferralProvider extends ChangeNotifier {
  final ReferralRepository _referralRepository;
  StreamSubscription? _referralsSubscription;

  List<ReferralEntity> _referrals = [];
  ReferralRewardConfigEntity? _rewardConfig;
  int _referralCount = 0;
  double _totalEarnings = 0.0;
  bool _isLoading = false;
  String? _errorMessage;

  // ─── New referral stats ────────────────────────────────
  int _completedProjectUsers = 0;
  double _lifetimeProjectCommission = 0.0;
  double _firstProjectBonusTotal = 0.0;

  /// Prevents notifyListeners() after dispose.
  bool _disposed = false;

  ReferralProvider({
    required ReferralRepository referralRepository,
  }) : _referralRepository = referralRepository;

  List<ReferralEntity> get referrals => _referrals;
  ReferralRewardConfigEntity? get rewardConfig => _rewardConfig;
  int get referralCount => _referralCount;
  double get totalEarnings => _totalEarnings;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Number of referred users who have completed at least one approved project.
  int get completedProjectUsers => _completedProjectUsers;

  /// Lifetime 5% commission earned from referred users' approved projects.
  double get lifetimeProjectCommission => _lifetimeProjectCommission;

  /// Total 7 pts first-project bonuses earned.
  double get firstProjectBonusTotal => _firstProjectBonusTotal;

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  void listenToReferrals(String userId) {
    if (_disposed) return;
    _referralsSubscription?.cancel();
    _referralsSubscription =
        _referralRepository.streamReferralsByReferrer(userId).listen(
      (referrals) {
        if (_disposed) return;
        _referrals = referrals;
        _referralCount = referrals.length;
        _totalEarnings = referrals.fold<double>(
          0,
          (sum, r) => sum + r.rewardAmount + r.lifetimeProjectCommission,
        );
        _completedProjectUsers =
            referrals.where((r) => r.approvedProjectCount > 0).length;
        _lifetimeProjectCommission = referrals.fold<double>(
          0,
          (sum, r) => sum + r.lifetimeProjectCommission,
        );
        _firstProjectBonusTotal = referrals
            .where((r) => r.firstProjectRewarded)
            .fold<double>(0, (sum, r) => sum + 7.0);
        _safeNotifyListeners();
      },
      onError: (error) {
        if (_disposed) return;
        _errorMessage = error.toString();
        _safeNotifyListeners();
      },
    );
  }

  void cancelSubscription() {
    _referralsSubscription?.cancel();
  }

  Future<void> loadReferrals(String userId) async {
    _setLoading(true);
    _clearError();
    try {
      _referrals = await _referralRepository.getReferralsByReferrer(userId);
      _referralCount = await _referralRepository.getReferralCount(userId);
      final baseEarnings = await _referralRepository.getTotalReferralEarnings(userId);
      final commissions = await _referralRepository.getLifetimeProjectCommission(userId);
      _totalEarnings = baseEarnings + commissions;
      _completedProjectUsers =
          await _referralRepository.getReferredUsersWithCompletedProject(userId);
      _lifetimeProjectCommission =
          await _referralRepository.getLifetimeProjectCommission(userId);
      _firstProjectBonusTotal = _referrals
          .where((r) => r.firstProjectRewarded)
          .fold<double>(0, (sum, r) => sum + 7.0);
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Failed to load referrals';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadRewardConfig() async {
    if (_disposed) return;
    try {
      _rewardConfig = await _referralRepository.getRewardConfig();
      _safeNotifyListeners();
    } catch (e) {
      // Silently fail - default config will be used
    }
  }

  String generateReferralLink(String referralCode) {
    return 'https://cashspark.app/signup?ref=$referralCode';
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
    cancelSubscription();
    super.dispose();
  }
}
