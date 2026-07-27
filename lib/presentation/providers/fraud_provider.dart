import 'package:cashspark/data/repositories/fraud_repository_impl.dart';
import 'package:cashspark/domain/entities/fraud_report_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/services/device_fingerprint_service.dart';
import 'package:cashspark/services/network_security_service.dart';
import 'package:flutter/foundation.dart';

class FraudProvider extends ChangeNotifier {
  final FraudRepositoryImpl _fraudRepository;
  final DeviceFingerprintService _deviceFingerprintService;
  final NetworkSecurityService _networkSecurityService;

  bool _isLoading = false;
  String? _errorMessage;
  String? _successMessage;

  // Device info
  String _deviceId = '';
  String? _deviceModel;
  String _platform = '';

  // Fraud reports & flagged users
  List<FraudReportEntity> _fraudReports = [];
  List<FraudReportEntity> _flaggedReports = [];
  List<UserEntity> _flaggedUsers = [];
  List<UserEntity> _allUsers = [];

  // Network security
  bool _isVpnActive = false;
  bool _isProxyDetected = false;
  double _networkRiskScore = 0.0;

  // Summary stats
  int _totalFraudReports = 0;
  int _highRiskUsers = 0;
  int _mediumRiskUsers = 0;
  int _lowRiskUsers = 0;
  int _confirmedFraud = 0;

  FraudProvider({
    required FraudRepositoryImpl fraudRepository,
    DeviceFingerprintService? deviceFingerprintService,
    NetworkSecurityService? networkSecurityService,
  })  : _fraudRepository = fraudRepository,
        _deviceFingerprintService =
            deviceFingerprintService ?? DeviceFingerprintService(),
        _networkSecurityService =
            networkSecurityService ?? NetworkSecurityService();

  // Getters
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;
  String get deviceId => _deviceId;
  String? get deviceModel => _deviceModel;
  String get platform => _platform;
  List<FraudReportEntity> get fraudReports => _fraudReports;
  List<FraudReportEntity> get flaggedReports => _flaggedReports;
  List<UserEntity> get flaggedUsers => _flaggedUsers;
  List<UserEntity> get allUsers => _allUsers;
  bool get isVpnActive => _isVpnActive;
  bool get isProxyDetected => _isProxyDetected;
  double get networkRiskScore => _networkRiskScore;
  int get totalFraudReports => _totalFraudReports;
  int get highRiskUsers => _highRiskUsers;
  int get mediumRiskUsers => _mediumRiskUsers;
  int get lowRiskUsers => _lowRiskUsers;
  int get confirmedFraud => _confirmedFraud;

  int get totalFlaggedUsers => _flaggedReports.length;
  int get pendingReviewCount =>
      _flaggedReports.where((r) => r.status == FraudStatus.underReview).length;

  /// Initialize device fingerprint and run security checks
  Future<void> initializeDevice() async {
    try {
      _deviceId = await _deviceFingerprintService.getDeviceId();
      _deviceModel = await _deviceFingerprintService.getDeviceModel();
      _platform = await _deviceFingerprintService.getPlatform();
      notifyListeners();
    } catch (_) {}
  }

  /// Perform network security checks
  Future<void> checkNetworkSecurity() async {
    try {
      _isVpnActive = await _networkSecurityService.isVpnActive();
      _isProxyDetected = await _networkSecurityService.isProxyDetected();
      _networkRiskScore = await _networkSecurityService.calculateNetworkRiskScore();
      notifyListeners();
    } catch (_) {}
  }

  /// Register the current device for a user
  Future<void> registerDevice(String userId) async {
    if (_deviceId.isEmpty) await initializeDevice();
    try {
      await _fraudRepository.registerDevice(
        deviceId: _deviceId,
        userId: userId,
        deviceModel: _deviceModel,
        devicePlatform: _platform,
      );
    } catch (_) {}
  }

  /// Check if device is already registered with another account
  Future<bool> isDeviceRegisteredElsewhere(String userId) async {
    if (_deviceId.isEmpty) return false;
    try {
      final owner = await _fraudRepository.getDeviceOwner(_deviceId);
      return owner != null && owner.userId != userId;
    } catch (e) {
      return false;
    }
  }

  /// Load flagged users from fraud reports
  Future<void> loadFlaggedUsers() async {
    _setLoading(true);
    _clearMessages();
    try {
      _flaggedReports = await _fraudRepository.getFlaggedUsers();
      _flaggedUsers = await _fraudRepository.getFlaggedUserProfiles();
      _computeStats();
    } catch (e) {
      _errorMessage = 'Failed to load flagged users';
    } finally {
      _setLoading(false);
    }
  }

  /// Load all fraud reports
  Future<void> loadFraudReports() async {
    _setLoading(true);
    _clearMessages();
    try {
      _fraudReports = await _fraudRepository.getFraudReports();
    } catch (e) {
      _errorMessage = 'Failed to load fraud reports';
    } finally {
      _setLoading(false);
    }
  }

  /// Load all users (for admin review)
  Future<void> loadAllUsers() async {
    _setLoading(true);
    _clearMessages();
    try {
      _allUsers = await _fraudRepository.getFlaggedUserProfiles();
    } catch (e) {
      _errorMessage = 'Failed to load users';
    } finally {
      _setLoading(false);
    }
  }

  /// Flag a user for suspicious activity
  Future<bool> flagUser({
    required String userId,
    required String reason,
    required RiskLevel riskLevel,
    required double fraudScore,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _fraudRepository.flagUser(
        userId: userId,
        reason: reason,
        riskLevel: riskLevel,
        fraudScore: fraudScore,
      );
      _successMessage = 'User flagged successfully';
      await loadFlaggedUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to flag user';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unflag a user
  Future<bool> unflagUser(String userId) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _fraudRepository.unflagUser(userId);
      _successMessage = 'User unflagged successfully';
      await loadFlaggedUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to unflag user';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Update fraud report status (confirm/dismiss)
  Future<bool> updateFraudReportStatus({
    required String reportId,
    required FraudStatus status,
    String? adminNotes,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _fraudRepository.updateFraudReportStatus(
        reportId: reportId,
        status: status,
        adminNotes: adminNotes,
      );
      _successMessage = status == FraudStatus.confirmed
          ? 'Fraud confirmed'
          : 'Fraud report dismissed';
      await loadFlaggedUsers();
      await loadFraudReports();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update report';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Lock a user's account
  Future<bool> lockAccount(String userId) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _fraudRepository.lockAccount(userId);
      _successMessage = 'Account locked';
      await loadFlaggedUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to lock account';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Unlock a user's account
  Future<bool> unlockAccount(String userId) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _fraudRepository.unlockAccount(userId);
      _successMessage = 'Account unlocked';
      await loadFlaggedUsers();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to unlock account';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Check if a user ID has high risk level
  Future<RiskLevel> getUserRiskLevel(String userId) async {
    try {
      return await _fraudRepository.getUserRiskLevel(userId);
    } catch (e) {
      return RiskLevel.low;
    }
  }

  /// Get fraud score for a user
  Future<double> getUserFraudScore(String userId) async {
    try {
      return await _fraudRepository.getUserFraudScore(userId);
    } catch (e) {
      return 0.0;
    }
  }

  /// Detect self-referral
  Future<bool> detectSelfReferral(String userId, String referredUserId) async {
    return await _fraudRepository.detectSelfReferral(userId, referredUserId);
  }

  /// Check if referral is suspicious
  Future<bool> isSuspiciousReferral(String userId) async {
    return await _fraudRepository.detectSuspiciousActivity(userId);
  }

  void _computeStats() {
    _totalFraudReports = _flaggedReports.length;
    _highRiskUsers =
        _flaggedReports.where((r) => r.riskLevel == RiskLevel.high).length;
    _mediumRiskUsers =
        _flaggedReports.where((r) => r.riskLevel == RiskLevel.medium).length;
    _lowRiskUsers =
        _flaggedReports.where((r) => r.riskLevel == RiskLevel.low).length;
    _confirmedFraud =
        _flaggedReports.where((r) => r.status == FraudStatus.confirmed).length;
  }

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
