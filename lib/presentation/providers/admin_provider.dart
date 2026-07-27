import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/models/banner_model.dart';
import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/entities/banner_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/admin_repository.dart';
import 'package:flutter/foundation.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository;
  final AdminFirestoreDataSource _adminDataSource;

  bool _isAdmin = false;
  AdminEntity? _adminProfile;
  bool _isLoading = false;
  bool _isVerifying = false;
  String? _errorMessage;
  String? _successMessage;

  // Dashboard stats
  int _totalUsers = 0;
  int _activeUsers = 0;
  double _totalEarnings = 0.0;
  double _totalWithdrawn = 0.0;
  int _pendingWithdrawals = 0;
  int _totalReferrals = 0;
  List<int> _dailyUserGrowth = [];
  Map<String, double> _revenueStats = {};

  // Management data
  List<UserEntity> _users = [];
  List<UserEntity> _searchedUsers = [];
  List<ReferralEntity> _referrals = [];
  List<AdminLogEntity> _adminLogs = [];
  List<BannerEntity> _banners = [];
  List<Map<String, dynamic>> _verificationRequests = [];
  Map<String, dynamic> _adConfig = {};
  AppSettingsEntity? _appSettings;

  AdminProvider({
    required AdminRepository adminRepository,
    AdminFirestoreDataSource? adminDataSource,
  })  : _adminRepository = adminRepository,
        _adminDataSource = adminDataSource ?? AdminFirestoreDataSource();

  bool get isAdmin => _isAdmin;
  AdminEntity? get adminProfile => _adminProfile;
  bool get isLoading => _isLoading;
  bool get isVerifying => _isVerifying;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  // Dashboard
  int get totalUsers => _totalUsers;
  int get activeUsers => _activeUsers;
  double get totalEarnings => _totalEarnings;
  double get totalWithdrawn => _totalWithdrawn;
  int get pendingWithdrawals => _pendingWithdrawals;
  int get totalReferrals => _totalReferrals;
  List<int> get dailyUserGrowth => _dailyUserGrowth;
  Map<String, double> get revenueStats => _revenueStats;

  // Management
  List<UserEntity> get users => _users;
  List<UserEntity> get searchedUsers => _searchedUsers;
  List<ReferralEntity> get referrals => _referrals;
  List<AdminLogEntity> get adminLogs => _adminLogs;
  List<BannerEntity> get banners => _banners;
  List<Map<String, dynamic>> get verificationRequests => _verificationRequests;
  Map<String, dynamic> get adConfig => _adConfig;
  AppSettingsEntity? get appSettings => _appSettings;

  Future<bool> verifyAdminAccess(String uid, {String? email}) async {
    _isVerifying = true;
    _clearMessages();
    notifyListeners();
    try {
      // Check by UID first
      _isAdmin = await _adminRepository.isAdmin(uid);

      if (_isAdmin) {
        _adminProfile = await _adminRepository.getAdmin(uid);
        await _adminRepository.recordAdminLogin(uid);
      } else if (email != null) {
        // If not found by UID, try by email (handles re-auth with different provider)
        final adminByEmail = await _adminDataSource.getAdminByEmail(email);
        if (adminByEmail != null && adminByEmail.isActive) {
          _isAdmin = true;
          _adminProfile = adminByEmail;
          // Use the original admin UID for login tracking
          await _adminRepository.recordAdminLogin(adminByEmail.uid);
        }
      }

notifyListeners();
      return _isAdmin;
    } catch (e) {
      _isAdmin = false;
      _errorMessage = 'Failed to verify admin access';
      notifyListeners();
      return false;
    } finally {
      _isVerifying = false;
      notifyListeners();
    }
  }

  Future<void> loadDashboard() async {
    _setLoading(true);
    _clearMessages();
    try {
      _totalUsers = await _adminRepository.getTotalUsers();
      _activeUsers = await _adminRepository.getActiveUsers();
      _totalEarnings = await _adminRepository.getTotalEarnings();
      _totalWithdrawn = await _adminRepository.getTotalWithdrawn();
      _pendingWithdrawals = await _adminRepository.getPendingWithdrawalsCount();
      _totalReferrals = await _adminRepository.getTotalReferrals();
      _dailyUserGrowth = await _adminRepository.getDailyUserGrowth();
      _revenueStats = await _adminRepository.getRevenueStats();
    } catch (e) {
      _errorMessage = 'Failed to load dashboard';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadUsers() async {
    _setLoading(true);
    _clearMessages();
    try {
      _users = await _adminRepository.getAllUsers();
    } catch (e) {
      _errorMessage = 'Failed to load users';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchedUsers = [];
      notifyListeners();
      return;
    }
    _setLoading(true);
    _clearMessages();
    try {
      _searchedUsers = await _adminRepository.searchUsers(query);
    } catch (e) {
      _errorMessage = 'Search failed';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadReferrals() async {
    _setLoading(true);
    _clearMessages();
    try {
      _referrals = await _adminRepository.getAllReferrals();
    } catch (e) {
      _errorMessage = 'Failed to load referrals';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAppSettings() async {
    _setLoading(true);
    _clearMessages();
    try {
      _appSettings = await _adminRepository.getAppSettings();
    } catch (e) {
      _errorMessage = 'Failed to load settings';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> creditUserWallet({
    required String userId,
    required double amount,
    required String description,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _adminRepository.creditUserWallet(
        userId: userId,
        amount: amount,
        description: description,
      );
      _successMessage = 'Credited ₹${amount.toStringAsFixed(2)} to user';
      notifyListeners();
      return true;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to credit wallet';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> debitUserWallet({
    required String userId,
    required double amount,
    required String description,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _adminRepository.debitUserWallet(
        userId: userId,
        amount: amount,
        description: description,
      );
      _successMessage = 'Debited ₹${amount.toStringAsFixed(2)} from user';
      notifyListeners();
      return true;
    } on AdminException catch (e) {
      _errorMessage = e.message;
      return false;
    } on FirestoreException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Failed to debit wallet';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> saveSettings(AppSettingsEntity settings) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _adminRepository.updateAppSettings(settings);
      _appSettings = settings;
      _successMessage = 'Settings saved';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save settings';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> sendAnnouncement(String message) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _adminRepository.sendAnnouncement(message);
      _successMessage = 'Announcement sent';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send announcement';
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadAdminLogs() async {
    _setLoading(true);
    _clearMessages();
    try {
      _adminLogs = await _adminRepository.getAdminLogs();
    } catch (e) {
      _errorMessage = 'Failed to load admin logs';
    } finally {
      _setLoading(false);
    }
  }

  // ─── Banner Management ────────────────────────────────────

  Future<void> loadBanners() async {
    _setLoading(true);
    _clearMessages();
    try {
      _banners = await _adminDataSource.getBanners();
    } catch (e) {
      _errorMessage = 'Failed to load banners';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> createBanner({
    required String title,
    required String subtitle,
    required String imageUrl,
    String? linkUrl,
    String? actionLabel,
    int sortOrder = 0,
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      final bannerId = 'bnr_${DateTime.now().millisecondsSinceEpoch}';
      final banner = BannerEntity(
        bannerId: bannerId,
        title: title,
        subtitle: subtitle,
        imageUrl: imageUrl,
        linkUrl: linkUrl,
        actionLabel: actionLabel,
        sortOrder: sortOrder,
        isActive: true,
        createdAt: DateTime.now(),
      );
      await _adminDataSource.createBanner(BannerModel.fromEntity(banner));
      _banners.insert(0, banner);
      _successMessage = 'Banner created!';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to create banner';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> toggleBanner(String bannerId, bool isActive) async {
    _clearMessages();
    try {
      final idx = _banners.indexWhere((b) => b.bannerId == bannerId);
      if (idx == -1) return false;
      final updated = _banners[idx].copyWith(isActive: isActive);
      await _adminDataSource.updateBanner(BannerModel.fromEntity(updated));
      _banners[idx] = updated;
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to toggle banner';
      notifyListeners();
      return false;
    }
  }

  Future<bool> deleteBanner(String bannerId) async {
    _clearMessages();
    try {
      await _adminDataSource.deleteBanner(bannerId);
      _banners.removeWhere((b) => b.bannerId == bannerId);
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to delete banner';
      notifyListeners();
      return false;
    }
  }

  // ─── Verification Requests ────────────────────────────────

  Future<void> loadVerificationRequests() async {
    _setLoading(true);
    _clearMessages();
    try {
      _verificationRequests = await _adminDataSource.getVerificationRequests();
    } catch (e) {
      _errorMessage = 'Failed to load verification requests';
    } finally {
      _setLoading(false);
    }
  }

  Future<bool> approveVerification(String requestId, String userId) async {
    _clearMessages();
    try {
      final adminUid = _adminProfile?.uid ?? 'admin';
      await _adminDataSource.updateVerificationRequestStatus(
          requestId, 'approved', adminUid);
      await _adminDataSource.updateUser({'isVerified': true}, userId);
      _verificationRequests.removeWhere((r) => r['requestId'] == requestId);
      _successMessage = 'User verified';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to approve verification';
      notifyListeners();
      return false;
    }
  }

  Future<bool> rejectVerification(String requestId) async {
    _clearMessages();
    try {
      final adminUid = _adminProfile?.uid ?? 'admin';
      await _adminDataSource.updateVerificationRequestStatus(
          requestId, 'rejected', adminUid);
      _verificationRequests.removeWhere((r) => r['requestId'] == requestId);
      _successMessage = 'Request rejected';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to reject request';
      notifyListeners();
      return false;
    }
  }

  // ─── Ad Config ────────────────────────────────────────────

  Future<void> loadAdConfig() async {
    _clearMessages();
    try {
      final config = await _adminDataSource.getAdConfig();
      if (config != null) {
        _adConfig = config;
      } else {
        _adConfig = _defaultAdConfig();
      }
      notifyListeners();
    } catch (e) {
      _adConfig = _defaultAdConfig();
      notifyListeners();
    }
  }

  Future<bool> saveAdConfig(Map<String, dynamic> config) async {
    _setLoading(true);
    _clearMessages();
    try {
      await _adminDataSource.saveAdConfig(config);
      _adConfig = config;
      _successMessage = 'Ad configuration saved';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to save ad config';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  Map<String, dynamic> _defaultAdConfig() {
    return {
      'interstitialEnabled': true,
      'bannerAdsEnabled': true,
      'rewardedAdEnabled': true,
      'interstitialInterval': 3,
      'maxBannerPerPage': 2,
      'adRewardAmount': 0.50,
      'showAdsOnHome': true,
      'showAdsOnOffers': true,
      'minRewardForAd': 0.10,
    };
  }

  void clearError() {
    _clearMessages();
  }

  void clearSuccess() {
    _successMessage = null;
    notifyListeners();
  }

  void signOut() {
    _isAdmin = false;
    _adminProfile = null;
    _users = [];
    _referrals = [];
    _searchedUsers = [];
    _banners = [];
    _verificationRequests = [];
    _adConfig = {};
    _errorMessage = null;
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
