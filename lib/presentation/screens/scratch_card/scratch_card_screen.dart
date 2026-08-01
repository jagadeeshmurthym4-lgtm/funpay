import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/scratch_card_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class ScratchCardScreen extends StatefulWidget {
  const ScratchCardScreen({super.key});

  @override
  State<ScratchCardScreen> createState() => _ScratchCardScreenState();
}

class _ScratchCardScreenState extends State<ScratchCardScreen>
    with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late Animation<double> _pulseAnimation;
  late AnimationController _popupController;
  late Animation<double> _popupScale;
  late Animation<double> _popupFade;

  // Scratch card visual state
  bool _isScratched = false;
  bool _showReward = false;
  bool _isProcessing = false;
  double _lastAmount = 0.0;

  @override
  void initState() {
    super.initState();

    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 0.95, end: 1.0).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    _popupController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    );
    _popupScale = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeOutBack,
    );
    _popupFade = CurvedAnimation(
      parent: _popupController,
      curve: Curves.easeIn,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) => _initialize());
  }

  void _initialize() {
    final userId = context.read<AuthProvider>().user?.uid;
    if (userId != null) {
      context.read<ScratchCardProvider>().listenToCards(userId);
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _popupController.dispose();
    super.dispose();
  }

  String get _userId =>
      context.read<AuthProvider>().user?.uid ?? '';

  Future<void> _onScratchComplete() async {
    if (_isProcessing) return;
    final uid = _userId;
    if (uid.isEmpty) return;

    HapticFeedback.heavyImpact();

    setState(() {
      _isProcessing = true;
      _showReward = true;
    });

    try {
      final provider = context.read<ScratchCardProvider>();
      final amount = await provider.scratchCard(uid);

      if (mounted) {
        if (amount != null) {
          _lastAmount = amount;
          setState(() => _isScratched = true);
          _popupController.reset();
          _popupController.forward();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(provider.errorMessage ?? 'Failed to scratch card'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
          setState(() {
            _isScratched = false;
            _showReward = false;
          });
        }
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF081A2E) : const Color(0xFFF0F5FF),
      body: SafeArea(
        child: Stack(
          children: [
            // Main content
            Consumer<ScratchCardProvider>(
              builder: (context, provider, _) {
                final available = provider.availableCards;
                final hasCards = available > 0;

                if (!provider.hasLoadedOnce) {
                  return Column(
                    children: [
                      _buildHeader(isDark, available),
                      const Expanded(
                        child: Center(
                          child: CircularProgressIndicator(color: Color(0xFF8B5CF6)),
                        ),
                      ),
                    ],
                  );
                }

                return Column(
                  children: [
                    _buildHeader(isDark, available),
                    Expanded(
                      child: SingleChildScrollView(
                        physics: const BouncingScrollPhysics(),
                        padding: const EdgeInsets.fromLTRB(16, 8, 16, 80),
                        child: Column(
                          children: [
                            const SizedBox(height: 12),
                            if (hasCards) ...[
                              _buildScratchCard(isDark, provider),
                              const SizedBox(height: 24),
                              _buildScratchInstruction(isDark),
                            ] else ...[
                              _buildEmptyState(isDark),
                            ],
                            const SizedBox(height: 24),
                            _buildCardStats(isDark, provider),
                          ],
                        ),
                      ),
                    ),
                  ],
                );
              },
            ),

            // Reward popup overlay
            if (_showReward)
              _buildRewardPopup(),
          ],
        ),
      ),
    );
  }

  Widget _buildHeader(bool isDark, int available) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => Navigator.pop(context),
            child: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F2740)
                    : Colors.white,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                      : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
                ),
              ),
              child: Icon(Icons.arrow_back_rounded,
                  color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
            ),
          ),
          const SizedBox(width: 12),
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.auto_fix_high_outlined,
                size: 20, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(width: 10),
          Text(
            'Scratch Card',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w800,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const Spacer(),
          // Available cards badge
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: available > 0
                  ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                  : (isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9)),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: available > 0
                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.3)
                    : (isDark ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                              : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.discount_outlined,
                  size: 14,
                  color: available > 0
                      ? const Color(0xFF8B5CF6)
                      : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                ),
                const SizedBox(width: 4),
                Text(
                  '$available card${available != 1 ? 's' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: available > 0
                        ? const Color(0xFF8B5CF6)
                        : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchCard(bool isDark, ScratchCardProvider provider) {
    return AnimatedBuilder(
      animation: _pulseAnimation,
      builder: (context, child) {
        return Transform.scale(
          scale: _isScratched ? 1.0 : _pulseAnimation.value,
          child: Container(
            width: double.infinity,
            constraints: const BoxConstraints(maxWidth: 320),
            height: 200,
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(24),
              gradient: const LinearGradient(
                colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: [
                BoxShadow(
                  color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                  blurRadius: 30,
                  offset: const Offset(0, 12),
                ),
              ],
            ),
            child: _isScratched
                ? _buildRevealedCard(isDark)
                : _buildUnscratchedCard(isDark),
          ),
        );
      },
    );
  }

  Widget _buildUnscratchedCard(bool isDark) {
    return GestureDetector(
      onTap: _isProcessing ? null : _onScratchComplete,
      child: Stack(
        children: [
          // Shimmer overlay pattern
          Positioned.fill(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(24),
              child: CustomPaint(
                painter: const _ScratchOverlayPainter(),
              ),
            ),
          ),
          // Content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.15),
                    shape: BoxShape.circle,
                  ),
                  child: _isProcessing
                      ? const SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.auto_fix_high_rounded,
                          size: 32, color: Colors.white),
                ),
                const SizedBox(height: 12),
                const Text(
                  'Tap to Scratch!',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Win up to 7 pts!',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.7),
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          // Decorative elements
          Positioned(
            top: 12,
            right: 12,
            child: Icon(Icons.star_rounded, size: 20,
                color: Colors.white.withValues(alpha: 0.2)),
          ),
          Positioned(
            bottom: 16,
            left: 16,
            child: Icon(Icons.star_rounded, size: 14,
                color: Colors.white.withValues(alpha: 0.15)),
          ),
          Positioned(
            bottom: 40,
            right: 24,
            child: Icon(Icons.star_rounded, size: 10,
                color: Colors.white.withValues(alpha: 0.2)),
          ),
        ],
      ),
    );
  }

  Widget _buildRevealedCard(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 40),
          const SizedBox(height: 8),
          const Text(
            'You Won!',
            style: TextStyle(
              color: Colors.white,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_lastAmount.toStringAsFixed(0)} pts',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 36,
              fontWeight: FontWeight.w900,
              letterSpacing: -1,
            ),
          ),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              _lastAmount >= 5 ? '🎉 Lucky!' : '✨ Nice!',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildScratchInstruction(bool isDark) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2740) : Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
              : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Icon(Icons.touch_app_outlined, size: 16,
              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Tap the card above to scratch and reveal your reward instantly!',
              style: TextStyle(
                fontSize: 12,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                height: 1.4,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(bool isDark) {
    final userId = context.watch<AuthProvider>().user?.uid ?? '';
    final scProv = context.watch<ScratchCardProvider>();
    final isEarning = scProv.isEarningFromAd;

    return Container(
      width: double.infinity,
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
      decoration: BoxDecoration(
        color: isDark
            ? const Color(0xFF0F2740).withValues(alpha: 0.6)
            : Colors.white.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark
              ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
              : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.auto_fix_high_outlined,
                size: 40, color: Color(0xFF8B5CF6)),
          ),
          const SizedBox(height: 16),
          Text(
            'No Scratch Cards',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Complete an approved project or watch an ad to earn a Scratch Card.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Watch Ad & Get Scratch Card button
          SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton.icon(
              onPressed: isEarning
                  ? null
                  : () async {
                      HapticFeedback.mediumImpact();
                      final success = await scProv.earnScratchCardFromAd(userId);
                      if (mounted) {
                        if (success) {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('🎉 Scratch Card earned! Check your cards below.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFF8B5CF6),
                            ),
                          );
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: const Text('Ad was skipped. Please try again.'),
                              behavior: SnackBarBehavior.floating,
                              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                              backgroundColor: const Color(0xFFEF4444),
                            ),
                          );
                        }
                      }
                    },
              icon: isEarning
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black87,
                      ),
                    )
                  : const Icon(Icons.play_circle_fill_rounded, size: 22),
              label: Text(
                isEarning ? 'Watching Ad...' : 'Watch Ad & Get Scratch Card',
                style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF8B5CF6),
                foregroundColor: Colors.white,
                disabledBackgroundColor: const Color(0xFF8B5CF6).withValues(alpha: 0.5),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                elevation: 4,
                shadowColor: const Color(0xFF8B5CF6).withValues(alpha: 0.3),
              ),
            ),
          ),
          const SizedBox(height: 12),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.2),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.info_outline, size: 14, color: Color(0xFF8B5CF6)),
                const SizedBox(width: 6),
                Flexible(
                  child: Text(
                    'Every approved project or ad = 1 Scratch Card',
                    style: TextStyle(
                      fontSize: 10,
                      color: const Color(0xFF8B5CF6),
                      fontWeight: FontWeight.w500,
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

  Widget _buildCardStats(bool isDark, ScratchCardProvider provider) {
    final total = provider.scratchCards.length;
    final used = total - provider.availableCards;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
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
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.bar_chart_rounded, size: 16,
                  color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
              const SizedBox(width: 6),
              Text(
                'Scratch Card Stats',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _buildStatItem(
                icon: Icons.discount_outlined,
                value: '$total',
                label: 'Total Earned',
                color: const Color(0xFF8B5CF6),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatItem(
                icon: Icons.check_circle_outline,
                value: '$used',
                label: 'Scratched',
                color: const Color(0xFF4ADE80),
                isDark: isDark,
              ),
              const SizedBox(width: 8),
              _buildStatItem(
                icon: Icons.pending_outlined,
                value: '${provider.availableCards}',
                label: 'Available',
                color: const Color(0xFFF59E0B),
                isDark: isDark,
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    required String label,
    required Color color,
    required bool isDark,
  }) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.08),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          children: [
            Icon(icon, color: color, size: 18),
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

  Widget _buildRewardPopup() {
    return AnimatedBuilder(
      animation: _popupController,
      builder: (context, child) {
        return Opacity(
          opacity: _popupFade.value,
          child: Stack(
            children: [
              // Backdrop
              Positioned.fill(
                child: GestureDetector(
                  onTap: () => _dismissPopup(),
                  child: Container(color: Colors.black.withValues(alpha: 0.5)),
                ),
              ),
              // Popup card
              Center(
                child: Transform.scale(
                  scale: _popupScale.value,
                  child: Container(
                    margin: const EdgeInsets.symmetric(horizontal: 32),
                    padding: const EdgeInsets.all(28),
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(28),
                      gradient: const LinearGradient(
                        colors: [Color(0xFF8B5CF6), Color(0xFF7C3AED)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF8B5CF6).withValues(alpha: 0.4),
                          blurRadius: 30,
                          offset: const Offset(0, 12),
                        ),
                      ],
                    ),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Text('🎉', style: TextStyle(fontSize: 56)),
                        const SizedBox(height: 12),
                        const Text(
                          'Congratulations!',
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        const SizedBox(height: 16),
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
                                const Text(
                                  'You Won',
                                  style: TextStyle(
                                    color: Colors.white70,
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  '${_lastAmount.toStringAsFixed(0)} pts',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 34,
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
                            onPressed: () => _dismissPopup(),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.white,
                              foregroundColor: const Color(0xFF7C3AED),
                              padding: const EdgeInsets.symmetric(vertical: 14),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              elevation: 4,
                            ),
                            child: const Text(
                              'Awesome!',
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 16,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  void _dismissPopup() {
    HapticFeedback.lightImpact();
    setState(() {
      _showReward = false;
      _isScratched = false;
    });
    _popupController.reset();
    // Clear the last scratch result in the provider
    context.read<ScratchCardProvider>().clearLastScratchResult();
  }
}

/// Simple painter for the scratch overlay design.
class _ScratchOverlayPainter extends CustomPainter {
  const _ScratchOverlayPainter();

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..shader = const LinearGradient(
        colors: [Color(0xFFA78BFA), Color(0xFF8B5CF6), Color(0xFF7C3AED)],
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    // Draw diagonal stripes for visual interest
    canvas.save();
    for (double i = -size.width; i < size.width + size.height; i += 24) {
      final stripePaint = Paint()
        ..color = Colors.white.withValues(alpha: 0.08);
      final path = Path();
      path.moveTo(i, 0);
      path.lineTo(i + 12, 0);
      path.lineTo(i + 12 + size.height, size.height);
      path.lineTo(i + size.height, size.height);
      path.close();
      canvas.drawPath(path, stripePaint);
    }
    canvas.restore();

    // Fill the card with gradient
    canvas.drawRect(Rect.fromLTWH(0, 0, size.width, size.height), paint);
  }

  @override
  bool shouldRepaint(_ScratchOverlayPainter oldDelegate) => false;
}
