import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/data/models/affiliate_project_model.dart';
import 'package:flutter/foundation.dart' show debugPrint;

class AffiliateProjectFirestoreDataSource {
  final FirebaseFirestore _firestore;

  AffiliateProjectFirestoreDataSource({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // ─── Real-time Streams ────────────────────────────────

  /// Helper: logs Firestore query metadata for every snapshot.
  void _logSnapshot({
    required String label,
    required QuerySnapshot snapshot,
    required String collection,
  }) {
    final fromCache = snapshot.metadata.isFromCache;
    final hasPendingWrites = snapshot.metadata.hasPendingWrites;
    debugPrint('[Firestore] $label - collection: $collection, '
        'docs: ${snapshot.docs.length}, '
        'fromCache: $fromCache, '
        'hasPendingWrites: $hasPendingWrites');
    if (snapshot.docs.isNotEmpty) {
      debugPrint('[Firestore] $label - first doc ID: ${snapshot.docs.first.id}');
    }
  }

  /// Real-time stream of all projects (for admin)
  /// Uses [snapshotMetadataChanges: true] to ensure we always get the latest
  /// server data, even when local cache is available.
  /// Sorting is done client-side to avoid needing composite indexes.
  Stream<List<AffiliateProjectModel>> streamAllProjects() {
    return _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      _logSnapshot(
        label: 'streamAllProjects',
        snapshot: snapshot,
        collection: AppConstants.affiliateProjectsCollection,
      );
      final models = snapshot.docs
          .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return models;
    });
  }

  /// Real-time stream of active projects (for users)
  ///
  /// Does NOT use [includeMetadataChanges] so that Firestore only emits
  /// snapshots when document data actually changes — not for metadata-only
  /// transitions (e.g. `isFromCache` flipping from true to false). This
  /// prevents an empty-cache snapshot on first load from prematurely
  /// resolving the loading state in the provider.
  ///
  /// On first subscription (empty local cache), Firestore fetches from
  /// the server directly and emits one snapshot with the actual data.
  /// On subsequent subscriptions, it emits cached data immediately then
  /// a server snapshot only if the documents changed.
  ///
  /// NOTE: Client-side sorting is used (featured then createdDate) to
  /// avoid requiring a composite index. Firestore auto-creates single-field
  /// indexes, so this query works without manual index creation.
  Stream<List<AffiliateProjectModel>> streamActiveProjects() {
    debugPrint('[Firestore] streamActiveProjects - subscribing to active projects stream');
    return _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .where('lifecycleStatus', isEqualTo: 'active')
        .snapshots()
        .map((snapshot) {
      _logSnapshot(
        label: 'streamActiveProjects',
        snapshot: snapshot,
        collection: AppConstants.affiliateProjectsCollection,
      );
      final models = snapshot.docs
          .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
          .toList();
      // Sort featured projects to the top (client-side to avoid composite index)
      models.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return b.createdDate.compareTo(a.createdDate);
      });
      return models;
    });
  }

  /// Real-time stream of featured projects
  Stream<List<AffiliateProjectModel>> streamFeaturedProjects() {
    debugPrint('[Firestore] streamFeaturedProjects - subscribing to featured projects stream');
    return _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .where('lifecycleStatus', isEqualTo: 'active')
        .where('featured', isEqualTo: true)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      _logSnapshot(
        label: 'streamFeaturedProjects',
        snapshot: snapshot,
        collection: AppConstants.affiliateProjectsCollection,
      );
      final models = snapshot.docs
          .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return models;
    });
  }

  /// Real-time stream of user participations
  Stream<List<ProjectParticipationModel>> streamUserParticipations(
      String userId) {
    debugPrint('[Firestore] streamUserParticipations - userId: $userId');
    return _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .where('userId', isEqualTo: userId)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      _logSnapshot(
        label: 'streamUserParticipations',
        snapshot: snapshot,
        collection: AppConstants.projectParticipationsCollection,
      );
      final models = snapshot.docs
          .map((doc) => ProjectParticipationModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return models;
    });
  }

  /// Real-time stream of pending participations (for admin)
  Stream<List<ProjectParticipationModel>> streamPendingParticipations() {
    return _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .where('status', whereIn: ['submitted', 'pendingReview', 'underReview'])
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      _logSnapshot(
        label: 'streamPendingParticipations',
        snapshot: snapshot,
        collection: AppConstants.projectParticipationsCollection,
      );
      final models = snapshot.docs
          .map((doc) => ProjectParticipationModel.fromFirestore(doc.data()))
          .toList();
      // submittedAt is nullable — sort non-null before null for descending
      models.sort((a, b) {
        if (a.submittedAt == null && b.submittedAt == null) return 0;
        if (a.submittedAt == null) return 1;
        if (b.submittedAt == null) return -1;
        return b.submittedAt!.compareTo(a.submittedAt!);
      });
      return models;
    });
  }

  /// Real-time stream of all participations (for admin analytics)
  Stream<List<ProjectParticipationModel>> streamAllParticipations() {
    return _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .snapshots(includeMetadataChanges: true)
        .map((snapshot) {
      _logSnapshot(
        label: 'streamAllParticipations',
        snapshot: snapshot,
        collection: AppConstants.projectParticipationsCollection,
      );
      final models = snapshot.docs
          .map((doc) => ProjectParticipationModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return models;
    });
  }

  // ─── One-time Queries ─────────────────────────────────

  Future<List<AffiliateProjectModel>> getAllProjects() async {
    try {
      debugPrint('[Firestore] getAllProjects - forcing server read');
      final snapshot = await _firestore
          .collection(AppConstants.affiliateProjectsCollection)
          .get(const GetOptions(source: Source.server));
      debugPrint('[Firestore] getAllProjects - server returned ${snapshot.docs.length} docs');
      final models = snapshot.docs
          .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.createdDate.compareTo(a.createdDate));
      return models;
    } catch (e) {
      debugPrint('[Firestore] getAllProjects ERROR: $e');
      // Fallback to cache
      try {
        debugPrint('[Firestore] getAllProjects - falling back to cache');
        final snapshot = await _firestore
            .collection(AppConstants.affiliateProjectsCollection)
            .get(const GetOptions(source: Source.cache));
        final models = snapshot.docs
            .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
            .toList();
        models.sort((a, b) => b.createdDate.compareTo(a.createdDate));
        return models;
      } catch (cacheError) {
        debugPrint('[Firestore] getAllProjects - cache fallback also failed: $cacheError');
        return [];
      }
    }
  }

  Future<List<AffiliateProjectModel>> getActiveProjects() async {
    try {
      debugPrint('[Firestore] getActiveProjects - forcing server read');
      final snapshot = await _firestore
          .collection(AppConstants.affiliateProjectsCollection)
          .where('lifecycleStatus', isEqualTo: 'active')
          .get(const GetOptions(source: Source.server));
      debugPrint('[Firestore] getActiveProjects - server returned ${snapshot.docs.length} docs');
      final models = snapshot.docs
          .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
          .toList();
      // Client-side sort to avoid composite index requirement
      models.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return b.createdDate.compareTo(a.createdDate);
      });
      return models;
    } catch (e) {
      debugPrint('[Firestore] getActiveProjects ERROR: $e');
      // Fallback to cache
      try {
        debugPrint('[Firestore] getActiveProjects - falling back to cache');
        final snapshot = await _firestore
            .collection(AppConstants.affiliateProjectsCollection)
            .where('lifecycleStatus', isEqualTo: 'active')
            .get(const GetOptions(source: Source.cache));
        final models = snapshot.docs
            .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
            .toList();
        models.sort((a, b) {
          if (a.featured && !b.featured) return -1;
          if (!a.featured && b.featured) return 1;
          return b.createdDate.compareTo(a.createdDate);
        });
        return models;
      } catch (cacheError) {
        debugPrint('[Firestore] getActiveProjects - cache fallback also failed: $cacheError');
        return [];
      }
    }
  }

  /// Paginated one-time query for active projects (for infinite scroll)
  /// Supports server-side category filtering and search prefix matching.
  ///
  /// NOTE: Pagination requires `orderBy` + cursors. If the composite index
  /// is missing, this query will fail and return an empty list (graceful
  /// degradation). The main non-paginated queries (`streamActiveProjects`,
  /// `getActiveProjects`) work without composite indexes.
  Future<List<AffiliateProjectModel>> getActiveProjectsPage({
    int pageSize = 20,
    DateTime? lastCreatedDate,
    String? lastProjectId,
    String? categoryFilter,
    String? searchPrefix,
  }) async {
    try {
      var query = _firestore
          .collection(AppConstants.affiliateProjectsCollection)
          .where('lifecycleStatus', isEqualTo: 'active')
          .orderBy('createdDate', descending: true);

      // Apply server-side category filter
      if (categoryFilter != null && categoryFilter.isNotEmpty) {
        query = query.where('category', isEqualTo: categoryFilter);
      }

      // Apply server-side search prefix filter (matches title prefix)
      if (searchPrefix != null && searchPrefix.isNotEmpty) {
        query = query
            .where('title', isGreaterThanOrEqualTo: searchPrefix)
            .where('title', isLessThan: '${searchPrefix}z');
      }

      query = query.limit(pageSize);

      if (lastCreatedDate != null) {
        query = query.startAfter([lastCreatedDate]);
      }

      final snapshot = await query.get();
      final models = snapshot.docs
          .map((doc) => AffiliateProjectModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) {
        if (a.featured && !b.featured) return -1;
        if (!a.featured && b.featured) return 1;
        return b.createdDate.compareTo(a.createdDate);
      });
      return models;
    } catch (e) {
      debugPrint('getActiveProjectsPage error: $e');
      return [];
    }
  }

  // ─── Admin CRUD ───────────────────────────────────────

  Future<void> createProject(AffiliateProjectModel project) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(project.projectId)
        .set(project.toFirestore());
  }

  Future<void> updateProject(AffiliateProjectModel project) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(project.projectId)
        .update(project.toFirestore());
  }

  Future<void> deleteProject(String projectId) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(projectId)
        .delete();
  }

  Future<void> updateProjectStatus(
      String projectId, String status) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(projectId)
        .update({
      'lifecycleStatus': status,
      'updatedDate': Timestamp.now(),
    });
  }

  Future<void> duplicateProject(String sourceProjectId,
      AffiliateProjectModel newProject) async {
    final batch = _firestore.batch();
    batch.set(
      _firestore
          .collection(AppConstants.affiliateProjectsCollection)
          .doc(newProject.projectId),
      newProject.toFirestore(),
    );
    await batch.commit();
  }

  // ─── Analytics ────────────────────────────────────────

  Future<Map<String, dynamic>> getProjectAnalytics() async {
    try {
      final projectsSnapshot = await _firestore
          .collection(AppConstants.affiliateProjectsCollection)
          .get();
      final participationsSnapshot = await _firestore
          .collection(AppConstants.projectParticipationsCollection)
          .get();

      return {
        'totalProjects': projectsSnapshot.docs.length,
        'activeProjects': projectsSnapshot.docs
            .where((d) => d.data()['lifecycleStatus'] == 'active')
            .length,
        'totalClicks': projectsSnapshot.docs.fold<int>(
            0, (total, d) => total + ((d.data()['clicks'] as num?)?.toInt() ?? 0)),
        'totalParticipants': projectsSnapshot.docs.fold<int>(
            0,
            (total, d) =>
                total + ((d.data()['currentParticipants'] as num?)?.toInt() ??
                    0)),
        'totalRewardsPaid': projectsSnapshot.docs.fold<double>(
            0,
            (total, d) =>
                total +
                ((d.data()['totalRewardsPaid'] as num?)?.toDouble() ?? 0.0)),
        'pendingReviews': participationsSnapshot.docs
            .where((d) =>
                d.data()['status'] == 'pendingReview' ||
                d.data()['status'] == 'submitted')
            .length,
        'approvedRewards': participationsSnapshot.docs
            .where((d) => d.data()['status'] == 'approved')
            .length,
        'rejectedRewards': participationsSnapshot.docs
            .where((d) => d.data()['status'] == 'rejected')
            .length,
      };
    } catch (e) {
      debugPrint('getProjectAnalytics error: $e');
      return {};
    }
  }

  // ─── Participation ────────────────────────────────────

  Future<List<ProjectParticipationModel>> getParticipations(
      String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectParticipationsCollection)
          .where('projectId', isEqualTo: projectId)
          .get();
      final models = snapshot.docs
          .map((doc) => ProjectParticipationModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return models;
    } catch (e) {
      debugPrint('getParticipations error: $e');
      return [];
    }
  }

  Future<List<ProjectParticipationModel>> getUserParticipations(
      String userId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectParticipationsCollection)
          .where('userId', isEqualTo: userId)
          .get();
      final models = snapshot.docs
          .map((doc) => ProjectParticipationModel.fromFirestore(doc.data()))
          .toList();
      models.sort((a, b) => b.startedAt.compareTo(a.startedAt));
      return models;
    } catch (e) {
      debugPrint('getUserParticipations error: $e');
      return [];
    }
  }

  Future<List<ProjectParticipationModel>> getPendingParticipations() async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectParticipationsCollection)
          .where('status', whereIn: ['submitted', 'pendingReview', 'underReview'])
          .get();
      final models = snapshot.docs
          .map((doc) => ProjectParticipationModel.fromFirestore(doc.data()))
          .toList();
      // submittedAt is nullable — sort non-null before null for descending
      models.sort((a, b) {
        if (a.submittedAt == null && b.submittedAt == null) return 0;
        if (a.submittedAt == null) return 1;
        if (b.submittedAt == null) return -1;
        return b.submittedAt!.compareTo(a.submittedAt!);
      });
      return models;
    } catch (e) {
      debugPrint('getPendingParticipations error: $e');
      return [];
    }
  }

  Future<ProjectParticipationModel?> getUserProjectParticipation(
      String userId, String projectId) async {
    try {
      final snapshot = await _firestore
          .collection(AppConstants.projectParticipationsCollection)
          .where('userId', isEqualTo: userId)
          .where('projectId', isEqualTo: projectId)
          .limit(1)
          .get();
      if (snapshot.docs.isEmpty) return null;
      return ProjectParticipationModel.fromFirestore(snapshot.docs.first.data());
    } catch (e) {
      return null;
    }
  }

  Future<void> createParticipation(
      ProjectParticipationModel participation) async {
    await _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .doc(participation.participationId)
        .set(participation.toFirestore());
  }

  Future<void> updateParticipationStatus(
      String participationId, String status, {String? reviewedBy}) async {
    await _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .doc(participationId)
        .update({
      'status': status,
      if (status == 'submitted' || status == 'pendingReview')
        'submittedAt': Timestamp.now(),
      if (status == 'approved' || status == 'rejected') ...{
        'reviewedAt': Timestamp.now(),
        if (reviewedBy != null) 'reviewedBy': reviewedBy,
      },
    });
  }

  Future<ProjectParticipationModel?> getParticipationById(
      String participationId) async {
    try {
      final doc = await _firestore
          .collection(AppConstants.projectParticipationsCollection)
          .doc(participationId)
          .get();
      if (!doc.exists || doc.data() == null) return null;
      return ProjectParticipationModel.fromFirestore(doc.data()!);
    } catch (e) {
      return null;
    }
  }

  Future<void> updateParticipationPartial(
      String participationId, Map<String, dynamic> updates) async {
    await _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .doc(participationId)
        .update(updates);
  }

  Future<void> markRewardCredited(String participationId) async {
    await _firestore
        .collection(AppConstants.projectParticipationsCollection)
        .doc(participationId)
        .update({
      'rewardCredited': true,
      'status': 'completed',
      'reviewedAt': Timestamp.now(),
    });
  }

  Future<void> incrementParticipants(String projectId) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(projectId)
        .update({
      'currentParticipants': FieldValue.increment(1),
      'updatedDate': Timestamp.now(),
    });
  }

  Future<void> incrementClicks(String projectId) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(projectId)
        .update({
      'clicks': FieldValue.increment(1),
    });
  }

  Future<void> incrementCompletedCount(String projectId) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(projectId)
        .update({
      'completedCount': FieldValue.increment(1),
      'totalRewardsPaid': FieldValue.increment(
          0.0), // actual amount added separately
    });
  }

  Future<void> incrementTotalRewardsPaid(
      String projectId, double amount) async {
    await _firestore
        .collection(AppConstants.affiliateProjectsCollection)
        .doc(projectId)
        .update({
      'totalRewardsPaid': FieldValue.increment(amount),
    });
  }
}
