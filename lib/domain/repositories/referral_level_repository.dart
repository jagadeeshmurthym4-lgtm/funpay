import 'package:cashspark/domain/entities/referral_level_entity.dart';

abstract class ReferralLevelRepository {
  /// Get all configured referral milestone levels.
  Future<List<ReferralLevelEntity>> getAllLevels();

  /// Save a referral level (create or update).
  Future<void> saveLevel(ReferralLevelEntity level);

  /// Delete a referral level.
  Future<void> deleteLevel(String levelId);

  /// Get the set of level numbers the user has already claimed rewards for.
  Future<Set<int>> getClaimedLevels(String userId);

  /// Mark a level milestone reward as claimed by the user.
  Future<void> claimMilestoneReward({
    required String userId,
    required int levelNumber,
    required double rewardAmount,
  });

  /// Get all claimed milestones for a user.
  Future<List<ClaimedMilestoneEntity>> getClaimedMilestones(String userId);
}
