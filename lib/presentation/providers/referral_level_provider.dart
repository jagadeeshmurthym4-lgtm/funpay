import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/domain/entities/referral_level_entity.dart';
import 'package:cashspark/domain/repositories/referral_level_repository.dart';
import 'package:flutter/foundation.dart';

class ReferralLevelProvider extends ChangeNotifier {
  final ReferralLevelRepository _repository;

  List<ReferralLevelEntity> _levels = [];
  Set<int> _claimedLevels = {};
  bool _isLoading = false;
  bool _isClaiming = false;
  String? _errorMessage;
  String? _successMessage;


  ReferralLevelProvider({
    required ReferralLevelRepository repository,
  }) : _repository = repository;

  List<ReferralLevelEntity> get levels => _levels;
  Set<int> get claimedLevels => _claimedLevels;
  bool get isLoading => _isLoading;
  bool get isClaiming => _isClaiming;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  /// Get the current level the user is at based on referral count.
  ReferralLevelEntity? getCurrentLevel(int referralCount) {
    ReferralLevelEntity? current;
    final sorted = [..._levels]
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
    for (final level in sorted) {
      if (!level.isActive) continue;
      if (referralCount >= level.requiredReferrals) {
        current = level;
      }
    }
    return current;
  }

  /// Get the next unachieved level.
  ReferralLevelEntity? getNextLevel(int referralCount) {
    final sorted = [..._levels]
      ..sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
    for (final level in sorted) {
      if (!level.isActive) continue;
      if (referralCount < level.requiredReferrals) return level;
    }
    return null;
  }

  /// Get progress toward the next level (0.0 - 1.0).
  double getProgressToNext(int referralCount) {
    final next = getNextLevel(referralCount);
    final current = getCurrentLevel(referralCount);
    if (next == null) return 1.0;
    final prevThreshold = current?.requiredReferrals ?? 0;
    final range = next.requiredReferrals - prevThreshold;
    if (range <= 0) return 1.0;
    final progress = (referralCount - prevThreshold) / range;
    return progress.clamp(0.0, 1.0);
  }

  /// Check if a level milestone reward is claimable.
  bool isLevelClaimable(int levelNumber, int referralCount) {
    if (_claimedLevels.contains(levelNumber)) return false;
    final level = _levels.where((l) => l.levelNumber == levelNumber).firstOrNull;
    if (level == null || !level.isActive) return false;
    return referralCount >= level.requiredReferrals;
  }

  /// Claim a milestone reward for a given level.
  Future<bool> claimMilestoneReward(String userId, int levelNumber, int referralCount) async {
    if (_isClaiming) return false;
    if (!isLevelClaimable(levelNumber, referralCount)) return false;

    final level = _levels.where((l) => l.levelNumber == levelNumber).firstOrNull;
    if (level == null) return false;

    _isClaiming = true;
    _clearMessages();
    notifyListeners();

    try {
      await _repository.claimMilestoneReward(
        userId: userId,
        levelNumber: levelNumber,
        rewardAmount: level.rewardAmount,
      );
      _claimedLevels.add(levelNumber);
      _successMessage = '🎉 You claimed ${level.title} reward! +₹${level.rewardAmount.toStringAsFixed(2)}';
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      notifyListeners();
      return false;
    } catch (e) {
      _errorMessage = 'Failed to claim milestone reward';
      notifyListeners();
      return false;
    } finally {
      _isClaiming = false;
      notifyListeners();
    }
  }

  Future<void> loadLevels() async {
    _setLoading(true);
    _clearMessages();
    try {
      _levels = await _repository.getAllLevels();
    } catch (e) {
      _errorMessage = 'Failed to load referral levels';
    } finally {
      _setLoading(false);
    }
  }

  /// Save a level (add or update). Exposed for admin panel.
  Future<bool> saveLevel(ReferralLevelEntity level) async {
    try {
      await _repository.saveLevel(level);
      await loadLevels();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save level: $e';
      notifyListeners();
      return false;
    }
  }

  /// Delete a level by ID. Exposed for admin panel.
  Future<bool> deleteLevel(String levelId) async {
    try {
      await _repository.deleteLevel(levelId);
      await loadLevels();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete level: $e';
      notifyListeners();
      return false;
    }
  }

  /// Toggle a level's active status.
  Future<bool> toggleLevelActive(ReferralLevelEntity level) async {
    final updated = level.copyWith(isActive: !level.isActive);
    return saveLevel(updated);
  }

  Future<void> loadClaimedLevels(String userId) async {
    try {
      _claimedLevels = await _repository.getClaimedLevels(userId);
      notifyListeners();
    } catch (e) {
      debugPrint('loadClaimedLevels error: $e');
    }
  }

  void clearMessages() {
    _clearMessages();
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }


}
