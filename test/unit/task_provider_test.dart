import 'package:cashspark/domain/entities/custom_task_entity.dart';
import 'package:cashspark/presentation/providers/task_provider.dart';
import 'package:cashspark/domain/repositories/task_repository.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uuid/uuid.dart';

import '../helpers/mock_repositories.dart';

void main() {
  late MockTaskRepository mockRepository;
  late TaskProvider taskProvider;
  late Uuid uuid;

  setUp(() {
    mockRepository = MockTaskRepository();
    uuid = const Uuid();
    taskProvider = TaskProvider(
      taskRepository: mockRepository as TaskRepository,
      uuid: uuid,
    );
  });

  tearDown(() {
    taskProvider.dispose();
  });

  group('TaskProvider.loadTasks', () {
    test('loads tasks successfully', () async {
      final tasks = [
        CustomTaskEntity(
          taskId: 'task-1',
          title: 'Test Task',
          description: 'Test Description',
          rewardAmount: 10.0,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      mockRepository.setTasks(tasks);

      await taskProvider.loadTasks();

      expect(taskProvider.isLoading, false);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks[0].title, 'Test Task');
      expect(taskProvider.errorMessage, isNull);
    });

    test('handles load error gracefully', () async {
      mockRepository.setShouldThrow(true);

      await taskProvider.loadTasks();

      expect(taskProvider.isLoading, false);
      expect(taskProvider.tasks, isEmpty);
      expect(taskProvider.errorMessage, isNotNull);
    });

    test('sets loading state correctly', () async {
      final loadFuture = taskProvider.loadTasks();
      expect(taskProvider.isLoading, true);
      await loadFuture;
      expect(taskProvider.isLoading, false);
    });
  });

  group('TaskProvider.loadActiveTasks', () {
    test('loads only active tasks', () async {
      final tasks = [
        CustomTaskEntity(
          taskId: 'task-1',
          title: 'Active Task',
          description: 'Active',
          rewardAmount: 10.0,
          isActive: true,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
        CustomTaskEntity(
          taskId: 'task-2',
          title: 'Inactive Task',
          description: 'Inactive',
          rewardAmount: 5.0,
          isActive: false,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ];
      mockRepository.setTasks(tasks);

      await taskProvider.loadActiveTasks();

      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks[0].title, 'Active Task');
    });
  });

  group('TaskProvider.createTask', () {
    test('creates task successfully', () async {
      final result = await taskProvider.createTask(
        title: 'New Task',
        description: 'New Description',
        rewardAmount: 15.0,
        createdBy: 'user-1',
      );

      expect(result, true);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks[0].title, 'New Task');
      expect(taskProvider.successMessage, isNotNull);
    });

    test('handles creation error', () async {
      mockRepository.setShouldThrow(true);

      final result = await taskProvider.createTask(
        title: 'Failing Task',
        description: 'Should fail',
        rewardAmount: 10.0,
        createdBy: 'user-1',
      );

      expect(result, false);
      expect(taskProvider.errorMessage, isNotNull);
    });
  });

  group('TaskProvider.toggleTaskStatus', () {
    test('toggles task active status', () async {
      // First create a task
      await taskProvider.createTask(
        title: 'Test',
        description: 'Test',
        rewardAmount: 5.0,
        createdBy: 'user-1',
      );
      final taskId = taskProvider.tasks[0].taskId;

      final result = await taskProvider.toggleTaskStatus(taskId, false);

      expect(result, true);
      expect(taskProvider.tasks[0].isActive, false);
    });
  });

  group('TaskProvider.deleteTask', () {
    test('deletes task successfully', () async {
      // First create a task
      await taskProvider.createTask(
        title: 'To Delete',
        description: 'Will be deleted',
        rewardAmount: 5.0,
        createdBy: 'user-1',
      );
      final taskId = taskProvider.tasks[0].taskId;

      final result = await taskProvider.deleteTask(taskId);

      expect(result, true);
      expect(taskProvider.tasks, isEmpty);
    });
  });

  group('TaskProvider.submitTaskProof', () {
    test('submits proof successfully', () async {
      final result = await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
        note: 'Here is my proof',
      );

      expect(result, true);
      expect(taskProvider.successMessage, isNotNull);
    });

    test('handles submission error', () async {
      mockRepository.setShouldThrow(true);

      final result = await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
      );

      expect(result, false);
      expect(taskProvider.errorMessage, isNotNull);
    });
  });

  group('TaskProvider.approveSubmission', () {
    test('approves submission and updates state', () async {
      // First create a submission via submit
      await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
      );

      // Load submissions
      await taskProvider.loadSubmissions();

      final submissionId = taskProvider.submissions[0].submissionId;

      final result = await taskProvider.approveSubmission(submissionId);

      expect(result, true);
      expect(taskProvider.submissions[0].status, 'approved');
      expect(taskProvider.successMessage, isNotNull);
    });
  });

  group('TaskProvider.rejectSubmission', () {
    test('rejects submission with reason', () async {
      await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
      );
      await taskProvider.loadSubmissions();
      final submissionId = taskProvider.submissions[0].submissionId;

      final result = await taskProvider.rejectSubmission(
        submissionId,
        'Insufficient proof',
      );

      expect(result, true);
      expect(taskProvider.submissions[0].status, 'rejected');
      expect(taskProvider.submissions[0].rejectionReason, 'Insufficient proof');
    });
  });

  group('TaskProvider._clearMessages (automatic clear before operations)', () {
    test('clears previous errorMessage when a new load succeeds', () async {
      // Set up error state first
      mockRepository.setShouldThrow(true);
      await taskProvider.loadTasks();
      expect(taskProvider.errorMessage, isNotNull);

      // Now succeed — _clearMessages() should fire at the top of loadTasks()
      mockRepository.setShouldThrow(false);
      mockRepository.setTasks([
        CustomTaskEntity(
          taskId: 'task-1',
          title: 'Post-Error Task',
          description: 'Loaded after an error',
          rewardAmount: 10.0,
          createdBy: 'user-1',
          createdAt: DateTime.now(),
          updatedAt: DateTime.now(),
        ),
      ]);
      await taskProvider.loadTasks();

      expect(taskProvider.errorMessage, isNull);
      expect(taskProvider.tasks.length, 1);
      expect(taskProvider.tasks[0].title, 'Post-Error Task');
    });

    test('clears previous successMessage when a new failing operation runs',
        () async {
      // Set up success state first
      await taskProvider.createTask(
        title: 'Original Task',
        description: 'First task',
        rewardAmount: 5.0,
        createdBy: 'user-1',
      );
      expect(taskProvider.successMessage, isNotNull);

      // Run a failing operation — should clear successMessage via _clearMessages
      mockRepository.setShouldThrow(true);
      await taskProvider.loadTasks();

      expect(taskProvider.successMessage, isNull);
      expect(taskProvider.errorMessage, isNotNull);
    });

    test('clears previous errorMessage in createTask after a failed load',
        () async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await taskProvider.loadTasks();
      expect(taskProvider.errorMessage, isNotNull);

      // Create task — should clear error via _clearMessages
      mockRepository.setShouldThrow(false);
      final result = await taskProvider.createTask(
        title: 'New Task After Error',
        description: 'Should clear old error',
        rewardAmount: 15.0,
        createdBy: 'user-1',
      );

      expect(result, true);
      expect(taskProvider.errorMessage, isNull);
      expect(taskProvider.successMessage, isNotNull);
      expect(taskProvider.tasks.length, 1);
    });

    test('clears previous successMessage when loadActiveTasks succeeds', () async {
      // Create a task to have data, then succeed to set successMessage
      await taskProvider.createTask(
        title: 'For Pagination',
        description: 'Seed',
        rewardAmount: 5.0,
        createdBy: 'user-1',
      );
      expect(taskProvider.successMessage, isNotNull);

      // Load active tasks (succeeds, clears success)
      await taskProvider.loadActiveTasks();
      expect(taskProvider.successMessage, isNull);
    });

    test('clears previous messages in submitTaskProof', () async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await taskProvider.loadTasks();
      expect(taskProvider.errorMessage, isNotNull);

      // Submit proof — should clear error via _clearMessages
      mockRepository.setShouldThrow(false);
      final result = await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
      );

      expect(result, true);
      expect(taskProvider.errorMessage, isNull);
      expect(taskProvider.successMessage, isNotNull);
    });

    test('clears previous messages in approveSubmission after a failure',
        () async {
      // Set up error state
      mockRepository.setShouldThrow(true);
      await taskProvider.loadSubmissions();
      expect(taskProvider.errorMessage, isNotNull);

      // Submit proof to have a submission to approve
      mockRepository.setShouldThrow(false);
      await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
      );
      mockRepository.setShouldThrow(false);
      await taskProvider.loadSubmissions();

      expect(taskProvider.submissions, isNotEmpty);
      final submissionId = taskProvider.submissions[0].submissionId;

      final result = await taskProvider.approveSubmission(submissionId);

      expect(result, true);
      expect(taskProvider.errorMessage, isNull);
      expect(taskProvider.successMessage, isNotNull);
    });

    test('clears previous messages in rejectSubmission', () async {
      // Set up error state first
      mockRepository.setShouldThrow(true);
      await taskProvider.loadTasks();
      expect(taskProvider.errorMessage, isNotNull);

      // Now submit and reject
      mockRepository.setShouldThrow(false);
      await taskProvider.submitTaskProof(
        taskId: 'task-1',
        taskTitle: 'Test Task',
        userId: 'user-1',
        userName: 'Test User',
        rewardAmount: 10.0,
      );
      await taskProvider.loadSubmissions();
      final submissionId = taskProvider.submissions[0].submissionId;

      final result = await taskProvider.rejectSubmission(
        submissionId,
        'Insufficient proof',
      );

      expect(result, true);
      expect(taskProvider.errorMessage, isNull);
      expect(taskProvider.successMessage, isNotNull);
    });
  });

  group('TaskProvider.clearError / clearSuccess', () {
    test('clears error message', () async {
      mockRepository.setShouldThrow(true);
      await taskProvider.loadTasks();
      expect(taskProvider.errorMessage, isNotNull);

      taskProvider.clearError();
      expect(taskProvider.errorMessage, isNull);
    });

    test('clears success message', () async {
      await taskProvider.createTask(
        title: 'Test',
        description: 'Test',
        rewardAmount: 5.0,
        createdBy: 'user-1',
      );
      expect(taskProvider.successMessage, isNotNull);

      taskProvider.clearSuccess();
      expect(taskProvider.successMessage, isNull);
    });
  });
}
