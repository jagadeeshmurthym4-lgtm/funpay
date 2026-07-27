import 'dart:async';

import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/affiliate_project_repository.dart';
import 'package:cashspark/domain/repositories/auth_repository.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/screens/projects/affiliate_projects_list_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:provider/provider.dart';

// ─── Mock AuthRepository ────────────────────────────────────

class MockAuthRepository implements AuthRepository {
  final _authStateController = StreamController<UserEntity?>.broadcast();

  @override
  UserEntity? get currentUser => null;

  @override
  Future<UserEntity?> getCurrentUser() async => null;

  @override
  Stream<UserEntity?> get authStateChanges => _authStateController.stream;

  @override
  Future<void> signOut() async {}

  @override
  Future<({UserEntity user, bool isNewUser})> signInWithGoogle() async {
    throw UnimplementedError('signInWithGoogle not needed for this test');
  }

  @override
  Future<UserEntity> completeProfile({
    required String firstName,
    required String lastName,
    required String phone,
    required String dateOfBirth,
    String? referralCode,
  }) async {
    throw UnimplementedError('completeProfile not needed for this test');
  }

  @override
  Future<void> reloadUser() async {}

  @override
  Future<UserEntity> updateProfile({
    String? fullName,
    String? username,
    String? phone,
    String? dateOfBirth,
    String? gender,
    String? address,
    String? city,
    String? state,
    String? country,
    String? aboutMe,
    String? education,
    String? experience,
    List<String>? skills,
    List<String>? portfolioLinks,
    String? profilePicture,
    String? coverImage,
  }) async {
    throw UnimplementedError('updateProfile not needed for this test');
  }

  @override
  Future<void> sendPasswordResetEmail(String email, {Map<String, dynamic>? actionCodeSettings}) async {}

  @override
  Future<bool> sendEmailVerification() async => true;

  @override
  Future<UserEntity> signUpWithEmail({
    required String fullName,
    required String email,
    required String phone,
    required String password,
    String? firstName,
    String? lastName,
    String? dateOfBirth,
    String? referralCode,
  }) async {
    throw UnimplementedError('signUpWithEmail not needed for this test');
  }

  @override
  Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
  }) async {}

  @override
  Future<UserEntity> signInWithEmail({
    required String email,
    required String password,
  }) async {
    throw UnimplementedError('signInWithEmail not needed for this test');
  }

  @override
  Future<void> deleteAccount() async {}

  void close() {
    _authStateController.close();
  }
}

// ─── Mock AffiliateProjectRepository ────────────────────────
/// A mock repository that returns controlled page results and can introduce
/// an artificial delay so tests can capture the skeleton loading state.

class MockAffiliateProjectRepository implements AffiliateProjectRepository {
  final _activeProjectsController =
      StreamController<List<AffiliateProjectEntity>>.broadcast(sync: true);
  final _featuredProjectsController =
      StreamController<List<AffiliateProjectEntity>>.broadcast(sync: true);
  final List<AffiliateProjectEntity> _storedActiveProjects;

  MockAffiliateProjectRepository({List<AffiliateProjectEntity>? projects})
      : _storedActiveProjects = projects ?? [];

  /// Emits projects on the active stream. Call AFTER the listener is attached
  /// (i.e. after pumpWidget + pump so postFrameCallback has run).
  void emitActiveProjects(List<AffiliateProjectEntity> projects) {
    _activeProjectsController.add(projects);
  }

  void emitFeaturedProjects(List<AffiliateProjectEntity> projects) {
    _featuredProjectsController.add(projects);
  }

  @override
  Stream<List<AffiliateProjectEntity>> streamActiveProjects() {
    return _activeProjectsController.stream;
  }

  @override
  Stream<List<AffiliateProjectEntity>> streamFeaturedProjects() {
    return _featuredProjectsController.stream;
  }

  @override
  Stream<List<AffiliateProjectEntity>> streamAllProjects() =>
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
  Future<List<AffiliateProjectEntity>> getActiveProjectsPage({
    int pageSize = 20,
    DateTime? lastCreatedDate,
    String? lastProjectId,
    String? categoryFilter,
    String? searchPrefix,
  }) async {
    return _storedActiveProjects;
  }

  @override
  Future<List<AffiliateProjectEntity>> getActiveProjects() async =>
      _storedActiveProjects;

  @override
  Future<List<AffiliateProjectEntity>> getAllProjects() async => [];

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
  }) async => 'mock-participation-id';

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
    _featuredProjectsController.close();
  }
}

// ─── Test Helpers ───────────────────────────────────────────

AffiliateProjectEntity createTestProject({
  String title = 'Test Project',
  String category = 'Finance',
  double reward = 50.0,
  bool featured = false,
  bool isNew = true,
}) {
  final now = DateTime.now();
  return AffiliateProjectEntity(
    projectId: 'test-${title.replaceAll(' ', '-').toLowerCase()}',
    title: title,
    description: 'A test project description',
    rewardAmount: reward,
    category: category,
    createdDate: now,
    expiryDate: now.add(const Duration(days: 30)),
    createdBy: 'admin',
    updatedDate: now,
    featured: featured,
    isNew: isNew,
    subtitle: 'Test subtitle',
    lifecycleStatus: ProjectLifecycleStatus.active,
  );
}

Widget buildTestApp({
  required AffiliateProjectProvider projectProvider,
  required AuthProvider authProvider,
}) {
  return MultiProvider(
    providers: [
      ChangeNotifierProvider<AuthProvider>.value(value: authProvider),
      ChangeNotifierProvider<AffiliateProjectProvider>.value(
          value: projectProvider),
    ],
    child: const MaterialApp(
      home: AffiliateProjectsListScreen(),
    ),
  );
}

// ─── Tests ──────────────────────────────────────────────────

void main() {
  late MockAuthRepository mockAuthRepo;
  late AuthProvider authProvider;

  setUp(() {
    mockAuthRepo = MockAuthRepository();
    authProvider = AuthProvider(authRepository: mockAuthRepo);
  });

  tearDown(() {
    // Dispose providers first so they cancel subscriptions before
    // closing the stream controllers they listen to.
    authProvider.dispose();
    mockAuthRepo.close();
  });

  group('Stream-based loading', () {
    testWidgets('emits projects via stream and shows real content',
        (tester) async {
      final mockProjects = [
        createTestProject(title: 'Finance App', category: 'Finance'),
        createTestProject(
            title: 'Shopping App', category: 'Shopping', reward: 30),
      ];

      final projectRepo = MockAffiliateProjectRepository();
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));

      // Pump once so postFrameCallback runs and stream listener attaches
      await tester.pump();

      // Emit projects on the active stream
      projectRepo.emitActiveProjects(mockProjects);
      await tester.pump();

      // Real content should be visible
      expect(find.byType(TextField), findsOneWidget,
          reason: 'Search TextField should show');
      expect(find.text('Finance App'), findsOneWidget,
          reason: 'Project title should show');
      expect(find.text('Shopping App'), findsOneWidget,
          reason: 'Project title should show');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets('shows project count in sort bar after stream emits',
        (tester) async {
      final mockProjects = [
        createTestProject(title: 'Project Alpha', category: 'Finance'),
        createTestProject(title: 'Project Beta', category: 'Technology'),
        createTestProject(title: 'Project Gamma', category: 'Gaming'),
      ];

      final projectRepo = MockAffiliateProjectRepository();
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));

      // Pump so postFrameCallback runs and stream listener attaches
      await tester.pump();

      // Emit projects
      projectRepo.emitActiveProjects(mockProjects);
      await tester.pump();

      // Should show the correct project count
      expect(find.textContaining('3 projects'), findsOneWidget,
          reason: 'Sort bar should show correct project count');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets('shows ProjectsEmptyState when empty stream emitted',
        (tester) async {
      final projectRepo = MockAffiliateProjectRepository();
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));

      await tester.pump();

      // Emit empty list
      projectRepo.emitActiveProjects([]);
      await tester.pump();

      // Should show ProjectsEmptyState
      expect(find.byType(ProjectsEmptyState), findsOneWidget,
          reason: 'ProjectsEmptyState should show for empty results');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets(
        'shows regular projects from stream and featured projects from separate stream',
        (tester) async {
      final projectRepo = MockAffiliateProjectRepository();
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));

      // Pump so postFrameCallback runs and stream listeners attach
      await tester.pump();

      // Emit active projects
      projectRepo.emitActiveProjects([
        createTestProject(title: 'Regular Project', category: 'Finance'),
      ]);
      await tester.pump();

      // Emit featured projects
      projectRepo.emitFeaturedProjects([
        createTestProject(
          title: 'Now Featured!',
          category: 'Gaming',
          reward: 75,
          featured: true,
        ),
      ]);
      await tester.pump();

      // Both regular and featured projects should show
      // Note: the provider upserts featured projects into the main list too,
      // so 'Now Featured!' appears in both the featured carousel AND the grid
      expect(find.text('Regular Project'), findsOneWidget,
          reason: 'Regular project should show');
      expect(find.text('Now Featured!'), findsWidgets,
          reason: 'Featured project title should show in carousel and/or grid');

      projectProvider.dispose();
      projectRepo.close();
    });
  });

  group('Search and category filter interactions', () {
    testWidgets('search field accepts text input', (tester) async {
      final mockProjects = [
        createTestProject(title: 'Finance Pro', category: 'Finance'),
        createTestProject(title: 'Shopping Deals', category: 'Shopping'),
      ];
      final projectRepo =
          MockAffiliateProjectRepository(projects: mockProjects);
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Find the search field and enter text
      await tester.enterText(find.byType(TextField), 'Finance');
      // Pump past the 300ms search debounce
      await tester.pumpAndSettle();

      // The provider should have updated its search query
      expect(projectProvider.searchQuery, 'Finance',
          reason: 'Provider searchQuery should be updated');

      // The clear button should now be visible
      expect(find.byIcon(Icons.clear), findsOneWidget,
          reason: 'Clear icon should appear when search has text');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets('clear button resets the search field', (tester) async {
      final mockProjects = [
        createTestProject(title: 'Finance Pro', category: 'Finance'),
        createTestProject(title: 'Shopping Deals', category: 'Shopping'),
      ];
      final projectRepo =
          MockAffiliateProjectRepository(projects: mockProjects);
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Enter text into the search field
      await tester.enterText(find.byType(TextField), 'Shopping');
      await tester.pumpAndSettle();

      expect(projectProvider.searchQuery, 'Shopping',
          reason: 'Search query should be set before clearing');

      // Tap the clear button
      await tester.tap(find.byIcon(Icons.clear));
      await tester.pumpAndSettle();

      // Search query should be cleared
      expect(projectProvider.searchQuery, '',
          reason: 'Search query should be cleared');

      // Clear icon should no longer be visible
      expect(find.byIcon(Icons.clear), findsNothing,
          reason: 'Clear icon should disappear after clearing');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets('renders category chips and can scroll to all',
        (tester) async {
      final projectRepo =
          MockAffiliateProjectRepository(projects: []);
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Verify categories visible without scrolling
      expect(find.text('All'), findsOneWidget,
          reason: 'Chip "All" should render initially');
      expect(find.text('Finance'), findsOneWidget,
          reason: 'Chip "Finance" should render initially');
      expect(find.text('Gaming'), findsOneWidget,
          reason: 'Chip "Gaming" should render initially');

      // Scroll the chip list in steps until later chips are revealed
      await tester.dragUntilVisible(
        find.text('Entertainment'),
        find.byType(ListView).first,
        const Offset(-200, 0),
      );
      await tester.pumpAndSettle();

      // Later categories should now be visible after scrolling
      expect(find.text('Social'), findsOneWidget,
          reason: 'Chip "Social" should be found after scrolling');
      expect(find.text('Entertainment'), findsOneWidget,
          reason: 'Chip "Entertainment" should be found after scrolling');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets('tapping a category chip selects it', (tester) async {
      final mockProjects = [
        createTestProject(title: 'Finance Pro', category: 'Finance'),
        createTestProject(title: 'Shopping Deals', category: 'Shopping'),
        createTestProject(title: 'Gaming World', category: 'Gaming'),
      ];
      final projectRepo =
          MockAffiliateProjectRepository(projects: mockProjects);
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Initially 'All' is selected
      expect(projectProvider.selectedCategory, 'All',
          reason: 'Default category should be All');

      // Find and tap the 'Finance' chip
      await tester.tap(find.text('Finance').last);
      await tester.pumpAndSettle();

      // The provider should reflect the selection change
      expect(projectProvider.selectedCategory, 'Finance',
          reason: 'Selected category should change to Finance');

      projectProvider.dispose();
      projectRepo.close();
    });

    testWidgets('tapping different category chips changes selection',
        (tester) async {
      final mockProjects = [
        createTestProject(title: 'Finance Pro', category: 'Finance'),
        createTestProject(title: 'Shopping Deals', category: 'Shopping'),
        createTestProject(title: 'Gaming World', category: 'Gaming'),
      ];
      final projectRepo =
          MockAffiliateProjectRepository(projects: mockProjects);
      final projectProvider =
          AffiliateProjectProvider(repository: projectRepo);

      await tester.pumpWidget(buildTestApp(
        projectProvider: projectProvider,
        authProvider: authProvider,
      ));
      await tester.pumpAndSettle();

      // Tap Finance → verify
      await tester.tap(find.text('Finance').last);
      await tester.pumpAndSettle();
      expect(projectProvider.selectedCategory, 'Finance');

      // Tap Gaming → verify change
      await tester.tap(find.text('Gaming').last);
      await tester.pumpAndSettle();
      expect(projectProvider.selectedCategory, 'Gaming',
          reason: 'Switching from Finance to Gaming should update');

      // Tap All → verify change back
      await tester.tap(find.text('All').last);
      await tester.pumpAndSettle();
      expect(projectProvider.selectedCategory, 'All',
          reason: 'Switching back to All should work');

      projectProvider.dispose();
      projectRepo.close();
    });
  });
}
