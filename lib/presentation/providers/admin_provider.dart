import 'dart:async';
import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/data/datasources/admin_firestore_datasource.dart';
import 'package:cashspark/data/datasources/referral_firestore_datasource.dart';
import 'package:cashspark/data/datasources/ticket_firestore_datasource.dart';
import 'package:cashspark/data/models/banner_model.dart';
import 'package:cashspark/data/repositories/support_ticket_repository_impl.dart';
import 'package:cashspark/domain/entities/admin_entity.dart';
import 'package:cashspark/domain/entities/banner_entity.dart';
import 'package:cashspark/domain/entities/chat_message_entity.dart';
import 'package:cashspark/domain/entities/referral_entity.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/domain/entities/user_entity.dart';
import 'package:cashspark/domain/repositories/admin_repository.dart';
import 'package:cashspark/domain/repositories/support_ticket_repository.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

class AdminProvider extends ChangeNotifier {
  final AdminRepository _adminRepository;
  final AdminFirestoreDataSource _adminDataSource;
  final ReferralFirestoreDataSource _referralDataSource;
  final SupportTicketRepository _supportTicketRepo;

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

  // Admin theme state (independent of app theme)
  bool _useDarkTheme = true;

  // System health indicators (simulated for now)
  final bool _systemOnline = true;
  final double _responseTime = 45; // ms
  final int _activeSessions = 12;
  final double _errorRate = 0.3; // %
  DateTime _lastHealthCheck = DateTime.now();

  // AI Insight data
  List<InsightItem> _insights = [];

  // Management data
  List<UserEntity> _users = [];
  List<UserEntity> _searchedUsers = [];
  List<ReferralEntity> _referrals = [];
  List<AdminLogEntity> _adminLogs = [];
  List<BannerEntity> _banners = [];
  List<Map<String, dynamic>> _verificationRequests = [];
  Map<String, dynamic> _adConfig = {};
  AppSettingsEntity? _appSettings;

  // ─── Support / Live Chat ────────────────────────────────
  List<SupportTicketEntity> _supportTickets = [];
  List<ChatMessageEntity> _activeChatMessages = [];
  SupportTicketEntity? _activeChatTicket;
  bool _supportLoading = false;
  int _unreadSupportCount = 0;
  StreamSubscription? _supportTicketSub;
  StreamSubscription? _activeTicketMsgSub;

  AdminProvider({
    required AdminRepository adminRepository,
    AdminFirestoreDataSource? adminDataSource,
    ReferralFirestoreDataSource? referralDataSource,
    SupportTicketRepository? supportTicketRepository,
  })  : _adminRepository = adminRepository,
        _adminDataSource = adminDataSource ?? AdminFirestoreDataSource(),
        _referralDataSource = referralDataSource ?? ReferralFirestoreDataSource(),
        _supportTicketRepo = supportTicketRepository ?? SupportTicketRepositoryImpl(
            dataSource: TicketFirestoreDataSource());

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

  // Admin Theme
  bool get useDarkTheme => _useDarkTheme;
  set useDarkTheme(bool value) {
    _useDarkTheme = value;
    notifyListeners();
  }
  void toggleTheme() {
    _useDarkTheme = !_useDarkTheme;
    notifyListeners();
  }

  // System Health
  bool get systemOnline => _systemOnline;
  double get responseTime => _responseTime;
  int get activeSessions => _activeSessions;
  double get errorRate => _errorRate;
  DateTime get lastHealthCheck => _lastHealthCheck;

  // AI Insights
  List<InsightItem> get insights => _insights;

  // Management
  List<UserEntity> get users => _users;
  List<UserEntity> get searchedUsers => _searchedUsers;
  List<ReferralEntity> get referrals => _referrals;
  List<AdminLogEntity> get adminLogs => _adminLogs;
  List<BannerEntity> get banners => _banners;
  List<Map<String, dynamic>> get verificationRequests => _verificationRequests;
  Map<String, dynamic> get adConfig => _adConfig;
  AppSettingsEntity? get appSettings => _appSettings;

  // Support / Live Chat
  List<SupportTicketEntity> get supportTickets => _supportTickets;
  List<ChatMessageEntity> get activeChatMessages => _activeChatMessages;
  SupportTicketEntity? get activeChatTicket => _activeChatTicket;
  bool get supportLoading => _supportLoading;
  int get unreadSupportCount => _unreadSupportCount;

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
      _lastHealthCheck = DateTime.now();
      _generateInsights();
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
      _refreshUserInList(userId);
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
      _refreshUserInList(userId);
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
      // Update the local user list so the Users tab reflects changes immediately
      final idx = _users.indexWhere((u) => u.uid == userId);
      if (idx != -1) {
        _users[idx] = _users[idx].copyWith(isVerified: true);
      }
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
    _searchedUsers = [];
    _referrals = [];
    _banners = [];
    _verificationRequests = [];
    _adConfig = {};
    _errorMessage = null;
    _successMessage = null;
    // Cancel support subscriptions
    _supportTicketSub?.cancel();
    _activeTicketMsgSub?.cancel();
    _supportTicketSub = null;
    _activeTicketMsgSub = null;
    _supportTickets = [];
    _activeChatMessages = [];
    _activeChatTicket = null;
    _unreadSupportCount = 0;
    notifyListeners();
  }

  /// Generates smart insight suggestions based on dashboard data.
  void _generateInsights() {
    _insights = [];
    if (_dailyUserGrowth.length >= 2) {
      final trend = _dailyUserGrowth.last - _dailyUserGrowth.first;
      if (trend > 0) {
        _insights.add(InsightItem(
          icon: Icons.trending_up_rounded,
          title: 'User growth trending up',
          subtitle: '${((trend / _dailyUserGrowth.first) * 100).toStringAsFixed(0)}% increase this week',
          color: const Color(0xFF22C55E),
        ));
      }
    }
    if (_pendingWithdrawals > 0) {        _insights.add(InsightItem(
          icon: Icons.hourglass_empty_rounded,
          title: '$_pendingWithdrawals withdrawals pending',
          subtitle: 'Process them to keep users happy',
          color: const Color(0xFFF59E0B),
        ));
    }
    if (_totalUsers > 0 && _activeUsers > 0) {
      final conversion = (_activeUsers / _totalUsers * 100);
      if (conversion < 30) {
        _insights.add(InsightItem(
          icon: Icons.people_outline_rounded,
          title: 'Active user rate: ${conversion.toStringAsFixed(0)}%',
          subtitle: 'Consider re-engagement campaigns',
          color: const Color(0xFF3B82F6),
        ));
      }
    }
    final balance = _revenueStats['remainingBalance'] ?? 0;
    if (balance > 10000) {        _insights.add(InsightItem(
          icon: Icons.account_balance_rounded,
          title: 'Platform balance: ₹${Helpers.formatNumber(balance.toInt())}',
          subtitle: 'Revenue is healthy',
          color: const Color(0xFF06B6D4),
        ));
    }
    notifyListeners();
  }

  /// Generates a CSV string of all users for export.
  String exportUsersToCsv() {
    final buffer = StringBuffer();
    buffer.writeln('UID,Name,Email,Phone,Referral Code,Wallet Balance,Total Earnings,Total Withdrawn,Joined,Verified');
    for (final user in _users) {
      buffer.writeln(
        '"${user.uid}",'
        '"${user.fullName}",'
        '"${user.email}",'
        '"${user.phone ?? ''}",'
        '"${user.referralCode}",'
        '${user.walletBalance.toStringAsFixed(2)},'
        '${user.totalEarnings.toStringAsFixed(2)},'
        '${user.totalWithdrawn.toStringAsFixed(2)},'
        '"${Helpers.formatDateTime(user.createdAt)}",'
        '${user.isEmailVerified ? 'Yes' : 'No'}'
      );
    }
    return buffer.toString();
  }

  /// Copies user CSV data to clipboard for pasting into spreadsheet.
  void copyUsersToClipboard() {
    final csv = exportUsersToCsv();
    Clipboard.setData(ClipboardData(text: csv));
    _successMessage = '${_users.length} users copied to clipboard! Paste into any spreadsheet.';
    notifyListeners();
  }

  // ─── Referral Bonus Credit ──────────────────────────────

  /// Credits a referral first-project bonus to the referrer's wallet
  /// and updates the referral record to mark it as rewarded.
  /// Allows custom [amount] and [notes] for flexible admin crediting.
  Future<bool> creditReferralBonus({
    required String referralId,
    required String referrerUserId,
    required String referredUserName,
    double amount = 7.0,
    String notes = '',
  }) async {
    _setLoading(true);
    _clearMessages();
    try {
      final description = notes.isNotEmpty
          ? notes
          : '₹${amount.toStringAsFixed(2)} first-project referral bonus for $referredUserName';

      // 1. Credit the referrer's wallet
      await _adminRepository.creditUserWallet(
        userId: referrerUserId,
        amount: amount,
        description: description,
      );

      // 2. Update the referral record to mark first project as rewarded
      await _referralDataSource.updateReferralReward(referralId, {
        'firstProjectRewarded': true,
        'firstProjectRewardDate': DateTime.now(),
        'rewardAmount': amount,
      });

      // 3. Update local state
      final idx = _referrals.indexWhere((r) => r.referralId == referralId);
      if (idx != -1) {
        _referrals[idx] = _referrals[idx].copyWith(
          firstProjectRewarded: true,
          rewardAmount: amount,
        );
      }

      _successMessage = 'Credited ₹${amount.toStringAsFixed(2)} referral bonus';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to credit referral bonus: $e';
      notifyListeners();
      return false;
    } finally {
      _setLoading(false);
    }
  }

  /// Bulk credits all eligible referral bonuses to their referrers' wallets.
  /// Processes one at a time and reports progress via [onProgress].
  /// Returns a map with 'successCount', 'failCount', and 'total'.
  Future<Map<String, int>> bulkCreditReferralBonuses({
    required List<Map<String, String>> pendingReferrals, // [{referralId, referrerUserId}]
    required double amount,
    required String notes,
    required void Function(int credited, int total) onProgress,
  }) async {
    int successCount = 0;
    int failCount = 0;
    final total = pendingReferrals.length;

    _clearMessages();

    for (int i = 0; i < total; i++) {
      final item = pendingReferrals[i];
      try {
        final description = notes.isNotEmpty
            ? notes
            : 'Bulk first-project referral bonus (₹${amount.toStringAsFixed(2)})';

        // Credit the referrer's wallet
        await _adminRepository.creditUserWallet(
          userId: item['referrerUserId']!,
          amount: amount,
          description: description,
        );

        // Update the referral record
        await _referralDataSource.updateReferralReward(item['referralId']!, {
          'firstProjectRewarded': true,
          'firstProjectRewardDate': DateTime.now(),
          'rewardAmount': amount,
        });

        // Update local state
        final idx = _referrals.indexWhere((r) => r.referralId == item['referralId']);
        if (idx != -1) {
          _referrals[idx] = _referrals[idx].copyWith(
            firstProjectRewarded: true,
            rewardAmount: amount,
          );
        }

        successCount++;
      } catch (e) {
        failCount++;
      }

      onProgress(successCount + failCount, total);
    }

    _successMessage = 'Bulk credited $successCount/$total referrals';
    notifyListeners();
    return {'successCount': successCount, 'failCount': failCount, 'total': total};
  }

  // ─── Support / Live Chat ──────────────────────────────

  /// Starts streaming all support tickets and recent chat messages
  /// for the admin's live chat inbox.
  Future<void> loadSupportTickets() async {
    _supportLoading = true;
    _clearMessages();
    notifyListeners();

    try {
      // Cancel old subscription — don't cancel _activeTicketMsgSub
      // because the admin might be actively viewing a chat
      await _supportTicketSub?.cancel();

      // Stream all tickets for the inbox list
      _supportTicketSub = _supportTicketRepo.streamAllTickets().listen(
        (tickets) {
          _supportTickets = tickets;

          // Compute unread count: tickets with 'open' status
          _unreadSupportCount = tickets
              .where((t) => t.status == TicketStatus.open)
              .length;

          _supportLoading = false;
          notifyListeners();
        },
        onError: (_) {
          _supportLoading = false;
          notifyListeners();
        },
      );
    } catch (e) {
      _supportLoading = false;
      notifyListeners();
    }
  }

  /// Loads chat messages for a specific ticket and sets it as active.
  /// Also marks the ticket as inProgress so the unread badge decreases.
  Future<void> openChatTicket(SupportTicketEntity ticket) async {
    _activeChatTicket = ticket;
    _activeTicketMsgSub?.cancel();

    // Mark as inProgress so the unread badge count decreases
    if (ticket.status == TicketStatus.open) {
      try {
        await _supportTicketRepo.updateTicketStatus(ticket.ticketId, 'inProgress');
      } catch (e) {
        debugPrint('Failed to mark ticket as inProgress: $e');
      }
    }

    _activeTicketMsgSub = _supportTicketRepo.streamMessages(ticket.ticketId).listen(
      (messages) {
        _activeChatMessages = messages;
        notifyListeners();
      },
      onError: (_) {
        notifyListeners();
      },
    );

    notifyListeners();
  }

  /// Closes the active chat view and unsubscribes from its messages.
  void closeChatTicket() {
    _activeChatTicket = null;
    _activeChatMessages = [];
    _activeTicketMsgSub?.cancel();
    _activeTicketMsgSub = null;
    notifyListeners();
  }

  /// Resolves or closes the active chat ticket.
  /// Defaults to 'resolved'; pass 'closed' to permanently close.
  /// Returns false if no ticket is active or if the update fails.
  Future<bool> resolveActiveTicket({String status = 'resolved'}) async {
    if (_activeChatTicket == null) return false;
    try {
      await _supportTicketRepo.updateTicketStatus(
        _activeChatTicket!.ticketId,
        status,
      );
      _successMessage = status == 'closed' ? 'Ticket closed' : 'Ticket resolved';
      notifyListeners();
      return true;
    } catch (e) {
      _errorMessage = 'Failed to update ticket status';
      notifyListeners();
      return false;
    }
  }

  /// Sends an admin reply to the currently active chat ticket.
  Future<bool> sendAdminReply(String text) async {
    if (_activeChatTicket == null) return false;

    try {
      final adminId = _adminProfile?.uid ?? 'admin';
      final adminName = _adminProfile?.fullName ?? 'Support';
      final message = ChatMessageEntity(
        messageId: 'msg_${DateTime.now().millisecondsSinceEpoch}',
        ticketId: _activeChatTicket!.ticketId,
        ticketUserId: _activeChatTicket!.userId,
        senderId: adminId,
        senderName: adminName,
        senderType: MessageSender.admin,
        text: text,
        createdAt: DateTime.now(),
      );
      await _supportTicketRepo.sendMessage(message);
      return true;
    } catch (e) {
      _errorMessage = 'Failed to send reply';
      notifyListeners();
      return false;
    }
  }

  /// Refreshes a single user in the local list after wallet operations
  /// so the Users tab shows updated balances immediately.
  Future<void> _refreshUserInList(String userId) async {
    try {
      final updatedUser = await _adminDataSource.getUser(userId);
      if (updatedUser != null) {
        final idx = _users.indexWhere((u) => u.uid == userId);
        if (idx != -1) {
          _users[idx] = updatedUser;
        }
      }
    } catch (_) {
      // Best-effort — the list will refresh on next loadUsers() call
    }
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

/// A data class for AI-generated insight cards on the dashboard.
class InsightItem {
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;

  const InsightItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
  });
}
