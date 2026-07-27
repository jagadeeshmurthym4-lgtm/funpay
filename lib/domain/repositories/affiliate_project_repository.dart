import 'dart:async';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';

abstract class AffiliateProjectRepository {
  // ─── Real-time Streams ────────────────────────────────
  Stream<List<AffiliateProjectEntity>> streamActiveProjects();
  Stream<List<AffiliateProjectEntity>> streamAllProjects();
  Stream<List<AffiliateProjectEntity>> streamFeaturedProjects();
  Stream<List<ProjectParticipationEntity>> streamUserParticipations(
      String userId);
  Stream<List<ProjectParticipationEntity>> streamPendingParticipations();
  Stream<List<ProjectParticipationEntity>> streamAllParticipations();

  // ─── One-time Queries ─────────────────────────────────
  Future<List<AffiliateProjectEntity>> getActiveProjects();
  Future<List<AffiliateProjectEntity>> getActiveProjectsPage({
    int pageSize = 20,
    DateTime? lastCreatedDate,
    String? lastProjectId,
    String? categoryFilter,
    String? searchPrefix,
  });
  Future<List<AffiliateProjectEntity>> getAllProjects();

  // ─── CRUD ─────────────────────────────────────────────
  Future<void> createProject(AffiliateProjectEntity project);
  Future<void> updateProject(AffiliateProjectEntity project);
  Future<void> deleteProject(String projectId);
  Future<void> updateProjectStatus(
      String projectId, ProjectLifecycleStatus status);
  Future<void> duplicateProject(AffiliateProjectEntity project);

  // ─── Analytics ────────────────────────────────────────
  Future<ProjectAnalytics> getProjectAnalytics();

  // ─── Participation ────────────────────────────────────
  Future<List<ProjectParticipationEntity>> getProjectParticipations(
      String projectId);
  Future<List<ProjectParticipationEntity>> getUserParticipations(
      String userId);
  Future<List<ProjectParticipationEntity>> getPendingParticipations();
  Future<ProjectParticipationEntity?> getUserProjectParticipation(
      String userId, String projectId);
  /// Returns the participationId if the project was started successfully (or already exists).
  /// Returns null if creation failed.
  Future<String?> startProject({
    required String projectId,
    required String projectTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
  });
  Future<void> submitProof({
    required String participationId,
    required String? screenshotUrl,
    required String? note,
    String? transactionId,
  });
  Future<void> approveParticipation(
      String participationId, {String? reviewedBy});
  Future<void> rejectParticipation(
      String participationId, String reason);
  Future<void> resubmitParticipation(String participationId);
  Future<bool> creditReward(String participationId, String userId);

  /// Combines approve + credit in a single operation.
  Future<bool> approveAndCreditReward(
      String participationId, String userId, {String? reviewedBy});

  // ─── Notifications ────────────────────────────────────
  Future<void> notifyProjectExpired(String projectId, String projectTitle);
  Future<void> notifyNewProject(String projectTitle, String createdBy);
}
