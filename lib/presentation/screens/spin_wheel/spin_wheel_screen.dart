import 'dart:async';
import 'dart:math' as math;
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/data/models/spin_data_model.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/reward_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';

class SpinWheelScreen extends StatefulWidget {
  const SpinWheelScreen({super.key});

  @override
  State<SpinWheelScreen> createState() => _SpinWheelScreenState();
}

class _SpinWheelScreenState extends State<SpinWheelScreen>
    with TickerProviderStateMixin {
  late AnimationController _spinController;
  late Animation<double> _spinAnimation;
  late AnimationController _spinGlowController;
  late Animation<double> _spinGlowAnimation;
  late AnimationController _popupController;
  late Animation<double> _popupAnimation;

  double _currentAngle = 0.0;
  double _targetAngle = 0.0;
  bool _isSpinning = false;
  bool _showResult = false;
  bool _isProcessing = false;
  int _winningIndex = -1;
  final _random = math.Random();

  // Firestore stream subscription for real-time spin data sync
  StreamSubscription<SpinDataEntity?>? _spinDataSubscription;

  // Spin lock to prevent race conditions / duplicate spins
  bool _isSaving = false;

  // Persisted spin data — kept in sync via Firestore stream
  SpinDataEntity? _spinData;
  bool _isLoadingData = true;
  String? _errorMessage;
  bool _hasError = false;


  // Daily limit
  static const int _dailyLimit = 3;
  static const String _spinCacheKey = 'cached_spin_data';

  // 8 segments: 0 pts, 1 pts, 2 pts, 5 pts (each duplicated)
  final List<_Segment> _segments = [
    const _Segment('0 pts', 0.0, Color(0xFF64748B)),
    const _Segment('1 pts', 1.0, Color(0xFFFF6B6B)),
    const _Segment('2 pts', 2.0, Color(0xFF4ECDC4)),
    const _Segment('5 pts', 5.0, Color(0xFFFFD93D)),
    _Segment('0 pts', 0.0, const Color(0xFF64748B).withValues(alpha: 0.7)),
    _Segment('1 pts', 1.0, const Color(0xFFFF6B6B).withValues(alpha: 0.85)),
    _Segment('2 pts', 2.0, const Color(0xFF4ECDC4).withValues(alpha: 0.85)),
    _Segment('5 pts', 5.0, const Color(0xFFFFD93D).withValues(alpha: 0.85)),
  ];

  int get _spinsToday => _spinData?.spinsToday ?? 0;
  int get _totalSpins => _spinData?.totalSpins ?? 0;
  int get _bonusSpins => _spinData?.bonusSpins ?? 0;
  int get _freeSpinsRemaining => (_dailyLimit - _spinsToday).clamp(0, _dailyLimit);
  int get _spinsRemaining => _freeSpinsRemaining + _bonusSpins;
  bool get _hasFreeSpinsLeft => _spinsToday < _dailyLimit;
  bool get _canSpin =>
      !_isSpinning && !_isSaving && _spinsRemaining > 0 && !_hasError && !_isLoadingData;
  bool _isWatchingAd = false;

  @override
  void initState() {
    super.initState();

    _spinController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    );
    _spinAnimation = CurvedAnimation(
      parent: _spinController,
      curve: Curves.easeOutCubic,
    );
    _spinController.addListener(() {
      if (!mounted) return;
      setState(() {
        _currentAngle = _targetAngle * _spinAnimation.value;
      });
    });
    _spinController.addStatusListener((status) {
      if (status == AnimationStatus.completed) {
        _onSpinComplete();
      }
    });

    _spinGlowController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _spinGlowAnimation = Tween<double>(begin: 0.6, end: 1.0).animate(
      CurvedAnimation(parent: _spinGlowController, curve: Curves.easeInOut),
    );

    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _popupAnimation = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOutBack,
    );

    // Load cached data immediately, then subscribe to real-time stream
    WidgetsBinding.instance.addPostFrameCallback((_) => _initializeSpinData());
  }

  @override
  void dispose() {
    _spinDataSubscription?.cancel();
    _spinController.dispose();
    _spinGlowController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  String get _userId {
    try {
      return context.read<AuthProvider>().user?.uid ?? '';
    } catch (_) {
      return '';
    }
  }

  /// Initialize spin data: load cached data instantly, then subscribe to Firestore stream.
  Future<void> _initializeSpinData() async {
    final userId = _userId;
    if (userId.isEmpty) {
      if (!mounted) return;
      setState(() {
        _isLoadingData = false;
        _hasError = true;
        _errorMessage = 'User not authenticated';
      });
      return;
    }

    // 1. Load cached data from SharedPreferences for instant display
    await _loadCachedSpinData(userId);

    // 2. Subscribe to Firestore real-time stream for live sync
    _subscribeToSpinData(userId);
  }

  /// Subscribe to the Firestore stream for real-time spin data updates.
  void _subscribeToSpinData(String userId) {
    _spinDataSubscription?.cancel();

    try {
      final rewardProvider = context.read<RewardProvider>();
      _spinDataSubscription = rewardProvider
          .streamSpinData(userId)
          .listen((SpinDataEntity? data) {
        if (!mounted) return;
        _onSpinDataReceived(data, userId);
      }, onError: (Object error) {
        if (!mounted) return;
        // Stream error — fall back to cached data if we have it
        if (_spinData == null) {
          setState(() {
            _hasError = true;
            _isLoadingData = false;
            _errorMessage = 'Connection error. Please try again.';
          });
        }
      });
    } catch (e) {
      // Provider unavailable — try one-time fetch instead
      _fetchSpinDataOnce(userId);
    }
  }

  /// Handle incoming spin data from the Firestore stream.
  Future<void> _onSpinDataReceived(SpinDataEntity? data, String userId) async {
    if (data != null) {
      // Check for daily reset using lastResetDate
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final resetDay = DateTime(
        data.lastResetDate.year,
        data.lastResetDate.month,
        data.lastResetDate.day,
      );

      if (resetDay.isBefore(today)) {
        // New day — reset daily counter, bonus spins, and lastResetDate
        final resetData = data.copyWith(
          spinsToday: 0,
          bonusSpins: 0,
          lastResetDate: now,
          lastSpinDate: now,
        );
        try {
          await context.read<RewardProvider>().saveSpinData(resetData);
        } catch (_) {
          // Save failed, still update local state
        }
        setState(() {
          _spinData = resetData;
          _isLoadingData = false;
          _hasError = false;
          _errorMessage = null;
        });
        await _cacheSpinDataLocally(resetData);
      } else {
        setState(() {
          _spinData = data;
          _isLoadingData = false;
          _hasError = false;
          _errorMessage = null;
        });
        await _cacheSpinDataLocally(data);
      }
    } else {
      // No data yet — create initial record
      final initialData = SpinDataEntity(
        userId: userId,
        lastSpinDate: DateTime.now(),
        lastResetDate: DateTime.now(),
      );
      try {
        await context.read<RewardProvider>().saveSpinData(initialData);
      } catch (_) {
        // Save may fail offline — use locally
      }
      if (!mounted) return;
      setState(() {
        _spinData = initialData;
        _isLoadingData = false;
        _hasError = false;
        _errorMessage = null;
      });
      await _cacheSpinDataLocally(initialData);
    }
  }

  /// Fallback: one-time fetch if stream is unavailable.
  Future<void> _fetchSpinDataOnce(String userId) async {
    try {
      final rewardProvider = context.read<RewardProvider>();
      final data = await rewardProvider.getSpinData(userId);
      if (!mounted) return;
      await _onSpinDataReceived(data, userId);
    } catch (e) {
      if (!mounted) return;
      // Already have cached data — use it
      if (_spinData != null) {
        setState(() {
          _isLoadingData = false;
        });
        return;
      }
      setState(() {
        _isLoadingData = false;
        _hasError = true;
        _errorMessage = 'Failed to load spin data';
      });
    }
  }

  /// Load cached spin data from SharedPreferences for instant display.
  Future<void> _loadCachedSpinData(String userId) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final cached = prefs.getString('${_spinCacheKey}_$userId');
      if (cached != null && cached.isNotEmpty) {
        final json = jsonDecode(cached) as Map<String, dynamic>;
        final cachedData = SpinDataModel.fromFirestore(json);
        if (!mounted) return;
        setState(() {
          _spinData = cachedData;
        });
      }
    } catch (_) {
      // Cache miss or parse error — will load from Firebase
    }
  }

  /// Cache current spin data locally for offline resilience.
  Future<void> _cacheSpinDataLocally(SpinDataEntity data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final model = SpinDataModel.fromEntity(data);
      await prefs.setString(
        '${_spinCacheKey}_${data.userId}',
        jsonEncode(model.toFirestore()),
      );
    } catch (_) {
      // Cache write failure is non-critical
    }
  }

  /// Determine reward: 0 pts=20%, 1 pts=30%, 2 pts=30%, 5 pts=20%
  int _determineRewardIndex() {
    final roll = _random.nextDouble();
    if (roll < 0.20) {
      // 0 pts – pick between index 0 and 4
      return _random.nextBool() ? 0 : 4;
    } else if (roll < 0.50) {
      // 1 pts – pick between index 1 and 5
      return _random.nextBool() ? 1 : 5;
    } else if (roll < 0.80) {
      // 2 pts – pick between index 2 and 6
      return _random.nextBool() ? 2 : 6;
    } else {
      // 5 pts – pick between index 3 and 7
      return _random.nextBool() ? 3 : 7;
    }
  }

  void _spin() {
    // Double-check lock: prevent duplicate spins from rapid button taps
    if (!_canSpin || _isSaving) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _isSpinning = true;
      _showResult = false;
      _winningIndex = -1;
    });

    // Determine reward
    _winningIndex = _determineRewardIndex();

    // Calculate angle to land on winning segment
    final segmentAngle = (2 * math.pi) / _segments.length;
    final offset = _random.nextDouble() * segmentAngle * 0.6;
    final fullRotations = 5 + _totalSpins % 4;
    _targetAngle = _currentAngle +
        fullRotations * 2 * math.pi +
        (2 * math.pi - _winningIndex * segmentAngle - offset - segmentAngle * 0.2);

    _spinController.reset();
    _spinController.forward();
  }

  void _onSpinComplete() async {
    HapticFeedback.mediumImpact();
    SystemSound.play(SystemSoundType.click);

    setState(() {
      _isSpinning = false;
      _showResult = true;
      _isProcessing = true;
    });

    _popupController.reset();
    _popupController.forward();

    // Credit reward and save spin data atomically
    await _creditAndSave();

    if (!mounted) return;
    setState(() => _isProcessing = false);
  }

  Future<void> _creditAndSave() async {
    final segment = _segments[_winningIndex];
    final amount = segment.value;
    final uid = _userId;
    if (uid.isEmpty) return;

    // Prevent concurrent saves (race condition guard)
    if (_isSaving) return;
    _isSaving = true;

    try {
      final rewardProvider = context.read<RewardProvider>();
      final walletProvider = context.read<WalletProvider>();
      final now = DateTime.now();

      // Build updated spin data with history entry
      final currentHistory = List<SpinHistoryEntry>.from(
        _spinData?.spinHistory ?? []);
      // Keep last 50 entries to avoid excessive Firestore document size
      if (currentHistory.length >= 50) {
        currentHistory.removeAt(0);
      }
      currentHistory.add(SpinHistoryEntry(
        amount: amount,
        timestamp: now,
      ));

      // If free spins are exhausted, consume a bonus spin
      final int newBonusSpins;
      if (!_hasFreeSpinsLeft && _bonusSpins > 0) {
        newBonusSpins = _bonusSpins - 1;
      } else {
        newBonusSpins = _bonusSpins;
      }

      final updated = _spinData?.copyWith(
            totalSpins: (_spinData!.totalSpins) + 1,
            spinsToday: (_spinData!.spinsToday) + 1,
            bonusSpins: newBonusSpins,
            lastSpinDate: now,
            totalRewardsEarned: _spinData!.totalRewardsEarned + amount,
            totalSpinsWon: amount > 0
                ? _spinData!.totalSpinsWon + 1
                : _spinData!.totalSpinsWon,
            spinHistory: currentHistory,
          ) ??
          SpinDataEntity(
            userId: uid,
            totalSpins: 1,
            spinsToday: 1,
            lastSpinDate: now,
            lastResetDate: now,
            totalRewardsEarned: amount,
            totalSpinsWon: amount > 0 ? 1 : 0,
            spinHistory: [
              SpinHistoryEntry(amount: amount, timestamp: now),
            ],
          );

      // Update local state immediately for instant UI feedback
      if (mounted) {
        setState(() => _spinData = updated);
      }
      // Cache locally for offline resilience
      await _cacheSpinDataLocally(updated);

      // Save to Firebase — this will trigger the stream and update UI
      await rewardProvider.saveSpinData(updated);

      // Credit reward to wallet immediately after successful save
      if (amount > 0) {
        await walletProvider.addSpinReward(uid, amount);
      }
    } catch (e) {
      // Save failed — revert local state by reloading from stream/cache
      debugPrint('Spin save failed: $e');
      // The Firestore stream will restore the correct data
    } finally {
      _isSaving = false;
    }
  }

  /// Show a rewarded ad and earn 1 bonus spin on successful completion.
  Future<void> _watchAdForExtraSpin() async {
    if (_isWatchingAd || _userId.isEmpty) return;
    _isWatchingAd = true;
    if (mounted) setState(() {});

    // Capture the ScaffoldMessenger before any async gaps to avoid
    // the use_build_context_synchronously lint warning.
    final messenger = ScaffoldMessenger.of(context);
    final rewardProvider = context.read<RewardProvider>();

    try {
      final rewardAmount = await AdMobServiceImpl.instance.showRewardedAd();

      if (rewardAmount == null || rewardAmount <= 0) {
        // Ad was skipped or failed
        if (mounted) {
          messenger.showSnackBar(
            const SnackBar(
              content: Text('Ad not completed. Please watch the full ad.'),
              duration: Duration(seconds: 2),
            ),
          );
        }
        return;
      }

      // Ad completed successfully — add 1 bonus spin
      if (_spinData == null) return;
      final now = DateTime.now();
      final updated = _spinData!.copyWith(
        bonusSpins: _bonusSpins + 1,
        lastSpinDate: now,
      );

      // Save to Firestore
      await rewardProvider.saveSpinData(updated);
      await _cacheSpinDataLocally(updated);

      if (!mounted) return;
      setState(() {
        _spinData = updated;
      });

      messenger.showSnackBar(
        const SnackBar(
          content: Text('🎉 Extra spin earned! Go ahead and spin!'),
          duration: Duration(seconds: 2),
          backgroundColor: Color(0xFF4ADE80),
        ),
      );
    } catch (e) {
      debugPrint('_watchAdForExtraSpin error: $e');
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(
            content: Text('Failed to load ad. Please try again.'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    } finally {
      _isWatchingAd = false;
      if (mounted) setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final size = MediaQuery.of(context).size;
    final wheelSize = size.width * 0.78;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Spin & Win'),
        centerTitle: true,
        actions: [
          if (_spinData != null && !_isLoadingData)
            Padding(
              padding: const EdgeInsets.only(right: 12),
              child: Center(
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: _spinsRemaining > 0
                        ? const Color(0xFF4ADE80).withValues(alpha: 0.15)
                        : const Color(0xFFEF4444).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: _spinsRemaining > 0
                          ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                          : const Color(0xFFEF4444).withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        _spinsRemaining > 0
                            ? Icons.timer_outlined
                            : Icons.timer_off_outlined,
                        size: 14,
                        color: _spinsRemaining > 0
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFFEF4444),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _spinsRemaining > 0
                            ? '$_spinsRemaining left'
                            : 'Limit reached',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: _spinsRemaining > 0
                              ? const Color(0xFF4ADE80)
                              : const Color(0xFFEF4444),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
        ],
      ),
      body: SafeArea(
        child: _isLoadingData
            ? const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    CircularProgressIndicator(color: Color(0xFF4ADE80)),
                    SizedBox(height: 16),
                    Text(
                      'Loading...',
                      style: TextStyle(
                        color: Color(0xFF94A3B8),
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              )
            : _hasError
                ? _buildErrorState()
                : _buildContent(isDark, wheelSize),
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.cloud_off_outlined,
                size: 64, color: Color(0xFF64748B)),
            const SizedBox(height: 16),
            const Text(
              'Failed to load data',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _errorMessage ?? 'Check your connection and try again.',
              style: const TextStyle(color: Color(0xFF64748B)),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () {
                setState(() {
                  _isLoadingData = true;
                  _hasError = false;
                  _errorMessage = null;
                });
                _initializeSpinData();
              },
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Retry'),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF4ADE80),
                foregroundColor: Colors.black,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(bool isDark, double wheelSize) {
    return Stack(
      children: [
        SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            children: [
              const SizedBox(height: 20),
              // Header
              Text(
                'Spin to earn rewards!',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.w800,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                _hasFreeSpinsLeft
                    ? 'You have $_freeSpinsRemaining free spin${_freeSpinsRemaining > 1 ? 's' : ''} today'
                    : _bonusSpins > 0
                        ? 'You have $_bonusSpins bonus spin${_bonusSpins > 1 ? 's' : ''}!'
                        : 'Watch an ad for an extra spin!',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _spinsRemaining > 0
                      ? const Color(0xFF4ADE80)
                      : const Color(0xFFF59E0B),
                ),
              ),
              const SizedBox(height: 28),
              // Wheel section
              Center(
                child: SizedBox(
                  width: wheelSize + 48,
                  height: wheelSize + 48,
                  child: Stack(
                    alignment: Alignment.center,
                    children: [
                      // Outer glow
                      AnimatedBuilder(
                        animation: _spinGlowAnimation,
                        builder: (context, child) {
                          return Container(
                            width: wheelSize + 48,
                            height: wheelSize + 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              boxShadow: [
                                BoxShadow(
                                  color: const Color(0xFF4ADE80).withValues(
                                      alpha: _isSpinning
                                          ? 0.25
                                          : _spinGlowAnimation.value * 0.15),
                                  blurRadius: 40,
                                  spreadRadius: 5,
                                ),
                              ],
                            ),
                          );
                        },
                      ),
                      // Wheel border
                      Container(
                        width: wheelSize + 16,
                        height: wheelSize + 16,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                              blurRadius: 20,
                              offset: const Offset(0, 8),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Container(
                            width: wheelSize + 4,
                            height: wheelSize + 4,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Color(0xFF081A2E),
                            ),
                          ),
                        ),
                      ),
                      // The wheel
                      CustomPaint(
                        size: Size(wheelSize, wheelSize),
                        painter: _WheelPainter(
                          segments: _segments,
                          rotation: _currentAngle,
                        ),
                      ),
                      // Center hub
                      Container(
                        width: 56,
                        height: 56,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: const LinearGradient(
                            colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                              blurRadius: 12,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Icon(
                            _isSpinning ? Icons.hourglass_top : Icons.casino,
                            color: Colors.black,
                            size: 28,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Pointer
              const SizedBox(height: 4),
              const Icon(
                Icons.keyboard_arrow_down,
                color: Color(0xFF4ADE80),
                size: 36,
              ),
              const SizedBox(height: 24),
              // Spin button or result
              if (_showResult)
                _buildResultPopup(isDark)
              else if (_spinsRemaining > 0)
                _buildSpinButton(isDark)
              else
                _buildWatchAdButton(isDark),
              const SizedBox(height: 24),
              // Stats row
              _buildStats(isDark),
              const SizedBox(height: 24),
            ],
          ),
        ),
        // Processing overlay
        if (_isProcessing)
          Container(
            color: Colors.black.withValues(alpha: 0.3),
            child: const Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircularProgressIndicator(color: Color(0xFF4ADE80)),
                  SizedBox(height: 12),
                  Text(
                    'Processing...',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildSpinButton(bool isDark) {
    final label = _isSpinning
        ? 'Spinning...'
        : !_canSpin
            ? 'No Spins Left'
            : _hasFreeSpinsLeft
                ? 'SPIN NOW'
                : 'SPIN (BONUS) 🎯';

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: SizedBox(
        width: double.infinity,
        height: 60,
        child: ElevatedButton.icon(
          onPressed: _canSpin ? _spin : null,
          icon: Icon(
            _isSpinning
                ? Icons.hourglass_top
                : !_canSpin
                    ? Icons.lock_outline
                    : Icons.casino_outlined,
            size: 24,
          ),
          label: Text(
            label,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              letterSpacing: 1,
            ),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: _canSpin
                ? const Color(0xFF4ADE80)
                : const Color(0xFF64748B),
            foregroundColor: Colors.black,
            disabledBackgroundColor: const Color(0xFF64748B).withValues(alpha: 0.5),
            disabledForegroundColor: Colors.white.withValues(alpha: 0.5),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
            elevation: 8,
            shadowColor: _canSpin
                ? const Color(0xFF4ADE80).withValues(alpha: 0.4)
                : Colors.transparent,
          ),
        ),
      ),
    );
  }

  Widget _buildWatchAdButton(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 40),
      child: Column(
        children: [
          SizedBox(
            width: double.infinity,
            height: 60,
            child: ElevatedButton.icon(
              onPressed: _isWatchingAd ? null : _watchAdForExtraSpin,
              icon: _isWatchingAd
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.black,
                      ),
                    )
                  : const Icon(Icons.play_circle_outline, size: 24),
              label: Text(
                _isWatchingAd
                    ? 'Watching Ad...'
                    : 'Watch Ad & Earn Extra Spin',
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 0.5,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFFF59E0B),
                foregroundColor: Colors.black,
                disabledBackgroundColor: const Color(0xFFF59E0B).withValues(alpha: 0.5),
                disabledForegroundColor: Colors.black54,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 8,
                shadowColor: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              ),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Watch a short ad to earn 1 extra spin',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? const Color(0xFF94A3B8) : const Color(0xFF64748B),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildResultPopup(bool isDark) {
    final segment = _segments[_winningIndex];
    final isWin = segment.value > 0;

    return AnimatedBuilder(
      animation: _popupAnimation,
      builder: (context, child) {
        return Opacity(
          opacity: _popupAnimation.value.clamp(0.0, 1.0),
          child: Transform.scale(
            scale: 0.5 + 0.5 * _popupAnimation.value,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 32),
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: isWin
                      ? [const Color(0xFF4ADE80), const Color(0xFF22C55E)]
                      : [const Color(0xFF64748B), const Color(0xFF475569)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: (isWin
                            ? const Color(0xFF4ADE80)
                            : const Color(0xFF64748B))
                        .withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Text(isWin ? '🎉' : '😅',
                      style: const TextStyle(fontSize: 48)),
                  const SizedBox(height: 8),
                  Text(
                    isWin ? 'Congratulations!' : 'Better Luck Next Time!',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Container(
                    width: 100,
                    height: 100,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                    ),
                    child: Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (isWin)
                            const Text(
                              'You Won',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          const SizedBox(height: 2),
                          Text(
                            isWin ? segment.label : '0 pts',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 32,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 20),
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton(
                      onPressed: () {
                        HapticFeedback.lightImpact();
                        setState(() => _showResult = false);
                        // Show interstitial ad after spin result closes
                        AdMobServiceImpl.instance.showInterstitialAd();
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.white,
                        foregroundColor: Colors.black,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                      ),
                      child: const Text(
                        'Awesome!',
                        style:
                            TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildStats(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          _buildStatCard(
            icon: Icons.casino_outlined,
            iconColor: const Color(0xFF4ADE80),
            value: '$_totalSpins',
            label: 'Total Spins',
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            icon: Icons.auto_awesome,
            iconColor: const Color(0xFFF59E0B),
            value: '${_spinData?.totalSpinsWon ?? 0}',
            label: 'Won',
            isDark: isDark,
          ),
          const SizedBox(width: 10),
          _buildStatCard(
            icon: Icons.monetization_on_outlined,
            iconColor: const Color(0xFF4ADE80),
            value:
                '${(_spinData?.totalRewardsEarned ?? 0).toStringAsFixed(0)} pts',
            label: 'Total Earned',
            isDark: isDark,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required Color iconColor,
    required String value,
    required String label,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2740) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark
                ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
          ),
        ),
        child: Column(
          children: [
            Icon(icon, color: iconColor, size: 22),
            const SizedBox(height: 4),
            Text(
              value,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
            Text(
              label,
              style: TextStyle(
                fontSize: 9,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── WHEEL PAINTER ─────────────────────────────────────────────
class _WheelPainter extends CustomPainter {
  final List<_Segment> segments;
  final double rotation;

  _WheelPainter({
    required this.segments,
    required this.rotation,
  });

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;
    final anglePerSegment = (2 * math.pi) / segments.length;

    canvas.save();
    canvas.translate(center.dx, center.dy);
    canvas.rotate(rotation);

    for (var i = 0; i < segments.length; i++) {
      final startAngle = i * anglePerSegment;

      // Draw segment
      final paint = Paint()
        ..color = segments[i].color
        ..style = PaintingStyle.fill;

      final path = Path();
      path.moveTo(0, 0);
      path.arcTo(
        Rect.fromCircle(center: Offset.zero, radius: radius),
        startAngle - math.pi / 2,
        anglePerSegment,
        true,
      );
      path.close();
      canvas.drawPath(path, paint);

      // Draw border
      final borderPaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.2)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 1.5;
      canvas.drawPath(path, borderPaint);

      // Draw text
      final midAngle = startAngle + anglePerSegment / 2;
      canvas.save();
      canvas.rotate(midAngle);

      final textPainter = TextPainter(
        text: TextSpan(
          text: segments[i].label,
          style: const TextStyle(
            color: Colors.white,
            fontSize: 13,
            fontWeight: FontWeight.w800,
          ),
        ),
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(radius * 0.58 - textPainter.width / 2, -textPainter.height / 2),
      );

      canvas.restore();
    }

    canvas.restore();

    // Center circle
    final centerPaint = Paint()
      ..color = const Color(0xFF081A2E)
      ..style = PaintingStyle.fill;
    canvas.drawCircle(center, radius * 0.12, centerPaint);

    // Center border
    final centerBorderPaint = Paint()
      ..color = const Color(0xFF4ADE80)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5;
    canvas.drawCircle(center, radius * 0.12, centerBorderPaint);
  }

  @override
  bool shouldRepaint(_WheelPainter oldDelegate) =>
      oldDelegate.rotation != rotation;
}

class _Segment {
  final String label;
  final double value;
  final Color color;

  const _Segment(this.label, this.value, this.color);
}
