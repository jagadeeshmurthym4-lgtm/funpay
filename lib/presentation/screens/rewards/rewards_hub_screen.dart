import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/reward_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Categories for reward features
enum RewardFeature {
  dailyCheckin,
  spinWin,
  watchEarn,
  scratchCard,
  weeklyBonus,
  monthlyBonus,
  streakRewards,
  coupons,
  surveys,
}

class RewardsHubScreen extends StatefulWidget {
  const RewardsHubScreen({super.key});

  @override
  State<RewardsHubScreen> createState() => _RewardsHubScreenState();
}

class _RewardsHubScreenState extends State<RewardsHubScreen> {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return SafeArea(
      child: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildHeader(isDark),
            const SizedBox(height: 16),
            _buildDailyCheckin(isDark),
            const SizedBox(height: 12),
            _buildRewardsGrid(isDark),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark) {
    return Row(
      children: [
        Container(
          width: 36,
          height: 36,
          decoration: BoxDecoration(
            color: AppTheme.accentOrange.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: const Icon(Icons.card_giftcard_outlined,
              size: 20, color: Color(0xFFF59E0B)),
        ),
        const SizedBox(width: 10),
        Text(
          'Rewards',
          style: TextStyle(
            fontSize: 20,
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const Spacer(),
        Consumer2<AuthProvider, RewardProvider>(
          builder: (context, auth, rewardProv, _) {
            final streak = rewardProv.streak?.currentStreak ?? 0;
            if (streak > 0) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 14)),
                    const SizedBox(width: 4),
                    Text(
                      '$streak',
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ],
                ),
              );
            }
            return const SizedBox.shrink();
          },
        ),
      ],
    );
  }

  Widget _buildDailyCheckin(bool isDark) {
    return Consumer2<AuthProvider, RewardProvider>(
      builder: (context, auth, rewardProv, _) {
        final hasCheckedIn = rewardProv.hasCheckedInToday;

        return GestureDetector(
          onTap: () {
            final userId = auth.user?.uid;
            if (userId == null) return;
            if (!hasCheckedIn) {
              final walletProv = context.read<WalletProvider>();
              rewardProv.claimDailyCheckIn(userId).then((_) {
                if (mounted) {
                  walletProv.listenToWallet(userId);
                }
              });
            }
          },
          child: Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              gradient: LinearGradient(
                colors: hasCheckedIn
                    ? [const Color(0xFF22C55E), const Color(0xFF16A34A)]
                    : [const Color(0xFFF59E0B), const Color(0xFFEA580C)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: (hasCheckedIn
                          ? const Color(0xFF22C55E)
                          : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.3),
                  blurRadius: 20,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Row(
              children: [
                Container(
                  width: 56,
                  height: 56,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text('🔥', style: TextStyle(fontSize: 24)),
                    ],
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        hasCheckedIn ? "Checked In ✓" : "Daily Check-In",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        hasCheckedIn
                            ? 'Come back tomorrow!'
                            : 'Earn ₹1–₹3 today',
                        style: TextStyle(
                          color: Colors.white.withValues(alpha: 0.8),
                          fontSize: 13,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!hasCheckedIn)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Check In',
                      style: TextStyle(
                        color: Colors.black87,
                        fontWeight: FontWeight.w700,
                        fontSize: 13,
                      ),
                    ),
                  ),
                if (hasCheckedIn)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.check, color: Colors.white, size: 20),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildRewardsGrid(bool isDark) {
    final features = [
      _RewardFeatureItem(
        RewardFeature.spinWin,
        'Spin & Win',
        'Spin to earn rewards',
        Icons.casino_outlined,
        const Color(0xFF4ADE80),
        const LinearGradient(colors: [Color(0xFF4ADE80), Color(0xFF22C55E)]),
        AppRouter.spinWheel,
      ),
      _RewardFeatureItem(
        RewardFeature.watchEarn,
        'Watch & Earn',
        'Watch ads, earn money',
        Icons.play_circle_fill_rounded,
        const Color(0xFFEC4899),
        const LinearGradient(colors: [Color(0xFFE879F9), Color(0xFFD946EF)]),
        AppRouter.watchEarn,
      ),
      _RewardFeatureItem(
        RewardFeature.scratchCard,
        'Scratch Card',
        'Scratch & win prizes',
        Icons.auto_fix_high_outlined,
        const Color(0xFF8B5CF6),
        const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)]),
        AppRouter.scratchCard,
      ),
      _RewardFeatureItem(
        RewardFeature.weeklyBonus,
        'Weekly Bonus',
        'Check in 7 days for ₹15',
        Icons.date_range_outlined,
        const Color(0xFF06B6D4),
        const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
        null,
      ),
      _RewardFeatureItem(
        RewardFeature.monthlyBonus,
        'Monthly Bonus',
        'Full month for ₹40',
        Icons.event_outlined,
        const Color(0xFFEC4899),
        const LinearGradient(colors: [Color(0xFFEC4899), Color(0xFFDB2777)]),
        null,
      ),
      _RewardFeatureItem(
        RewardFeature.streakRewards,
        'Streak Rewards',
        'Maintain your streak',
        Icons.local_fire_department_outlined,
        const Color(0xFFF97316),
        const LinearGradient(colors: [Color(0xFFF97316), Color(0xFFEA580C)]),
        null,
      ),
      _RewardFeatureItem(
        RewardFeature.dailyCheckin,
        'Refer & Earn',
        'Invite friends, earn ₹7',
        Icons.person_add_outlined,
        const Color(0xFFF59E0B),
        const LinearGradient(colors: [Color(0xFFF59E0B), Color(0xFFD97706)]),
        AppRouter.referrals,
      ),
      // Coupons card — placed immediately after Refer & Earn
      _RewardFeatureItem(
        RewardFeature.coupons,
        'Coupons',
        'Save more with exclusive deals',
        Icons.local_offer_outlined,
        const Color(0xFF8B5CF6),
        const LinearGradient(colors: [Color(0xFF8B5CF6), Color(0xFF6D28D9)]),
        AppRouter.couponsMarketplace,
      ),
      // Surveys — CPX Research paid surveys
      _RewardFeatureItem(
        RewardFeature.surveys,
        'Surveys',
        'Earn from CPX surveys',
        Icons.quiz_outlined,
        const Color(0xFF06B6D4),
        const LinearGradient(colors: [Color(0xFF06B6D4), Color(0xFF0891B2)]),
        AppRouter.surveys,
      ),
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 4,
              height: 16,
              decoration: BoxDecoration(
                color: AppTheme.accentOrange,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(width: 8),
            Text(
              'Bonus Features',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w700,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 1.4,
            crossAxisSpacing: 10,
            mainAxisSpacing: 10,
          ),
          itemCount: features.length,
          itemBuilder: (context, index) => _buildFeatureCard(features[index], isDark),
        ),
      ],
    );
  }

  Widget _buildFeatureCard(_RewardFeatureItem feature, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        if (feature.type == RewardFeature.weeklyBonus) {
          _showWeeklyBonusSheet();
        } else if (feature.type == RewardFeature.monthlyBonus) {
          _showMonthlyBonusSheet();
        } else if (feature.type == RewardFeature.streakRewards) {
          final streak = context.read<RewardProvider>().streak?.currentStreak ?? 0;
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(streak > 0
                  ? '🔥 $streak-day streak! Keep it up!'
                  : 'Check in daily to start your streak!'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 2),
            ),
          );
        } else if (feature.route != null) {
          Navigator.pushNamed(context, feature.route!);
        }
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          gradient: feature.gradient,
          boxShadow: [
            BoxShadow(
              color: feature.color.withValues(alpha: 0.2),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(feature.icon, size: 20, color: Colors.white),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    feature.label,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    feature.subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 10,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ─── Weekly Bonus Bottom Sheet ─────────────────────

  void _showWeeklyBonusSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Consumer<RewardProvider>(
          builder: (context, rp, _) {
            final weekDays = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
            final checked = rp.weeklyBonus?.checkedDays ?? [];
            final canClaim = rp.canClaimWeekly;
            final claimed = rp.weeklyBonus?.claimed ?? false;
            final canRecover = rp.canRecoverWeekly;
            final isRecovering = rp.isRecoveringWeekly;

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F2740) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.textMuted.withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFF06B6D4).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.date_range_outlined, size: 20, color: Color(0xFF06B6D4)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Weekly Bonus',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check in every day for 7 consecutive days to earn ₹15!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 20),
                  // 7-day calendar
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: List.generate(7, (index) {
                      final dayNum = index + 1; // 1=Mon
                      final isChecked = checked.contains(dayNum);
                      return Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 36,
                            height: 36,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isChecked
                                  ? const Color(0xFF4ADE80)
                                  : (isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0)),
                              border: Border.all(
                                color: isChecked
                                    ? const Color(0xFF4ADE80)
                                    : (isDark ? const Color(0xFF1E3A5F).withValues(alpha: 0.5) : const Color(0xFFCBD5E1)),
                              ),
                            ),
                            child: Center(
                              child: isChecked
                                  ? const Icon(Icons.check, size: 18, color: Colors.black)
                                  : Text(
                                      '${index + 1}',
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                                      ),
                                    ),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            weekDays[index],
                            style: TextStyle(
                              fontSize: 9,
                              fontWeight: FontWeight.w600,
                              color: isChecked
                                  ? const Color(0xFF4ADE80)
                                  : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                            ),
                          ),
                        ],
                      );
                    }),
                  ),
                  const SizedBox(height: 12),
                  // Progress bar
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: checked.length / 7.0,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFF4ADE80)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${checked.length}/7 days',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Recover Streak button
                  if (canRecover && !claimed)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: isRecovering
                            ? null
                            : () async {
                                // Step 1: Show rewarded ad
                                final rewardAmount =
                                    await AdMobServiceImpl.instance.showRewardedAd();
                                if (rewardAmount == null || ctx.mounted == false) {
                                  // Ad was skipped or failed
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Ad was skipped. Watch the full ad to recover your streak.'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                // Step 2: Ad completed — recover streak
                                final rewardProv = context.read<RewardProvider>();
                                final success =
                                    await rewardProv.recoverWeeklyStreak(userId);
                                if (success && ctx.mounted) {
                                  setSheetState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          '✅ Streak recovered! Missed day restored.'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: const Color(0xFF8B5CF6),
                                    ),
                                  );
                                }
                              },
                        icon: isRecovering
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.restore_outlined, size: 18),
                        label: Text(
                          isRecovering ? 'Recovering...' : 'Recover Streak',
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Claim button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: canClaim
                          ? () async {
                              final success = await context.read<RewardProvider>().claimWeeklyBonus(userId);
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  context.read<WalletProvider>().listenToWallet(userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('🎉 Weekly Bonus claimed! ₹15 added to your wallet.'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      icon: Icon(
                        claimed ? Icons.check_circle : Icons.monetization_on_outlined,
                        size: 20,
                      ),
                      label: Text(
                        claimed
                            ? 'Already Claimed ✓'
                            : canClaim
                                ? 'Claim ₹15'
                                : 'Check in ${7 - checked.length} more day${7 - checked.length != 1 ? 's' : ''}',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: claimed
                            ? const Color(0xFF64748B)
                            : canClaim
                                ? const Color(0xFF06B6D4)
                                : const Color(0xFF64748B).withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ─── Monthly Bonus Bottom Sheet ─────────────────────

  void _showMonthlyBonusSheet() {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final userId = context.read<AuthProvider>().user?.uid ?? '';

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setSheetState) => Consumer<RewardProvider>(
          builder: (context, rp, _) {
            final now = DateTime.now();
            final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
            final checked = rp.monthlyBonus?.checkedDays ?? [];
            final canClaim = rp.canClaimMonthly;
            final claimed = rp.monthlyBonus?.claimed ?? false;
            final canRecoverMonthly = rp.canRecoverMonthly;
            final isRecoveringMonthly = rp.isRecoveringMonthly;
            final monthNames = ['', 'January', 'February', 'March', 'April', 'May', 'June',
                'July', 'August', 'September', 'October', 'November', 'December'];

            // Build calendar grid (start from day 1)
            final firstDay = DateTime(now.year, now.month, 1);
            final startWeekday = firstDay.weekday; // 1=Mon...7=Sun

            return Container(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 32),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF0F2740) : Colors.white,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Handle
                  Container(
                    width: 40, height: 4,
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: isDark ? AppTheme.textMuted.withValues(alpha: 0.3) : const Color(0xFFCBD5E1),
                      borderRadius: BorderRadius.circular(2),
                    ),
                  ),
                  // Title
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: const Color(0xFFEC4899).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.event_outlined, size: 20, color: Color(0xFFEC4899)),
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Monthly Bonus - ${monthNames[now.month]}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w800,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Check in every day this month to earn ₹40!',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 12,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 16),
                  // Day headers
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'].map((d) {
                      return SizedBox(
                        width: 32,
                        child: Text(
                          d,
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                  const SizedBox(height: 6),
                  // Calendar grid
                  SizedBox(
                    height: 240,
                    child: GridView.builder(
                      physics: const NeverScrollableScrollPhysics(),
                      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                        crossAxisCount: 7,
                        childAspectRatio: 1.0,
                        mainAxisSpacing: 4,
                        crossAxisSpacing: 4,
                      ),
                      itemCount: startWeekday - 1 + daysInMonth,
                      itemBuilder: (context, index) {
                        if (index < startWeekday - 1) {
                          return const SizedBox.shrink();
                        }
                        final dayNum = index - (startWeekday - 1) + 1;
                        final isChecked = checked.contains(dayNum);
                        final isToday = dayNum == now.day;

                        return Container(
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: isChecked
                                ? const Color(0xFF4ADE80)
                                : (isToday
                                    ? const Color(0xFFEC4899).withValues(alpha: 0.15)
                                    : Colors.transparent),
                            border: isToday && !isChecked
                                ? Border.all(color: const Color(0xFFEC4899), width: 1.5)
                                : null,
                          ),
                          child: Center(
                            child: isChecked
                                ? const Icon(Icons.check, size: 16, color: Colors.black)
                                : Text(
                                    '$dayNum',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                                      color: isToday
                                          ? const Color(0xFFEC4899)
                                          : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                                    ),
                                  ),
                          ),
                        );
                      },
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Progress
                  ClipRRect(
                    borderRadius: BorderRadius.circular(10),
                    child: LinearProgressIndicator(
                      value: checked.length / daysInMonth,
                      minHeight: 6,
                      backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                      valueColor: const AlwaysStoppedAnimation<Color>(Color(0xFFEC4899)),
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '${checked.length}/$daysInMonth days',
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 8),
                  // Recover Streak button (monthly)
                  if (canRecoverMonthly && !claimed)
                    SizedBox(
                      width: double.infinity,
                      height: 42,
                      child: ElevatedButton.icon(
                        onPressed: isRecoveringMonthly
                            ? null
                            : () async {
                                // Step 1: Show rewarded ad
                                final rewardAmount =
                                    await AdMobServiceImpl.instance.showRewardedAd();
                                if (rewardAmount == null || ctx.mounted == false) {
                                  if (ctx.mounted) {
                                    ScaffoldMessenger.of(context).showSnackBar(
                                      SnackBar(
                                        content: const Text(
                                            'Ad was skipped. Watch the full ad to recover your streak.'),
                                        behavior: SnackBarBehavior.floating,
                                        shape: RoundedRectangleBorder(
                                            borderRadius: BorderRadius.circular(12)),
                                        backgroundColor: const Color(0xFFEF4444),
                                      ),
                                    );
                                  }
                                  return;
                                }
                                // Step 2: Ad completed — recover streak
                                final rewardProv = context.read<RewardProvider>();
                                final success =
                                    await rewardProv.recoverMonthlyStreak(userId);
                                if (success && ctx.mounted) {
                                  setSheetState(() {});
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text(
                                          '✅ Streak recovered! Missed days restored.'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(
                                          borderRadius: BorderRadius.circular(12)),
                                      backgroundColor: const Color(0xFF8B5CF6),
                                    ),
                                  );
                                }
                              },
                        icon: isRecoveringMonthly
                            ? const SizedBox(
                                width: 18,
                                height: 18,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.restore_outlined, size: 18),
                        label: Text(
                          isRecoveringMonthly
                              ? 'Recovering...'
                              : 'Recover Streak',
                          style: const TextStyle(
                              fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: const Color(0xFF8B5CF6),
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12)),
                        ),
                      ),
                    ),
                  const SizedBox(height: 8),
                  // Claim button
                  SizedBox(
                    width: double.infinity,
                    height: 48,
                    child: ElevatedButton.icon(
                      onPressed: canClaim
                          ? () async {
                              final success = await context.read<RewardProvider>().claimMonthlyBonus(userId);
                              if (success && ctx.mounted) {
                                Navigator.pop(ctx);
                                if (mounted) {
                                  context.read<WalletProvider>().listenToWallet(userId);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('🎉 Monthly Bonus claimed! ₹40 added to your wallet.'),
                                      behavior: SnackBarBehavior.floating,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                                    ),
                                  );
                                }
                              }
                            }
                          : null,
                      icon: Icon(
                        claimed ? Icons.check_circle : Icons.monetization_on_outlined,
                        size: 20,
                      ),
                      label: Text(
                        claimed
                            ? 'Already Claimed ✓'
                            : canClaim
                                ? 'Claim ₹40'
                                : '${daysInMonth - checked.length} day${daysInMonth - checked.length != 1 ? 's' : ''} remaining',
                        style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: claimed
                            ? const Color(0xFF64748B)
                            : canClaim
                                ? const Color(0xFFEC4899)
                                : const Color(0xFF64748B).withValues(alpha: 0.5),
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _RewardFeatureItem {
  final RewardFeature type;
  final String label;
  final String subtitle;
  final IconData icon;
  final Color color;
  final LinearGradient gradient;
  final String? route;

  const _RewardFeatureItem(
    this.type,
    this.label,
    this.subtitle,
    this.icon,
    this.color,
    this.gradient,
    this.route,
  );
}
