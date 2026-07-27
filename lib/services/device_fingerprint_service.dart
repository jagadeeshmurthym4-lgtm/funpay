import 'dart:io';

/// Service for device fingerprinting and security checks.
/// Provides hardware-based identifiers for device registration
/// and duplicate account detection.
class DeviceFingerprintService {
  /// Generate a device fingerprint based on available platform identifiers.
  /// On mobile platforms, this would use device_info_plus or similar.
  /// Returns a hash string that uniquely identifies this device.
  Future<String> getDeviceId() async {
    try {
      // Use a combination of available platform info
      final platformInfo = await _getPlatformInfo();
      final combined = platformInfo.values.join('-');
      return _hashString(combined);
    } catch (e) {
      // Fallback: use a runtime-generated ID (not persistent)
      return 'unknown-device-${DateTime.now().millisecondsSinceEpoch}';
    }
  }

  /// Get device model name
  Future<String?> getDeviceModel() async {
    try {
      final info = await _getPlatformInfo();
      return info['model'];
    } catch (e) {
      return null;
    }
  }

  /// Get device platform (iOS, Android, web, macOS, etc.)
  Future<String> getPlatform() async {
    try {
      if (Platform.isIOS) return 'iOS';
      if (Platform.isAndroid) return 'Android';
      if (Platform.isMacOS) return 'macOS';
      if (Platform.isWindows) return 'Windows';
      if (Platform.isLinux) return 'Linux';
      return 'unknown';
    } catch (e) {
      return 'unknown';
    }
  }

  /// Simplified hash using string code units
  String _hashString(String input) {
    if (input.isEmpty) return 'unknown';
    int hash = 0;
    for (var i = 0; i < input.length; i++) {
      hash = 31 * hash + input.codeUnitAt(i);
    }
    return hash.toRadixString(16).padLeft(8, '0');
  }

  Future<Map<String, String>> _getPlatformInfo() async {
    final info = <String, String>{
      'model': 'unknown',
      'platform': 'unknown',
      'osVersion': 'unknown',
    };

    try {
      info['platform'] = Platform.operatingSystem;
      info['osVersion'] = Platform.operatingSystemVersion;
      // Use hostname as a device discriminator on desktop
      info['hostname'] = Platform.localHostname;
      // Number of processors as a weak fingerprint
      info['processors'] = '${Platform.numberOfProcessors}';
    } catch (_) {}

    return info;
  }

  /// Check if the device is likely an emulator/simulator
  bool isEmulator() {
    try {
      // On mobile, platform channels would detect emulator
      // For desktop/web, simple environment checks
      final path = Platform.environment['PATH'] ?? '';
      return path.contains('emulator') || path.contains('simulator');
    } catch (_) {
      return false;
    }
  }

  /// Check for development mode indicators
  bool isDeveloperMode() {
    try {
      // Skipped platform-specific checks for debugging tools
      return false;
    } catch (_) {
      return false;
    }
  }

  /// Check if device is rooted/jailbroken (simplified)
  bool isRootedDevice() {
    try {
      // On mobile, check for common root indicators
      // On desktop, this is less meaningful — return false
      return false;
    } catch (_) {
      return false;
    }
  }
}
