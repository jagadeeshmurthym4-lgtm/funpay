import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/fraud_firestore_datasource.dart';
import 'package:cashspark/data/models/fraud_report_model.dart';
import 'package:cashspark/domain/entities/device_registry_entity.dart';
import 'package:cashspark/domain/entities/fraud_report_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/fraud_repository.dart';
import 'package:uuid/uuid.dart';

class FraudRepositoryImpl implements FraudRepository {
  final FraudFirestoreDataSource _dataSource;
  final Uuid _uuid;

  FraudRepositoryImpl({
    required FraudFirestoreDataSource dataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<bool> isDeviceRegistered(String deviceId) async {
    try {
      return await _dataSource.isDeviceRegistered(deviceId);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<DeviceRegistryEntity?> getDeviceOwner(String deviceId) async {
    try {
      return await _dataSource.getDeviceOwner(deviceId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> registerDevice({
    required String deviceId,
    required String userId,
    String? deviceModel,
    String? devicePlatform,
  }) async {
    try {
      await _dataSource.registerDevice({
        'userId': userId,
        'registeredAt': DateTime.now(),
        if (deviceModel != null) 'deviceModel': deviceModel,
        if (devicePlatform != null) 'devicePlatform': devicePlatform,
      }, deviceId);
    } catch (e) {
      throw FirestoreException('Failed to register device: $e');
    }
  }

  @override
  Future<int> getDevicesForUser(String userId) async {
    try {
      return await _dataSource.getDevicesForUser(userId);
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<List<DeviceRegistryEntity>> getUsersOnDevice(String deviceId) async {
    try {
      return await _dataSource.getUsersOnDevice(deviceId);
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<FraudReportEntity>> getFraudReports({int limit = 50}) async {
    try {
      return await _dataSource.getFraudReports(limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get fraud reports: $e');
    }
  }

  @override
  Future<List<FraudReportEntity>> getFlaggedUsers({int limit = 50}) async {
    try {
      return await _dataSource.getFlaggedUsers(limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get flagged users: $e');
    }
  }

  @override
  Future<FraudReportEntity?> getFraudReport(String reportId) async {
    try {
      return await _dataSource.getFraudReport(reportId);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> createFraudReport({
    required String userId,
    required String reason,
    required RiskLevel riskLevel,
    required double fraudScore,
    String? detectedBy,
  }) async {
    try {
      final reportId = _uuid.v4();
      final report = FraudReportModel(
        reportId: reportId,
        userId: userId,
        reason: reason,
        riskLevel: riskLevel,
        fraudScore: fraudScore,
        status: FraudStatus.underReview,
        createdAt: DateTime.now(),
        detectedBy: detectedBy,
      );
      await _dataSource.createFraudReport(report.toFirestore(), reportId);
    } catch (e) {
      throw FirestoreException('Failed to create fraud report: $e');
    }
  }

  @override
  Future<void> updateFraudReportStatus({
    required String reportId,
    required FraudStatus status,
    String? adminNotes,
  }) async {
    try {
      await _dataSource.updateFraudReportStatus(reportId, {
        'status': status.name,
        if (adminNotes != null) 'adminNotes': adminNotes,
      });
    } catch (e) {
      throw FirestoreException('Failed to update fraud report: $e');
    }
  }

  @override
  Future<bool> isUserFlagged(String userId) async {
    try {
      final reports = await _dataSource.getFraudReportsForUser(userId);
      return reports.any((r) =>
          r.status == FraudStatus.underReview ||
          r.status == FraudStatus.confirmed);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<RiskLevel> getUserRiskLevel(String userId) async {
    try {
      final reports = await _dataSource.getFraudReportsForUser(userId);
      if (reports.isEmpty) return RiskLevel.low;

      final highestRisk = reports
          .where((r) =>
              r.status == FraudStatus.underReview ||
              r.status == FraudStatus.confirmed)
          .toList();

      if (highestRisk.isEmpty) return RiskLevel.low;

      if (highestRisk.any((r) => r.riskLevel == RiskLevel.high)) {
        return RiskLevel.high;
      }
      if (highestRisk.any((r) => r.riskLevel == RiskLevel.medium)) {
        return RiskLevel.medium;
      }
      return RiskLevel.low;
    } catch (e) {
      return RiskLevel.low;
    }
  }

  @override
  Future<double> getUserFraudScore(String userId) async {
    try {
      final reports = await _dataSource.getFraudReportsForUser(userId);
      if (reports.isEmpty) return 0.0;
      final activeReports = reports
          .where((r) =>
              r.status == FraudStatus.underReview ||
              r.status == FraudStatus.confirmed);
      double total = 0.0;
      for (final r in activeReports) {
        total += r.fraudScore;
      }
      return total;
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<void> flagUser({
    required String userId,
    required String reason,
    required RiskLevel riskLevel,
    required double fraudScore,
  }) async {
    try {
      await createFraudReport(
        userId: userId,
        reason: reason,
        riskLevel: riskLevel,
        fraudScore: fraudScore,
        detectedBy: 'system',
      );
      // Mark user as not active (flagged)
      await _dataSource.updateUserField(userId, {'isActive': false});
    } catch (e) {
      throw FirestoreException('Failed to flag user: $e');
    }
  }

  @override
  Future<void> unflagUser(String userId) async {
    try {
      // Mark all active reports as dismissed
      final reports = await _dataSource.getFraudReportsForUser(userId);
      for (final report in reports) {
        if (report.status == FraudStatus.underReview) {
          await _dataSource.updateFraudReportStatus(report.reportId, {
            'status': FraudStatus.dismissed.name,
            'adminNotes': 'Unflagged by admin',
          });
        }
      }
      // Reactivate user
      await _dataSource.updateUserField(userId, {'isActive': true});
    } catch (e) {
      throw FirestoreException('Failed to unflag user: $e');
    }
  }

  @override
  Future<List<UserEntity>> getFlaggedUserProfiles({int limit = 50}) async {
    try {
      final reports = await _dataSource.getFlaggedUsers(limit: limit);
      final userIds = reports.map((r) => r.userId).toSet().toList();
      return await _dataSource.getUsersByIds(userIds);
    } catch (e) {
      throw FirestoreException('Failed to get flagged user profiles: $e');
    }
  }

  @override
  Future<bool> detectSelfReferral(String userId, String referredUserId) async {
    return userId == referredUserId;
  }

  @override
  Future<bool> detectDuplicateReferral(
      String ipAddress, String referredUserId) async {
    // This would require IP tracking — simplified check
    // In production, query recent referrals by IP address
    return false;
  }

  @override
  Future<bool> detectSuspiciousActivity(String userId) async {
    try {
      final attempts = await getFailedLoginAttempts(userId, withinMinutes: 15);
      return attempts >= 5;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<int> getLoginAttempts(String userId,
      {int withinMinutes = 15}) async {
    try {
      final attempts =
          await _dataSource.getRecentLoginAttempts(userId, withinMinutes: withinMinutes);
      return attempts.length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<void> recordLoginAttempt({
    required String userId,
    required bool success,
    String? ipAddress,
    String? deviceId,
  }) async {
    try {
      await _dataSource.recordLoginAttempt({
        'userId': userId,
        'success': success,
        'createdAt': DateTime.now(),
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (deviceId != null) 'deviceId': deviceId,
      }, _uuid.v4());
    } catch (_) {}
  }

  @override
  Future<int> getFailedLoginAttempts(String userId,
      {int withinMinutes = 15}) async {
    try {
      final attempts =
          await _dataSource.getRecentLoginAttempts(userId, withinMinutes: withinMinutes);
      return attempts.where((a) => !a.success).length;
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<bool> isAccountLocked(String userId,
      {int lockoutMinutes = 30}) async {
    try {
      final user = await _dataSource.getUser(userId);
      if (user == null) return false;
      if (user.isActive) return false;
      // Check if there's a recent lockout
      final attempts =
          await _dataSource.getRecentLoginAttempts(userId, withinMinutes: lockoutMinutes);
      final failedCount = attempts.where((a) => !a.success).length;
      return failedCount >= 5;
    } catch (e) {
      return false;
    }
  }

  @override
  Future<void> lockAccount(String userId, {int durationMinutes = 30}) async {
    try {
      await _dataSource.updateUserField(userId, {'isActive': false});
      await createFraudReport(
        userId: userId,
        reason: 'Account locked due to suspicious activity',
        riskLevel: RiskLevel.medium,
        fraudScore: 30.0,
        detectedBy: 'system',
      );
    } catch (e) {
      throw FirestoreException('Failed to lock account: $e');
    }
  }

  @override
  Future<void> unlockAccount(String userId) async {
    try {
      await _dataSource.updateUserField(userId, {'isActive': true});
      // Dismiss active fraud reports related to lockout
      final reports = await _dataSource.getFraudReportsForUser(userId);
      for (final report in reports) {
        if (report.status == FraudStatus.underReview &&
            report.reason.contains('locked')) {
          await _dataSource.updateFraudReportStatus(report.reportId, {
            'status': FraudStatus.dismissed.name,
            'adminNotes': 'Account unlocked by admin',
          });
        }
      }
    } catch (e) {
      throw FirestoreException('Failed to unlock account: $e');
    }
  }
}
