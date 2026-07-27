import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/admin_model.dart';
import 'package:cashspark/data/models/banner_model.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AdminFirestoreDataSource {
  final FirebaseFirestore _firestore;

  AdminFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // --- Admin Auth ---

  Future<bool> checkIsAdmin(String uid) async {
    // Try by document ID first
    final doc = await _firestore
        .collection(AppConstants.adminsCollection)
        .doc(uid)
        .get();
    Map<String, dynamic>? data;
    if (doc.exists && doc.data() != null) {
      data = doc.data();
    } else {
      // Fallback: query by uid field
      final snapshot = await _firestore
          .collection(AppConstants.adminsCollection)
          .where('uid', isEqualTo: uid)
          .get();
      if (snapshot.docs.isEmpty) return false;
      data = snapshot.docs.first.data();
    }
    final isActive = data!['isActive'];
    if (isActive is bool) return isActive;
    if (isActive is String) return isActive.toLowerCase() == 'true';
    if (isActive is num) return isActive != 0;
    return true;
  }

  /// Checks if a user is admin by looking up the admins collection
  /// First tries by UID (document ID), then falls back to email query
  Future<bool> checkIsAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.adminsCollection)
          .where('email', isEqualTo: email)
          .get();
      if (snapshot.docs.isEmpty) return false;
      final data = snapshot.docs.first.data();
      // Handle both boolean and other types
      final isActive = data['isActive'];
      if (isActive is bool) return isActive;
      if (isActive is String) return isActive.toLowerCase() == 'true';
      if (isActive is num) return isActive != 0;
      return true;
    } catch (e) {
      debugPrint('checkIsAdminByEmail error: $e');
      return false;
    }
  }

  /// Gets an admin by email (returns full admin data including the original UID)
  Future<AdminModel?> getAdminByEmail(String email) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.adminsCollection)
          .where('email', isEqualTo: email)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return AdminModel.fromFirestore(snapshot.docs.first.data());
    } catch (e) {
      debugPrint('getAdminByEmail error: $e');
      return null;
    }
  }

  Future<AdminModel?> getAdmin(String uid) async {
    // First try: lookup by document ID
    var doc = await _firestore
        .collection(AppConstants.adminsCollection)
        .doc(uid)
        .get();
    if (doc.exists && doc.data() != null) {
      return AdminModel.fromFirestore(doc.data()!);
    }
    // Fallback: query by uid field
    final snapshot = await _firestore
        .collection(AppConstants.adminsCollection)
        .where('uid', isEqualTo: uid)
        .get();
    if (snapshot.docs.isEmpty) return null;
    return AdminModel.fromFirestore(snapshot.docs.first.data());
  }

  Future<void> updateAdmin(AdminModel admin) async {
    await _firestore
        .collection(AppConstants.adminsCollection)
        .doc(admin.uid)
        .update(admin.toFirestore());
  }

  // --- Dashboard Stats ---

  Future<int> getTotalUsers() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('getTotalUsers error: $e');
      return 0;
    }
  }

  Future<int> getActiveUsers({int days = 30}) async {
    try {
      final since = DateTime.now().subtract(Duration(days: days));
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        final createdAt = (doc.data()['createdAt'] as dynamic)?.toDate() as DateTime?;
        if (createdAt != null && createdAt.isAfter(since)) {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('getActiveUsers error: $e');
      return 0;
    }
  }

  Future<double> getTotalEarnings() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.transactionsCollection)
          .get();
      double total = 0;
      for (final doc in snapshot.docs) {
        if (doc.data()['type'] == 'credit') {
          total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      debugPrint('getTotalEarnings error: $e');
      return 0;
    }
  }

  Future<double> getTotalWithdrawn() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .get();
      double total = 0;
      for (final doc in snapshot.docs) {
        if (doc.data()['status'] == 'approved') {
          total += (doc.data()['amount'] as num?)?.toDouble() ?? 0.0;
        }
      }
      return total;
    } catch (e) {
      debugPrint('getTotalWithdrawn error: $e');
      return 0;
    }
  }

  Future<int> getPendingWithdrawalsCount() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.withdrawalsCollection)
          .get();
      int count = 0;
      for (final doc in snapshot.docs) {
        if (doc.data()['status'] == 'pending') {
          count++;
        }
      }
      return count;
    } catch (e) {
      debugPrint('getPendingWithdrawalsCount error: $e');
      return 0;
    }
  }

  Future<int> getTotalReferrals() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.referralsCollection)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('getTotalReferrals error: $e');
      return 0;
    }
  }

  Future<List<int>> getDailyUserGrowth({int days = 7}) async {
    try {
      final today = DateTime.now();
      final results = <int>[];
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      for (int i = days - 1; i >= 0; i--) {
        final day = DateTime(today.year, today.month, today.day).subtract(Duration(days: i));
        final nextDay = day.add(const Duration(days: 1));
        int count = 0;
        for (final doc in snapshot.docs) {
          final createdAt = (doc.data()['createdAt'] as dynamic)?.toDate() as DateTime?;
          if (createdAt != null && createdAt.isAfter(day) && createdAt.isBefore(nextDay)) {
            count++;
          }
        }
        results.add(count);
      }
      return results;
    } catch (e) {
      debugPrint('getDailyUserGrowth error: $e');
      return List.filled(days, 0);
    }
  }

  // --- User Management ---

  Future<List<UserModel>> getAllUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();
      final users = snapshot.docs
          .map((doc) => UserModel.fromFirestore(doc.data()))
          .toList();
      users.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return users.take(limit).toList();
    } catch (e) {
      debugPrint('getAllUsers error: $e');
      return [];
    }
  }

  Future<List<UserModel>> searchUsers(String query) async {
    final lowerQuery = query.toLowerCase();
    try {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .get();

      final filtered = snapshot.docs.where((doc) {
        final data = doc.data();
        final name = (data['fullName'] as String? ?? '').toLowerCase();
        final email = (data['email'] as String? ?? '').toLowerCase();
        final uid = (data['uid'] as String? ?? '').toLowerCase();
        return name.contains(lowerQuery) ||
            email.contains(lowerQuery) ||
            uid.contains(lowerQuery);
      }).toList();

      return filtered
          .map((doc) => UserModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('searchUsers error: $e');
      return [];
    }
  }

  Future<void> updateUser(Map<String, dynamic> data, String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .update(data);
  }

  Future<UserModel?> getUser(String uid) async {
    final doc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return UserModel.fromFirestore(doc.data()!);
  }

  Future<void> deleteUserDocument(String uid) async {
    await _firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .delete();
  }

  // --- Referral Management ---

  Future<QuerySnapshot> getReferralsQuery({int limit = 50}) async {
    return await _firestore
        .collection(AppConstants.referralsCollection)
        .get();
  }

  // --- Banners ---

  Future<List<BannerModel>> getBanners() async {
    try {
      final query = await _firestore
          .collection(AppConstants.bannersCollection)
          .get();
      return query.docs
          .map((doc) => BannerModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getBanners error: $e');
      return [];
    }
  }

  Future<void> createBanner(BannerModel banner) async {
    await _firestore
        .collection(AppConstants.bannersCollection)
        .doc(banner.bannerId)
        .set(banner.toFirestore());
  }

  Future<void> updateBanner(BannerModel banner) async {
    await _firestore
        .collection(AppConstants.bannersCollection)
        .doc(banner.bannerId)
        .update(banner.toFirestore());
  }

  Future<void> deleteBanner(String bannerId) async {
    await _firestore
        .collection(AppConstants.bannersCollection)
        .doc(bannerId)
        .delete();
  }

  // --- Verification Requests ---

  Future<void> createVerificationRequest(Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(data['requestId'] as String)
        .set(data);
  }

  Future<List<Map<String, dynamic>>> getVerificationRequests() async {
    try {
      final query = await _firestore
          .collection(AppConstants.verificationRequestsCollection)
          .get();
      return query.docs.map((doc) => doc.data()).toList();
    } catch (e) {
      debugPrint('getVerificationRequests error: $e');
      return [];
    }
  }

  Future<void> updateVerificationRequestStatus(
      String requestId, String status, String adminUid) async {
    await _firestore
        .collection(AppConstants.verificationRequestsCollection)
        .doc(requestId)
        .update({
      'status': status,
      'reviewedBy': adminUid,
      'reviewedAt': DateTime.now(),
    });
  }

  // --- Ad Config ---

  Future<Map<String, dynamic>?> getAdConfig() async {
    try {
      final doc = await _firestore
          .collection(AppConstants.adConfigCollection)
          .doc('config')
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return doc.data()!;
    } catch (e) {
      debugPrint('getAdConfig error: $e');
      return null;
    }
  }

  Future<void> saveAdConfig(Map<String, dynamic> config) async {
    await _firestore
        .collection(AppConstants.adConfigCollection)
        .doc('config')
        .set(config, SetOptions(merge: true));
  }

  // --- Audit Log ---

  Future<void> createAdminLog(AdminLogModel log) async {
    await _firestore
        .collection(AppConstants.adminLogsCollection)
        .doc(log.logId)
        .set(log.toFirestore());
  }

  Future<List<AdminLogModel>> getAdminLogs({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.adminLogsCollection)
          .get();
      final logs = snapshot.docs
          .map((doc) => AdminLogModel.fromFirestore(doc.data()))
          .toList();
      logs.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return logs.take(limit).toList();
    } catch (e) {
      debugPrint('getAdminLogs error: $e');
      return [];
    }
  }

  // --- App Settings ---

  Future<AppSettingsModel?> getAppSettings() async {
    final doc = await _firestore
        .collection(AppConstants.appSettingsCollection)
        .doc('settings')
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return AppSettingsModel.fromFirestore(doc.data()!);
  }

  Future<void> saveAppSettings(AppSettingsModel settings) async {
    await _firestore
        .collection(AppConstants.appSettingsCollection)
        .doc('settings')
        .set(settings.toFirestore());
  }
}
