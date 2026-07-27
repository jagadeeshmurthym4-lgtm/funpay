import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service for monitoring network connectivity and managing offline state.
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._();
  factory ConnectivityService() => _instance;
  ConnectivityService._();

  final Connectivity _connectivity = Connectivity();
  final StreamController<bool> _connectionStatusController =
      StreamController<bool>.broadcast();

  bool _isConnected = true;
  StreamSubscription? _subscription;

  /// Whether the device currently has network connectivity
  bool get isConnected => _isConnected;

  /// Stream that emits connectivity changes (true = connected, false = offline)
  Stream<bool> get onConnectionChanged => _connectionStatusController.stream;

  /// Initialize connectivity monitoring
  Future<void> initialize() async {
    try {
      final result = await _connectivity.checkConnectivity();
      _isConnected = !result.contains(ConnectivityResult.none);
      _connectionStatusController.add(_isConnected);

      _subscription = _connectivity.onConnectivityChanged.listen((results) {
        _isConnected = !results.contains(ConnectivityResult.none);
        _connectionStatusController.add(_isConnected);
        debugPrint(
            'Connectivity changed: ${_isConnected ? "online" : "offline"}');
      });
    } catch (e) {
      debugPrint('Failed to initialize connectivity: $e');
      _isConnected = true; // Assume connected on error
    }
  }

  /// Dispose cleanup
  void dispose() {
    _subscription?.cancel();
    _connectionStatusController.close();
  }
}
