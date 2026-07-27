import 'dart:async';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/domain/repositories/affiliate_project_repository.dart';
import 'package:flutter/foundation.dart';
import 'package:uuid/uuid.dart';

class AffiliateProjectProvider extends ChangeNotifier {
  final AffiliateProjectRepository _repository;
  final Uuid _uuid;

  // ─── Subscriptions ────────────────────────────────────
  StreamSubscription<List<AffiliateProjectEntity>>? _projectsSub;
  StreamSubscription<List<AffiliateProjectEntity>>? _allProjectsSub;
  StreamSubscription<List<AffiliateProjectEntity>>? _featuredProjectsSub;
  StreamSubscription<List<ProjectParticipationEntity>>? _participationsSub;
  StreamSubscription<List<ProjectParticipationEntity>>? _pendingSub;
  StreamSubscription<List<ProjectParticipationEntity>>? _allParticipationsSub;

  // ─── Auto-retry ───────────────────────────────────────
  int _retryCount = 0;
  Timer? _retryTimer;
  static const int _maxRetries = 5;

  // ─── Projects ─────────────────────────────────────────
  List<AffiliateProjectEntity> _projects = [];
  List<AffiliateProjectEntity> _filteredProjects = [];
  String _searchQuery = '';
  String _selectedCategory = 'All';
  String _selectedProjectType = 'All';
  String _sortBy = 'newest';

  // ─── Participation ────────────────────────────────────
  List<ProjectParticipationEntity> _participations = [];
  List<ProjectParticipationEntity> _pendingParticipations = [];
  List<ProjectParticipationEntity> _allParticipations = [];
  ProjectParticipationEntity? _currentParticipation;

  // ─── Analytics ────────────────────────────────────────
  ProjectAnalytics _analytics = const ProjectAnalytics();

  // ─── Tab persistence ─────────────────────────────────
  int _myProjectsTabIndex = 0;

  // ─── UI State ─────────────────────────────────────────
  bool _isLoading = false;
  /// Tracks whether the initial stream data has been received at least once.
  /// This prevents showing "No projects" empty state before the first
  /// server response arrives.
  bool _hasInitialProjectsData = false;
  bool _hasInitialParticipationsData = false;
  bool _hasTimedOut = false;
  String? _errorMessage;
  String? _successMessage;

  /// Timer that forces the loading state to resolve after a timeout,
  /// preventing infinite "Loading projects..." spinner when the stream
  /// never emits data or errors (e.g. missing Firestore composite index,
  /// auth permissions, or network issues that don't trigger the onError).
  Timer? _loadingTimeout;

  /// Guards against re-entrance into [_fallbackLoadProjects].
  bool _isFallbackRunning = false;

  // ─── Search Debounce ─────────────────────────────────
  Timer? _searchDebounce;

  static const List<String> categories = [
    'All', 'Finance', 'Shopping', 'Gaming', 'Surveys',
    'Education', 'Technology', 'Social', 'Entertainment',
  ];

  static const List<String> projectTypeOptions = [
    'All', 'affiliateOffer', 'installApp', 'registration',
    'kycVerification', 'purchase', 'survey', 'watchVideo',
    'quiz', 'uploadScreenshot', 'customTask',
  ];

  AffiliateProjectProvider({
    required AffiliateProjectRepository repository,
    Uuid? uuid,
  })  : _repository = repository,
        _uuid = uuid ?? const Uuid();

  // ─── Getters ──────────────────────────────────────────
  List<AffiliateProjectEntity> get projects => _filteredProjects;
  List<AffiliateProjectEntity> get allProjects => _projects;
  List<ProjectParticipationEntity> get participations => _participations;
  List<ProjectParticipationEntity> get pendingParticipations =>
      _pendingParticipations;
  List<ProjectParticipationEntity> get allParticipations =>
      _allParticipations;
  ProjectParticipationEntity? get currentParticipation =>
      _currentParticipation;
  /// Persisted tab index for the My Projects screen (remembers last tab).
  int get myProjectsTabIndex => _myProjectsTabIndex;
  void setMyProjectsTabIndex(int index) {
    _myProjectsTabIndex = index;
  }

  ProjectAnalytics get analytics => _analytics;
  bool get isLoading => _isLoading;
  /// Returns true while waiting for the initial server response for projects.
  /// Prevents showing "No projects" before data arrives.
  /// Returns true while waiting for the initial stream data.
  /// The `!_isLoading` guard is intentionally NOT included because a one-time
  /// load (e.g. loadActiveProjects) that sets `_isLoading = true` should not
  /// suppress this — the stream is the canonical data source.
  /// A timeout prevents indefinite spinner if the stream never emits.
  bool get isInitialLoading =>
      !_hasInitialProjectsData && _projects.isEmpty && !_hasTimedOut;
  bool get hasInitialProjectsData => _hasInitialProjectsData;
  bool get hasInitialParticipationsData => _hasInitialParticipationsData;
  bool get hasTimedOut => _hasTimedOut;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get searchQuery => _searchQuery;
  String get selectedCategory => _selectedCategory;
  String get selectedProjectType => _selectedProjectType;
  String get sortBy => _sortBy;

  List<AffiliateProjectEntity> get featuredProjects =>
      _projects.where((p) => p.featured && p.isActive).toList();

  List<AffiliateProjectEntity> get endingSoonProjects =>
      _projects.where((p) => p.isEndingSoon).toList();

  List<AffiliateProjectEntity> get trendingProjects {
    final sorted = List<AffiliateProjectEntity>.from(_projects);
    sorted.sort((a, b) => b.currentParticipants.compareTo(a.currentParticipants));
    return sorted.take(5).toList();
  }

  // ─── Real-time Subscriptions ──────────────────────────

  /// Subscribes to the active projects stream from Firestore.
  ///
  /// If the stream fails (e.g., missing composite index or network issue),
  /// it falls back to a one-time query (`loadActiveProjects()`) instead of
  /// infinitely retrying the same failing stream.
  void subscribeToActiveProjects() {
    _cancelRetry();
    _projectsSub?.cancel();
    _hasInitialProjectsData = false;
    _hasTimedOut = false;
    _isLoading = true; // Show loading state while waiting for stream
    _startLoadingTimeout();
    debugPrint('[AffiliateProjectProvider] subscribeToActiveProjects - subscribing');
    _projectsSub = _repository.streamActiveProjects().listen(
      (projects) {
        _isLoading = false;

        if (!_hasInitialProjectsData) {
          // First snapshot from the stream — always mark initial data as received
          // so the UI stops showing the loading state. Even if the snapshot is
          // empty (e.g. empty cache, no active projects), we've received the
          // initial response and should transition out of the loading state.
          _hasInitialProjectsData = true;
          _cancelLoadingTimeout();
          _hasTimedOut = false;
          _projects = projects;
          _errorMessage = null;
          _retryCount = 0;
          _applyFilters();
          debugPrint('[AffiliateProjectProvider] subscribeToActiveProjects - '
              'FIRST data received: ${projects.length} projects');
        } else {
          // Subsequent updates — apply normally
          debugPrint('[AffiliateProjectProvider] subscribeToActiveProjects - '
              'UPDATE: ${projects.length} projects');
          _cancelLoadingTimeout();
          _projects = projects;
          _errorMessage = null;
          _retryCount = 0;
          _hasTimedOut = false;
          _applyFilters();
        }
      },
      onError: (error) {
        _cancelLoadingTimeout();
        _isLoading = false;
        debugPrint('[AffiliateProjectProvider] subscribeToActiveProjects ERROR: $error');
        debugPrint('[AffiliateProjectProvider] subscribeToActiveProjects - '
            'Stream failed. Falling back to one-time query.');
        if (!_hasInitialProjectsData) {
          _hasInitialProjectsData = true;
        }
        _hasTimedOut = true;
        _errorMessage = 'Failed to load projects. Tap Retry to try again.';
        notifyListeners();

        // Fallback: try one-time query instead of retrying the same stream
        _fallbackLoadProjects();
      },
    );
    startAutoExpiryCheck();
  }

  /// Fallback: tries the one-time Firestore query when the stream fails.
  ///
  /// Uses a 15-second timeout to prevent infinite loading if the Firestore
  /// query hangs (e.g., missing indexes, network issues).
  /// Has a re-entrance guard to prevent concurrent invocations.
  Future<void> _fallbackLoadProjects() async {
    // Guard: prevent re-entrance
    if (_isFallbackRunning) {
      debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects - already running, skipping');
      return;
    }
    _isFallbackRunning = true;

    debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects - trying one-time query');
    try {
      // Only set loading if not already in timed-out/error state to avoid
      // flickering from error → loading → error/projects
      if (!_hasTimedOut) {
        _isLoading = true;
        notifyListeners();
      }

      final projects = await _repository
          .getActiveProjects()
          .timeout(
            const Duration(seconds: 10),
            onTimeout: () {
              debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects TIMEOUT '
                  '- Firestore query did not respond within 10s');
              return [];
            },
          );
      debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects - '
          'received ${projects.length} projects');

      if (projects.isNotEmpty) {
        // Sort featured projects to the top
        final sorted = List<AffiliateProjectEntity>.from(projects);
        sorted.sort((a, b) {
          if (a.featured && !b.featured) return -1;
          if (!a.featured && b.featured) return 1;
          return b.createdDate.compareTo(a.createdDate);
        });
        _projects = sorted;
        _errorMessage = null;
        _hasInitialProjectsData = true;
        _hasTimedOut = false;
        _isLoading = false;
        _applyFilters();
        debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects - '
            'Fallback succeeded: ${projects.length} projects loaded');
      } else {
        // No data from fallback either — keep the timeout/error state
        _isLoading = false;
        debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects - '
            'Fallback returned empty list, keeping error state');
        _hasTimedOut = true;
        _hasInitialProjectsData = true;
        _errorMessage = 'Unable to load projects. Check your connection and tap Retry.';
        notifyListeners();
      }
    } catch (e) {
      _isLoading = false;
      debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects ERROR: $e');
      debugPrint('[AffiliateProjectProvider] _fallbackLoadProjects - '
          'Fallback also failed. Keeping error state.');
      _hasTimedOut = true;
      _hasInitialProjectsData = true;
      _errorMessage = 'Unable to load projects. Check your connection and tap Retry.';
      notifyListeners();
    } finally {
      _isFallbackRunning = false;
    }
  }

  void subscribeToAllProjects() {
    _cancelRetry();
    _allProjectsSub?.cancel();
    _hasInitialProjectsData = false;
    _hasTimedOut = false;
    _startLoadingTimeout();
    debugPrint('[AffiliateProjectProvider] subscribeToAllProjects - subscribing');
    _allProjectsSub = _repository.streamAllProjects().listen(
      (projects) {
        if (!_hasInitialProjectsData) {
          if (projects.isNotEmpty) {
            debugPrint('[AffiliateProjectProvider] subscribeToAllProjects - '
                'FIRST data received: ${projects.length} projects');
            _hasInitialProjectsData = true;
            _cancelLoadingTimeout();
            _hasTimedOut = false;
            _projects = projects;
            _retryCount = 0;
            _applyFilters();
          } else {
            debugPrint('[AffiliateProjectProvider] subscribeToAllProjects - '
                'Empty first snapshot, waiting for server data...');
            notifyListeners();
          }
        } else {
          _cancelLoadingTimeout();
          _projects = projects;
          _retryCount = 0;
          _hasTimedOut = false;
          _applyFilters();
        }
      },
      onError: (error) {
        _cancelLoadingTimeout();
        debugPrint('[AffiliateProjectProvider] subscribeToAllProjects ERROR: $error');
        if (!_hasInitialProjectsData) {
          _hasInitialProjectsData = true;
        }
        _hasTimedOut = true;
        _errorMessage = 'Failed to load projects. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToAllProjects());
      },
    );
    startAutoExpiryCheck();
  }

  void subscribeToFeaturedProjects() {
    _cancelRetry();
    _featuredProjectsSub?.cancel();
    _featuredProjectsSub = _repository.streamFeaturedProjects().listen(
      (projects) {
        // Replace featured projects: remove all old ones, add all current ones
        final featuredIds = projects.map((p) => p.projectId).toSet();
        _projects.removeWhere((p) => featuredIds.contains(p.projectId));
        for (final project in projects) {
          final idx = _projects.indexWhere((p) => p.projectId == project.projectId);
          if (idx >= 0) {
            _projects[idx] = project;
          } else {
            _projects.add(project);
          }
        }
        _retryCount = 0;
        _applyFilters();
      },
      onError: (error) {
        _errorMessage = 'Failed to load projects. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToFeaturedProjects());
      },
    );
  }

  void subscribeToUserParticipations(String userId) {
    _cancelRetry();
    _participationsSub?.cancel();
    _hasInitialParticipationsData = false;
    debugPrint('[AffiliateProjectProvider] subscribeToUserParticipations - '
        'subscribing for userId: $userId');
    _participationsSub =
        _repository.streamUserParticipations(userId).listen(
      (parts) {
        if (!_hasInitialParticipationsData) {
          debugPrint('[AffiliateProjectProvider] subscribeToUserParticipations - '
              'FIRST data received: ${parts.length} participations');
          _hasInitialParticipationsData = true;
        }
        _participations = parts;
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[AffiliateProjectProvider] subscribeToUserParticipations ERROR: $error');
        if (!_hasInitialParticipationsData) {
          _hasInitialParticipationsData = true;
        }
        _errorMessage = 'Failed to load participations. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToUserParticipations(userId));
      },
    );
  }

  void subscribeToPendingParticipations() {
    _cancelRetry();
    _pendingSub?.cancel();
    debugPrint('[AffiliateProjectProvider] subscribeToPendingParticipations');
    _pendingSub =
        _repository.streamPendingParticipations().listen(
      (parts) {
        debugPrint('[AffiliateProjectProvider] subscribeToPendingParticipations - '
            'data received: ${parts.length} participations');
        _pendingParticipations = parts;
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[AffiliateProjectProvider] subscribeToPendingParticipations ERROR: $error');
        _errorMessage = 'Failed to load pending submissions. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToPendingParticipations());
      },
    );
  }

  void subscribeToAllParticipations() {
    _cancelRetry();
    _allParticipationsSub?.cancel();
    debugPrint('[AffiliateProjectProvider] subscribeToAllParticipations');
    _allParticipationsSub =
        _repository.streamAllParticipations().listen(
      (parts) {
        debugPrint('[AffiliateProjectProvider] subscribeToAllParticipations - '
            'data received: ${parts.length} participations');
        _allParticipations = parts;
        _updateAnalytics();
        _retryCount = 0;
        notifyListeners();
      },
      onError: (error) {
        debugPrint('[AffiliateProjectProvider] subscribeToAllParticipations ERROR: $error');
        _errorMessage = 'Failed to load projects. Pull down to retry.';
        notifyListeners();
        _scheduleRetry(() => subscribeToAllParticipations());
      },
    );
  }

  void unsubscribeAll() {
    _cancelRetry();
    _cancelLoadingTimeout();
    _projectsSub?.cancel();
    _allProjectsSub?.cancel();
    _participationsSub?.cancel();
    _pendingSub?.cancel();
    _allParticipationsSub?.cancel();
  }

  @override
  void dispose() {
    unsubscribeAll();
    stopAutoExpiryCheck();
    _searchDebounce?.cancel();
    super.dispose();
  }

  /// Refresh projects by re-establishing the real-time stream subscription.
  /// If the stream previously failed, this will try again.
  Future<void> refreshProjects() async {
    subscribeToActiveProjects();
  }

  // ─── One-time Loads ───────────────────────────────────

  Future<void> loadActiveProjects() async {
    _setLoading(true);
    _clearMessages();
    _hasInitialProjectsData = false;
    debugPrint('[AffiliateProjectProvider] loadActiveProjects - fetching from server');
    try {
      _projects = await _repository.getActiveProjects();
      _hasInitialProjectsData = true;
      debugPrint('[AffiliateProjectProvider] loadActiveProjects - '
          'received ${_projects.length} projects');
      _applyFilters();
    } catch (e) {
      _hasInitialProjectsData = true;
      debugPrint('[AffiliateProjectProvider] loadActiveProjects ERROR: $e');
      _errorMessage = 'Failed to load projects';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAllProjects() async {
    _setLoading(true);
    _clearMessages();
    _hasInitialProjectsData = false;
    debugPrint('[AffiliateProjectProvider] loadAllProjects - fetching from server');
    try {
      _projects = await _repository.getAllProjects();
      _hasInitialProjectsData = true;
      debugPrint('[AffiliateProjectProvider] loadAllProjects - '
          'received ${_projects.length} projects');
      _applyFilters();
    } catch (e) {
      _hasInitialProjectsData = true;
      debugPrint('[AffiliateProjectProvider] loadAllProjects ERROR: $e');
      _errorMessage = 'Failed to load projects';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUserParticipations(String userId) async {
    _setLoading(true);
    _clearMessages();
    try {
      _participations = await _repository.getUserParticipations(userId);
    } catch (e) {
      _errorMessage = 'Failed to load participations';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingParticipations() async {
    _setLoading(true);
    _clearMessages();
    try {
      _pendingParticipations = await _repository.getPendingParticipations();
    } catch (e) {
      _errorMessage = 'Failed to load pending submissions';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAnalytics() async {
    try {
      _analytics = await _repository.getProjectAnalytics();
      notifyListeners();
    } catch (e) {
      debugPrint('loadAnalytics error: $e');
    }
  }

  void _updateAnalytics() {
    _analytics = ProjectAnalytics.fromProjects(_projects, _allParticipations);
  }

  // ─── Filters ──────────────────────────────────────────

  /// Update search query with a 300ms debounce.
  /// All filtering is applied client-side on the streamed data.
  void setSearchQuery(String query) {
    _searchQuery = query;
    _searchDebounce?.cancel();
    _searchDebounce = Timer(const Duration(milliseconds: 300), () {
      _applyFilters();
      notifyListeners();
    });
  }

  /// Update category filter (applied client-side on streamed data).
  void setCategory(String category) {
    _selectedCategory = category;
    _applyFilters();
    notifyListeners();
  }

  void setProjectType(String type) {
    _selectedProjectType = type;
    _applyFilters();
    notifyListeners();
  }

  /// Update sort order (applied client-side on loaded data).
  void setSortBy(String sort) {
    _sortBy = sort;
    _applyFilters();
    notifyListeners();
  }

  void _applyFilters() {
    final totalProjects = _projects.length;
    var result = List<AffiliateProjectEntity>.from(_projects);

    if (_searchQuery.isNotEmpty) {
      final query = _searchQuery.toLowerCase();
      result = result.where((p) =>
          p.title.toLowerCase().contains(query) ||
          p.subtitle.toLowerCase().contains(query) ||
          p.category.toLowerCase().contains(query) ||
          p.description.toLowerCase().contains(query)).toList();
    }

    if (_selectedCategory != 'All') {
      result = result.where((p) => p.category == _selectedCategory).toList();
    }

    if (_selectedProjectType != 'All') {
      result = result
          .where((p) => p.projectType.name == _selectedProjectType)
          .toList();
    }

    switch (_sortBy) {
      case 'newest':
        result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        break;
      case 'highestReward':
        result.sort((a, b) => b.rewardAmount.compareTo(a.rewardAmount));
        break;
      case 'lowestReward':
        result.sort((a, b) => a.rewardAmount.compareTo(b.rewardAmount));
        break;
      case 'shortestTime':
        result.sort((a, b) => a.completionTime.compareTo(b.completionTime));
        break;
      case 'longestTime':
        result.sort((a, b) => b.completionTime.compareTo(a.completionTime));
        break;
      case 'endingSoon':
        result.sort((a, b) => a.expiryDate.compareTo(b.expiryDate));
        break;
      case 'mostPopular':
        result.sort(
            (a, b) => b.currentParticipants.compareTo(a.currentParticipants));
        break;
      case 'featured':
        result.sort((a, b) {
          if (a.featured && !b.featured) return -1;
          if (!a.featured && b.featured) return 1;
          return b.createdDate.compareTo(a.createdDate);
        });
        break;
      default:
        result.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    }

    _filteredProjects = result;
    debugPrint('[AffiliateProjectProvider] _applyFilters - '
        'total: $totalProjects, filtered: ${result.length}, '
        'category: $_selectedCategory, search: "$_searchQuery"');
    notifyListeners();
  }

  // ─── Admin Operations ─────────────────────────────────

  Future<bool> createProject({
    required String title,
    String subtitle = '',
    required String description,
    required double rewardAmount,
    required String category,
    String projectType = 'affiliateOffer',
    String bannerImage = '',
    String logoImage = '',
    String affiliateTrackingLink = '',
    String affiliateProvider = '',
    List<String> instructions = const [],
    String termsAndConditions = '',
    int completionTime = 30,
    String difficulty = 'easy',
    int maxParticipants = 1000,
    DateTime? expiryDate,
    String createdBy = 'admin',
    bool featured = false,
    ProjectEligibility? eligibility,
    List<String> tags = const [],
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      final now = DateTime.now();
      final project = AffiliateProjectEntity(
        projectId: _uuid.v4(),
        title: title,
        subtitle: subtitle,
        description: description,
        rewardAmount: rewardAmount,
        category: category,
        projectType: ProjectType.values.firstWhere(
          (e) => e.name == projectType,
          orElse: () => ProjectType.affiliateOffer,
        ),
        bannerImage: bannerImage,
        logoImage: logoImage,
        affiliateTrackingLink: affiliateTrackingLink,
        affiliateProvider: affiliateProvider,
        instructions: instructions,
        termsAndConditions: termsAndConditions,
        completionTime: completionTime,
        difficulty: ProjectDifficulty.values.firstWhere(
          (e) => e.name == difficulty,
          orElse: () => ProjectDifficulty.easy,
        ),
        maxParticipants: maxParticipants,
        lifecycleStatus: ProjectLifecycleStatus.active,
        featured: featured,
        createdDate: now,
        expiryDate: expiryDate ?? now.add(const Duration(days: 30)),
        createdBy: createdBy,
        updatedDate: now,
        eligibility: eligibility ?? const ProjectEligibility(),
        tags: tags,
      );
      await _repository.createProject(project);
      // Notify about new project
      await _repository.notifyNewProject(title, createdBy);
      _successMessage = 'Project created successfully';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create project';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> updateProject(AffiliateProjectEntity project) async {
    _setLoading(true);
    _clearMessages();
    try {
      final updated = project.copyWith(updatedDate: DateTime.now());
      await _repository.updateProject(updated);
      _successMessage = 'Project updated';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> deleteProject(String projectId) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _repository.deleteProject(projectId);
      _successMessage = 'Project deleted';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete project';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleProjectStatus(
      String projectId, ProjectLifecycleStatus status) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _repository.updateProjectStatus(projectId, status);
      _successMessage = 'Project ${status.label}';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update project status';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> duplicateProject(String projectId) async {
    _setLoading(true);
    _clearMessages();
    try {
      final project = _projects.firstWhere((p) => p.projectId == projectId);
      await _repository.duplicateProject(project);
      _successMessage = 'Project duplicated';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to duplicate project';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  // ─── Participation ────────────────────────────────────

  Future<ProjectParticipationEntity?> checkParticipation(
      String userId, String projectId) async {
    try {
      _currentParticipation =
          await _repository.getUserProjectParticipation(userId, projectId);
      return _currentParticipation;
    } catch (e) {
      return null;
    }
  }

  Future<bool> startProject({
    required String projectId,
    required String projectTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
  }) async {
    _clearMessages();
    try {
      final participationId = await _repository.startProject(
        projectId: projectId,
        projectTitle: projectTitle,
        userId: userId,
        userName: userName,
        rewardAmount: rewardAmount,
      );
      if (participationId != null) {
        debugPrint('startProject provider: Success — participation $participationId');
        _successMessage =
            'Project started! Complete the steps to earn the reward.';
        notifyListeners();
        return true;
      } else {
        debugPrint('startProject provider: Repository returned null (unexpected)');
        _errorMessage = 'Failed to start project';
        notifyListeners();
        return false;
      }
    } catch (e) {
      debugPrint('startProject provider: ERROR: $e');
      _errorMessage = 'Failed to start project';
      notifyListeners();
      return false;
    }
  }

  Future<bool> submitProof({
    required String participationId,
    String? screenshotUrl,
    String? note,
    String? transactionId,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _repository.submitProof(
        participationId: participationId,
        screenshotUrl: screenshotUrl,
        note: note,
        transactionId: transactionId,
      );
      _successMessage = 'Proof submitted! Waiting for admin review.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to submit proof';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveParticipation(
      String participationId, {String? reviewedBy}) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _repository.approveParticipation(
        participationId,
        reviewedBy: reviewedBy,
      );
      _successMessage = 'Participation approved';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve participation';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> rejectParticipation(
      String participationId, String reason) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _repository.rejectParticipation(participationId, reason);
      _successMessage = 'Participation rejected';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject participation';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> resubmitParticipation(String participationId) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _repository.resubmitParticipation(participationId);
      _successMessage = 'Ready to resubmit. Please upload your proof again.';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to resubmit';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> creditReward(String participationId, String userId) async {
    _setLoading(true);
    _clearMessages();
    try {
      final credited =
          await _repository.creditReward(participationId, userId);
      if (credited) {
        _successMessage = 'Reward credited to wallet!';
        notifyListeners();
        return true;
      } else {
        _errorMessage =
            'Reward already credited or participation not found';
        return false;
      }
    } catch (e) {
      _errorMessage = 'Failed to credit reward';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Approval + credit in a single call with one loading toggle.
  Future<({bool approved, bool credited})> approveAndCreditReward(
    String participationId,
    String userId, {
    String? reviewedBy,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      final credited = await _repository.approveAndCreditReward(
        participationId,
        userId,
        reviewedBy: reviewedBy,
      );
      if (credited) {
        _successMessage = 'Approved and reward credited to wallet!';
      } else {
        _successMessage = 'Approved, but reward may already have been credited.';
      }
      notifyListeners();
      return (approved: true, credited: credited);
    } catch (e) {
      _errorMessage = 'Failed to approve and credit reward';
      return (approved: false, credited: false);
    } finally {
      _setLoading(false);
    }
  }

  // ─── Auto-expiry ─────────────────────────────────────

  Timer? _expiryTimer;

  void startAutoExpiryCheck() {
    _expiryTimer?.cancel();
    // Check every minute
    _expiryTimer = Timer.periodic(const Duration(minutes: 1), (_) {
      _checkExpiredProjects();
    });
    // Also check immediately
    _checkExpiredProjects();
  }

  void stopAutoExpiryCheck() {
    _expiryTimer?.cancel();
    _expiryTimer = null;
  }

  Future<void> _checkExpiredProjects() async {
    try {
      final now = DateTime.now();
      for (final project in _projects) {
        if (project.isActive && project.expiryDate.isBefore(now)) {
          await _repository.updateProjectStatus(
            project.projectId,
            ProjectLifecycleStatus.expired,
          );
          // Notify participants about expiry
          await _repository.notifyProjectExpired(
            project.projectId,
            project.title,
          );
        }
      }
    } catch (e) {
      debugPrint('Auto-expiry check error: $e');
    }
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

  // ─── Loading timeout ────────────────────────────────

  /// If the stream never emits data or errors within this timeout,
  /// we mark as timed-out so the UI can show an appropriate message
  /// instead of an infinite spinner.
  static const Duration _loadingTimeoutDuration = Duration(seconds: 10);

  void _startLoadingTimeout() {
    _cancelLoadingTimeout();
    _loadingTimeout = Timer(_loadingTimeoutDuration, () {
      debugPrint('[AffiliateProjectProvider] Loading TIMEOUT - stream did not emit within '
          '${_loadingTimeoutDuration.inSeconds}s');
      if (!_hasInitialProjectsData) {
        debugPrint('[AffiliateProjectProvider] Loading TIMEOUT - '
            'Falling back to one-time query.');
        _hasInitialProjectsData = true;
        _hasTimedOut = true;
        _isLoading = false;
        // Don't set error message yet — the fallback query will determine
        // the final state. If fallback returns data, we show projects.
        // If fallback returns empty, we show "No projects available".
        // The error message is only set if the fallback itself fails.
        notifyListeners();

        // Fallback: try one-time query
        _fallbackLoadProjects();
      }
    });
  }

  void _cancelLoadingTimeout() {
    _loadingTimeout?.cancel();
    _loadingTimeout = null;
  }

  // ─── Utility ──────────────────────────────────────────

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void _clearMessages() {
    _errorMessage = null;
    _successMessage = null;
  }

  void _setLoading(bool value) {
    _isLoading = value;
    notifyListeners();
  }
}
