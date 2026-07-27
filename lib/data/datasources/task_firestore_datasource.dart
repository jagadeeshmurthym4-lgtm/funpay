import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/custom_task_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Result of a paginated Firestore query for custom tasks.
class PaginatedTasks {
  final List<CustomTaskModel> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedTasks({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });
}

/// Result of a paginated Firestore query for task submissions.
class PaginatedSubmissions {
  final List<TaskSubmissionModel> items;
  final DocumentSnapshot? lastDoc;
  final bool hasMore;

  const PaginatedSubmissions({
    required this.items,
    this.lastDoc,
    this.hasMore = false,
  });
}

class TaskFirestoreDataSource {
  final FirebaseFirestore _firestore;

  TaskFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // --- Custom Tasks ---

  Future<List<CustomTaskModel>> getAllTasks() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.customTasksCollection)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CustomTaskModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getAllTasks error: $e');
      return [];
    }
  }

  /// Paginated: fetches active tasks sorted by createdAt descending.
  Future<PaginatedTasks> getActiveTasksPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    try {
      var query = _firestore
          .collection(AppConstants.customTasksCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final tasks = snapshot.docs
          .map((doc) => CustomTaskModel.fromFirestore(doc.data()))
          .toList();

      return PaginatedTasks(
        items: tasks,
        lastDoc: tasks.isEmpty ? null : snapshot.docs.last,
        hasMore: tasks.length >= limit,
      );
    } catch (e) {
      debugPrint('getActiveTasksPaginated error: $e');
      return const PaginatedTasks(items: []);
    }
  }

  /// Non-paginated fallback (for admin use).
  Future<List<CustomTaskModel>> getActiveTasks() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.customTasksCollection)
          .where('isActive', isEqualTo: true)
          .orderBy('createdAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => CustomTaskModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getActiveTasks error: $e');
      return [];
    }
  }

  Future<void> createTask(CustomTaskModel task) async {
    try {
      await _firestore
          .collection(AppConstants.customTasksCollection)
          .doc(task.taskId)
          .set(task.toFirestore());
    } catch (e) {
      debugPrint('[TaskFirestoreDataSource] createTask error: $e');
      rethrow;
    }
  }

  Future<void> updateTask(CustomTaskModel task) async {
    await _firestore
        .collection(AppConstants.customTasksCollection)
        .doc(task.taskId)
        .update(task.toFirestore());
  }

  Future<void> deleteTask(String taskId) async {
    await _firestore
        .collection(AppConstants.customTasksCollection)
        .doc(taskId)
        .delete();
  }

  Future<void> toggleTaskStatus(String taskId, bool isActive) async {
    await _firestore
        .collection(AppConstants.customTasksCollection)
        .doc(taskId)
        .update({'isActive': isActive, 'updatedAt': DateTime.now()});
  }

  // --- Task Submissions ---

  /// Paginated: fetches all submissions sorted by submittedAt descending.
  Future<PaginatedSubmissions> getAllSubmissionsPaginated({
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection(AppConstants.taskSubmissionsCollection)
          .orderBy('submittedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final submissions = snapshot.docs
          .map((doc) => TaskSubmissionModel.fromFirestore(doc.data()))
          .toList();

      return PaginatedSubmissions(
        items: submissions,
        lastDoc: submissions.isEmpty ? null : snapshot.docs.last,
        hasMore: submissions.length >= limit,
      );
    } catch (e) {
      debugPrint('getAllSubmissionsPaginated error: $e');
      return const PaginatedSubmissions(items: []);
    }
  }

  /// Paginated: fetches user submissions sorted by submittedAt descending.
  Future<PaginatedSubmissions> getUserSubmissionsPaginated({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      var query = _firestore
          .collection(AppConstants.taskSubmissionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .limit(limit);

      if (startAfter != null) {
        query = query.startAfterDocument(startAfter);
      }

      final snapshot = await query.get();
      final submissions = snapshot.docs
          .map((doc) => TaskSubmissionModel.fromFirestore(doc.data()))
          .toList();

      return PaginatedSubmissions(
        items: submissions,
        lastDoc: submissions.isEmpty ? null : snapshot.docs.last,
        hasMore: submissions.length >= limit,
      );
    } catch (e) {
      debugPrint('getUserSubmissionsPaginated error: $e');
      return const PaginatedSubmissions(items: []);
    }
  }

  /// Non-paginated fallback (for admin use).
  Future<List<TaskSubmissionModel>> getAllSubmissions() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.taskSubmissionsCollection)
          .orderBy('submittedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TaskSubmissionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getAllSubmissions error: $e');
      return [];
    }
  }

  Future<List<TaskSubmissionModel>> getUserSubmissions(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.taskSubmissionsCollection)
          .where('userId', isEqualTo: userId)
          .orderBy('submittedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TaskSubmissionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getUserSubmissions error: $e');
      return [];
    }
  }

  Future<List<TaskSubmissionModel>> getPendingSubmissions() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.taskSubmissionsCollection)
          .where('status', isEqualTo: 'pending')
          .orderBy('submittedAt', descending: true)
          .get();
      return snapshot.docs
          .map((doc) => TaskSubmissionModel.fromFirestore(doc.data()))
          .toList();
    } catch (e) {
      debugPrint('getPendingSubmissions error: $e');
      return [];
    }
  }

  Future<void> createSubmission(TaskSubmissionModel submission) async {
    await _firestore
        .collection(AppConstants.taskSubmissionsCollection)
        .doc(submission.submissionId)
        .set(submission.toFirestore());
  }

  Future<void> updateSubmission(
      TaskSubmissionModel submission) async {
    await _firestore
        .collection(AppConstants.taskSubmissionsCollection)
        .doc(submission.submissionId)
        .update(submission.toFirestore());
  }

  Future<void> approveSubmission(
      String submissionId, String reviewedBy) async {
    await _firestore
        .collection(AppConstants.taskSubmissionsCollection)
        .doc(submissionId)
        .update({
      'status': 'approved',
      'reviewedBy': reviewedBy,
      'reviewedAt': DateTime.now(),
    });
  }

  Future<void> rejectSubmission(
      String submissionId, String reason, String reviewedBy) async {
    await _firestore
        .collection(AppConstants.taskSubmissionsCollection)
        .doc(submissionId)
        .update({
      'status': 'rejected',
      'rejectionReason': reason,
      'reviewedBy': reviewedBy,
      'reviewedAt': DateTime.now(),
    });
  }
}
