import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/streak_multiplier_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class StreakMultiplierFirestoreDataSource {
  final FirebaseFirestore _firestore;

  StreakMultiplierFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<StreakMultiplierConfigModel?> getConfig() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.streakMultiplierConfigCollection)
          .doc('config')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return StreakMultiplierConfigModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('getMultiplierConfig error: $e');
      return null;
    }
  }

  Future<void> saveConfig(StreakMultiplierConfigModel config) async {
    await _firestore
        .collection(AppConstants.streakMultiplierConfigCollection)
        .doc('config')
        .set(config.toFirestore());
  }

  Stream<StreakMultiplierConfigModel?> streamConfig() {
    return _firestore
        .collection(AppConstants.streakMultiplierConfigCollection)
        .doc('config')
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return StreakMultiplierConfigModel.fromFirestore(snapshot.data()!);
    });
  }
}
