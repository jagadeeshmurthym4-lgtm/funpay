import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/data/models/referral_reward_config_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ReferralFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ReferralFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // --- Reward Config ---

  Future<ReferralRewardConfigModel?> getRewardConfig() async {
    final doc = await _firestore
        .collection(AppConstants.referralRewardsCollection)
        .doc('config')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return ReferralRewardConfigModel.fromFirestore(doc.data()!);
  }

  // --- Referral Operations ---

  Future<void> createReferral(ReferralModel referral) async {
    await _firestore
        .collection(AppConstants.referralsCollection)
        .doc(referral.referralId)
        .set(referral.toFirestore());
  }

  Future<ReferralModel?> getReferralById(String referralId) async {
    final doc = await _firestore
        .collection(AppConstants.referralsCollection)
        .doc(referralId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return ReferralModel.fromFirestore(doc.data()!);
  }

  Future<List<ReferralModel>> getReferralsByReferrer(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.referralsCollection)
          .where('referrerUserId', isEqualTo: userId)
          .get();
      final referrals = query.docs
          .map((doc) => ReferralModel.fromFirestore(doc.data()))
          .toList();
      referrals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return referrals;
    } catch (e) {
      debugPrint('getReferralsByReferrer error: $e');
      return [];
    }
  }

  Future<List<ReferralModel>> getReferralsByReferred(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.referralsCollection)
          .where('referredUserId', isEqualTo: userId)
          .get();
      final referrals = query.docs
          .map((doc) => ReferralModel.fromFirestore(doc.data()))
          .toList();
      referrals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return referrals;
    } catch (e) {
      debugPrint('getReferralsByReferred error: $e');
      return [];
    }
  }

  Future<int> getReferralCount(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.referralsCollection)
          .where('referrerUserId', isEqualTo: userId)
          .get();
      return query.docs.where((doc) {
        return doc.data()['status'] == 'completed';
      }).length;
    } catch (e) {
      debugPrint('getReferralCount error: $e');
      return 0;
    }
  }

  Future<double> getTotalReferralEarnings(String userId) async {
    try {
      double total = 0;
      final query = await _firestore
          .collection(AppConstants.referralsCollection)
          .where('referrerUserId', isEqualTo: userId)
          .get();
      for (final doc in query.docs) {
        final data = doc.data();
        // Sum rewardAmount from completed referrals (new system tracks rewards in rewardAmount,
        // old system also had completed status with rewardAmount).
        final status = data['status'] as String? ?? '';
        if (status == 'completed' || status == 'rewarded') {
          total += (data['rewardAmount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      debugPrint('getTotalReferralEarnings error: $e');
      return 0;
    }
  }

  Stream<List<ReferralModel>> streamReferralsByReferrer(String userId) {
    return _firestore
        .collection(AppConstants.referralsCollection)
        .where('referrerUserId', isEqualTo: userId)
        .snapshots()
        .map((snapshot) {
      final referrals = snapshot.docs
          .map((doc) => ReferralModel.fromFirestore(doc.data()))
          .toList();
      referrals.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return referrals;
    });
  }

  // --- Fraud Prevention ---

  /// Find the referral record where a user was referred
  Future<ReferralModel?> getReferralByReferredUser(String referredUserId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.referralsCollection)
          .where('referredUserId', isEqualTo: referredUserId)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return ReferralModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      debugPrint('getReferralByReferredUser error: $e');
      return null;
    }
  }

  /// Update specific fields on a referral document (used by Cloud Function for reward tracking).
  Future<void> updateReferralReward(String referralId, Map<String, dynamic> updates) async {
    try {
      await _firestore
          .collection(AppConstants.referralsCollection)
          .doc(referralId)
          .update(updates);
    } catch (e) {
      debugPrint('updateReferralReward error: $e');
      rethrow;
    }
  }

  /// Update the full referral document with new model data.
  Future<void> updateReferral(ReferralModel referral) async {
    try {
      await _firestore
          .collection(AppConstants.referralsCollection)
          .doc(referral.referralId)
          .update(referral.toFirestore());
    } catch (e) {
      debugPrint('updateReferral error: $e');
      rethrow;
    }
  }

  /// Check if a user has already been referred by someone
  Future<bool> hasUserBeenReferred(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.referralsCollection)
          .where('referredUserId', isEqualTo: userId)
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('hasUserBeenReferred error: $e');
      return false;
    }
  }

  /// Check if a user is trying to refer themselves
  Future<bool> isSelfReferral(String referrerUserId, String referralCode) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return false;
      return query.docs.first.id == referrerUserId;
    } catch (e) {
      debugPrint('isSelfReferral error: $e');
      return false;
    }
  }
}
