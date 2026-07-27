import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/device_registry_model.dart';
import 'package:cashspark/data/models/fraud_report_model.dart';
import 'package:cashspark/data/models/login_attempt_model.dart';
import 'package:cashspark/data/models/user_model.dart';
import 'package:cashspark/domain/entities/fraud_report_entity.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class FraudFirestoreDataSource {
  final FirebaseFirestore _firestore;

  FraudFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // --- Device Registry ---

  Future<bool> isDeviceRegistered(String deviceId) async {
    final doc = await _firestore
        .collection(AppConstants.deviceRegistryCollection)
        .doc(deviceId)
        .get();
    return doc.exists;
  }

  Future<DeviceRegistryModel?> getDeviceOwner(String deviceId) async {
    final doc = await _firestore
        .collection(AppConstants.deviceRegistryCollection)
        .doc(deviceId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return DeviceRegistryModel.fromFirestore(doc.data()!, doc.id);
  }

  Future<void> registerDevice(Map<String, dynamic> data, String deviceId) async {
    await _firestore
        .collection(AppConstants.deviceRegistryCollection)
        .doc(deviceId)
        .set(data);
  }

  Future<int> getDevicesForUser(String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.deviceRegistryCollection)
          .where('userId', isEqualTo: userId)
          .get();
      return snapshot.docs.length;
    } catch (e) {
      debugPrint('getDevicesForUser error: $e');
      return 0;
    }
  }

  Future<List<DeviceRegistryModel>> getUsersOnDevice(String deviceId) async {
    final doc = await _firestore
        .collection(AppConstants.deviceRegistryCollection)
        .doc(deviceId)
        .get();
    if (!doc.exists || doc.data() == null) return [];
    return [DeviceRegistryModel.fromFirestore(doc.data()!, doc.id)];
  }

  // --- Fraud Reports ---

  Future<List<FraudReportModel>> getFraudReports({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.fraudReportsCollection)
          .get();
      final reports = snapshot.docs
          .map((doc) => FraudReportModel.fromFirestore(doc.data()))
          .toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports.take(limit).toList();
    } catch (e) {
      debugPrint('getFraudReports error: $e');
      return [];
    }
  }

  Future<List<FraudReportModel>> getFlaggedUsers({int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.fraudReportsCollection)
          .get();
      var reports = snapshot.docs
          .map((doc) => FraudReportModel.fromFirestore(doc.data()))
          .where((r) => r.status == FraudStatus.underReview || r.status == FraudStatus.confirmed)
          .toList();
      reports.sort((a, b) => b.fraudScore.compareTo(a.fraudScore));
      return reports.take(limit).toList();
    } catch (e) {
      debugPrint('getFlaggedUsers error: $e');
      return [];
    }
  }

  Future<FraudReportModel?> getFraudReport(String reportId) async {
    final doc = await _firestore
        .collection(AppConstants.fraudReportsCollection)
        .doc(reportId)
        .get();
    if (!doc.exists || doc.data() == null) return null;
    return FraudReportModel.fromFirestore(doc.data()!);
  }

  Future<void> createFraudReport(Map<String, dynamic> data, String reportId) async {
    await _firestore
        .collection(AppConstants.fraudReportsCollection)
        .doc(reportId)
        .set(data);
  }

  Future<void> updateFraudReportStatus(
      String reportId, Map<String, dynamic> data) async {
    await _firestore
        .collection(AppConstants.fraudReportsCollection)
        .doc(reportId)
        .update(data);
  }

  Future<List<FraudReportModel>> getFraudReportsForUser(String userId,
      {int limit = 50}) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.fraudReportsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final reports = snapshot.docs
          .map((doc) => FraudReportModel.fromFirestore(doc.data()))
          .toList();
      reports.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return reports.take(limit).toList();
    } catch (e) {
      debugPrint('getFraudReportsForUser error: $e');
      return [];
    }
  }

  // --- Login Attempts ---

  Future<List<LoginAttemptModel>> getRecentLoginAttempts(String userId,
      {int withinMinutes = 15}) async {
    try {
      final since = DateTime.now().subtract(Duration(minutes: withinMinutes));
      final snapshot = await _firestore
          .collection(AppConstants.loginAttemptsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      var attempts = snapshot.docs
          .map((doc) => LoginAttemptModel.fromFirestore(doc.data(), doc.id))
          .where((a) => a.createdAt.isAfter(since))
          .toList();
      attempts.sort((a, b) => b.createdAt.compareTo(a.createdAt));
      return attempts;
    } catch (e) {
      debugPrint('getRecentLoginAttempts error: $e');
      return [];
    }
  }

  Future<void> recordLoginAttempt(Map<String, dynamic> data, String attemptId) async {
    await _firestore
        .collection(AppConstants.loginAttemptsCollection)
        .doc(attemptId)
        .set(data);
  }

  // --- User Queries ---

  Future<List<UserModel>> getUsersByIds(List<String> uids) async {
    if (uids.isEmpty) return [];
    final batches = <List<String>>[];
    for (var i = 0; i < uids.length; i += 30) {
      batches.add(uids.sublist(i, i + 30 > uids.length ? uids.length : i + 30));
    }
    final users = <UserModel>[];
    for (final batch in batches) {
      final snapshot = await _firestore
          .collection(AppConstants.usersCollection)
          .where('uid', whereIn: batch)
          .get();
      for (final doc in snapshot.docs) {
        users.add(UserModel.fromFirestore(doc.data()));
      }
    }
    return users;
  }

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

  Future<void> updateUserField(String uid, Map<String, dynamic> data) async {
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
}
