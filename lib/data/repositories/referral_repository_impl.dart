import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/referral_reward_config_entity.dart';
import 'package:cashspark/domain/repositories/referral_repository.dart';
import 'package:uuid/uuid.dart';

class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralFirestoreDataSource _dataSource;
  final Uuid _uuid;

  ReferralRepositoryImpl({
    required ReferralFirestoreDataSource dataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<ReferralRewardConfigEntity> getRewardConfig() async {
    try {
      final config = await _dataSource.getRewardConfig();
      if (config == null) {
        // Return default config if not set in Firestore
        return const ReferralRewardConfigEntity(
          id: 'config',
          referrerBonus: 10.0,
          referredBonus: 4.0,
          isActive: true,
        );
      }
      return config;
    } catch (e) {
      throw FirestoreException('Failed to get reward config: $e');
    }
  }

  @override
  Future<ReferralEntity> createReferral({
    required String referrerUserId,
    required String referredUserId,
    required String referralCode,
  }) async {
    try {
      // Fraud prevention: check self-referral
      if (referrerUserId == referredUserId) {
        throw ReferralException('You cannot refer yourself');
      }

      // Fraud prevention: check if already referred
      final alreadyReferred = await _dataSource.hasUserBeenReferred(referredUserId);
      if (alreadyReferred) {
        throw ReferralException('This user has already been referred');
      }

      // Get reward configuration
      final config = await getRewardConfig();
      if (!config.isActive) {
        throw ReferralException('Referral system is currently disabled');
      }

      // Create referral record (no immediate sign-up bonus anymore)
      // Rewards are now given via Cloud Function when referred user completes projects
      final referral = ReferralModel(
        referralId: _uuid.v4(),
        referrerUserId: referrerUserId,
        referredUserId: referredUserId,
        referralCode: referralCode.toUpperCase(),
        rewardAmount: 0.0, // No immediate bonus
        status: ReferralStatus.completed,
        createdAt: DateTime.now(),
        firstProjectRewarded: false,
        lifetimeProjectCommission: 0.0,
        rewardedProjectIds: [],
        approvedProjectCount: 0,
      );

      await _dataSource.createReferral(referral);

      return referral;
    } on ReferralException {
      rethrow;
    } on FirestoreException {
      rethrow;
    } catch (e) {
      throw FirestoreException('Failed to create referral: $e');
    }
  }

  @override
  Future<List<ReferralEntity>> getReferralsByReferrer(String userId) async {
    try {
      return await _dataSource.getReferralsByReferrer(userId);
    } catch (e) {
      throw FirestoreException('Failed to get referrals: $e');
    }
  }

  @override
  Future<List<ReferralEntity>> getReferralsByReferred(String userId) async {
    try {
      return await _dataSource.getReferralsByReferred(userId);
    } catch (e) {
      throw FirestoreException('Failed to get referrals: $e');
    }
  }

  @override
  Future<int> getReferralCount(String userId) async {
    try {
      return await _dataSource.getReferralCount(userId);
    } catch (e) {
      throw FirestoreException('Failed to get referral count: $e');
    }
  }

  @override
  Future<double> getTotalReferralEarnings(String userId) async {
    try {
      return await _dataSource.getTotalReferralEarnings(userId);
    } catch (e) {
      throw FirestoreException('Failed to get referral earnings: $e');
    }
  }

  @override
  Stream<List<ReferralEntity>> streamReferralsByReferrer(String userId) {
    return _dataSource.streamReferralsByReferrer(userId);
  }

  @override
  Future<ReferralEntity?> validateReferralCode(String code) async {
    // The code will be validated via FirebaseFirestoreDataSource.getUserByReferralCode
    // This method returns null if not found, which means invalid code
    return null; // Validation happens at the auth level
  }

  @override
  Future<int> getReferredUsersWithCompletedProject(String userId) async {
    try {
      final referrals = await _dataSource.getReferralsByReferrer(userId);
      return referrals.where((r) => r.approvedProjectCount > 0).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<double> getLifetimeProjectCommission(String userId) async {
    try {
      final referrals = await _dataSource.getReferralsByReferrer(userId);
      return referrals.fold<double>(
        0,
        (sum, r) => sum + r.lifetimeProjectCommission,
      );
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<ReferralEntity?> getReferralByReferredUser(String referredUserId) async {
    try {
      return await _dataSource.getReferralByReferredUser(referredUserId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> updateReferralReward(String referralId, Map<String, dynamic> updates) async {
    try {
      await _dataSource.updateReferralReward(referralId, updates);
    } catch (e) {
      throw FirestoreException('Failed to update referral reward: $e');
    }
  }
}
