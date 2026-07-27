import 'package:cashspark/core/constants/app_constants.dart';
import 'package:flutter/foundation.dart';

/// Service for managing app update checks and force/optional update flows.
class AppUpdateService {
  static final AppUpdateService _instance = AppUpdateService._();
  factory AppUpdateService() => _instance;
  AppUpdateService._();

  /// Check if an update is available by comparing against stored config.
  /// In production, this would query Firestore app_settings for the latest version.
  ///
  /// Returns [UpdateInfo] with update status details.
  Future<UpdateInfo> checkForUpdate({
    String? latestVersion,
    bool forceUpdate = false,
    String? updateUrl,
  }) async {
    try {
      const current = AppConstants.appVersion;
      final latest = latestVersion ?? current;

      if (_compareVersions(latest, current) > 0) {
        return UpdateInfo(
          updateAvailable: true,
          latestVersion: latest,
          forceUpdate: forceUpdate,
          updateUrl: updateUrl ?? '',
          currentVersion: current,
        );
      }

      return UpdateInfo(
        updateAvailable: false,
        latestVersion: latest,
        forceUpdate: false,
        currentVersion: current,
      );
    } catch (e) {
      debugPrint('Failed to check for updates: $e');
      return const UpdateInfo(
        updateAvailable: false,
        latestVersion: AppConstants.appVersion,
        currentVersion: AppConstants.appVersion,
      );
    }
  }

  /// Compare two semver strings. Returns positive if v1 > v2.
  int _compareVersions(String v1, String v2) {
    try {
      final parts1 = v1.split('.').map((e) => int.tryParse(e) ?? 0).toList();
      final parts2 = v2.split('.').map((e) => int.tryParse(e) ?? 0).toList();

      for (int i = 0; i < 3; i++) {
        final p1 = i < parts1.length ? parts1[i] : 0;
        final p2 = i < parts2.length ? parts2[i] : 0;
        if (p1 != p2) return p1 - p2;
      }
      return 0;
    } catch (_) {
      return 0;
    }
  }
}

/// Information about an available app update.
class UpdateInfo {
  final bool updateAvailable;
  final String latestVersion;
  final bool forceUpdate;
  final String updateUrl;
  final String currentVersion;

  const UpdateInfo({
    required this.updateAvailable,
    required this.latestVersion,
    this.forceUpdate = false,
    this.updateUrl = '',
    required this.currentVersion,
  });
}
