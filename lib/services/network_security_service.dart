import 'dart:io';

/// Service for network security checks including VPN, proxy,
/// and other connection-based fraud indicators.
class NetworkSecurityService {
  /// Check if the device is connected through a VPN
  Future<bool> isVpnActive() async {
    try {
      // On mobile, check network interfaces for VPN tunnel adapters
      final interfaces = await _getNetworkInterfaces();
      return interfaces.any((iface) =>
          iface.toLowerCase().contains('tun') ||
          iface.toLowerCase().contains('tap') ||
          iface.toLowerCase().contains('ppp') ||
          iface.toLowerCase().contains('vpn') ||
          iface.toLowerCase().contains('utun'));
    } catch (_) {
      return false;
    }
  }

  /// Check if the device is behind a proxy
  Future<bool> isProxyDetected() async {
    try {
      // Check common proxy environment variables
      final envVars = Platform.environment;
      return envVars.containsKey('http_proxy') ||
          envVars.containsKey('https_proxy') ||
          envVars.containsKey('HTTP_PROXY') ||
          envVars.containsKey('HTTPS_PROXY') ||
          envVars.containsKey('ALL_PROXY') ||
          envVars.containsKey('all_proxy');
    } catch (_) {
      return false;
    }
  }

  /// Get the device's public IP (would need an external API in production)
  Future<String?> getPublicIp() async {
    try {
      // In production, call an external IP detection API
      // For now, return local network info
      final interfaces = await _getNetworkInterfaces();
      return interfaces.isNotEmpty ? interfaces.first : null;
    } catch (_) {
      return null;
    }
  }

  /// Calculate a network risk score (0.0 - 1.0)
  Future<double> calculateNetworkRiskScore() async {
    double score = 0.0;

    if (await isVpnActive()) score += 0.4;
    if (await isProxyDetected()) score += 0.3;

    return score.clamp(0.0, 1.0);
  }

  Future<List<String>> _getNetworkInterfaces() async {
    try {
      return NetworkInterface.list().then((interfaces) =>
          interfaces.map((i) => i.name).toList());
    } catch (_) {
      return [];
    }
  }
}
