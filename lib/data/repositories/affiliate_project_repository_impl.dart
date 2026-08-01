import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/data/datasources/affiliate_project_firestore_datasource.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/notification_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/datasources/scratch_card_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/affiliate_project_model.dart';
import 'package:cashspark/data/models/notification_model.dart';
import 'package:cashspark/data/models/scratch_card_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/data/models/wallet_model.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/repositories/affiliate_project_repository.dart';
import 'package:cashspark/services/fcm_service.dart';
import 'package:flutter/foundation.dart' show debugPrint;
import 'package:uuid/uuid.dart';

class AffiliateProjectRepositoryImpl implements AffiliateProjectRepository {
  final AffiliateProjectFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final NotificationFirestoreDataSource _notificationDataSource;
  final AdminFirestoreDataSource _adminDataSource;
  final ScratchCardFirestoreDataSource _scratchCardDataSource;
  final ReferralFirestoreDataSource _referralDataSource;
  final Uuid _uuid;

  AffiliateProjectRepositoryImpl({
    required AffiliateProjectFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    required NotificationFirestoreDataSource notificationDataSource,
    AdminFirestoreDataSource? adminDataSource,
    ScratchCardFirestoreDataSource? scratchCardDataSource,
    ReferralFirestoreDataSource? referralDataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _notificationDataSource = notificationDataSource,
        _adminDataSource = adminDataSource ?? AdminFirestoreDataSource(),
        _scratchCardDataSource = scratchCardDataSource ?? ScratchCardFirestoreDataSource(),
        _referralDataSource = referralDataSource ?? ReferralFirestoreDataSource(),
        _uuid = uuid ?? const Uuid();

  // ─── Real-time Streams ────────────────────────────────

  @override
  Stream<List<AffiliateProjectEntity>> streamActiveProjects() {
    return _dataSource.streamActiveProjects().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<AffiliateProjectEntity>> streamAllProjects() {
    return _dataSource.streamAllProjects().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<AffiliateProjectEntity>> streamFeaturedProjects() {
    return _dataSource.streamFeaturedProjects().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<ProjectParticipationEntity>> streamUserParticipations(
      String userId) {
    return _dataSource.streamUserParticipations(userId).map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<ProjectParticipationEntity>> streamPendingParticipations() {
    return _dataSource.streamPendingParticipations().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  @override
  Stream<List<ProjectParticipationEntity>> streamAllParticipations() {
    return _dataSource.streamAllParticipations().map((models) =>
        models.map((m) => m.toEntity()).toList());
  }

  // ─── One-time Queries ─────────────────────────────────

  @override
  Future<List<AffiliateProjectEntity>> getActiveProjects() async {
    final models = await _dataSource.getActiveProjects();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AffiliateProjectEntity>> getActiveProjectsPage({
    int pageSize = 20,
    DateTime? lastCreatedDate,
    String? lastProjectId,
    String? categoryFilter,
    String? searchPrefix,
  }) async {
    final models = await _dataSource.getActiveProjectsPage(
      pageSize: pageSize,
      lastCreatedDate: lastCreatedDate,
      categoryFilter: categoryFilter,
      searchPrefix: searchPrefix,
    );
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<AffiliateProjectEntity>> getAllProjects() async {
    final models = await _dataSource.getAllProjects();
    return models.map((m) => m.toEntity()).toList();
  }

  // ─── CRUD ─────────────────────────────────────────────

  @override
  Future<void> createProject(AffiliateProjectEntity project) async {
    final model = AffiliateProjectModel.fromEntity(project);
    await _dataSource.createProject(model);
  }

  @override
  Future<void> updateProject(AffiliateProjectEntity project) async {
    final model = AffiliateProjectModel.fromEntity(project);
    await _dataSource.updateProject(model);
  }

  @override
  Future<void> deleteProject(String projectId) async {
    await _dataSource.deleteProject(projectId);
  }

  @override
  Future<void> updateProjectStatus(
      String projectId, ProjectLifecycleStatus status) async {
    await _dataSource.updateProjectStatus(projectId, status.name);
  }

  @override
  Future<void> duplicateProject(AffiliateProjectEntity project) async {
    final newProject = project.copyWith(
      projectId: _uuid.v4(),
      title: '${project.title} (Copy)',
      currentParticipants: 0,
      clicks: 0,
      completedCount: 0,
      totalRewardsPaid: 0.0,
      lifecycleStatus: ProjectLifecycleStatus.draft,
      createdDate: DateTime.now(),
      updatedDate: DateTime.now(),
    );
    await _dataSource.duplicateProject(
      project.projectId,
      AffiliateProjectModel.fromEntity(newProject),
    );
  }

  // ─── Analytics ────────────────────────────────────────

  @override
  Future<ProjectAnalytics> getProjectAnalytics() async {
    final raw = await _dataSource.getProjectAnalytics();
    final projects = await getAllProjects();
    final totalCompleted =
        projects.fold<int>(0, (total, p) => total + p.completedCount);
    final totalParticipants = raw['totalParticipants'] as int? ?? 0;
    final conversionRate = totalParticipants > 0
        ? totalCompleted / totalParticipants
        : 0.0;

    return ProjectAnalytics(
      totalProjects: raw['totalProjects'] as int? ?? 0,
      activeProjects: raw['activeProjects'] as int? ?? 0,
      totalClicks: raw['totalClicks'] as int? ?? 0,
      totalParticipants: totalParticipants,
      pendingReviews: raw['pendingReviews'] as int? ?? 0,
      approvedRewards: raw['approvedRewards'] as int? ?? 0,
      rejectedRewards: raw['rejectedRewards'] as int? ?? 0,
      totalRewardsPaid: raw['totalRewardsPaid'] as double? ?? 0.0,
      conversionRate: conversionRate,
    );
  }

  // ─── Participation ────────────────────────────────────

  @override
  Future<List<ProjectParticipationEntity>> getProjectParticipations(
      String projectId) async {
    final models = await _dataSource.getParticipations(projectId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProjectParticipationEntity>> getUserParticipations(
      String userId) async {
    final models = await _dataSource.getUserParticipations(userId);
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<List<ProjectParticipationEntity>> getPendingParticipations() async {
    final models = await _dataSource.getPendingParticipations();
    return models.map((m) => m.toEntity()).toList();
  }

  @override
  Future<ProjectParticipationEntity?> getUserProjectParticipation(
      String userId, String projectId) async {
    final model =
        await _dataSource.getUserProjectParticipation(userId, projectId);
    return model?.toEntity();
  }

  @override
  Future<String?> startProject({
    required String projectId,
    required String projectTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
  }) async {
    // 1. Check if user already has a participation for this project
    final existing =
        await _dataSource.getUserProjectParticipation(userId, projectId);
    if (existing != null) {
      debugPrint('startProject: User $userId already has participation'
          ' ${existing.participationId} for project "$projectTitle"');
      return existing.participationId;
    }

    // 2. Create new participation
    final participationId = _uuid.v4();
    final participation = ProjectParticipationModel(
      participationId: participationId,
      projectId: projectId,
      projectTitle: projectTitle,
      userId: userId,
      userName: userName,
      rewardAmount: rewardAmount,
      status: 'inProgress',
      startedAt: DateTime.now(),
    );
    try {
      await _dataSource.createParticipation(participation);
      debugPrint('startProject: Created participation $participationId'
          ' for user $userId, project "$projectTitle"');
    } catch (e) {
      debugPrint('startProject: FAILED to create participation: $e');
      rethrow; // Critical — fail if we can't create
    }

    // 3. Increment counters (non-critical — can fail due to Firestore rules)
    //    These may fail because only admins can write to affiliate_projects.
    //    Participation creation is the core operation; counters are best-effort.
    try {
      await _dataSource.incrementParticipants(projectId);
      debugPrint('startProject: Incremented participants for $projectId');
    } catch (e) {
      debugPrint('startProject: incrementParticipants failed (non-critical): $e');
    }

    try {
      await _dataSource.incrementClicks(projectId);
      debugPrint('startProject: Incremented clicks for $projectId');
    } catch (e) {
      debugPrint('startProject: incrementClicks failed (non-critical): $e');
    }

    return participationId;
  }

  @override
  Future<void> submitProof({
    required String participationId,
    required String? screenshotUrl,
    required String? note,
    String? transactionId,
  }) async {
    final updates = <String, dynamic>{
      'status': 'underReview',
      'submittedAt': Timestamp.now(),
    };
    if (screenshotUrl != null) updates['screenshotUrl'] = screenshotUrl;
    if (note != null) updates['note'] = note;
    if (transactionId != null) updates['transactionId'] = transactionId;

    await _dataSource.updateParticipationPartial(participationId, updates);
  }

  // ─── Helper: Create Notification ─────────────────────

  Future<void> _createNotification({
    required String userId,
    required String title,
    required String message,
    required NotificationType type,
  }) async {
    try {
      final notification = NotificationModel(
        notificationId: _uuid.v4(),
        userId: userId,
        title: title,
        message: message,
        type: type,
        isRead: false,
        createdAt: DateTime.now(),
      );
      await _notificationDataSource.createNotification(notification);
    } catch (e) {
      // Log but don't fail the operation
      debugPrint('Failed to create notification: $e');
    }
  }

  /// Send an FCM push notification to the targeted user.
  /// FcmService.sendTargetedPush() already handles errors internally;
  /// the parent methods also catch and log exceptions from this call.
  Future<void> _sendFcmTargetedPush({
    required String userId,
    required String title,
    required String message,
    required String type,
  }) async {
    await FcmService.sendTargetedPush(
      userId: userId,
      title: title,
      message: message,
      type: type,
    );
  }

  @override
  Future<void> approveParticipation(
      String participationId, {String? reviewedBy}) async {
    // Fetch participation to get user + project info
    final participation =
        await _dataSource.getParticipationById(participationId);
    if (participation == null) return;

    await _dataSource.updateParticipationStatus(
      participationId,
      'approved',
      reviewedBy: reviewedBy,
    );

    // Notify user (in-app + push)
    await _createNotification(
      userId: participation.userId,
      title: 'Reward Approved 🎉',
      message:
          'Your submission for "${participation.projectTitle}" has been approved! Reward will be credited shortly.',
      type: NotificationType.reward,
    );
    await _sendFcmTargetedPush(
      userId: participation.userId,
      title: 'Reward Approved 🎉',
      message:
          'Your submission for "${participation.projectTitle}" has been approved! Reward will be credited shortly.',
      type: 'reward',
    );
  }

  @override
  Future<void> rejectParticipation(
      String participationId, String reason) async {
    final participation =
        await _dataSource.getParticipationById(participationId);

    await _dataSource.updateParticipationPartial(participationId, {
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedAt': Timestamp.now(),
    });

    if (participation != null) {
      // Notify user (in-app + push)
      await _createNotification(
        userId: participation.userId,
        title: '❌ Submission Rejected',
        message:
            'Your submission for "${participation.projectTitle}" was rejected. Reason: $reason. Please review and resubmit.',
        type: NotificationType.reward,
      );
      await _sendFcmTargetedPush(
        userId: participation.userId,
        title: '❌ Submission Rejected',
        message:
            'Your submission for "${participation.projectTitle}" was rejected. Reason: $reason. Please review and resubmit.',
        type: 'reward',
      );
    }
  }

  @override
  Future<void> resubmitParticipation(String participationId) async {
    await _dataSource.updateParticipationPartial(participationId, {
      'status': 'inProgress',
      'rejectionReason': null,
      'reviewedAt': null,
      'submittedAt': null,
    });
  }

  @override
  Future<bool> creditReward(String participationId, String userId) async {
    final participation =
        await _dataSource.getParticipationById(participationId);
    if (participation == null || participation.rewardCredited) {
      return false;
    }

    final rewardAmount = participation.rewardAmount;

    // Update wallet (auto-create if missing)
    try {
      await _walletDataSource.updateWalletBalance(
        userId: userId,
        amountChange: rewardAmount,
        earningsChange: rewardAmount,
        withdrawnChange: 0,
      );
    } catch (_) {
      // Wallet may not exist — create it and retry
      try {
        await _walletDataSource.createWallet(
          WalletModel(userId: userId, updatedAt: DateTime.now()),
        );
        await _walletDataSource.updateWalletBalance(
          userId: userId,
          amountChange: rewardAmount,
          earningsChange: rewardAmount,
          withdrawnChange: 0,
        );
      } catch (e) {
        debugPrint('creditReward wallet error: $e');
        return false;
      }
    }

    // Create transaction record
    final transaction = TransactionModel(
      transactionId: _uuid.v4(),
      userId: userId,
      type: TransactionType.credit,
      amount: rewardAmount,
      source: TransactionSource.reward,
      status: TransactionStatus.completed,
      description: 'Affiliate project reward: ${participation.projectTitle}',
      createdAt: DateTime.now(),
    );
    await _walletDataSource.createTransaction(transaction);

    // Mark reward as credited
    await _dataSource.markRewardCredited(participationId);
    await _dataSource.incrementCompletedCount(participation.projectId);
    await _dataSource.incrementTotalRewardsPaid(
        participation.projectId, rewardAmount);

    // Notify user about credited reward (in-app + push)
    await _createNotification(
      userId: userId,
      title: 'Reward Credited 💰',
      message:
          '${rewardAmount.toStringAsFixed(2)} pts has been credited to your wallet for completing "${participation.projectTitle}"!',
      type: NotificationType.reward,
    );
    await _sendFcmTargetedPush(
      userId: userId,
      title: 'Reward Credited 💰',
      message:
          '${rewardAmount.toStringAsFixed(2)} pts has been credited to your wallet for completing "${participation.projectTitle}"!',
      type: 'reward',
    );

    // ─── Scratch Card Reward ───────────────────────────────
    // Every approved project grants exactly one scratch card
    try {
      final alreadyExists = await _scratchCardDataSource.hasScratchCardForSubmission(participationId);
      if (!alreadyExists) {
        final scratchCard = ScratchCardModel(
          scratchCardId: _uuid.v4(),
          userId: userId,
          submissionId: participationId,
          rewardAmount: 0.0, // will be set when scratched
          isUsed: false,
          createdAt: DateTime.now(),
        );
        await _scratchCardDataSource.createScratchCard(scratchCard);

        // Notify user about the scratch card (in-app + push)
        await _createNotification(
          userId: userId,
          title: '🎴 Scratch Card Earned!',
          message: 'You earned a Scratch Card for completing "${participation.projectTitle}"! Scratch it to win up to 7 pts!',
          type: NotificationType.reward,
        );
        await _sendFcmTargetedPush(
          userId: userId,
          title: '🎴 Scratch Card Earned!',
          message: 'You earned a Scratch Card for completing "${participation.projectTitle}"! Scratch it to win up to 7 pts!',
          type: 'reward',
        );
      }
    } catch (e) {
      // Don't fail the credit if scratch card creation fails — log and continue
      debugPrint('Failed to create scratch card for affiliate project: $e');
    }

    // ─── Referral Reward Logic (Client-side) ────────────────
    // Since Cloud Functions require the Blaze (paid) plan, we process
    // referral rewards directly on the client side. The referral doc
    // is updated atomically and the participation is stamped with
    // referralProcessed=true to prevent double-processing if the
    // Cloud Function is ever deployed later.
    //
    // Uses participationId for dedup (not projectId) to stay consistent
    // with what the server-side function would use.
    try {
      final referrerRecord = await _referralDataSource.getReferralByReferredUser(userId);
      if (referrerRecord != null && referrerRecord.status == ReferralStatus.completed) {
        final reward = rewardAmount;
        final referrerId = referrerRecord.referrerUserId;
        final pId = participation.projectId;
        final pTitle = participation.projectTitle;

        // Prevent duplicate rewards for the same participation
        if (referrerRecord.rewardedProjectIds.contains(participationId)) {
          debugPrint('Referral reward already given for participation $participationId');
        } else {
          double referrerBonus = 0.0;
          String bonusDescription;
          String notificationTitle;

          if (!referrerRecord.firstProjectRewarded) {
            // First approved project → 7 pts bonus
            referrerBonus = 7.0;
            bonusDescription = '7 pts first-project referral bonus for "$pTitle"';
            notificationTitle = '🎉 First Project Referral Bonus';
          } else {
            // Subsequent approved projects → 5% commission
            referrerBonus = reward * 0.05;
            referrerBonus = double.parse(referrerBonus.toStringAsFixed(2));
            bonusDescription = '5% commission (${referrerBonus.toStringAsFixed(2)} pts) from "$pTitle"';
            notificationTitle = '💰 Referral Commission Earned';
          }

          if (referrerBonus > 0) {
            // Credit the referrer's wallet
            await _walletDataSource.updateWalletBalance(
              userId: referrerId,
              amountChange: referrerBonus,
              earningsChange: referrerBonus,
              withdrawnChange: 0,
            );

            // Create transaction record for referrer
            final referralTransaction = TransactionModel(
              transactionId: _uuid.v4(),
              userId: referrerId,
              type: TransactionType.credit,
              amount: referrerBonus,
              source: TransactionSource.referral,
              status: TransactionStatus.completed,
              description: bonusDescription,
              createdAt: DateTime.now(),
            );
            await _walletDataSource.createTransaction(referralTransaction);

            // Notify the referrer (in-app + push)
            await _createNotification(
              userId: referrerId,
              title: notificationTitle,
              message: bonusDescription,
              type: NotificationType.referral,
            );
            await _sendFcmTargetedPush(
              userId: referrerId,
              title: notificationTitle,
              message: bonusDescription,
              type: 'referral',
            );

            // Build referral doc updates
            final updatedRewardedProjectIds = [...referrerRecord.rewardedProjectIds, participationId];
            final updatedCommission = referrerRecord.lifetimeProjectCommission + referrerBonus;
            final updatedApprovedCount = referrerRecord.approvedProjectCount + 1;

            final updates = <String, dynamic>{
              'rewardedProjectIds': updatedRewardedProjectIds,
              'lifetimeProjectCommission': updatedCommission,
              'approvedProjectCount': updatedApprovedCount,
            };

            if (!referrerRecord.firstProjectRewarded) {
              updates['firstProjectRewarded'] = true;
              updates['firstProjectId'] = pId;
              updates['firstProjectRewardDate'] = DateTime.now();
              updates['rewardAmount'] = referrerRecord.rewardAmount + 7.0;
            }

            await _referralDataSource.updateReferralReward(
              referrerRecord.referralId,
              updates,
            );

            debugPrint('Referral reward processed: $bonusDescription');
          }
        }
      }
    } catch (e) {
      debugPrint('Failed to process referral reward: $e');
    }

    // Stamp the participation with referralProcessed guard flag
    // so the Cloud Function (if ever deployed) skips it.
    try {
      await _dataSource.updateParticipationPartial(
        participationId,
        {'referralProcessed': true},
      );
    } catch (e) {
      debugPrint('Failed to set referralProcessed flag (non-critical): $e');
    }

    return true;
  }

  @override
  Future<bool> approveAndCreditReward(
      String participationId, String userId, {String? reviewedBy}) async {
    // First: approve
    await approveParticipation(participationId, reviewedBy: reviewedBy);

    // Then: credit reward (returns false if already credited)
    return creditReward(participationId, userId);
  }

  /// Create a bulk notification for all participants of a project (for expiry)
  @override
  Future<void> notifyProjectExpired(
      String projectId, String projectTitle) async {
    try {
      final participations = await _dataSource.getParticipations(projectId);
      for (final p in participations) {
        if (p.status == 'inProgress' || p.status == 'pendingReview') {
          await _createNotification(
            userId: p.userId,
            title: 'Project Expired ⏰',
            message:
                'The project "$projectTitle" has expired and your pending submission will not be reviewed. Contact support if you believe this is an error.',
            type: NotificationType.reward,
          );
          await _sendFcmTargetedPush(
            userId: p.userId,
            title: 'Project Expired ⏰',
            message:
                'The project "$projectTitle" has expired and your pending submission will not be reviewed. Contact support if you believe this is an error.',
            type: 'reward',
          );
        }
      }
    } catch (e) {
      debugPrint('Failed to notify project expired: $e');
    }
  }

  /// Create a notification when a new project is added (broadcast to all users).
  /// Sends FCM push broadcast independently so it still works
  /// even if fetching all users for in-app notifications fails.
  @override
  Future<void> notifyNewProject(String projectTitle, String createdBy) async {
    const title = '🆕 New Project Available';
    final message =
        '"$projectTitle" is now live! Check it out and start earning rewards.';

    // 1. In-app notifications for each user (best-effort)
    try {
      final users = await _adminDataSource.getAllUsers(limit: 1000);
      for (final user in users) {
        await _createNotification(
          userId: user.uid,
          title: title,
          message: message,
          type: NotificationType.announcement,
        );
      }
    } catch (e) {
      debugPrint('Failed to broadcast in-app new-project notification: $e');
    }

    // 2. FCM push notification (always attempt, independent of user listing)
    try {
      await FcmService.sendBroadcastPush(
        title: title,
        message: message,
        type: 'announcement',
      );
    } catch (e) {
      debugPrint('Failed to send FCM broadcast for new project: $e');
    }
  }
}
