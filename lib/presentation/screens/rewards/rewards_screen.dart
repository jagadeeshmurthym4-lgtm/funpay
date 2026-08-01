import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:cashspark/domain/entities/reward_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/reward_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RewardsScreen extends StatefulWidget {
  const RewardsScreen({super.key});

  @override
  State<RewardsScreen> createState() => _RewardsScreenState();
}

class _RewardsScreenState extends State<RewardsScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _scaleAnim;
  late Animation<double> _fadeAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.9, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutBack),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId != null) {
      context.read<RewardProvider>().initialize(userId);
    }
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  Future<void> _handleCheckIn() async {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId == null) return;

    final provider = context.read<RewardProvider>();
    if (provider.hasCheckedInToday) return;

    await provider.claimDailyCheckIn(userId);

    if (mounted) {
      context.read<WalletProvider>().listenToWallet(userId);
      // Show interstitial ad after daily check-in
      AdMobServiceImpl.instance.showInterstitialAd();
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Daily Check-In',
        onBack: () => Navigator.pop(context),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: isDark
                ? [
                    AppTheme.accentGreen.withValues(alpha: 0.08),
                    AppTheme.bgDark,
                    AppTheme.bgDark,
                  ]
                : [
                    const Color(0xFF4ADE80).withValues(alpha: 0.06),
                    const Color(0xFFF0F5FF),
                    const Color(0xFFF0F5FF),
                  ],
          ),
        ),
        child: Consumer2<AuthProvider, RewardProvider>(
          builder: (context, auth, rewardProvider, _) {
            if (rewardProvider.isLoading) {
              return const RewardsScreenSkeleton();
            }

            final streak = rewardProvider.streak;
            final hasCheckedIn = rewardProvider.hasCheckedInToday;
            final currentStreak = streak?.currentStreak ?? 0;
            final longestStreak = streak?.longestStreak ?? 0;
            final rewardAmount = 3.0 + (currentStreak - 1).clamp(0, 999) * 2.0;

            return RefreshIndicator(
              onRefresh: () async {
                final userId = auth.user?.uid;
                if (userId != null) {
                  await rewardProvider.initialize(userId);
                }
              },
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ListView(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  children: [
                    const SizedBox(height: 20),

                    // ─── Premium Check-In Card ────────────────
                    ScaleTransition(
                      scale: _scaleAnim,
                      child: _buildCheckInCard(
                        theme,
                        isDark,
                        currentStreak,
                        longestStreak,
                        hasCheckedIn,
                        rewardAmount,
                        rewardProvider.isClaimingReward,
                      ),
                    ),

                    const SizedBox(height: 24),

                    // ─── Streak Milestone ─────────────────────
                    _buildStreakMilestone(theme, isDark, currentStreak),

                    const SizedBox(height: 24),

                    // ─── Reward History ───────────────────────
                    _buildRewardHistory(
                        theme, isDark, rewardProvider.recentRewards),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildCheckInCard(
    ThemeData theme,
    bool isDark,
    int currentStreak,
    int longestStreak,
    bool hasCheckedIn,
    double rewardAmount,
    bool isClaiming,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(28),
        gradient: LinearGradient(
          colors: hasCheckedIn
              ? [
                  AppTheme.accentGreen.withValues(alpha: 0.85),
                  const Color(0xFF16A34A),
                ]
              : [
                  theme.colorScheme.primary,
                  theme.colorScheme.tertiary.withValues(alpha: 0.9),
                ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: (hasCheckedIn
                    ? AppTheme.accentGreen
                    : theme.colorScheme.primary)
                .withValues(alpha: 0.35),
            blurRadius: 30,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        children: [
          // ─── Streak counter ─────────────────────────
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Text('🔥', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 6),
                Text(
                  '$currentStreak-day streak',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),

          // ─── 7-day streak circles ──────────────────
          SizedBox(
            width: double.infinity,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: List.generate(7, (index) {
                final dayNum = index + 1;
                final isActive = dayNum <= currentStreak;
                final isToday = dayNum == (currentStreak % 7 == 0 ? 7 : currentStreak % 7) ||
                    (dayNum == currentStreak && currentStreak <= 7);

                return Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isActive
                            ? Colors.white
                            : Colors.white.withValues(alpha: 0.15),
                        border: isToday && !hasCheckedIn
                            ? Border.all(color: Colors.white, width: 2.5)
                            : null,
                        boxShadow: isActive
                            ? [
                                BoxShadow(
                                  color: Colors.white.withValues(alpha: 0.3),
                                  blurRadius: 8,
                                  offset: const Offset(0, 2),
                                ),
                              ]
                            : [],
                      ),
                      child: Center(
                        child: isActive
                            ? const Icon(Icons.check,
                                size: 22, color: Colors.black87)
                            : Text(
                                '$dayNum',
                                style: TextStyle(
                                  fontSize: 14,
                                  fontWeight: isToday ? FontWeight.bold : FontWeight.w600,
                                  color: isToday && !hasCheckedIn
                                      ? Colors.white
                                      : Colors.white.withValues(alpha: 0.5),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      ['M', 'T', 'W', 'T', 'F', 'S', 'S'][index],
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Colors.white.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                );
              }),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Reward amount ─────────────────────────
          Text(
            hasCheckedIn ? "Today's Reward Claimed" : "Today's Reward",
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: Colors.white.withValues(alpha: 0.85),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${rewardAmount.toStringAsFixed(2)} pts',
            style: const TextStyle(
              fontSize: 42,
              fontWeight: FontWeight.w900,
              color: Colors.white,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Day $currentStreak reward',
            style: TextStyle(
              fontSize: 12,
              color: Colors.white.withValues(alpha: 0.7),
            ),
          ),
          const SizedBox(height: 24),

          // ─── Check-In Button ───────────────────────
          SizedBox(
            width: double.infinity,
            height: 54,
            child: FilledButton.icon(
              onPressed:
                  (hasCheckedIn || isClaiming) ? null : _handleCheckIn,
              icon: isClaiming
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black87,
                      ),
                    )
                  : Icon(
                      hasCheckedIn ? Icons.check_circle : Icons.login_rounded,
                      size: 22,
                    ),
              label: Text(
                isClaiming
                    ? 'Claiming...'
                    : hasCheckedIn
                        ? "Checked In! ✓"
                        : 'Check In Now',
                style: const TextStyle(
                    fontSize: 16, fontWeight: FontWeight.w700),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: hasCheckedIn
                    ? AppTheme.accentGreen
                    : theme.colorScheme.primary,
                disabledBackgroundColor: Colors.white.withValues(alpha: 0.5),
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 4,
                shadowColor: Colors.white.withValues(alpha: 0.3),
              ),
            ),
          ),

          const SizedBox(height: 16),

          // ─── Longest streak ────────────────────────
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(Icons.emoji_events_outlined,
                  size: 16, color: Colors.white.withValues(alpha: 0.7)),
              const SizedBox(width: 6),
              Text(
                'Best streak: $longestStreak days',
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.white.withValues(alpha: 0.8),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStreakMilestone(
      ThemeData theme, bool isDark, int currentStreak) {
    final nextMilestone = ((currentStreak ~/ 7) + 1) * 7;
    final daysToNext = nextMilestone - currentStreak;

    return GlassContainer(
      borderRadius: 20,
      padding: const EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppTheme.accentOrange,
                  Color(0xFFFB923C),
                ],
              ),
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: AppTheme.accentOrange.withValues(alpha: 0.3),
                  blurRadius: 12,
                  offset: const Offset(0, 4),
                ),
              ],
            ),
            child: const Center(
              child: Text(
                '🏆',
                style: TextStyle(fontSize: 26),
              ),
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  '$daysToNext days to $nextMilestone-day milestone',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Keep your streak alive!',
                  style: TextStyle(
                    fontSize: 12,
                    color:
                        isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          // Mini progress
          SizedBox(
            width: 48,
            height: 48,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: (currentStreak % 7) / 7.0,
                  strokeWidth: 5,
                  backgroundColor: isDark
                      ? AppTheme.borderColor
                      : const Color(0xFFE2E8F0),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    AppTheme.accentOrange,
                  ),
                ),
                Text(
                  '${currentStreak % 7}/7',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color:
                        isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRewardHistory(
      ThemeData theme, bool isDark, List<RewardEntity> rewards) {
    final checkInRewards =
        rewards.where((r) => r.rewardType == RewardType.dailyCheckIn).toList();

    return Column(
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
              'Check-In History',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (checkInRewards.isEmpty)
          GlassContainer(
            borderRadius: 16,
            padding: const EdgeInsets.symmetric(vertical: 32),
            child: Column(
              children: [
                Icon(Icons.calendar_today_outlined,
                    size: 48,
                    color: isDark
                        ? AppTheme.textMuted.withValues(alpha: 0.4)
                        : const Color(0xFF94A3B8).withValues(alpha: 0.4)),
                const SizedBox(height: 8),
                Text(
                  'No check-ins yet',
                  style: TextStyle(
                    fontSize: 14,
                    color:
                        isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
                Text(
                  'Check in daily to build your streak!',
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
          ...checkInRewards.take(10).map((reward) => _CheckInHistoryRow(
                reward: reward,
                theme: theme,
                isDark: isDark,
              )),
      ],
    );
  }
}

class _CheckInHistoryRow extends StatelessWidget {
  final RewardEntity reward;
  final ThemeData theme;
  final bool isDark;

  const _CheckInHistoryRow({
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
                color: AppTheme.accentGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(Icons.calendar_today_outlined,
                  size: 18, color: AppTheme.accentGreen),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Daily Check-In',
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
                '+${reward.rewardAmount.toStringAsFixed(2)} pts',
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
