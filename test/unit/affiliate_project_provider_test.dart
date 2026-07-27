import 'dart:async';

import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/domain/repositories/affiliate_project_repository.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ─── Mock Repository ────────────────────────────────────────
class MockAffiliateProjectRepository implements AffiliateProjectRepository {
  final _activeProjectsController =
      StreamController<List<AffiliateProjectEntity>>.broadcast(sync: true);

  List<AffiliateProjectEntity>? fallbackResult;
  Exception? fallbackError;
  Duration fallbackDelay = Duration.zero;

  /// Allows tests to override [getActiveProjects] behavior.
  /// If null (default), uses the standard fallbackResult/fallbackError logic.
  Future<List<AffiliateProjectEntity>> Function()? getActiveProjectsOverride;

  void emitActiveProjects(List<AffiliateProjectEntity> projects) {
    _activeProjectsController.add(projects);
  }

  void emitError(Object error) {
    _activeProjectsController.addError(error);
  }

  @override
  Stream<List<AffiliateProjectEntity>> streamActiveProjects() {
    return _activeProjectsController.stream;
  }

  @override
  Future<List<AffiliateProjectEntity>> getActiveProjects() async {
    if (getActiveProjectsOverride != null) {
      return getActiveProjectsOverride!();
    }
    if (fallbackDelay > Duration.zero) {
      await Future.delayed(fallbackDelay);
    }
    if (fallbackError != null) throw fallbackError!;
    return fallbackResult ?? [];
  }

  // ── Unused stubs ────────────────────────────────────────────
  @override
  Stream<List<AffiliateProjectEntity>> streamAllProjects() =>
      const Stream.empty();

  @override
  Stream<List<AffiliateProjectEntity>> streamFeaturedProjects() =>
      const Stream.empty();

  @override
  Stream<List<ProjectParticipationEntity>> streamUserParticipations(
          String userId) =>
      const Stream.empty();

  @override
  Stream<List<ProjectParticipationEntity>> streamPendingParticipations() =>
      const Stream.empty();

  @override
  Stream<List<ProjectParticipationEntity>> streamAllParticipations() =>
      const Stream.empty();

  @override
  Future<List<AffiliateProjectEntity>> getAllProjects() async => [];

  @override
  Future<List<AffiliateProjectEntity>> getActiveProjectsPage({
    int pageSize = 20,
    DateTime? lastCreatedDate,
    String? lastProjectId,
    String? categoryFilter,
    String? searchPrefix,
  }) async => [];  

  @override
  Future<void> createProject(AffiliateProjectEntity project) async {}

  @override
  Future<void> updateProject(AffiliateProjectEntity project) async {}

  @override
  Future<void> deleteProject(String projectId) async {}

  @override
  Future<void> updateProjectStatus(
      String projectId, ProjectLifecycleStatus status) async {}

  @override
  Future<void> duplicateProject(AffiliateProjectEntity project) async {}

  @override
  Future<ProjectAnalytics> getProjectAnalytics() =>
      Future.value(const ProjectAnalytics());

  @override
  Future<List<ProjectParticipationEntity>> getProjectParticipations(
          String projectId) =>
      Future.value([]);

  @override
  Future<List<ProjectParticipationEntity>> getUserParticipations(
          String userId) =>
      Future.value([]);

  @override
  Future<List<ProjectParticipationEntity>> getPendingParticipations() =>
      Future.value([]);

  @override
  Future<ProjectParticipationEntity?> getUserProjectParticipation(
          String userId, String projectId) =>
      Future.value(null);

  @override
  Future<String?> startProject({
    required String projectId,
    required String projectTitle,
    required String userId,
    required String userName,
    required double rewardAmount,
  }) async => 'mock-id';

  @override
  Future<void> submitProof({
    required String participationId,
    required String? screenshotUrl,
    required String? note,
    String? transactionId,
  }) async {}

  @override
  Future<void> approveParticipation(
      String participationId, {String? reviewedBy}) async {}

  @override
  Future<void> rejectParticipation(
      String participationId, String reason) async {}

  @override
  Future<bool> creditReward(String participationId, String userId) =>
      Future.value(true);

  @override
  Future<bool> approveAndCreditReward(
      String participationId, String userId, {String? reviewedBy}) =>
      Future.value(true);

  @override
  Future<void> resubmitParticipation(String participationId) async {}

  @override
  Future<void> notifyProjectExpired(
      String projectId, String projectTitle) async {}

  @override
  Future<void> notifyNewProject(String projectTitle, String createdBy) async {}

  void close() {
    _activeProjectsController.close();
  }
}

// ─── Test Helpers ───────────────────────────────────────────

AffiliateProjectEntity _createProject({
  String title = 'Test Project',
  String category = 'Finance',
  double reward = 50.0,
}) {
  final now = DateTime.now();
  return AffiliateProjectEntity(
    projectId: 'test-${title.replaceAll(' ', '-').toLowerCase()}',
    title: title,
    description: 'A test project',
    rewardAmount: reward,
    category: category,
    createdDate: now,
    expiryDate: now.add(const Duration(days: 30)),
    createdBy: 'admin',
    updatedDate: now,
    subtitle: 'Test subtitle',
    lifecycleStatus: ProjectLifecycleStatus.active,
  );
}

Widget _buildApp(AffiliateProjectProvider projectProvider) {
  return MaterialApp(
    home: ChangeNotifierProvider<AffiliateProjectProvider>.value(
      value: projectProvider,
      child: const SizedBox.shrink(),
    ),
  );
}

/// Helper to create a fresh provider + mock and register cleanup.
({MockAffiliateProjectRepository repo, AffiliateProjectProvider provider})
    _createFixture() {
  final repo = MockAffiliateProjectRepository();
  final provider = AffiliateProjectProvider(repository: repo);
  return (repo: repo, provider: provider);
}

void disposeFixture(
    MockAffiliateProjectRepository repo, AffiliateProjectProvider provider) {
  // Stop expiry timer & dispose BEFORE test framework checks for pending timers.
  // The provider's startAutoExpiryCheck() creates a periodic Timer that must be
  // cancelled within the test body (not in tearDown).
  provider.stopAutoExpiryCheck();
  provider.dispose();
  repo.close();
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  // ═══════════════════════════════════════════════════════════
  // Initial State
  // ═══════════════════════════════════════════════════════════
  group('initial state', () {
    testWidgets('all loading flags start in correct defaults', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));

      expect(fixture.provider.isLoading, isFalse);
      // isInitialLoading = !_hasInitialProjectsData && _projects.isEmpty && !_hasTimedOut
      // Since _hasInitialProjectsData=false, _projects=[], _hasTimedOut=false → true
      expect(fixture.provider.isInitialLoading, isTrue);
      expect(fixture.provider.hasInitialProjectsData, isFalse);
      expect(fixture.provider.hasTimedOut, isFalse);
      expect(fixture.provider.errorMessage, isNull);
      expect(fixture.provider.allProjects, isEmpty);
      expect(fixture.provider.projects, isEmpty);

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // subscribeToActiveProjects – Loading States
  // ═══════════════════════════════════════════════════════════
  group('subscribeToActiveProjects', () {
    testWidgets('sets loading state immediately when called', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();

      expect(fixture.provider.isLoading, isTrue);
      expect(fixture.provider.isInitialLoading, isTrue,
          reason: '(!hasInitialProjectsData && projects.isEmpty && !hasTimedOut)');
      expect(fixture.provider.hasInitialProjectsData, isFalse);
      expect(fixture.provider.hasTimedOut, isFalse);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('stops loading and populates projects when stream emits data',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      final projects = [_createProject(title: 'Project A')];

      fixture.provider.subscribeToActiveProjects();
      expect(fixture.provider.isLoading, isTrue);

      fixture.repo.emitActiveProjects(projects);
      await tester.pump();

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.hasInitialProjectsData, isTrue);
      expect(fixture.provider.hasTimedOut, isFalse);
      expect(fixture.provider.allProjects, hasLength(1));
      expect(fixture.provider.allProjects.first.title, 'Project A');
      expect(fixture.provider.errorMessage, isNull);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('marks initial data on empty first snapshot (stream resolved)',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      expect(fixture.provider.isLoading, isTrue);

      // Empty first snapshot — provider always marks initial data as received
      // because the stream has emitted its first response (even if empty).
      fixture.repo.emitActiveProjects([]);
      await tester.pump();

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.hasInitialProjectsData, isTrue,
          reason: 'should mark initial data even for empty first snapshot');
      expect(fixture.provider.isInitialLoading, isFalse,
          reason: 'should exit initial loading state once stream emits');
      expect(fixture.provider.hasTimedOut, isFalse);
      expect(fixture.provider.allProjects, isEmpty);
      expect(fixture.provider.errorMessage, isNull);

      // Now emit real data — should populate projects
      fixture.repo.emitActiveProjects([_createProject(title: 'Real Data')]);
      await tester.pump();

      expect(fixture.provider.hasInitialProjectsData, isTrue);
      expect(fixture.provider.isInitialLoading, isFalse);
      expect(fixture.provider.allProjects, hasLength(1));

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('handles stream error and triggers fallback query',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      expect(fixture.provider.isLoading, isTrue);

      fixture.repo.emitError(Exception('Firestore index missing'));
      await tester.pump();

      expect(fixture.provider.hasInitialProjectsData, isTrue,
          reason: 'should be true so UI stops showing loader');
      expect(fixture.provider.hasTimedOut, isTrue,
          reason: 'should be true after stream error');
      expect(fixture.provider.errorMessage, isNotNull);

      // Wait for async fallback to complete
      await tester.pump();
      expect(fixture.provider.errorMessage, isNotNull);
      expect(fixture.provider.hasTimedOut, isTrue);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets(
        'stream error followed by successful fallback populates projects',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.repo.fallbackResult = [
        _createProject(title: 'Fallback Project'),
      ];

      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitError(Exception('Stream failed'));
      await tester.pump();

      // Wait for fallback to complete
      await tester.pump();
      await tester.pump();

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.hasInitialProjectsData, isTrue);
      expect(fixture.provider.hasTimedOut, isFalse,
          reason: 'should be false after successful fallback');
      expect(fixture.provider.errorMessage, isNull,
          reason: 'should be cleared after successful fallback');
      expect(fixture.provider.allProjects, hasLength(1));
      expect(fixture.provider.allProjects.first.title, 'Fallback Project');

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets(
        'stream error followed by failed fallback maintains error state',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.repo.fallbackError = Exception('Fallback also failed');

      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitError(Exception('Stream failed'));
      await tester.pump();

      // Wait for fallback to complete
      await tester.pump();

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.hasInitialProjectsData, isTrue);
      expect(fixture.provider.hasTimedOut, isTrue);
      expect(fixture.provider.errorMessage, isNotNull);
      expect(fixture.provider.allProjects, isEmpty);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets(
        'stream emits data after initial emission updates projects in-place',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      final project1 = _createProject(title: 'Project 1');
      final project2 = _createProject(title: 'Project 2');

      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitActiveProjects([project1]);
      await tester.pump();
      expect(fixture.provider.allProjects, hasLength(1));

      fixture.repo.emitActiveProjects([project1, project2]);
      await tester.pump();

      expect(fixture.provider.allProjects, hasLength(2));

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // isInitialLoading getter
  // ═══════════════════════════════════════════════════════════
  group('isInitialLoading', () {
    testWidgets('returns true when no data received and no timeout',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      expect(fixture.provider.isInitialLoading, isTrue);
      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('returns false after stream emits data', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitActiveProjects([_createProject()]);
      await tester.pump();
      expect(fixture.provider.isInitialLoading, isFalse);
      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('returns false after empty first snapshot (stream resolved)',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();

      // Empty first snapshot — provider resolves initial loading once
      // the stream emits its first snapshot, even if empty.
      fixture.repo.emitActiveProjects([]);
      await tester.pump();
      expect(fixture.provider.isInitialLoading, isFalse,
          reason: 'initial loading should resolve once stream emits first snapshot');

      // Emit real data — stays resolved
      fixture.repo.emitActiveProjects([_createProject()]);
      await tester.pump();
      expect(fixture.provider.isInitialLoading, isFalse);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('returns false after stream error triggers timeout',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitError(Exception('error'));
      await tester.pump();
      expect(fixture.provider.isInitialLoading, isFalse);
      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // Multiple subscribe calls
  // ═══════════════════════════════════════════════════════════
  group('multiple subscribeToActiveProjects calls', () {
    testWidgets('resets loading state and replaces projects on new data',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitActiveProjects([_createProject(title: 'First')]);
      await tester.pump();
      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.allProjects, hasLength(1));

      // Subscribe again — resets initial-loading flags
      fixture.provider.subscribeToActiveProjects();
      expect(fixture.provider.isLoading, isTrue,
          reason: 'should reset to true on re-subscribe');
      expect(fixture.provider.hasInitialProjectsData, isFalse,
          reason: 'should reset on re-subscribe');
      // Note: _projects is NOT cleared by re-subscribe — old data persists
      // until the new stream emits its first snapshot.

      // Emit new data
      fixture.repo.emitActiveProjects([_createProject(title: 'Second')]);
      await tester.pump();

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.allProjects, hasLength(1));
      expect(fixture.provider.allProjects.first.title, 'Second',
          reason:
              'projects should be replaced with new stream data');

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // _fallbackLoadProjects – Re-entrance guard
  // ═══════════════════════════════════════════════════════════
  group('fallback re-entrance guard', () {
    testWidgets('blocks concurrent fallback invocations', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      int callCount = 0;

      // Use fallbackDelay to make the fallback slow enough that a second
      // error can fire BEFORE the first fallback completes.
      fixture.repo.fallbackDelay = const Duration(milliseconds: 50);
      fixture.repo.fallbackResult = [_createProject(title: 'Slow')];

      // Track fallback calls via override
      fixture.repo.getActiveProjectsOverride = () async {
        callCount++;
        // Respect the delay to ensure the first call is still in-flight
        await Future.delayed(fixture.repo.fallbackDelay);
        return fixture.repo.fallbackResult ?? [];
      };

      fixture.provider.subscribeToActiveProjects();

      // Fire both errors synchronously (same microtask turn) to simulate
      // a race condition between onError and loading timeout.
      fixture.repo.emitError(Exception('First error'));
      fixture.repo.emitError(Exception('Second error'));

      // Advance time enough for the delayed fallback to complete
      await tester.pump();
      await tester.pump(const Duration(milliseconds: 100));
      await tester.pump();

      // Only one call should have been made — the second was blocked by
      // the _isFallbackRunning re-entrance guard.
      expect(callCount, 1,
          reason:
              'getActiveProjects should be called once; second call blocked by guard');

      fixture.repo.getActiveProjectsOverride = null;
      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // clearError & clearSuccess
  // ═══════════════════════════════════════════════════════════
  group('clearError / clearSuccess', () {
    testWidgets('clearError sets errorMessage to null after stream error',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitError(Exception('test error'));
      await tester.pump();

      expect(fixture.provider.errorMessage, isNotNull);
      fixture.provider.clearError();
      expect(fixture.provider.errorMessage, isNull);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('clearSuccess sets successMessage to null via createProject',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      await fixture.provider.createProject(
        title: 'Test Project',
        description: 'Test description',
        rewardAmount: 50.0,
        category: 'Finance',
      );
      await tester.pump();

      expect(fixture.provider.successMessage, isNotNull);
      fixture.provider.clearSuccess();
      expect(fixture.provider.successMessage, isNull);

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // unsubscribeAll
  // ═══════════════════════════════════════════════════════════
  group('unsubscribeAll', () {
    testWidgets('stops receiving stream updates after unsubscribing',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();

      fixture.repo.emitActiveProjects([_createProject(title: 'Before')]);
      await tester.pump();
      expect(fixture.provider.allProjects, hasLength(1));

      fixture.provider.unsubscribeAll();

      // Emitting new data should have no effect
      fixture.repo.emitActiveProjects([
        _createProject(title: 'After'),
      ]);
      await tester.pump();

      expect(fixture.provider.allProjects, hasLength(1));
      expect(fixture.provider.allProjects.first.title, 'Before');

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // loadActiveProjects (one-time query)
  // ═══════════════════════════════════════════════════════════
  group('loadActiveProjects (one-time query)', () {
    testWidgets('sets loading, fetches projects, stops loading',
        (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.repo.fallbackResult = [_createProject(title: 'Loaded')];

      final loadFuture = fixture.provider.loadActiveProjects();
      expect(fixture.provider.isLoading, isTrue);
      await loadFuture;

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.allProjects, hasLength(1));
      expect(fixture.provider.allProjects.first.title, 'Loaded');
      expect(fixture.provider.hasInitialProjectsData, isTrue);

      disposeFixture(fixture.repo, fixture.provider);
    });

    testWidgets('handles error without hanging', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.repo.fallbackError = Exception('Failed to load');

      await fixture.provider.loadActiveProjects();

      expect(fixture.provider.isLoading, isFalse);
      expect(fixture.provider.errorMessage, 'Failed to load projects');
      expect(fixture.provider.allProjects, isEmpty);
      expect(fixture.provider.hasInitialProjectsData, isTrue);

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // refreshProjects
  // ═══════════════════════════════════════════════════════════
  group('refreshProjects', () {
    testWidgets('re-subscribes to active projects', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitActiveProjects([_createProject(title: 'First')]);
      await tester.pump();
      expect(fixture.provider.allProjects, hasLength(1));

      await fixture.provider.refreshProjects();
      expect(fixture.provider.isLoading, isTrue,
          reason: 'should be true after refresh');

      fixture.repo.emitActiveProjects([
        _createProject(title: 'Refreshed'),
      ]);
      await tester.pump();

      expect(fixture.provider.allProjects, hasLength(1));
      expect(fixture.provider.allProjects.first.title, 'Refreshed');

      disposeFixture(fixture.repo, fixture.provider);
    });
  });

  // ═══════════════════════════════════════════════════════════
  // featuredProjects getter
  // ═══════════════════════════════════════════════════════════
  group('featuredProjects', () {
    testWidgets('returns only featured active projects', (tester) async {
      final fixture = _createFixture();
      await tester.pumpWidget(_buildApp(fixture.provider));
      final regular = _createProject(title: 'Regular');
      final featured =
          _createProject(title: 'Featured', reward: 100).copyWith(featured: true);

      fixture.provider.subscribeToActiveProjects();
      fixture.repo.emitActiveProjects([regular, featured]);
      await tester.pump();

      expect(fixture.provider.featuredProjects, hasLength(1));
      expect(fixture.provider.featuredProjects.first.title, 'Featured');

      disposeFixture(fixture.repo, fixture.provider);
    });
  });
}
