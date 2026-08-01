import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/admin_model.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/referral_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/domain/repositories/admin_repository.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

class AdminRepositoryImpl implements AdminRepository {
  final AdminFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final NotificationFirestoreDataSource _notificationDataSource;
  final Uuid _uuid;

  AdminRepositoryImpl({
    required AdminFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    required NotificationFirestoreDataSource notificationDataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _notificationDataSource = notificationDataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<bool> isAdmin(String uid) async {
    try {
      return await _dataSource.checkIsAdmin(uid);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<bool> isAdminByEmail(String email) async {
    try {
      return await _dataSource.checkIsAdminByEmail(email);
    } catch (e) {
      return false;
    }
  }

  @override
  Future<AdminEntity?> getAdmin(String uid) async {
    try {
      return await _dataSource.getAdmin(uid);
    } catch (e) {
      return null;
    }
  }

  @override
  Future<void> recordAdminLogin(String uid) async {
    try {
      final admin = await _dataSource.getAdmin(uid);
      if (admin != null) {
        final updated = AdminModel.fromEntity(admin).copyWithModel(
          lastLoginAt: DateTime.now(),
        );
        await _dataSource.updateAdmin(updated);
      }
      await logAdminAction(
        adminUid: uid,
        action: 'admin_login',
        targetType: 'admin',
        targetId: uid,
      );
    } catch (_) {}
  }

  @override
  Future<int> getTotalUsers() async {
    try {
      return await _dataSource.getTotalUsers();
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getActiveUsers({int days = 30}) async {
    try {
      return await _dataSource.getActiveUsers(days: days);
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<double> getTotalEarnings() async {
    try {
      return await _dataSource.getTotalEarnings();
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<double> getTotalWithdrawn() async {
    try {
      return await _dataSource.getTotalWithdrawn();
    } catch (e) {
      return 0.0;
    }
  }

  @override
  Future<int> getPendingWithdrawalsCount() async {
    try {
      return await _dataSource.getPendingWithdrawalsCount();
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<int> getTotalReferrals() async {
    try {
      return await _dataSource.getTotalReferrals();
    } catch (e) {
      return 0;
    }
  }

  @override
  Future<List<int>> getDailyUserGrowth({int days = 7}) async {
    try {
      return await _dataSource.getDailyUserGrowth(days: days);
    } catch (e) {
      return List.filled(days, 0);
    }
  }

  @override
  Future<Map<String, double>> getRevenueStats() async {
    try {
      final earnings = await _dataSource.getTotalEarnings();
      final withdrawn = await _dataSource.getTotalWithdrawn();
      return {
        'totalEarnings': earnings,
        'totalWithdrawn': withdrawn,
        'remainingBalance': earnings - withdrawn,
      };
    } catch (e) {
      return {'totalEarnings': 0, 'totalWithdrawn': 0, 'remainingBalance': 0};
    }
  }

  @override
  Future<List<UserEntity>> getAllUsers({int limit = 50}) async {
    try {
      return await _dataSource.getAllUsers(limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get users: $e');
    }
  }

  @override
  Future<List<UserEntity>> searchUsers(String query) async {
    try {
      return await _dataSource.searchUsers(query);
    } catch (e) {
      throw FirestoreException('Failed to search users: $e');
    }
  }

  @override
  Future<UserEntity> updateUserStatus(String uid, {required bool isActive}) async {
    try {
      await _dataSource.updateUser({'isActive': isActive}, uid);
      final user = await _dataSource.getUser(uid);
      if (user == null) throw FirestoreException('User not found');
      return user;
    } catch (e) {
      throw FirestoreException('Failed to update user: $e');
    }
  }

  @override
  Future<void> deleteUser(String uid) async {
    try {
      await _dataSource.deleteUserDocument(uid);
    } catch (e) {
      throw FirestoreException('Failed to delete user: $e');
    }
  }

  @override
  Future<void> creditUserWallet({
    required String userId,
    required double amount,
    required String description,
  }) async {
    try {
      await _walletDataSource.updateWalletBalance(
        userId: userId,
        amountChange: amount,
        earningsChange: amount,
        withdrawnChange: 0,
      );
      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.credit,
        amount: amount,
        source: TransactionSource.adminAdjustment,
        status: TransactionStatus.completed,
        description: description,
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);
    } catch (e) {
      throw FirestoreException('Failed to credit wallet: $e');
    }
  }

  @override
  Future<void> debitUserWallet({
    required String userId,
    required double amount,
    required String description,
  }) async {
    try {
      await _walletDataSource.updateWalletBalance(
        userId: userId,
        amountChange: -amount,
        earningsChange: 0,
        withdrawnChange: 0,
      );
      final transaction = TransactionModel(
        transactionId: _uuid.v4(),
        userId: userId,
        type: TransactionType.debit,
        amount: amount,
        source: TransactionSource.adminAdjustment,
        status: TransactionStatus.completed,
        description: description,
        createdAt: DateTime.now(),
      );
      await _walletDataSource.createTransaction(transaction);
    } on InsufficientBalanceException {
      throw AdminException('Insufficient balance to debit');
    } catch (e) {
      throw FirestoreException('Failed to debit wallet: $e');
    }
  }

  @override
  Future<List<ReferralEntity>> getAllReferrals({int limit = 50}) async {
    try {
      final snapshot = await _dataSource.getReferralsQuery(limit: limit);
      return snapshot.docs
          .map((doc) => ReferralModel.fromFirestore(doc.data() as Map<String, dynamic>))
          .toList();
    } catch (e) {
      throw FirestoreException('Failed to get referrals: $e');
    }
  }

  @override
  Future<void> disableReferralSystem() async {
    try {
      final settingsData = await _dataSource.getAppSettings();
      if (settingsData != null) {
        final updated = settingsData.copyWithModel(isReferralActive: false);
        await _dataSource.saveAppSettings(updated);
      }
    } catch (e) {
      throw FirestoreException('Failed to disable referrals: $e');
    }
  }

  @override
  Future<List<WithdrawalEntity>> getAllWithdrawals({
    WithdrawalStatus? status,
    int limit = 50,
  }) async {
    try {
      return [];
    } catch (e) {
      throw FirestoreException('Failed to get withdrawals: $e');
    }
  }

  @override
  Stream<List<WithdrawalEntity>> streamAllWithdrawals({WithdrawalStatus? status}) {
    throw UnimplementedError('Use WithdrawalRepository for withdrawals');
  }

  @override
  Future<WithdrawalEntity> approveWithdrawal(
    String withdrawalId, {
    String? remarks,
  }) async {
    throw UnimplementedError('Use WithdrawalRepository for withdrawals');
  }

  @override
  Future<WithdrawalEntity> rejectWithdrawal(
    String withdrawalId, {
    required String remarks,
  }) async {
    throw UnimplementedError('Use WithdrawalRepository for withdrawals');
  }

  @override
  Future<AppSettingsEntity> getAppSettings() async {
    try {
      final settings = await _dataSource.getAppSettings();
      return settings ??
          AppSettingsModel(
            id: 'settings',
            updatedAt: DateTime.now(),
          );
    } catch (e) {
      return AppSettingsModel(
        id: 'settings',
        updatedAt: DateTime.now(),
      );
    }
  }

  @override
  Future<AppSettingsEntity> updateAppSettings(AppSettingsEntity settings) async {
    try {
      final model = settings is AppSettingsModel
          ? settings
          : AppSettingsModel(
              id: settings.id,
              updatedAt: settings.updatedAt,
            );
      final updated = model.copyWithModel(updatedAt: DateTime.now());
      await _dataSource.saveAppSettings(updated);
      return updated;
    } catch (e) {
      throw FirestoreException('Failed to update settings: $e');
    }
  }

  @override
  Future<void> sendAnnouncement(String message) async {
    try {
      // 1. Save announcement to app settings (existing behavior)
      final settingsData = await _dataSource.getAppSettings();
      if (settingsData != null) {
        final updated = settingsData.copyWithModel(announcement: message);
        await _dataSource.saveAppSettings(updated);
      }

      // 2. Broadcast notification to ALL users
      await _broadcastNotification(
        title: '📢 New Announcement',
        message: message,
        type: NotificationType.announcement,
      );
    } catch (e) {
      throw FirestoreException('Failed to send announcement: $e');
    }
  }

  /// Create a notification for every active user in the system.
  /// Sends FCM push broadcast independently so it still works
  /// even if fetching all users for in-app notifications fails.
  Future<void> _broadcastNotification({
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    // 1. In-app notifications for each user (best-effort)
    try {
      final users = await _dataSource.getAllUsers(limit: 1000);
      for (final user in users) {
        try {
          final notification = NotificationModel(
            notificationId: _uuid.v4(),
            userId: user.uid,
            title: title,
            message: message,
            type: type,
            isRead: false,
            createdAt: DateTime.now(),
          );
          await _notificationDataSource.createNotification(notification);
        } catch (e) {
          debugPrint('Failed to create notification for user ${user.uid}: $e');
        }
      }
    } catch (e) {
      debugPrint('Failed to fetch users for in-app broadcast: $e');
    }

    // 2. FCM push notification (always attempt, independent of user listing)
    try {
      await FcmService.sendBroadcastPush(
        title: title,
        message: message,
        type: type.name,
      );
    } catch (e) {
      debugPrint('Failed to send FCM broadcast push: $e');
    }
  }

  @override
  Future<void> broadcastNewTaskNotification(String taskTitle, double rewardAmount) async {
    try {
      await _broadcastNotification(
        title: '🆕 New Task Available',
        message: '"$taskTitle" is now live! Complete it to earn ${rewardAmount.toStringAsFixed(0)} pts reward.',
        type: NotificationType.announcement,
      );
    } catch (e) {
      debugPrint('Failed to broadcast task notification: $e');
    }
  }

  @override
  Future<void> logAdminAction({
    required String adminUid,
    required String action,
    required String targetType,
    String? targetId,
    String? details,
  }) async {
    try {
      final log = AdminLogModel(
        logId: _uuid.v4(),
        adminUid: adminUid,
        action: action,
        targetType: targetType,
        targetId: targetId,
        details: details,
        createdAt: DateTime.now(),
      );
      await _dataSource.createAdminLog(log);
    } catch (_) {}
  }

  @override
  Future<List<AdminLogEntity>> getAdminLogs({int limit = 50}) async {
    try {
      return await _dataSource.getAdminLogs(limit: limit);
    } catch (e) {
      throw FirestoreException('Failed to get admin logs: $e');
    }
  }
}
