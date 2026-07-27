import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/reward_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/services/ad_service.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class WatchEarnScreen extends StatefulWidget {
  const WatchEarnScreen({super.key});

  @override
  State<WatchEarnScreen> createState() => _WatchEarnScreenState();
}

class _WatchEarnScreenState extends State<WatchEarnScreen>
    with SingleTickerProviderStateMixin {
  // Access the AdService singleton directly since this screen does not
  // have easy access to a Provider<AdService> in its deeply nested widget tree.
  AdService get _adService => AdMobServiceImpl.instance;
  bool _isAdLoading = false;
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _loadInitialAd());
  }

  Future<void> _loadInitialAd() async {
    if (!mounted) return;
    // Load ad with auto-retry on failure
    await _retryLoadAd(maxRetries: 3);
  }

  /// Retry loading ad up to [maxRetries] times with a delay between attempts.
  Future<void> _retryLoadAd({int maxRetries = 3}) async {
    for (int attempt = 0; attempt < maxRetries; attempt++) {
      if (!mounted) return;
      try {
        await _adService.loadRewardedAd();
      } catch (e) {
        debugPrint('[WatchEarn] Ad load exception on attempt ${attempt + 1}: $e');
      }
      if (_adService.isAdReady || !mounted) return;
      if (attempt < maxRetries - 1) {
        await Future.delayed(const Duration(seconds: 2));
      }
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    _adService.dispose();
    super.dispose();
  }

  Future<void> _handleWatchAd() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId == null) return;

    final rewardProvider = context.read<RewardProvider>();

    if (!_adService.isAdReady) {
      setState(() => _isAdLoading = true);
      // Auto-retry loading the ad
      await _retryLoadAd(maxRetries: 2);
      setState(() => _isAdLoading = false);

      if (!mounted) return;
      if (!_adService.isAdReady) {
        _showSnackBar(
            _adService.lastError ?? 'Ad not available. Tap to retry.');
        return;
      }
    }

    if (!mounted) return;

    // Show ad and wait for user to fully complete it
    // Returns reward amount ($) if user earned it, null otherwise
    final earnedAmount = await _adService.showRewardedAd();

    // Only claim reward if the ad was fully watched (earnedAmount != null)
    if (earnedAmount != null && mounted) {
      final claimedAmount = await rewardProvider.claimAdReward(userId);
      if (claimedAmount != null && mounted) {
        // Refresh wallet balance instantly
        context.read<WalletProvider>().listenToWallet(userId);
        _showRewardPopup(claimedAmount);
      }
    } else if (mounted) {
      _showSnackBar('Ad failed to show. Tap to retry.');
    }
  }

  void _showSnackBar(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  void _showRewardPopup(double amount) {
    showDialog(
      context: context,
      builder: (ctx) => _WatchAdRewardPopup(
          amount: amount, theme: Theme.of(context)),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Watch & Earn',
        onBack: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.05),
              theme.colorScheme.surface,
              theme.colorScheme.tertiary.withValues(alpha: 0.03),
            ],
          ),
        ),
        child: Consumer2<AuthProvider, RewardProvider>(
          builder: (context, auth, rewardProvider, _) {
            return FadeTransition(
              opacity: _fadeAnim,
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // ─── Header ──────────────────────────────
                  _buildHeader(theme, isDark),
                  const SizedBox(height: 20),

                  // ─── Error Banner ────────────────────────
                  if (_adService.lastError != null &&
                      !_isAdLoading &&
                      !_adService.isAdReady)
                    _buildErrorBanner(theme),

                  // ─── Today's Progress ────────────────────
                  _TodayAdProgress(
                    watched: rewardProvider.todayAdCount,
                    todayEarnings: rewardProvider.todayAdEarnings,
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // ─── Watch Ad Card ────────────────────────
                  _WatchAdCard(
                    isAdReady: _adService.isAdReady,
                    isAdLoading: _isAdLoading,
                    isClaiming: rewardProvider.isClaimingReward,
                    lastError: _adService.lastError,
                    onWatch: _handleWatchAd,
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 24),

                  // ─── Recent Ad History ───────────────────
                  _buildAdRewardHistory(theme, rewardProvider.adRewardHistory,
                      isDark),
                  const SizedBox(height: 16),

                  // ─── Lifetime Stats ───────────────────────
                  _LifetimeAdStats(
                    totalWatched: rewardProvider.lifetimeAdCount,
                    totalEarned: rewardProvider.lifetimeAdEarnings,
                    theme: theme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 32),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildErrorBanner(ThemeData theme) {
    final errorMsg = _adService.lastError!;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.2)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(Icons.error_outline, color: theme.colorScheme.error, size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ad Failed to Load',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.error,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  simplifyAdError(errorMsg),
                  style: TextStyle(
                    fontSize: 11,
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
                const SizedBox(height: 6),
                GestureDetector(
                  onTap: () {
                    _adService.loadRewardedAd();
                    setState(() => _isAdLoading = true);
                    _retryLoadAd(maxRetries: 2).then((_) {
                      if (mounted) setState(() => _isAdLoading = false);
                    });
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 12, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Retry',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Simplifies AdMob error codes into user-friendly messages
  /// The error format is "Ad failed to load: {code} - {message}"
  static String simplifyAdError(String error) {
    if (error.contains(': 0 -')) {
      return 'Internal error. Please try again.';
    }
    if (error.contains(': 1 -')) {
      return 'Invalid ad request. The ad unit ID may be misconfigured.';
    }
    if (error.contains(': 2 -')) {
      return 'Network error. Check your internet connection.';
    }
    if (error.contains(': 3 -')) {
      return 'No ad to show. Try again later.';
    }
    if (error.contains(': 4 -')) {
      return 'Ad request timed out. Please try again.';
    }
    if (error.contains(': 5 -')) {
      return 'Ad unit ID is not valid. Contact support.';
    }
    if (error.contains(': 6 -')) {
      return 'Ad too frequent. Slow down your requests.';
    }
    if (error.contains(': 7 -')) {
      return 'Ad request already in progress. Please wait.';
    }
    if (error.contains(': 8 -')) {
      return 'App ID is missing or invalid.';
    }
    // Return the raw error if we can't simplify it
    if (error.length > 80) {
      return '${error.substring(0, 80)}...';
    }
    return error;
  }

  Widget _buildHeader(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.3),
            blurRadius: 24,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(Icons.play_circle_fill_rounded,
                size: 34, color: Colors.white),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watch & Earn',
                  style: theme.textTheme.titleLarge?.copyWith(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Watch rewarded ads and earn real money',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.85),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAdRewardHistory(
      ThemeData theme, List<RewardEntity> history, bool isDark) {
    // adRewardHistory already contains only ad rewards from the datasource
    final adHistory = history;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 18,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              'Recent Ad Earnings',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (adHistory.isEmpty)
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.play_circle_outline,
                    size: 48,
                    color: isDark
                        ? AppTheme.textMuted.withValues(alpha: 0.4)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(
                  'No ad rewards yet',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Watch your first ad to start earning!',
                  style: TextStyle(
                    fontSize: 12,
                    color: isDark
                        ? AppTheme.textMuted.withValues(alpha: 0.6)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          )
        else
          ...adHistory.take(10).map((reward) => _AdHistoryRow(
                reward: reward,
                theme: theme,
                isDark: isDark,
              )),
      ],
    );
  }
}

// ─── Today's Ad Progress Card ─────────────────────────────────

class _TodayAdProgress extends StatelessWidget {
  final int watched;
  final double todayEarnings;
  final ThemeData theme;
  final bool isDark;

  const _TodayAdProgress({
    required this.watched,
    required this.todayEarnings,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.trending_up_rounded,
                    color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Text(
                "Today's Progress",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const Spacer(),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '$watched watched',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Icon(Icons.all_inclusive, size: 14, color: theme.colorScheme.primary),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stats row
          Row(
            children: [
              _MiniStat(
                icon: Icons.play_circle_outline,
                label: 'Watched Today',
                value: '$watched',
                color: theme.colorScheme.primary,
                isDark: isDark,
              ),
              const Spacer(),
              _MiniStat(
                icon: Icons.all_inclusive_outlined,
                label: 'Unlimited Ads',
                value: '∞',
                color: AppTheme.accentGreen,
                isDark: isDark,
              ),
              const Spacer(),
              _MiniStat(
                icon: Icons.monetization_on_outlined,
                label: "Today's Earnings",
                value: '₹${todayEarnings.toStringAsFixed(2)}',
                color: AppTheme.accentGreen,
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Watch Ad Card ────────────────────────────────────────────

class _WatchAdCard extends StatelessWidget {
  final bool isAdReady;
  final bool isAdLoading;
  final bool isClaiming;
  final String? lastError;
  final VoidCallback onWatch;
  final ThemeData theme;
  final bool isDark;

  const _WatchAdCard({
    this.isAdReady = false,
    this.isAdLoading = false,
    this.isClaiming = false,
    this.lastError,
    required this.onWatch,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    final isLoading = isAdLoading || isClaiming;

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [
            theme.colorScheme.primary.withValues(alpha: 0.15),
            theme.colorScheme.tertiary.withValues(alpha: 0.08),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        border: Border.all(
          color: theme.colorScheme.primary.withValues(alpha: 0.2),
        ),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            blurRadius: 20,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            // Icon & title
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: LinearGradient(
                  colors: [
                    theme.colorScheme.primary,
                    theme.colorScheme.tertiary,
                  ],
                ),
                boxShadow: [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.3),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: const Icon(Icons.play_circle_fill_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 16),

            // Reward amount
            Text(
              '₹0.80 – ₹2.00',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.w900,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
                letterSpacing: -1,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'per rewarded ad',
              style: TextStyle(
                fontSize: 13,
                color:
                    isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 20),

            // Watch button
            SizedBox(
              width: double.infinity,
              height: 54,
              child: FilledButton.icon(
                onPressed: isLoading ? null : onWatch,
                icon: isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2.5,
                          color: Colors.white,
                        ),
                      )
                    : Icon(
                        isAdReady
                            ? Icons.play_arrow_rounded
                            : Icons.download_outlined,
                        size: 22,
                      ),
                label: Text(
                  isLoading
                      ? (isAdLoading ? 'Loading Ad...' : 'Processing...')
                      : (isAdReady
                          ? 'Watch Ad Now'
                          : (lastError != null ? 'Tap to Retry' : 'Load Ad')),
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: theme.colorScheme.primary,
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  elevation: 4,
                  shadowColor: theme.colorScheme.primary.withValues(alpha: 0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Ad History Row ──────────────────────────────────────────

class _AdHistoryRow extends StatelessWidget {
  final RewardEntity reward;
  final ThemeData theme;
  final bool isDark;

  const _AdHistoryRow({
    required this.reward,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      decoration: BoxDecoration(
        color: isDark
            ? AppTheme.bgCardLight.withValues(alpha: 0.4)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: (isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0))
              .withValues(alpha: 0.3),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: theme.colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Icon(Icons.play_circle_outline,
                  size: 18, color: theme.colorScheme.primary),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Ad Reward',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  Text(
                    Helpers.formatDateTime(reward.createdAt),
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
            ),
            Container(
              padding:
                  const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
              decoration: BoxDecoration(
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '+₹${reward.rewardAmount.toStringAsFixed(2)}',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentGreen,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lifetime Stats ──────────────────────────────────────────

class _LifetimeAdStats extends StatelessWidget {
  final int totalWatched;
  final double totalEarned;
  final ThemeData theme;
  final bool isDark;

  const _LifetimeAdStats({
    required this.totalWatched,
    required this.totalEarned,
    required this.theme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 4,
                height: 18,
                decoration: BoxDecoration(
                  color: AppTheme.accentGreen,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(width: 10),
              Text(
                'Lifetime Ad Statistics',
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _StatTile(
                  icon: Icons.play_circle_outline,
                  label: 'Total Ads Watched',
                  value: Helpers.formatNumber(totalWatched),
                  color: theme.colorScheme.primary,
                  isDark: isDark,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatTile(
                  icon: Icons.monetization_on_outlined,
                  label: 'Total Earned',
                  value: '₹${totalEarned.toStringAsFixed(2)}',
                  color: AppTheme.accentGreen,
                  isDark: isDark,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Stat Tile ───────────────────────────────────────────────

class _StatTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _StatTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.15)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 8),
          Text(
            value,
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Mini Stat (for today's progress) ────────────────────────

class _MiniStat extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final bool isDark;

  const _MiniStat({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Icon(icon, size: 20, color: color),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
      ],
    );
  }
}

// ─── Reward Popup ────────────────────────────────────────────

class _WatchAdRewardPopup extends StatelessWidget {
  final double amount;
  final ThemeData theme;

  const _WatchAdRewardPopup({required this.amount, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      backgroundColor: Colors.transparent,
      child: Container(
        padding: const EdgeInsets.all(32),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(28),
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              theme.colorScheme.tertiary.withValues(alpha: 0.9),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          boxShadow: [
            BoxShadow(
              color: theme.colorScheme.primary.withValues(alpha: 0.4),
              blurRadius: 40,
              offset: const Offset(0, 10),
            ),
          ],
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: const Icon(Icons.monetization_on_rounded,
                  size: 40, color: Colors.white),
            ),
            const SizedBox(height: 20),
            Text(
              'You Earned! 🎉',
              style: theme.textTheme.titleLarge?.copyWith(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
              decoration: BoxDecoration(
                color: Colors.white.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withValues(alpha: 0.2)),
              ),
              child: Text(
                '₹${amount.toStringAsFixed(2)}',
                style: theme.textTheme.displaySmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'from watching a rewarded ad',
              style: TextStyle(
                color: Colors.white.withValues(alpha: 0.8),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                style: FilledButton.styleFrom(
                  backgroundColor: Colors.white,
                  foregroundColor: theme.colorScheme.primary,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                child: const Text(
                  'Awesome!',
                  style: TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
