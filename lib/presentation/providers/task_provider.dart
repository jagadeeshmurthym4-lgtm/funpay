import 'package:cashspark/domain/entities/custom_task_entity.dart';
import 'package:cashspark/domain/repositories/task_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class TaskProvider extends ChangeNotifier {
  final TaskRepository _taskRepository;
  final Uuid _uuid;

  List<CustomTaskEntity> _tasks = [];
  List<TaskSubmissionEntity> _submissions = [];
  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;
  bool _disposed = false;

  TaskProvider({
    required TaskRepository taskRepository,
    Uuid? uuid,
  })  : _taskRepository = taskRepository,
        _uuid = uuid ?? const Uuid();

  List<CustomTaskEntity> get tasks => _tasks;
  List<TaskSubmissionEntity> get submissions => _submissions;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (e) {
      debugPrint('TaskProvider._safeNotifyListeners suppressed: $e');
    }
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    _safeNotifyListeners();
  }

  /// Load all tasks from the repository.
  Future<void> loadTasks() async {
    _clearMessages();
    _setLoading(true);
    try {
      _tasks = await _taskRepository.getAllTasks();
    } catch (e) {
      debugPrint('TaskProvider.loadTasks error: $e');
      _errorMessage = 'Failed to load tasks';
    } finally {
      _setLoading(false);
    }
  }

  /// Load only active tasks.
  Future<void> loadActiveTasks() async {
    _clearMessages();
    _setLoading(true);
    try {
      _tasks = await _taskRepository.getActiveTasks();
    } catch (e) {
      debugPrint('TaskProvider.loadActiveTasks error: $e');
      _errorMessage = 'Failed to load active tasks';
    } finally {
      _setLoading(false);
    }
  }

  /// Create a new task and add it to the local list.
  Future<bool> createTask({
    required String title,
    required String description,
    required double rewardAmount,
    required String createdBy,
    String? taskLink,
    String category = 'General',
  }) async {
    _clearMessages();
    _setLoading(true);
    try {
      final now = DateTime.now();
      final task = CustomTaskEntity(
        taskId: _uuid.v4(),
        title: title,
        description: description,
        rewardAmount: rewardAmount,
        taskLink: taskLink,
        category: category,
        isActive: true,
        createdBy: createdBy,
        createdAt: now,
        updatedAt: now,
      );
      await _taskRepository.createTask(task);
      _tasks = [task, ..._tasks];
      _successMessage = 'Task created successfully';
      return true;
    } catch (e) {
      debugPrint('TaskProvider.createTask error: $e');
      _errorMessage = 'Failed to create task';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Toggle the active status of a task.
  Future<bool> toggleTaskStatus(String taskId, bool isActive) async {
    _clearMessages();
    try {
      await _taskRepository.toggleTaskStatus(taskId, isActive);
      final index = _tasks.indexWhere((t) => t.taskId == taskId);
      if (index != -1) {
        _tasks[index] = _tasks[index].copyWith(isActive: isActive);
      }
      _successMessage = isActive ? 'Task activated' : 'Task deactivated';
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('TaskProvider.toggleTaskStatus error: $e');
      _errorMessage = 'Failed to toggle task status';
      _safeNotifyListeners();
      return false;
    }
  }

  /// Delete a task and remove it from the local list.
  Future<bool> deleteTask(String taskId) async {
    _clearMessages();
    try {
      await _taskRepository.deleteTask(taskId);
      _tasks.removeWhere((t) => t.taskId == taskId);
      _successMessage = 'Task deleted';
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('TaskProvider.deleteTask error: $e');
      _errorMessage = 'Failed to delete task';
      _safeNotifyListeners();
      return false;
    }
  }

  /// Submit proof for a task.
  Future<bool> submitTaskProof({
    required String taskId,
    required String taskTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
    String? note,
    String? screenshotUrl,
  }) async {
    _clearMessages();
    _setLoading(true);
    try {
      await _taskRepository.submitTaskProof(
        submissionId: _uuid.v4(),
        taskId: taskId,
        taskTitle: taskTitle,
        userId: userId,
        userName: userName,
        rewardAmount: rewardAmount,
        note: note,
        screenshotUrl: screenshotUrl,
      );
      _successMessage = 'Proof submitted successfully';
      return true;
    } catch (e) {
      debugPrint('TaskProvider.submitTaskProof error: $e');
      _errorMessage = 'Failed to submit proof';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Load all submissions.
  Future<void> loadSubmissions() async {
    _clearMessages();
    _setLoading(true);
    try {
      _submissions = await _taskRepository.getAllSubmissions();
    } catch (e) {
      debugPrint('TaskProvider.loadSubmissions error: $e');
      _errorMessage = 'Failed to load submissions';
    } finally {
      _setLoading(false);
    }
  }

  /// Approve a submission (admin action).
  Future<bool> approveSubmission(String submissionId) async {
    _clearMessages();
    try {
      await _taskRepository.approveSubmission(submissionId, '');
      final index = _submissions.indexWhere((s) => s.submissionId == submissionId);
      if (index != -1) {
        _submissions[index] = _submissions[index].copyWith(
          status: 'approved',
          reviewedAt: DateTime.now(),
        );
      }
      _successMessage = 'Submission approved';
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('TaskProvider.approveSubmission error: $e');
      _errorMessage = 'Failed to approve submission';
      _safeNotifyListeners();
      return false;
    }
  }

  /// Reject a submission with a reason (admin action).
  Future<bool> rejectSubmission(
    String submissionId,
    String reason,
  ) async {
    _clearMessages();
    try {
      await _taskRepository.rejectSubmission(submissionId, reason, '');
      final index = _submissions.indexWhere((s) => s.submissionId == submissionId);
      if (index != -1) {
        _submissions[index] = _submissions[index].copyWith(
          status: 'rejected',
          rejectionReason: reason,
          reviewedAt: DateTime.now(),
        );
      }
      _successMessage = 'Submission rejected';
      _safeNotifyListeners();
      return true;
    } catch (e) {
      debugPrint('TaskProvider.rejectSubmission error: $e');
      _errorMessage = 'Failed to reject submission';
      _safeNotifyListeners();
      return false;
    }
  }

  void clearError() {
    _errorMessage = null;
    _safeNotifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    _safeNotifyListeners();
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
