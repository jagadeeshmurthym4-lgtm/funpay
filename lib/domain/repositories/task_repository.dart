import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/domain/entities/custom_task_entity.dart';

/// Result of a paginated query for custom tasks.
class PaginatedTaskResult {
  final List<CustomTaskEntity> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedTaskResult({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });
}

/// Result of a paginated query for task submissions.
class PaginatedSubmissionResult {
  final List<TaskSubmissionEntity> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedSubmissionResult({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });
}

abstract class TaskRepository {
  // Custom Tasks
  Future<List<CustomTaskEntity>> getAllTasks();
  Future<List<CustomTaskEntity>> getActiveTasks();

  /// Paginated variant using Firestore cursor-based pagination.
  Future<PaginatedTaskResult> getActiveTasksPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  });

  Future<void> createTask(CustomTaskEntity task);
  Future<void> toggleTaskStatus(String taskId, bool isActive);
  Future<void> deleteTask(String taskId);

  // Task Submissions
  Future<List<TaskSubmissionEntity>> getAllSubmissions();
  Future<List<TaskSubmissionEntity>> getUserSubmissions(String userId);
  Future<List<TaskSubmissionEntity>> getPendingSubmissions();

  /// Paginated variant for user submissions using Firestore cursor-based pagination.
  Future<PaginatedSubmissionResult> getUserSubmissionsPaginated({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  });

  Future<void> submitTaskProof({
    required String submissionId,
    required String taskId,
    required String taskTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
    String? note,
    String? screenshotUrl,
  });
  Future<void> approveSubmission(String submissionId, String reviewedBy);
  Future<void> rejectSubmission(
      String submissionId, String reason, String reviewedBy);
}
