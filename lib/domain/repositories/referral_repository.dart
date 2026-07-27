import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/referral_reward_config_entity.dart';

abstract class ReferralRepository {
  Future<ReferralRewardConfigEntity> getRewardConfig();
  Future<ReferralEntity> createReferral({
    required String referrerUserId,
    required String referredUserId,
    required String referralCode,
  });
  Future<List<ReferralEntity>> getReferralsByReferrer(String userId);
  Future<List<ReferralEntity>> getReferralsByReferred(String userId);
  Future<int> getReferralCount(String userId);
  Future<double> getTotalReferralEarnings(String userId);
  Future<int> getReferredUsersWithCompletedProject(String userId);
  Future<double> getLifetimeProjectCommission(String userId);
  Stream<List<ReferralEntity>> streamReferralsByReferrer(String userId);
  Future<ReferralEntity?> validateReferralCode(String code);
  Future<ReferralEntity?> getReferralByReferredUser(String referredUserId);
  Future<void> updateReferralReward(String referralId, Map<String, dynamic> updates);
}
