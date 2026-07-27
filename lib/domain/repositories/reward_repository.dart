import 'package:cashspark/data/models/bonus_models.dart';
import 'package:cashspark/data/models/spin_data_model.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';

abstract class RewardRepository {
  // Reward Config
  Future<RewardConfigEntity> getRewardConfig();

  // Rewarded Ads
  Future<RewardEntity> claimAdReward(String userId);
  Future<int> getTodayAdCount(String userId);
  Future<DateTime?> getLastAdWatchTime(String userId);
  Future<List<RewardEntity>> getAdRewardHistory(String userId);

  // Scratch card generation from ad reward
  /// Generate a scratch card for a user as a reward for watching an ad.
  Future<void> addScratchCardFromAd(String userId, String sourceId);

  // Daily Check-In
  Future<DailyCheckInEntity> claimDailyCheckIn(String userId);
  Future<StreakEntity> getStreak(String userId);
  Future<DailyCheckInEntity?> getTodayCheckIn(String userId);
  Future<List<DailyCheckInEntity>> getCheckInHistory(String userId,
      {int limit = 30});

  // Streak Tracking
  Stream<StreakEntity?> streamStreak(String userId);

  // Weekly Bonus
  Future<WeeklyBonusModel?> getWeeklyBonus(String userId);
  Future<void> saveWeeklyBonus(WeeklyBonusModel bonus);
  Stream<WeeklyBonusModel?> streamWeeklyBonus(String userId);

  // Streak Recovery
  /// Recover a missed weekly day by watching a rewarded ad.
  /// Returns true if recovery succeeded.
  Future<bool> recoverWeeklyStreak(String userId);
  /// Recover a missed monthly day by watching a rewarded ad.
  /// Returns true if recovery succeeded.
  Future<bool> recoverMonthlyStreak(String userId);

  // Monthly Bonus
  Future<MonthlyBonusModel?> getMonthlyBonus(String userId, String monthKey);
  Future<void> saveMonthlyBonus(MonthlyBonusModel bonus);
  Stream<MonthlyBonusModel?> streamMonthlyBonus(String userId);

  // Tasks
  Future<List<TaskEntity>> getTodaysTasks(String userId);
  Future<TaskEntity> updateTaskProgress(String taskId, int increment);
  Future<RewardEntity> claimTaskReward(String taskId);
  Stream<List<TaskEntity>> streamTasks(String userId);

  // Spin Data
  Future<SpinDataEntity?> getSpinData(String userId);
  Future<void> saveSpinData(SpinDataEntity data);
  Stream<SpinDataEntity?> streamSpinData(String userId);

  // Rewards History
  Future<List<RewardEntity>> getRewardHistory(String userId,
      {RewardType? type, int limit = 50});
  Future<double> getTotalRewardsByType(String userId, RewardType type);
  Future<double> getTodayAdEarnings(String userId);
  Future<int> getLifetimeAdCount(String userId);
}
