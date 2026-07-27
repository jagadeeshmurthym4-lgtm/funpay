import 'package:cashspark/data/datasources/task_firestore_datasource.dart';
import 'package:cashspark/data/datasources/wallet_firestore_datasource.dart';
import 'package:cashspark/data/models/custom_task_model.dart';
import 'package:cashspark/data/models/transaction_model.dart';
import 'package:cashspark/domain/entities/custom_task_entity.dart';
import 'package:cashspark/domain/entities/transaction_entity.dart';
import 'package:cashspark/domain/repositories/task_repository.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:uuid/uuid.dart';

class TaskRepositoryImpl implements TaskRepository {
  final TaskFirestoreDataSource _dataSource;
  final WalletFirestoreDataSource _walletDataSource;
  final Uuid _uuid;

  TaskRepositoryImpl({
    required TaskFirestoreDataSource dataSource,
    required WalletFirestoreDataSource walletDataSource,
    Uuid? uuid,
  })  : _dataSource = dataSource,
        _walletDataSource = walletDataSource,
        _uuid = uuid ?? const Uuid();

  @override
  Future<List<CustomTaskEntity>> getAllTasks() async {
    try {
      final models = await _dataSource.getAllTasks();
      return models.map((m) => m as CustomTaskEntity).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<CustomTaskEntity>> getActiveTasks() async {
    try {
      final models = await _dataSource.getActiveTasks();
      return models.map((m) => m as CustomTaskEntity).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PaginatedTaskResult> getActiveTasksPaginated({
    DocumentSnapshot? startAfter,
    int limit = 10,
  }) async {
    try {
      final result = await _dataSource.getActiveTasksPaginated(
        startAfter: startAfter,
        limit: limit,
      );
      return PaginatedTaskResult(
        items: result.items.map((m) => m as CustomTaskEntity).toList(),
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
      );
    } catch (e) {
      return const PaginatedTaskResult(items: []);
    }
  }

  @override
  Future<void> createTask(CustomTaskEntity task) async {
    final model = task is CustomTaskModel
        ? task
        : CustomTaskModel.fromEntity(task);
    await _dataSource.createTask(model);
  }

  @override
  Future<void> toggleTaskStatus(String taskId, bool isActive) async {
    await _dataSource.toggleTaskStatus(taskId, isActive);
  }

  @override
  Future<void> deleteTask(String taskId) async {
    await _dataSource.deleteTask(taskId);
  }

  @override
  Future<List<TaskSubmissionEntity>> getAllSubmissions() async {
    try {
      final models = await _dataSource.getAllSubmissions();
      return models.map((m) => m as TaskSubmissionEntity).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<TaskSubmissionEntity>> getUserSubmissions(
      String userId) async {
    try {
      final models = await _dataSource.getUserSubmissions(userId);
      return models.map((m) => m as TaskSubmissionEntity).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<List<TaskSubmissionEntity>> getPendingSubmissions() async {
    try {
      final models = await _dataSource.getPendingSubmissions();
      return models.map((m) => m as TaskSubmissionEntity).toList();
    } catch (e) {
      return [];
    }
  }

  @override
  Future<PaginatedSubmissionResult> getUserSubmissionsPaginated({
    required String userId,
    DocumentSnapshot? startAfter,
    int limit = 20,
  }) async {
    try {
      final result = await _dataSource.getUserSubmissionsPaginated(
        userId: userId,
        startAfter: startAfter,
        limit: limit,
      );
      return PaginatedSubmissionResult(
        items: result.items.map((m) => m as TaskSubmissionEntity).toList(),
        lastDoc: result.lastDoc,
        hasMore: result.hasMore,
      );
    } catch (e) {
      return const PaginatedSubmissionResult(items: []);
    }
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
    final submission = TaskSubmissionModel(
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
    await _dataSource.createSubmission(submission);
  }

  @override
  Future<void> approveSubmission(
      String submissionId, String reviewedBy) async {
    // Get the submission to find the reward amount
    final all = await _dataSource.getAllSubmissions();
    final submission = all.where((s) => s.submissionId == submissionId).firstOrNull;
    if (submission == null) return;

    // Credit the user's wallet
    await _walletDataSource.updateWalletBalance(
      userId: submission.userId,
      amountChange: submission.rewardAmount,
      earningsChange: submission.rewardAmount,
      withdrawnChange: 0,
    );

    // Create transaction record
    final transaction = TransactionModel(
      transactionId: _uuid.v4(),
      userId: submission.userId,
      type: TransactionType.credit,
      amount: submission.rewardAmount,
      source: TransactionSource.reward,
      status: TransactionStatus.completed,
      description: 'Task reward: ${submission.taskTitle}',
      createdAt: DateTime.now(),
    );
    await _walletDataSource.createTransaction(transaction);

    // Mark submission as approved
    await _dataSource.approveSubmission(submissionId, reviewedBy);
  }

  @override
  Future<void> rejectSubmission(
      String submissionId, String reason, String reviewedBy) async {
    await _dataSource.rejectSubmission(submissionId, reason, reviewedBy);
  }
}
