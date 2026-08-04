import 'dart:convert';

import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart';

/// Configuration for the CPX Research offer wall, read from the
/// `app_settings/cpx` Firestore doc (authenticated users can read it,
/// only admins can write — see firestore.rules).
class CpxConfig {
  final String appId;
  final String appSecureHash;
  final bool enabled;

  const CpxConfig({
    this.appId = AppConstants.cpxAppId,
    this.appSecureHash = '',
    this.enabled = true,
  });

  /// Fallback used when the config doc is missing or unreadable:
  /// enabled with the baked-in App ID so the wall always works.
  static const CpxConfig fallback =
      CpxConfig(appId: AppConstants.cpxAppId, enabled: true);

  CpxConfig copyWith({
    String? appId,
    String? appSecureHash,
    bool? enabled,
  }) {
    return CpxConfig(
      appId: appId ?? this.appId,
      appSecureHash: appSecureHash ?? this.appSecureHash,
      enabled: enabled ?? this.enabled,
    );
  }
}

/// Loads the CPX Research config and builds the signed offer wall URL.
///
/// URL format follows the official CPX Research integration docs:
///   https://offers.cpx-research.com/index.php?app_id={appId}
///     &ext_user_id={userId}
///     &secure_hash={md5("{userId}-{appSecureHash}")}   (when a hash is set)
///     &email={email}
class CpxProvider extends ChangeNotifier {
  CpxConfig? _config;
  bool _isLoading = false;
  String? _errorMessage;

  /// Prevents notifyListeners() after dispose.
  bool _disposed = false;

  /// Firestore instance (injectable for tests; defaults to the singleton).
  ///
  /// Resolved lazily inside the async load/save try/catch blocks so that
  /// constructing a provider in a non-Firebase environment (e.g. widget/unit
  /// tests) never throws — it simply falls back to [CpxConfig.fallback].
  final FirebaseFirestore? _injectedFirestore;

  CpxProvider({FirebaseFirestore? firestore})
      : _injectedFirestore = firestore {
    // Fire-and-forget load; the URL builder falls back to [CpxConfig.fallback]
    // until the doc arrives, so the screen never blocks on this.
    loadConfig();
  }

  FirebaseFirestore get _firestore =>
      _injectedFirestore ?? FirebaseFirestore.instance;

  bool get isLoading => _isLoading;

  /// Last loaded config (null until the first read completes).
  CpxConfig? get config => _config;

  /// Message from the last failed load/save (null when all is well).
  String? get errorMessage => _errorMessage;

  /// The wall is considered available unless the config doc explicitly
  /// sets `enabled: false`.
  bool get isEnabled => _config?.enabled ?? true;

  String get appId => _config?.appId ?? AppConstants.cpxAppId;

  /// Loads config from `app_settings/cpx`. Falls back to [CpxConfig.fallback]
  /// when the doc is missing or unreadable.
  Future<void> loadConfig() async {
    _isLoading = true;
    _safeNotifyListeners();
    try {
      final doc = await _firestore
          .collection(AppConstants.appSettingsCollection)
          .doc(AppConstants.cpxSettingsDocId)
          .get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        _config = CpxConfig(
          appId: (data['appId'] as String?)?.trim().isNotEmpty == true
              ? data['appId'] as String
              : AppConstants.cpxAppId,
          appSecureHash: (data['appSecureHash'] as String?)?.trim() ?? '',
          enabled: (data['enabled'] as bool?) ?? true,
        );
      } else {
        _config = CpxConfig.fallback;
      }
    } catch (_) {
      // Offline / permission issues → keep the default app id.
      _errorMessage = 'Could not load CPX config';
      _config = CpxConfig.fallback;
    } finally {
      _isLoading = false;
      _safeNotifyListeners();
    }
  }

  /// Forces a fresh fetch (e.g. after an admin updates the config).
  Future<void> refresh() async {
    _config = null;
    await loadConfig();
  }

  /// Persists [config] to `app_settings/cpx` (admin-only per Firestore rules)
  /// and updates the in-memory state. Returns `true` on success.
  ///
  /// Only NON-secret values are written here: appId, appSecureHash (used for
  /// the offer wall *entry link* only) and the enabled flag. The postback
  /// verification secret stays server-side (CPX_SECRET on the backend).
  Future<bool> saveConfig(CpxConfig config) async {
    _errorMessage = null;
    try {
      await _firestore
          .collection(AppConstants.appSettingsCollection)
          .doc(AppConstants.cpxSettingsDocId)
          .set({
        'appId': config.appId,
        'appSecureHash': config.appSecureHash,
        'enabled': config.enabled,
        'updatedAt': FieldValue.serverTimestamp(),
      }, SetOptions(merge: true));
      _config = config;
      _safeNotifyListeners();
      return true;
    } catch (_) {
      _errorMessage = 'Failed to save CPX config';
      return false;
    }
  }

  /// Builds the CPX offer wall URL for [userId].
  ///
  /// The `secure_hash` mirrors the documented formula:
  /// `md5("{ext_user_id}-{app_secure_hash}")`. It is only appended when an
  /// app secure hash has been configured (it is optional in the CPX docs).
  ///
  /// [config] overrides the loaded config (used by tests); defaults to the
  /// config loaded via [loadConfig].
  String buildOfferWallUrl({
    required String userId,
    String? email,
    String? username,
    CpxConfig? config,
  }) {
    final cfg = config ?? _config;
    final params = <String, String>{
      'app_id': cfg?.appId ?? AppConstants.cpxAppId,
      'ext_user_id': userId,
    };

    final hash = (cfg?.appSecureHash ?? '').trim();
    if (hash.isNotEmpty) {
      params['secure_hash'] =
          md5.convert(utf8.encode('$userId-$hash')).toString();
    }
    if (email != null && email.trim().isNotEmpty) params['email'] = email.trim();
    if (username != null && username.trim().isNotEmpty) {
      params['username'] = username.trim();
    }

    return Uri.parse(AppConstants.cpxOfferWallBaseUrl)
        .replace(queryParameters: params)
        .toString();
  }

  void _safeNotifyListeners() {
    if (_disposed) return;
    try {
      notifyListeners();
    } catch (_) {}
  }

  @override
  void dispose() {
    _disposed = true;
    super.dispose();
  }
}
