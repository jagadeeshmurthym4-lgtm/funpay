import 'dart:async';
import 'package:cashspark/domain/entities/project_entity.dart';
import 'package:cashspark/domain/repositories/project_repository.dart';
import 'package:flutter/foundation.dart';

class ProjectProvider extends ChangeNotifier {
  final ProjectRepository _projectRepository;

  List<ProjectEntity> _projects = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<ProjectEntity>>? _projectsSub;

  // ─── Auto-retry ───────────────────────────────────────
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 5;

  ProjectProvider({
    required ProjectRepository projectRepository,
  }) : _projectRepository = projectRepository;

  List<ProjectEntity> get projects => _projects;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  /// Subscribe to real-time active projects stream.
  void subscribeToActiveProjects() {
    _cancelRetry();
    _projectsSub?.cancel();
    _projectsSub = _projectRepository.streamActiveProjects().listen(
      (projects) {
        _projects = projects;
        _errorMessage = null;
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load projects. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToActiveProjects());
      },
    );
  }

  /// Subscribe to real-time stream of all projects (including inactive, for admin use).
  void subscribeToAllProjects() {
    _cancelRetry();
    _projectsSub?.cancel();
    _projectsSub = _projectRepository.streamAllProjects().listen(
      (projects) {
        _projects = projects;
        _errorMessage = null;
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        _errorMessage = 'Failed to load projects. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToAllProjects());
      },
    );
  }

  /// One-time fetch (fallback / for screens that don't need real-time).
  Future<void> loadActiveProjects() async {
    _setLoading(true);
    _clearError();
    try {
      _projects = await _projectRepository.getActiveProjects();
    } catch (e) {
      _errorMessage = 'Failed to load projects';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllProjects() async {
    _setLoading(true);
    _clearError();
    try {
      _projects = await _projectRepository.getAllProjects();
    } catch (e) {
      _errorMessage = 'Failed to load projects';
    } finally {
      _setLoading(false);
    }
  }

  void unsubscribe() {
    _cancelRetry();
    _projectsSub?.cancel();
    _projectsSub = null;
  }

  @override
  void dispose() {
    unsubscribe();
    super.dispose();
  }

  // ─── Auto-retry helpers ───────────────────────────────

  void _scheduleRetry(VoidCallback retryFn) {
    if (_retryCount >= _maxRetries) return;
    _retryCount++;
    // Exponential backoff: 2s, 4s, 8s, 16s, 32s
    final delay = Duration(seconds: 1 << _retryCount);
    _retryTimer?.cancel();
    _retryTimer = Timer(delay, retryFn);
  }

  void _cancelRetry() {
    _retryTimer?.cancel();
    _retryTimer = null;
    _retryCount = 0;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }

  void _clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
