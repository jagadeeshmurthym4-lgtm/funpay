import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FirebaseFirestoreDataSource {
  final FirebaseFirestore _firestore;

  FirebaseFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  Future<UserModel?> getUser(String uid) async {
    try {
      debugPrint('[Firestore] getUser - uid: $uid (forcing server read)');
      final doc = await _firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      if (!doc.exists || doc.data() == null) {
        debugPrint('[Firestore] getUser - user $uid NOT FOUND on server');
        return null;
      }
      debugPrint('[Firestore] getUser - user $uid FOUND on server');
      return UserModel.fromFirestore(doc.data()!);
    } catch (e) {
      debugPrint('[Firestore] getUser - ERROR for uid $uid: $e');
      // Fallback to cache
      try {
        debugPrint('[Firestore] getUser - falling back to cache for $uid');
        final doc = await _firestore
            .collection(AppConstants.usersCollection)
            .doc(uid)
            .get(const GetOptions(source: Source.cache));
        if (!doc.exists || doc.data() == null) return null;
        return UserModel.fromFirestore(doc.data()!);
      } catch (cacheError) {
        debugPrint('[Firestore] getUser - cache fallback also failed for $uid: $cacheError');
        return null;
      }
    }
  }

  Future<void> createUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .set(user.toFirestore());
  }

  Future<void> updateUser(UserModel user) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(user.uid)
        .update(user.toFirestore());
  }

  Future<void> deleteUser(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }

  Stream<UserModel?> streamUser(String uid) {
    return _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .snapshots()
        .map((snapshot) {
      if (!snapshot.exists || snapshot.data() == null) return null;
      return UserModel.fromFirestore(snapshot.data()!);
    });
  }

  Future<UserModel?> getUserByReferralCode(String referralCode) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      debugPrint('getUserByReferralCode error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByPhone(String phone) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('phone', isEqualTo: phone)
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      debugPrint('getUserByPhone error: $e');
      return null;
    }
  }

  Future<UserModel?> getUserByEmail(String email) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('email', isEqualTo: email.toLowerCase().trim())
          .limit(1)
          .get();
      if (query.docs.isEmpty) return null;
      return UserModel.fromFirestore(query.docs.first.data());
    } catch (e) {
      debugPrint('getUserByEmail error: $e');
      return null;
    }
  }

  Future<bool> isReferralCodeTaken(String referralCode) async {
    try {
      final query = await _firestore
          .collection(AppConstants.usersCollection)
          .where('referralCode', isEqualTo: referralCode.toUpperCase())
          .limit(1)
          .get();
      return query.docs.isNotEmpty;
    } catch (e) {
      debugPrint('isReferralCodeTaken error: $e');
      return false;
    }
  }
}
