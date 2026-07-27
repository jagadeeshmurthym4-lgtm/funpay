import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/foundation.dart' show debugPrint;

/// Service that ensures Firestore local cache is invalidated periodically.
///
/// On every app start and after login, if the last full refresh was more than
/// [refreshInterval] ago, we force-read the most important collections from
/// the server (with `Source.server`), which populates the local cache with
/// fresh data and clears any stale metadata.
///
/// The timestamp is persisted in SharedPreferences so it survives app restarts.
class FirestoreCacheBustingService {
  static const String _lastRefreshKey = 'firestore_last_refresh_ts';

  /// Refresh at most once every 15 minutes.
  static const Duration refreshInterval = Duration(minutes: 15);

  final FirebaseFirestore _firestore;
  SharedPreferences? _prefs;

  FirestoreCacheBustingService({FirebaseFirestore? firestoreInstance})
      : _firestore = firestoreInstance ?? FirebaseFirestore.instance;

  // ─── Public API ─────────────────────────────────────────

  /// Call on every app start. Refreshes if the interval has elapsed.
  Future<void> refreshOnAppStart() async {
    _prefs = await SharedPreferences.getInstance();
    if (_needsRefresh()) {
      debugPrint('[CacheBusting] App start - refresh needed, busting cache...');
      await _forceRefreshAll();
      _markRefreshed();
    } else {
      debugPrint('[CacheBusting] App start - cache still fresh, skipping');
    }
  }

  /// Call after every successful login. Always refreshes so the newly
  /// logged-in user immediately sees the latest data from the server.
  Future<void> refreshOnLogin() async {
    _prefs ??= await SharedPreferences.getInstance();
    debugPrint('[CacheBusting] Login - force-refreshing all collections');
    await _forceRefreshAll();
    _markRefreshed();
  }

  // ─── Internal ──────────────────────────────────────────

  bool _needsRefresh() {
    final lastTs = _prefs!.getInt(_lastRefreshKey) ?? 0;
    if (lastTs == 0) return true; // Never refreshed
    final elapsed = DateTime.now().millisecondsSinceEpoch - lastTs;
    return elapsed >= refreshInterval.inMilliseconds;
  }

  void _markRefreshed() {
    _prefs!.setInt(_lastRefreshKey, DateTime.now().millisecondsSinceEpoch);
    debugPrint('[CacheBusting] Refresh timestamp updated');
  }

  /// Force-reads all critical collections from the server, bypassing the
  /// local Firestore cache. If a server read fails (e.g. offline), we
  /// silently fall back to the cache — the data may be stale but the app
  /// still works.
  Future<void> _forceRefreshAll() async {
    await Future.wait([
      _refreshCollection('affiliate_projects'),
      _refreshCollection('project_participations', limit: 100),
      _refreshCollection('offers'),
      _refreshCollection('projects'),
      if (_prefs!.containsKey('cached_uid')) _refreshUserDoc(),
    ]);
    debugPrint('[CacheBusting] All collections refreshed');
  }

  Future<void> _refreshCollection(String collectionName, {int limit = 50}) async {
    try {
      debugPrint('[CacheBusting] Force-refreshing collection: $collectionName');
      final snapshot = await _firestore
          .collection(collectionName)
          .limit(limit)
          .get(const GetOptions(source: Source.server));
      debugPrint('[CacheBusting] $collectionName: ${snapshot.docs.length} docs from server');
    } catch (e) {
      debugPrint('[CacheBusting] Server read failed for $collectionName: $e');
      // Non-critical — the app will use cached or stream data instead.
    }
  }

  Future<void> _refreshUserDoc() async {
    final uid = _prefs!.getString('cached_uid');
    if (uid == null || uid.isEmpty) return;
    try {
      debugPrint('[CacheBusting] Force-refreshing user doc: $uid');
      await _firestore
          .collection('users')
          .doc(uid)
          .get(const GetOptions(source: Source.server));
      debugPrint('[CacheBusting] User doc $uid refreshed from server');
    } catch (e) {
      debugPrint('[CacheBusting] Server read failed for user $uid: $e');
    }
  }

  /// Store the current user's UID so we can also force-read their user doc
  /// during app-start cache busting.
  Future<void> cacheCurrentUserUid(String uid) async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString('cached_uid', uid);
  }
}
