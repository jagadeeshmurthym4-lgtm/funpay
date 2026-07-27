import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';

abstract class AdminRepository {
  // Admin Authentication
  Future<bool> isAdmin(String uid);
  Future<bool> isAdminByEmail(String email);
  Future<AdminEntity?> getAdmin(String uid);
  Future<void> recordAdminLogin(String uid);

  // Dashboard Stats
  Future<int> getTotalUsers();
  Future<int> getActiveUsers({int days = 30});
  Future<double> getTotalEarnings();
  Future<double> getTotalWithdrawn();
  Future<int> getPendingWithdrawalsCount();
  Future<int> getTotalReferrals();
  Future<List<int>> getDailyUserGrowth({int days = 7});
  Future<Map<String, double>> getRevenueStats();

  // User Management
  Future<List<UserEntity>> getAllUsers({int limit = 50});
  Future<List<UserEntity>> searchUsers(String query);
  Future<UserEntity> updateUserStatus(String uid, {required bool isActive});
  Future<void> deleteUser(String uid);

  // Wallet Management
  Future<void> creditUserWallet({
    required String userId,
    required double amount,
    required String description,
  });
  Future<void> debitUserWallet({
    required String userId,
    required double amount,
    required String description,
  });

  // Referral Management
  Future<List<ReferralEntity>> getAllReferrals({int limit = 50});
  Future<void> disableReferralSystem();

  // Withdrawal Management
  Future<List<WithdrawalEntity>> getAllWithdrawals({WithdrawalStatus? status, int limit = 50});
  Stream<List<WithdrawalEntity>> streamAllWithdrawals({WithdrawalStatus? status});
  Future<WithdrawalEntity> approveWithdrawal(String withdrawalId, {String? remarks});
  Future<WithdrawalEntity> rejectWithdrawal(String withdrawalId, {required String remarks});

  // Settings
  Future<AppSettingsEntity> getAppSettings();
  Future<AppSettingsEntity> updateAppSettings(AppSettingsEntity settings);
  Future<void> sendAnnouncement(String message);
  Future<void> broadcastNewTaskNotification(String taskTitle, double rewardAmount);

  // Audit Logging
  Future<void> logAdminAction({
    required String adminUid,
    required String action,
    required String targetType,
    String? targetId,
    String? details,
  });
  Future<List<AdminLogEntity>> getAdminLogs({int limit = 50});
}
