import 'package:cashspark/domain/entities/device_registry_entity.dart';
import 'package:cashspark/domain/entities/fraud_report_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';

abstract class FraudRepository {
  // Device Registration
  Future<bool> isDeviceRegistered(String deviceId);
  Future<DeviceRegistryEntity?> getDeviceOwner(String deviceId);
  Future<void> registerDevice({
    required String deviceId,
    required String userId,
    String? deviceModel,
    String? devicePlatform,
  });
  Future<int> getDevicesForUser(String userId);
  Future<List<DeviceRegistryEntity>> getUsersOnDevice(String deviceId);

  // Fraud Reports
  Future<List<FraudReportEntity>> getFraudReports({int limit = 50});
  Future<List<FraudReportEntity>> getFlaggedUsers({int limit = 50});
  Future<FraudReportEntity?> getFraudReport(String reportId);
  Future<void> createFraudReport({
    required String userId,
    required String reason,
    required RiskLevel riskLevel,
    required double fraudScore,
    String? detectedBy,
  });
  Future<void> updateFraudReportStatus({
    required String reportId,
    required FraudStatus status,
    String? adminNotes,
  });

  // Security Checks
  Future<bool> isUserFlagged(String userId);
  Future<RiskLevel> getUserRiskLevel(String userId);
  Future<double> getUserFraudScore(String userId);

  // User Actions
  Future<void> flagUser({
    required String userId,
    required String reason,
    required RiskLevel riskLevel,
    required double fraudScore,
  });
  Future<void> unflagUser(String userId);
  Future<List<UserEntity>> getFlaggedUserProfiles({int limit = 50});

  // Fraud Detection
  Future<bool> detectSelfReferral(String userId, String referredUserId);
  Future<bool> detectDuplicateReferral(String ipAddress, String referredUserId);
  Future<bool> detectSuspiciousActivity(String userId);
  Future<int> getLoginAttempts(String userId, {int withinMinutes = 15});
  Future<void> recordLoginAttempt({
    required String userId,
    required bool success,
    String? ipAddress,
    String? deviceId,
  });
  Future<int> getFailedLoginAttempts(String userId, {int withinMinutes = 15});
  Future<bool> isAccountLocked(String userId, {int lockoutMinutes = 30});
  Future<void> lockAccount(String userId, {int durationMinutes = 30});
  Future<void> unlockAccount(String userId);
}
