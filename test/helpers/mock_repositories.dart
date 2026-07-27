import 'dart:async';

import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/entities/custom_task_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/referral_reward_config_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/entities/wallet_entity.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/domain/repositories/admin_repository.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:cashspark/domain/repositories/referral_repository.dart';
import 'package:cashspark/domain/repositories/task_repository.dart';
import 'package:cashspark/domain/repositories/wallet_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
// ─── Mock Auth Repository ─────────────────────────────────────

class MockAuthRepository implements AuthRepository {
  UserEntity? _mockUser;
  bool _shouldThrowOnSignOut = false;
  bool _shouldThrowOnDeleteAccount = false;
  /// Controls what signInWithGoogle returns.
  bool _simulateNewUser = false;
  final StreamController<UserEntity?> _authStateController =
      StreamController<UserEntity?>.broadcast();

  void setMockUser(UserEntity? user) {
    _mockUser = user;
  }

  /// When true, signInWithGoogle will return a new user (profile not completed).
  /// When false (default), returns an existing user with completed profile.
  void setSimulateNewUser(bool value) {
    _simulateNewUser = value;
  }

  void setShouldThrowOnSignOut(bool shouldThrow) {
    _shouldThrowOnSignOut = shouldThrow;
  }

  void setShouldThrowOnDeleteAccount(bool shouldThrow) {
    _shouldThrowOnDeleteAccount = shouldThrow;
  }

  void emitAuthState(UserEntity? user) {
    _authStateController.add(user);
  }

  @override
  UserEntity? get currentUser => _mockUser;

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  Future<({UserEntity user, bool isNewUser})> signInWithGoogle() async {
    final user = UserEntity(
      uid: 'google-uid',
      firstName: 'Google',
      lastName: 'User',
      fullName: 'Google User',
      email: 'google@example.com',
      referralCode: 'GOOG1234',
      profileCompleted: !_simulateNewUser,
      createdAt: DateTime.now(),
    );
    _mockUser = user;
    return (user: user, isNewUser: _simulateNewUser);
  }

  @override
  Future<UserEntity> completeProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    String? referralCode,
  }) async {
    if (_mockUser == null) throw Exception('Not authenticated');
    _mockUser = _mockUser!.copyWith(
      firstName: firstName,
      lastName: lastName,
      fullName: '$firstName $lastName',
      phone: phone.isNotEmpty ? phone : null,
      dateOfBirth: dateOfBirth,
      referralCodeUsed: referralCode?.toUpperCase(),
      profileCompleted: true,
      profileCompletionPercentage: 100,
    );
    return _mockUser!;
  }

  @override
  Future<void> reloadUser() async {}

  @override
  Future<void> signOut() async {
    if (_shouldThrowOnSignOut) throw Exception('Sign out failed');
    _mockUser = null;
    _authStateController.add(null);
  }

  @override
  Future<UserEntity?> getCurrentUser() async => _mockUser;

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? aboutMe,
    String? education,
    String? experience,
    List<String>? portfolioLinks,
    String? profilePicture,
    String? coverImage,
  }) async {
    if (_mockUser == null) throw Exception('Not authenticated');
    _mockUser = _mockUser!.copyWith(
      fullName: fullName ?? _mockUser!.fullName,
      username: username ?? _mockUser!.username,
      phone: phone ?? _mockUser!.phone,
      dateOfBirth: dateOfBirth ?? _mockUser!.dateOfBirth,
      gender: gender ?? _mockUser!.gender,
      address: address ?? _mockUser!.address,
      city: city ?? _mockUser!.city,
      state: state ?? _mockUser!.state,
      country: country ?? _mockUser!.country,
      aboutMe: aboutMe ?? _mockUser!.aboutMe,
      education: education ?? _mockUser!.education,
      experience: experience ?? _mockUser!.experience,
      portfolioLinks: portfolioLinks ?? _mockUser!.portfolioLinks,
      profilePicture: profilePicture ?? _mockUser!.profilePicture,
      coverImage: coverImage ?? _mockUser!.coverImage,
    );
    return _mockUser!;
  }

  @override
  Future<void> sendPasswordResetEmail(String email, {Map<String, dynamic>? actionCodeSettings}) async {}

  @override
  Future<bool> sendEmailVerification() async => true;

  @override
  Future<UserEntity> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? referralCode,
  }) async {
    return UserEntity(
      uid: 'email-uid',
      firstName: firstName ?? fullName.split(' ').first,
      lastName: lastName ??
          (fullName.split(' ').length > 1
              ? fullName.split(' ').sublist(1).join(' ')
              : ''),
      fullName: fullName,
      email: email,
      phone: phone.isNotEmpty ? phone : null,
      dateOfBirth: dateOfBirth,
      referralCode: 'REF1234',
      profileCompleted: true,
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<void> deleteAccount() async {
    if (_shouldThrowOnDeleteAccount) throw Exception('Delete account failed');
    _mockUser = null;
    _authStateController.add(null);
  }

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    if (_mockUser == null) {
      throw Exception('No mock user configured');
    }
    return _mockUser!;
  }
}

// ─── Mock Referral Repository ──────────────────────────────────

class MockReferralRepository implements ReferralRepository {
  List<ReferralEntity> _referrals = [];
  ReferralRewardConfigEntity? _rewardConfig;
  bool _shouldThrow = false;
  bool _shouldThrowFirestore = false;
  bool _shouldThrowOnRewardConfig = false;
  final StreamController<List<ReferralEntity>> _referralsController =
      StreamController<List<ReferralEntity>>.broadcast();

  void setReferrals(List<ReferralEntity> referrals) {
    _referrals = referrals;
  }

  void setRewardConfig(ReferralRewardConfigEntity config) {
    _rewardConfig = config;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  void setShouldThrowFirestore(bool shouldThrow) {
    _shouldThrowFirestore = shouldThrow;
  }

  void setShouldThrowOnRewardConfig(bool shouldThrow) {
    _shouldThrowOnRewardConfig = shouldThrow;
  }

  void emitReferrals(List<ReferralEntity> referrals) {
    _referralsController.add(referrals);
  }

  void emitReferralsError(Object error) {
    _referralsController.addError(error);
  }

  @override
  Future<ReferralRewardConfigEntity> getRewardConfig() async {
    if (_shouldThrowOnRewardConfig) {
      throw Exception('Failed to load config');
    }
    return _rewardConfig ?? const ReferralRewardConfigEntity(id: 'default');
  }

  @override
  Future<ReferralEntity> createReferral({
    required String referrerUserId,
    required String referredUserId,
    required String referralCode,
  }) async {
    final referral = ReferralEntity(
      referralId: 'ref-${DateTime.now().millisecondsSinceEpoch}',
      referrerUserId: referrerUserId,
      referredUserId: referredUserId,
      referralCode: referralCode,
      rewardAmount: 10.0,
      createdAt: DateTime.now(),
    );
    _referrals = [referral, ..._referrals];
    return referral;
  }

  @override
  Future<List<ReferralEntity>> getReferralsByReferrer(String userId) async {
    if (_shouldThrowFirestore) {
      throw FirestoreException('Permission denied', code: 'permission-denied');
    }
    if (_shouldThrow) throw Exception('Failed to load referrals');
    return _referrals.where((r) => r.referrerUserId == userId).toList();
  }

  @override
  Future<List<ReferralEntity>> getReferralsByReferred(String userId) async {
    return _referrals.where((r) => r.referredUserId == userId).toList();
  }

  @override
  Future<int> getReferralCount(String userId) async {
    return _referrals.where((r) => r.referrerUserId == userId).length;
  }

  @override
  Future<double> getTotalReferralEarnings(String userId) async {
    return _referrals
        .where((r) => r.referrerUserId == userId)
        .fold<double>(0, (total, r) => total + r.rewardAmount);
  }

  @override
  Stream<List<ReferralEntity>> streamReferralsByReferrer(String userId) {
    return _referralsController.stream;
  }

  @override
  Future<ReferralEntity?> validateReferralCode(String code) async {
    return _referrals.isNotEmpty ? _referrals.first : null;
  }

  @override
  Future<int> getReferredUsersWithCompletedProject(String userId) async {
    return _referrals
        .where((r) => r.referrerUserId == userId && r.approvedProjectCount > 0)
        .length;
  }

  @override
  Future<double> getLifetimeProjectCommission(String userId) async {
    return _referrals
        .where((r) => r.referrerUserId == userId)
        .fold<double>(0, (total, r) => total + r.lifetimeProjectCommission);
  }

  @override
  Future<ReferralEntity?> getReferralByReferredUser(String referredUserId) async {
    try {
      return _referrals.firstWhere((r) => r.referredUserId == referredUserId);
    } catch (_) {
      return null;
    }
  }

  @override
  Future<void> updateReferralReward(
      String referralId, Map<String, dynamic> updates) async {
    final index = _referrals.indexWhere((r) => r.referralId == referralId);
    if (index != -1) {
      final r = _referrals[index];
      _referrals[index] = r.copyWith(
        firstProjectRewarded: updates['firstProjectRewarded'] as bool? ?? r.firstProjectRewarded,
        firstProjectId: updates['firstProjectId'] as String? ?? r.firstProjectId,
        firstProjectRewardDate: updates['firstProjectRewardDate'] as DateTime? ?? r.firstProjectRewardDate,
        rewardAmount: (updates['rewardAmount'] as num?)?.toDouble() ?? r.rewardAmount,
        lifetimeProjectCommission: (updates['lifetimeProjectCommission'] as num?)?.toDouble() ?? r.lifetimeProjectCommission,
        approvedProjectCount: updates['approvedProjectCount'] as int? ?? r.approvedProjectCount,
        rewardedProjectIds: (updates['rewardedProjectIds'] as List<dynamic>?)?.cast<String>() ?? r.rewardedProjectIds,
      );
    }
  }
}

// ─── Mock Wallet Repository ───────────────────────────────────

class MockWalletRepository implements WalletRepository {
  WalletEntity? _wallet;
  List<TransactionEntity> _transactions = [];
  bool _shouldThrow = false;
  bool _shouldThrowFirestore = false;
  final StreamController<WalletEntity?> _walletController =
      StreamController<WalletEntity?>.broadcast();
  final StreamController<List<TransactionEntity>> _transactionController =
      StreamController<List<TransactionEntity>>.broadcast();

  void setWallet(WalletEntity? wallet) {
    _wallet = wallet;
  }

  void setTransactions(List<TransactionEntity> transactions) {
    _transactions = transactions;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  void setShouldThrowFirestore(bool shouldThrow) {
    _shouldThrowFirestore = shouldThrow;
  }

  void emitWallet(WalletEntity? wallet) {
    _walletController.add(wallet);
  }

  void emitWalletError(Object error) {
    _walletController.addError(error);
  }

  @override
  Future<WalletEntity> getWallet(String userId) async {
    if (_shouldThrowFirestore) {
      throw FirestoreException('Permission denied', code: 'permission-denied');
    }
    if (_shouldThrow) throw Exception('Wallet not found');
    if (_wallet == null) throw FirestoreException('Wallet not found', code: 'not-found');
    return _wallet!;
  }

  @override
  Future<WalletEntity> createWallet(WalletEntity wallet) async {
    if (_shouldThrow) throw Exception('Failed to create wallet');
    _wallet = wallet;
    return wallet;
  }

  @override
  Future<WalletEntity> addFunds({
    required String userId,
    required double amount,
    required TransactionSource source,
    required String description,
  }) async {
    if (_shouldThrowFirestore) {
      throw FirestoreException('Permission denied', code: 'permission-denied');
    }
    if (_shouldThrow) throw Exception('Failed to add funds');
    _wallet = _wallet?.copyWith(
      walletBalance: (_wallet!.walletBalance + amount),
      totalEarnings: (_wallet!.totalEarnings + amount),
    );
    return _wallet!;
  }

  @override
  Future<WalletEntity> deductFunds({
    required String userId,
    required double amount,
    required TransactionSource source,
    required String description,
  }) async {
    _wallet = _wallet?.copyWith(
      walletBalance: (_wallet!.walletBalance - amount),
      totalWithdrawn: (_wallet!.totalWithdrawn + amount),
    );
    return _wallet!;
  }

  @override
  Stream<WalletEntity?> streamWallet(String userId) {
    return _walletController.stream;
  }

  @override
  Stream<List<TransactionEntity>> streamRecentTransactions(
      String userId, {int limit = 20}) {
    return _transactionController.stream;
  }

  @override
  Future<List<TransactionEntity>> getTransactions(String userId,
      {int limit = 20}) async {
    if (_shouldThrowFirestore) {
      throw FirestoreException('Permission denied', code: 'permission-denied');
    }
    if (_shouldThrow) throw Exception('Failed to load transactions');
    return _transactions;
  }

  @override
  Future<TransactionEntity?> getTransaction(String transactionId) async {
    try {
      return _transactions.firstWhere((t) => t.transactionId == transactionId);
    } catch (_) {
      return null;
    }
  }
}

// ─── Mock Admin Repository ────────────────────────────────────

class MockAdminRepository implements AdminRepository {
  bool _shouldThrow = false;
  int _totalUsers = 0;

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  void setTotalUsers(int count) {
    _totalUsers = count;
  }

  @override
  Future<bool> isAdmin(String uid) async => true;

  @override
  Future<bool> isAdminByEmail(String email) async => true;

  @override
  Future<AdminEntity?> getAdmin(String uid) async {
    return AdminEntity(
      uid: uid,
      email: 'admin@test.com',
      fullName: 'Admin User',
      createdAt: DateTime.now(),
    );
  }

  @override
  Future<void> recordAdminLogin(String uid) async {}

  @override
  Future<int> getTotalUsers() async {
    if (_shouldThrow) throw Exception('Failed to load dashboard');
    return _totalUsers;
  }

  @override
  Future<int> getActiveUsers({int days = 30}) async => 0;

  @override
  Future<double> getTotalEarnings() async => 0.0;

  @override
  Future<double> getTotalWithdrawn() async => 0.0;

  @override
  Future<int> getPendingWithdrawalsCount() async => 0;

  @override
  Future<int> getTotalReferrals() async => 0;

  @override
  Future<List<int>> getDailyUserGrowth({int days = 7}) async => List.filled(days, 0);

  @override
  Future<Map<String, double>> getRevenueStats() async => {};

  @override
  Future<List<UserEntity>> getAllUsers({int limit = 50}) async => [];

  @override
  Future<List<UserEntity>> searchUsers(String query) async => [];

  @override
  Future<UserEntity> updateUserStatus(String uid, {required bool isActive}) async {
    throw UnimplementedError();
  }

  @override
  Future<void> deleteUser(String uid) async {}

  @override
  Future<void> creditUserWallet({
    required String userId,
    required double amount,
    required String description,
  }) async {
    if (_shouldThrow) throw Exception('Failed to credit wallet');
  }

  @override
  Future<void> debitUserWallet({
    required String userId,
    required double amount,
    required String description,
  }) async {
    if (_shouldThrow) throw Exception('Failed to debit wallet');
  }

  @override
  Future<List<ReferralEntity>> getAllReferrals({int limit = 50}) async => [];

  @override
  Future<void> disableReferralSystem() async {}

  @override
  Future<List<WithdrawalEntity>> getAllWithdrawals({
    WithdrawalStatus? status,
    int limit = 50,
  }) async => [];

  @override
  Stream<List<WithdrawalEntity>> streamAllWithdrawals({
    WithdrawalStatus? status,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<WithdrawalEntity> approveWithdrawal(
    String withdrawalId, {
    String? remarks,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<WithdrawalEntity> rejectWithdrawal(
    String withdrawalId, {
    required String remarks,
  }) async {
    throw UnimplementedError();
  }

  @override
  Future<AppSettingsEntity> getAppSettings() async {
    return AppSettingsEntity(
      id: 'settings',
      updatedAt: DateTime.now(),
    );
  }

  @override
  Future<AppSettingsEntity> updateAppSettings(AppSettingsEntity settings) async {
    return settings;
  }

  @override
  Future<void> sendAnnouncement(String message) async {
    if (_shouldThrow) throw Exception('Failed to send announcement');
  }

  @override
  Future<void> broadcastNewTaskNotification(String taskTitle, double rewardAmount) async {
    if (_shouldThrow) throw Exception('Failed to broadcast notification');
  }

  @override
  Future<void> logAdminAction({
    required String adminUid,
    required String action,
    required String targetType,
    String? targetId,
    String? details,
  }) async {}

  @override
  Future<List<AdminLogEntity>> getAdminLogs({int limit = 50}) async => [];
}

// ─── Mock Task Repository ──────────────────────────────────────

class MockTaskRepository implements TaskRepository {
  List<CustomTaskEntity> _tasks = [];
  List<TaskSubmissionEntity> _submissions = [];
  bool _shouldThrow = false;

  void setTasks(List<CustomTaskEntity> tasks) {
    _tasks = tasks;
  }

  void setShouldThrow(bool shouldThrow) {
    _shouldThrow = shouldThrow;
  }

  @override
  Future<List<CustomTaskEntity>> getAllTasks() async {
    if (_shouldThrow) throw Exception('Failed to load tasks');
    return _tasks;
  }

  @override
  Future<List<CustomTaskEntity>> getActiveTasks() async {
    if (_shouldThrow) throw Exception('Failed to load active tasks');
    return _tasks.where((t) => t.isActive).toList();
  }

  @override
  Future<PaginatedTaskResult> getActiveTasksPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    if (_shouldThrow) throw Exception('Failed to load active tasks');
    final active = _tasks.where((t) => t.isActive).toList();
    return PaginatedTaskResult(
      items: active.take(limit).toList(),
      hasMore: active.length > limit,
    );
  }

  @override
  Future<void> createTask(CustomTaskEntity task) async {
    if (_shouldThrow) throw Exception('Failed to create task');
    _tasks = [task, ..._tasks];
  }

  @override
  Future<void> toggleTaskStatus(String taskId, bool isActive) async {
    if (_shouldThrow) throw Exception('Failed to toggle status');
    final index = _tasks.indexWhere((t) => t.taskId == taskId);
    if (index != -1) {
      _tasks[index] = _tasks[index].copyWith(isActive: isActive);
    }
  }

  @override
  Future<void> deleteTask(String taskId) async {
    if (_shouldThrow) throw Exception('Failed to delete task');
    _tasks.removeWhere((t) => t.taskId == taskId);
  }

  @override
  Future<List<TaskSubmissionEntity>> getAllSubmissions() async {
    if (_shouldThrow) throw Exception('Failed to load submissions');
    return _submissions;
  }

  @override
  Future<List<TaskSubmissionEntity>> getUserSubmissions(String userId) async {
    if (_shouldThrow) throw Exception('Failed to load submissions');
    return _submissions.where((s) => s.userId == userId).toList();
  }

  @override
  Future<List<TaskSubmissionEntity>> getPendingSubmissions() async {
    if (_shouldThrow) throw Exception('Failed to load submissions');
    return _submissions.where((s) => s.status == 'pending').toList();
  }

  @override
  Future<PaginatedSubmissionResult> getUserSubmissionsPaginated({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    if (_shouldThrow) throw Exception('Failed to load submissions');
    final userSubs = _submissions.where((s) => s.userId == userId).toList();
    return PaginatedSubmissionResult(
      items: userSubs.take(limit).toList(),
      hasMore: userSubs.length > limit,
    );
  }

  @override
  Future<void> submitTaskProof({
    required String submissionId,
    required String taskId,
    required String taskTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
    String? note,
    String? screenshotUrl,
  }) async {
    if (_shouldThrow) throw Exception('Failed to submit proof');
    final submission = TaskSubmissionEntity(
      submissionId: submissionId,
      taskId: taskId,
      taskTitle: taskTitle,
      userId: userId,
      userName: userName,
      rewardAmount: rewardAmount,
      note: note ?? '',
      screenshotUrl: screenshotUrl,
      submittedAt: DateTime.now(),
    );
    _submissions = [submission, ..._submissions];
  }

  @override
  Future<void> approveSubmission(
      String submissionId, String reviewedBy) async {
    if (_shouldThrow) throw Exception('Failed to approve');
    final index = _submissions.indexWhere((s) => s.submissionId == submissionId);
    if (index != -1) {
      _submissions[index] = _submissions[index].copyWith(
        status: 'approved',
        reviewedAt: DateTime.now(),
        reviewedBy: reviewedBy,
      );
    }
  }

  @override
  Future<void> rejectSubmission(
      String submissionId, String reason, String reviewedBy) async {
    if (_shouldThrow) throw Exception('Failed to reject');
    final index = _submissions.indexWhere((s) => s.submissionId == submissionId);
    if (index != -1) {
      _submissions[index] = _submissions[index].copyWith(
        status: 'rejected',
        rejectionReason: reason,
        reviewedAt: DateTime.now(),
        reviewedBy: reviewedBy,
      );
    }
  }
}

