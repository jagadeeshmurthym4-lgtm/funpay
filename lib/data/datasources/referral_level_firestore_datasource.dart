import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/referral_level_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class ReferralLevelFirestoreDataSource {
  final FirebaseFirestore _firestore;

  ReferralLevelFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<List<ReferralLevelModel>> getAllLevels() async {
    try {
      final query = await _firestore
          .collection(AppConstants.referralLevelsConfigCollection)
          .get();
      final levels = query.docs
          .map((doc) => ReferralLevelModel.fromFirestore(doc.data()))
          .toList();
      levels.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
      return levels;
    } catch (e) {
      debugPrint('getAllLevels error: $e');
      return [];
    }
  }

  Future<void> saveLevel(ReferralLevelModel level) async {
    await _firestore
        .collection(AppConstants.referralLevelsConfigCollection)
        .doc(level.id)
        .set(level.toFirestore());
  }

  Future<void> deleteLevel(String levelId) async {
    await _firestore
        .collection(AppConstants.referralLevelsConfigCollection)
        .doc(levelId)
        .delete();
  }

  Stream<List<ReferralLevelModel>> streamLevels() {
    return _firestore
        .collection(AppConstants.referralLevelsConfigCollection)
        .snapshots()
        .map((snapshot) {
      final levels = snapshot.docs
          .map((doc) => ReferralLevelModel.fromFirestore(doc.data()))
          .toList();
      levels.sort((a, b) => a.levelNumber.compareTo(b.levelNumber));
      return levels;
    });
  }

  Future<List<ClaimedMilestoneModel>> getClaimedMilestones(String userId) async {
    try {
      final query = await _firestore
          .collection(AppConstants.claimedMilestonesCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return query.docs
          .map((doc) => ClaimedMilestoneModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getClaimedMilestones error: $e');
      return [];
    }
  }

  Future<void> claimMilestone(ClaimedMilestoneModel milestone) async {
    await _firestore
        .collection(AppConstants.claimedMilestonesCollection)
        .doc(milestone.id)
        .set(milestone.toFirestore());
  }
}
