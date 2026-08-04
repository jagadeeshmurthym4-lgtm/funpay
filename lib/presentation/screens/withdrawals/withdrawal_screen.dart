import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/providers/withdrawal_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Redeem screen.
///
/// Wallet balance is in-platform currency and has no real-world monetary
/// value. Users spend it on premium features, extra spins, themes and boosters.
/// There are NO cash payouts (UPI / Paytm / bank / QR) — this is aligned with
/// AdSense policy, which prohibits compensating users with real money.
class WithdrawalScreen extends StatefulWidget {
  const WithdrawalScreen({super.key});

  @override
  State<WithdrawalScreen> createState() => _WithdrawalScreenState();
}

class _WithdrawalScreenState extends State<WithdrawalScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId != null) {
      context.read<WithdrawalProvider>().initialize(userId);
    }
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Redeem',
        onBack: () => Navigator.pop(context),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
              borderRadius: BorderRadius.circular(12),
            ),
            child: TabBar(
              controller: _tabController,
              indicator: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.white,
              unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
              tabs: const [
                Tab(text: 'Redeem'),
                Tab(text: 'History'),
              ],
            ),
          ),
        ),
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
        child: Consumer3<AuthProvider, WithdrawalProvider, WalletProvider>(
          builder: (context, auth, withdrawalProvider, walletProvider, _) {
            if (withdrawalProvider.isLoading) {
              return const Center(child: PremiumLoader());
            }

            return TabBarView(
              controller: _tabController,
              children: [
                _RedeemTab(
                  withdrawalProvider: withdrawalProvider,
                  auth: auth,
                  walletProvider: walletProvider,
                  theme: theme,
                ),
                _RedemptionHistoryTab(
                  withdrawals: withdrawalProvider.userWithdrawals,
                  theme: theme,
                  withdrawalProvider: withdrawalProvider,
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// REDEMPTION PERKS CATALOG
// ═══════════════════════════════════════════════════════════════

class _Perk {
  final RedemptionMethod method;
  final String title;
  final String description;
  final double cost;
  final IconData icon;

  const _Perk({
    required this.method,
    required this.title,
    required this.description,
    required this.cost,
    required this.icon,
  });
}

const List<_Perk> _perks = [
  _Perk(
    method: RedemptionMethod.premiumWeek,
    title: 'Premium (1 Week)',
    description: 'Unlock all premium features for 7 days',
    cost: 500,
    icon: Icons.workspace_premium_rounded,
  ),
  _Perk(
    method: RedemptionMethod.premiumMonth,
    title: 'Premium (1 Month)',
    description: 'Unlock all premium features for 30 days',
    cost: 1500,
    icon: Icons.diamond_rounded,
  ),
  _Perk(
    method: RedemptionMethod.extraSpins,
    title: 'Bonus Spins',
    description: '10 extra spins on the Lucky Wheel',
    cost: 300,
    icon: Icons.casino_rounded,
  ),
  _Perk(
    method: RedemptionMethod.themeUnlock,
    title: 'Exclusive Theme',
    description: 'Unlock a limited-edition app theme',
    cost: 400,
    icon: Icons.palette_rounded,
  ),
  _Perk(
    method: RedemptionMethod.boosterPack,
    title: 'Booster Pack',
    description: 'Scratch card + spin boosters bundle',
    cost: 200,
    icon: Icons.rocket_launch_rounded,
  ),
];

// ═══════════════════════════════════════════════════════════════
// REDEEM TAB
// ═══════════════════════════════════════════════════════════════

class _RedeemTab extends StatefulWidget {
  final WithdrawalProvider withdrawalProvider;
  final AuthProvider auth;
  final WalletProvider walletProvider;
  final ThemeData theme;

  const _RedeemTab({
    required this.withdrawalProvider,
    required this.auth,
    required this.walletProvider,
    required this.theme,
  });

  @override
  State<_RedeemTab> createState() => _RedeemTabState();
}

class _RedeemTabState extends State<_RedeemTab> {
  bool _showSuccessAnimation = false;

  Future<void> _submitRedemption(_Perk perk) async {
    final wp = widget.withdrawalProvider;
    final user = widget.auth.user;
    final userId = user?.uid;
    if (userId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        child: PremiumCard(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                ),
                child: Icon(perk.icon,
                    color: widget.theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Redeem ${perk.title}',
                  style: widget.theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Spend ₹${perk.cost.toStringAsFixed(0)} to redeem\\n${perk.description.toLowerCase()}?',
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodyMedium?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 8),
              Text(
                'Your balance is in-platform only and has no cash value.',
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodySmall?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Redeem'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );

    if (confirmed == true && mounted) {
      await wp.requestWithdrawal(
        userId: userId,
        amount: perk.cost,
        method: perk.method,
        accountDetails: perk.title,
        userName: user?.fullName,
        userEmail: user?.email,
        userPhone: user?.phone,
        walletBalanceAtRequest: widget.walletProvider.wallet?.walletBalance ?? user?.walletBalance ?? 0.0,
      );
      if (mounted) setState(() => _showSuccessAnimation = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = widget.withdrawalProvider;
    final user = widget.auth.user;
    final balance = widget.walletProvider.wallet?.walletBalance ?? user?.walletBalance ?? 0.0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Error/Success banners
          if (wp.errorMessage != null)
            _buildBanner(
              message: wp.errorMessage!,
              isError: true,
              onDismiss: wp.clearError,
            ),
          if (wp.successMessage != null)
            _buildBanner(
              message: wp.successMessage!,
              isError: false,
              onDismiss: wp.clearSuccess,
            ),

          // Success animation overlay
          Stack(
            children: [
              // Balance card
              PremiumCard(
                padding: const EdgeInsets.all(20),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.stars_rounded,
                          color: widget.theme.colorScheme.primary, size: 26),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Your Balance',
                              style: widget.theme.textTheme.bodySmall?.copyWith(
                                  color: widget.theme.colorScheme.onSurfaceVariant)),
                          const SizedBox(height: 4),
                          Text(
                            '₹${balance.toStringAsFixed(2)}',
                            style: widget.theme.textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                              color: widget.theme.colorScheme.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                      decoration: BoxDecoration(
                        color: widget.theme.colorScheme.tertiary.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'No cash value',
                        style: widget.theme.textTheme.labelSmall?.copyWith(
                          color: widget.theme.colorScheme.tertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              if (_showSuccessAnimation)
                Positioned.fill(
                  child: _SuccessAnimationOverlay(
                    theme: widget.theme,
                    onComplete: () {
                      if (mounted) setState(() => _showSuccessAnimation = false);
                    },
                  ),
                ),
            ],
          ),

          const SizedBox(height: 16),

          // Info card
          PremiumCard(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(Icons.info_outline, size: 18,
                        color: widget.theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('How it works',
                        style: widget.theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Spend your balance on in-platform perks like Premium access, bonus spins, exclusive themes and boosters. Your balance has no real-world monetary value and cannot be converted to cash.',
                  style: widget.theme.textTheme.bodySmall?.copyWith(
                      color: widget.theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          if (wp.hasPendingWithdrawal)
            PremiumGlass(
              margin: const EdgeInsets.only(bottom: 12),
              padding: const EdgeInsets.all(12),
              gradient: LinearGradient(colors: [
                widget.theme.colorScheme.tertiary.withValues(alpha: 0.12),
                widget.theme.colorScheme.tertiary.withValues(alpha: 0.04),
              ]),
              child: Row(
                children: [
                  Icon(Icons.hourglass_top_rounded,
                      color: widget.theme.colorScheme.tertiary, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'You have a pending redemption request. You can submit a new one once it is processed.',
                      style: widget.theme.textTheme.bodySmall?.copyWith(
                        color: widget.theme.colorScheme.tertiary,
                      ),
                    ),
                  ),
                ],
              ),
            ),

          // Perks grid
          Text('Available Perks',
              style: widget.theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w700)),
          const SizedBox(height: 12),
          ..._perks.map((perk) => _PerkCard(
                perk: perk,
                theme: widget.theme,
                enabled: !wp.isSubmitting && !wp.hasPendingWithdrawal,
                onTap: () => _submitRedemption(perk),
              )),
        ],
      ),
    );
  }

  Widget _buildBanner({
    required String message,
    required bool isError,
    required VoidCallback onDismiss,
  }) {
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      gradient: LinearGradient(colors: [
        isError
            ? widget.theme.colorScheme.error.withValues(alpha: 0.15)
            : widget.theme.colorScheme.tertiary.withValues(alpha: 0.15),
        isError
            ? widget.theme.colorScheme.error.withValues(alpha: 0.05)
            : widget.theme.colorScheme.tertiary.withValues(alpha: 0.05),
      ]),
      child: Row(
        children: [
          Icon(
            isError ? Icons.error_outline : Icons.check_circle,
            color: isError
                ? widget.theme.colorScheme.error
                : widget.theme.colorScheme.tertiary,
            size: 20,
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              message,
              style: widget.theme.textTheme.bodyMedium?.copyWith(
                color: isError
                    ? widget.theme.colorScheme.error
                    : widget.theme.colorScheme.onTertiaryContainer,
              ),
            ),
          ),
          IconButton(
            icon: Icon(Icons.close, size: 18,
                color: isError
                    ? widget.theme.colorScheme.error
                    : widget.theme.colorScheme.onTertiaryContainer),
            onPressed: onDismiss,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// PERK CARD
// ═══════════════════════════════════════════════════════════════

class _PerkCard extends StatelessWidget {
  final _Perk perk;
  final ThemeData theme;
  final bool enabled;
  final VoidCallback onTap;

  const _PerkCard({
    required this.perk,
    required this.theme,
    required this.enabled,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: PremiumGlass(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: enabled ? onTap : null,
          borderRadius: BorderRadius.circular(16),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(perk.icon, color: theme.colorScheme.primary, size: 24),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(perk.title,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    const SizedBox(height: 3),
                    Text(
                      perk.description,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    '₹${perk.cost.toStringAsFixed(0)}',
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w800,
                      color: theme.colorScheme.primary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'Redeem',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
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
}

// ═══════════════════════════════════════════════════════════════
// SUCCESS ANIMATION OVERLAY
// ═══════════════════════════════════════════════════════════════

class _SuccessAnimationOverlay extends StatefulWidget {
  final VoidCallback onComplete;
  final ThemeData theme;

  const _SuccessAnimationOverlay({
    required this.onComplete,
    required this.theme,
  });

  @override
  State<_SuccessAnimationOverlay> createState() => _SuccessAnimationOverlayState();
}

class _SuccessAnimationOverlayState extends State<_SuccessAnimationOverlay>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnimation = CurvedAnimation(
      parent: _controller,
      curve: Curves.elasticOut,
    );
    _controller.forward();
    // Auto-dismiss after animation completes + brief pause
    Future.delayed(const Duration(milliseconds: 2400), () {
      if (mounted) widget.onComplete();
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) {
        final scaleValue = _controller.value;
        final scale = _scaleAnimation.value.clamp(0.0, 1.5);
        final opacity = scaleValue > 0.85
            ? (1.0 - (scaleValue - 0.85) / 0.15).clamp(0.0, 1.0)
            : 1.0;

        return IgnorePointer(
          child: Opacity(
            opacity: opacity,
            child: Transform.scale(
              scale: scale,
              child: Container(
                height: 180,
                decoration: BoxDecoration(
                  color: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.9),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 64,
                        height: 64,
                        child: CustomPaint(
                          painter: _CheckmarkPainter(
                            progress: scaleValue.clamp(0.0, 1.0),
                            color: widget.theme.colorScheme.tertiary,
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Redemption Requested!',
                        style: widget.theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Balance will be deducted after approval',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        );
      },
    );
  }
}

/// Paints an animated circular progress ring + checkmark.
class _CheckmarkPainter extends CustomPainter {
  final double progress;
  final Color color;

  _CheckmarkPainter({required this.progress, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final center = size.center(Offset.zero) + const Offset(0, 0);
    final radius = size.width / 2 - 4;
    final paint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3.5
      ..strokeCap = StrokeCap.round;

    // Phase 1 (0 - 0.6): Draw circular progress ring
    final ringProgress = (progress / 0.6).clamp(0.0, 1.0);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: radius),
      -0.5 * 3.14159, // Start from top
      ringProgress * 2 * 3.14159,
      false,
      paint,
    );

    // Phase 2 (0.4 - 1.0): Draw checkmark
    if (progress > 0.4) {
      final checkProgress = ((progress - 0.4) / 0.6).clamp(0.0, 1.0);
      final checkPaint = Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 3.5
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round;

      final path = Path();
      final c = center;
      final r = radius * 0.5;

      // First stroke of checkmark (down-left)
      final midX = c.dx - r * 0.35;
      final midY = c.dy + r * 0.1;

      if (checkProgress < 0.5) {
        final p = (checkProgress / 0.5).clamp(0.0, 1.0);
        path.moveTo(c.dx - r * 0.5, c.dy - r * 0.1);
        path.lineTo(
          c.dx - r * 0.5 + (midX - (c.dx - r * 0.5)) * p,
          c.dy - r * 0.1 + (midY - (c.dy - r * 0.1)) * p,
        );
      } else {
        final p = ((checkProgress - 0.5) / 0.5).clamp(0.0, 1.0);
        path.moveTo(c.dx - r * 0.5, c.dy - r * 0.1);
        path.lineTo(midX, midY);
        path.lineTo(
          midX + (c.dx + r * 0.5 - midX) * p,
          midY + (c.dy + r * 0.35 - midY) * p,
        );
      }

      canvas.drawPath(path, checkPaint);
    }
  }

  @override
  bool shouldRepaint(_CheckmarkPainter oldDelegate) =>
      oldDelegate.progress != progress;
}

// ═══════════════════════════════════════════════════════════════
// REDEMPTION HISTORY TAB
// ═══════════════════════════════════════════════════════════════

class _RedemptionHistoryTab extends StatelessWidget {
  final List<WithdrawalEntity> withdrawals;
  final ThemeData theme;
  final WithdrawalProvider withdrawalProvider;

  const _RedemptionHistoryTab({
    required this.withdrawals,
    required this.theme,
    required this.withdrawalProvider,
  });

  @override
  Widget build(BuildContext context) {
    if (withdrawals.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.redeem_rounded, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No redemptions yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Redeem your balance for in-platform perks above',
                style: theme.textTheme.bodyMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        final auth = context.read<AuthProvider>();
        final userId = auth.user?.uid;
        if (userId != null) await withdrawalProvider.initialize(userId);
      },
      child: ListView.builder(
        padding: const EdgeInsets.all(16),
        itemCount: withdrawals.length,
        itemBuilder: (context, index) {
          final withdrawal = withdrawals[index];
          return _RedemptionCard(
            withdrawal: withdrawal,
            theme: theme,
            onTap: () {
              withdrawalProvider.selectWithdrawal(withdrawal);
              _showDetail(context, withdrawal, theme);
            },
          );
        },
      ),
    );
  }

  void _showDetail(
      BuildContext context, WithdrawalEntity withdrawal, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumCard(
        margin: EdgeInsets.zero,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: _RedemptionDetailSheet(withdrawal: withdrawal, theme: theme),
      ),
    );
  }
}

class _RedemptionCard extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;
  final VoidCallback onTap;

  const _RedemptionCard({
    required this.withdrawal,
    required this.theme,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(withdrawal.status);
    final statusLabel = _statusLabel(withdrawal.status);

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Row(
          children: [
            IconContainer(
                icon: Icons.redeem_rounded,
                color: statusColor,
                containerSize: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(withdrawal.accountDetails,
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(
                    Helpers.formatDateTime(withdrawal.requestedAt),
                    style: theme.textTheme.bodySmall?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  '-₹${withdrawal.amount.toStringAsFixed(2)}',
                  style: theme.textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: theme.colorScheme.primary,
                  ),
                ),
                const SizedBox(height: 4),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    statusLabel,
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: statusColor,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.paid:
        return Colors.teal;
      case WithdrawalStatus.approved:
        return Colors.green;
      case WithdrawalStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  String _statusLabel(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.paid:
        return 'Granted';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }
}

class _RedemptionDetailSheet extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;

  const _RedemptionDetailSheet({required this.withdrawal, required this.theme});

  @override
  Widget build(BuildContext context) {
    final statusColor = _statusColor(withdrawal.status);

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
              borderRadius: BorderRadius.circular(2),
            ),
          ),
        ),
        const SizedBox(height: 20),

        // Status badge
        Center(
          child: Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
            decoration: BoxDecoration(
              color: statusColor.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _statusLabel(withdrawal.status).toUpperCase(),
              style: theme.textTheme.labelMedium?.copyWith(
                color: statusColor,
                fontWeight: FontWeight.bold,
                letterSpacing: 1,
              ),
            ),
          ),
        ),
        const SizedBox(height: 24),

        // Amount
        Center(
          child: Text(
            '-₹${withdrawal.amount.toStringAsFixed(2)}',
            style: theme.textTheme.displaySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.colorScheme.primary,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            withdrawal.accountDetails,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 12),

        _DetailRow(
            label: 'Redemption ID',
            value: withdrawal.withdrawalId,
            theme: theme),
        const SizedBox(height: 8),
        _DetailRow(
            label: 'Perk',
            value: withdrawal.accountDetails,
            theme: theme),
        const SizedBox(height: 8),
        if (withdrawal.transactionId != null) ...[
          _DetailRow(
              label: 'Reference ID',
              value: withdrawal.transactionId!,
              theme: theme),
          const SizedBox(height: 8),
        ],
        _DetailRow(
          label: 'Requested',
          value: Helpers.formatDateTime(withdrawal.requestedAt),
          theme: theme,
        ),
        if (withdrawal.processedAt != null) ...[
          const SizedBox(height: 8),
          _DetailRow(
            label: 'Processed',
            value: Helpers.formatDateTime(withdrawal.processedAt!),
            theme: theme,
          ),
        ],
        if (withdrawal.adminRemarks != null) ...[
          const SizedBox(height: 8),
          _DetailRow(
              label: 'Admin Remarks',
              value: withdrawal.adminRemarks!,
              theme: theme),
        ],
        const SizedBox(height: 16),
      ],
    );
  }

  Color _statusColor(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return Colors.orange;
      case WithdrawalStatus.paid:
        return Colors.teal;
      case WithdrawalStatus.approved:
        return Colors.green;
      case WithdrawalStatus.rejected:
        return theme.colorScheme.error;
    }
  }

  String _statusLabel(WithdrawalStatus status) {
    switch (status) {
      case WithdrawalStatus.pending:
        return 'Pending';
      case WithdrawalStatus.paid:
        return 'Granted';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _DetailRow(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120,
          child: Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: theme.textTheme.bodyMedium
                ?.copyWith(fontWeight: FontWeight.w500),
          ),
        ),
      ],
    );
  }
}
