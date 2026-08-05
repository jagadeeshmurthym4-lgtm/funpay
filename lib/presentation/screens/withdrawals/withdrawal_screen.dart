import 'package:cached_network_image/cached_network_image.dart';
import 'package:cashspark/core/utils/helpers.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/withdrawal_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/wallet_provider.dart';
import 'package:cashspark/presentation/providers/withdrawal_provider.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';

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
        title: 'Withdrawals',
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
                Tab(text: 'Request'),
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
                _WithdrawalRequestTab(
                  withdrawalProvider: withdrawalProvider,
                  auth: auth,
                  walletProvider: walletProvider,
                  theme: theme,
                ),
                _WithdrawalHistoryTab(
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
// SUCCESS ANIMATION OVERLAY
// ═══════════════════════════════════════════════════════════════

/// A premium success overlay with a scale-in, circular progress + checkmark draw animation.
/// Shows for ~2 seconds then dismisses itself.
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
                        'QR Code Uploaded!',
                        style: widget.theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: widget.theme.colorScheme.tertiary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Ready for withdrawals',
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
// QR CODE CARD
// ═══════════════════════════════════════════════════════════════

class _QrCodeCard extends StatelessWidget {
  final String userId;
  final String? qrCodeUrl;
  final bool isUploading;
  final VoidCallback onUpload;
  final VoidCallback onReplace;
  final VoidCallback onDelete;
  final VoidCallback onPreview;
  final ThemeData theme;

  const _QrCodeCard({
    required this.userId,
    this.qrCodeUrl,
    required this.isUploading,
    required this.onUpload,
    required this.onReplace,
    required this.onDelete,
    required this.onPreview,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: theme.colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(Icons.qr_code_scanner_rounded,
                    color: theme.colorScheme.primary, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('UPI QR Code',
                        style: theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                      qrCodeUrl != null
                          ? 'QR Code ready for withdrawals'
                          : 'Upload your UPI QR code to withdraw',
                      style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // QR Code preview or upload area
          if (isUploading)
            Container(
              height: 180,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
              ),
              child: const Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    SizedBox(
                      width: 36,
                      height: 36,
                      child: CircularProgressIndicator(strokeWidth: 3),
                    ),
                    SizedBox(height: 12),
                    Text('Uploading QR Code...'),
                  ],
                ),
              ),
            )
          else if (qrCodeUrl != null)
            GestureDetector(
              onTap: onPreview,
              child: Container(
                height: 160,
                width: double.infinity,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: theme.colorScheme.primary.withValues(alpha: 0.2),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: theme.colorScheme.primary.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(15),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: qrCodeUrl!,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.broken_image_outlined, size: 32,
                                  color: theme.colorScheme.error),
                              const SizedBox(height: 4),
                              Text('Failed to load',
                                  style: theme.textTheme.bodySmall?.copyWith(
                                      color: theme.colorScheme.error)),
                            ],
                          ),
                        ),
                      ),
                      // Tap to zoom hint
                      Positioned(
                        right: 8,
                        top: 8,
                        child: Container(
                          padding: const EdgeInsets.all(6),
                          decoration: BoxDecoration(
                            color: Colors.black54,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: const Icon(Icons.zoom_in, color: Colors.white, size: 18),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          else
            Container(
              height: 140,
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: theme.colorScheme.outlineVariant.withValues(alpha: 0.5),
                  style: BorderStyle.solid,
                ),
              ),
              child: InkWell(
                onTap: onUpload,
                borderRadius: BorderRadius.circular(16),
                child: Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.cloud_upload_outlined,
                          size: 40, color: theme.colorScheme.primary),
                      const SizedBox(height: 8),
                      Text('Tap to Upload UPI QR Code',
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.primary,
                            fontWeight: FontWeight.w500,
                          )),
                      const SizedBox(height: 4),
                      Text('PNG, JPG or JPEG • Max 5 MB',
                          style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),
            ),

          if (qrCodeUrl != null) ...[
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onReplace,
                    icon: const Icon(Icons.swap_horiz_rounded, size: 18),
                    label: const Text('Replace'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onPreview,
                    icon: const Icon(Icons.zoom_in_rounded, size: 18),
                    label: const Text('Preview'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: onDelete,
                    icon: const Icon(Icons.delete_outline_rounded, size: 18),
                    label: const Text('Delete'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: theme.colorScheme.error,
                      side: BorderSide(color: theme.colorScheme.error.withValues(alpha: 0.5)),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════
// WITHDRAWAL REQUEST TAB
// ═══════════════════════════════════════════════════════════════

class _WithdrawalRequestTab extends StatefulWidget {
  final WithdrawalProvider withdrawalProvider;
  final AuthProvider auth;
  final WalletProvider walletProvider;
  final ThemeData theme;

  const _WithdrawalRequestTab({
    required this.withdrawalProvider,
    required this.auth,
    required this.walletProvider,
    required this.theme,
  });

  @override
  State<_WithdrawalRequestTab> createState() => _WithdrawalRequestTabState();
}

class _WithdrawalRequestTabState extends State<_WithdrawalRequestTab> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _accountDetailsController = TextEditingController();
  final _picker = ImagePicker();
  WithdrawalMethod _selectedMethod = WithdrawalMethod.upi;
  bool _showSuccessAnimation = false;

  @override
  void initState() {
    super.initState();
    // Set QR code URL from user profile
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final auth = widget.auth;
      if (auth.user?.upiQrCodeUrl != null) {
        widget.withdrawalProvider.setQrCodeUrl(auth.user!.upiQrCodeUrl!);
      }
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _accountDetailsController.dispose();
    super.dispose();
  }

  Future<void> _pickAndUploadQr() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 1024,
        maxHeight: 1024,
      );
      if (image == null) return;

      final userId = widget.auth.user?.uid;
      if (userId == null) return;

      final success = await widget.withdrawalProvider.uploadQrCode(
        userId: userId,
        imageFile: image,
      );

      if (success && mounted) {
        // Update the user's profile with the QR code URL and timestamps
        final wp = widget.withdrawalProvider;
        if (wp.qrCodeUrl != null) {
          final now = DateTime.now();
          final userId = widget.auth.user?.uid;
          await widget.auth.updateProfile(
            upiQrCodeUrl: wp.qrCodeUrl,
            qrCodeUploadedAt: now,
            qrCodeUpdatedAt: now,
            qrCodeUploadedBy: userId,
          );
        }
        // Show success animation overlay
        setState(() => _showSuccessAnimation = true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _deleteQr() async {
    final userId = widget.auth.user?.uid;
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
                  color: widget.theme.colorScheme.error.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.delete_outline_rounded,
                    color: widget.theme.colorScheme.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Delete QR Code?',
                  style: widget.theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text(
                'Your UPI QR Code will be removed. You cannot withdraw until you upload a new one.',
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodyMedium?.copyWith(
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
                        backgroundColor: widget.theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Delete'),
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
      final success = await widget.withdrawalProvider.deleteQrCode(userId: userId);
      if (success && mounted) {
        await widget.auth.updateProfile(
          upiQrCodeUrl: null,
          qrCodeUploadedAt: null,
          qrCodeUpdatedAt: null,
          qrCodeUploadedBy: null,
        );
      }
    }
  }

  void _showQrPreview() {
    final url = widget.withdrawalProvider.qrCodeUrl;
    if (url == null) return;

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Container(
                      height: 300,
                      color: widget.theme.colorScheme.surfaceContainerHighest,
                      child: const Center(child: CircularProgressIndicator()),
                    ),
                    errorWidget: (_, __, ___) => Container(
                      height: 300,
                      color: widget.theme.colorScheme.surfaceContainerHighest,
                      child: const Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.broken_image_outlined, size: 48),
                          Text('Failed to load image'),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _submitRequest() async {
    if (!_formKey.currentState!.validate()) return;

    final wp = widget.withdrawalProvider;
    final user = widget.auth.user;
    final userId = user?.uid;
    if (userId == null) return;

    final amount = double.tryParse(_amountController.text) ?? 0;
    final accountDetails = _accountDetailsController.text.trim();

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
                child: Icon(Icons.payments_outlined,
                    color: widget.theme.colorScheme.primary, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Confirm Withdrawal',
                  style: widget.theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              Text(
                'Are you sure you want to withdraw\n₹${amount.toStringAsFixed(2)} via ${_methodDisplayName()}?',
                textAlign: TextAlign.center,
                style: widget.theme.textTheme.bodyMedium?.copyWith(
                    color: widget.theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              if (_selectedMethod == WithdrawalMethod.upi && wp.qrCodeUrl != null)
                Container(
                  height: 80,
                  width: 80,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                        color: widget.theme.colorScheme.primary.withValues(alpha: 0.2)),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(11),
                    child: CachedNetworkImage(
                      imageUrl: wp.qrCodeUrl!,
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Padding(
                        padding: EdgeInsets.all(16),
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  ),
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
                      child: const Text('Confirm'),
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
        amount: amount,
        method: _selectedMethod,
        accountDetails: _selectedMethod == WithdrawalMethod.upi
            ? 'UPI QR Code'
            : accountDetails,
        qrCodeUrl: _selectedMethod == WithdrawalMethod.upi ? wp.qrCodeUrl : null,
        userName: user?.fullName,
        userEmail: user?.email,
        userPhone: user?.phone,
        walletBalanceAtRequest: widget.walletProvider.wallet?.walletBalance ?? user?.walletBalance ?? 0.0,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final wp = widget.withdrawalProvider;
    final user = widget.auth.user;
    final hasQrCode = wp.qrCodeUrl != null;
    final needsQrCode = _selectedMethod == WithdrawalMethod.upi;
    final canSubmit = !wp.isSubmitting &&
        !wp.hasPendingWithdrawal &&
        (!needsQrCode || hasQrCode);

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

          // QR Code Card with success animation overlay
          Stack(
            children: [
              _QrCodeCard(
                userId: user?.uid ?? '',
                qrCodeUrl: wp.qrCodeUrl,
                isUploading: wp.isQrUploading,
                onUpload: _pickAndUploadQr,
                onReplace: _pickAndUploadQr,
                onDelete: _deleteQr,
                onPreview: _showQrPreview,
                theme: widget.theme,
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

          // Limits Card
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
                    Text('Withdrawal Info',
                        style: widget.theme.textTheme.titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600)),
                  ],
                ),
                const SizedBox(height: 12),
                _LimitRow(
                  label: 'Minimum Amount',
                  value: '₹${wp.minWithdrawalAmount.toStringAsFixed(2)}',
                  theme: widget.theme,
                ),
                const SizedBox(height: 8),
                _LimitRow(
                  label: 'Wallet Balance',
                  value: '₹${(widget.walletProvider.wallet?.walletBalance ?? user?.walletBalance ?? 0).toStringAsFixed(2)}',
                  theme: widget.theme,
                ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Withdrawal Form
          PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Request Withdrawal',
                      style: widget.theme.textTheme.titleSmall
                          ?.copyWith(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 20),

                  // Amount
                  TextFormField(
                    controller: _amountController,
                    keyboardType:
                        const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Amount',
                      prefixText: '₹ ',
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      hintText: 'Enter amount',
                      filled: true,
                      fillColor: widget.theme.colorScheme.surfaceContainerHighest
                          .withValues(alpha: 0.3),
                    ),
                    validator: (value) {
                      if (value == null || value.isEmpty) {
                        return 'Please enter an amount';
                      }
                      final amount = double.tryParse(value);
                      if (amount == null || amount <= 0) {
                        return 'Enter a valid amount';
                      }
                      if (amount < wp.minWithdrawalAmount) {
                        return 'Minimum withdrawal is ₹${wp.minWithdrawalAmount.toStringAsFixed(2)}';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),

                  // Withdrawal Method (UPI QR is default, other methods available)
                  DropdownButtonFormField<WithdrawalMethod>(
                    value: _selectedMethod,
                    decoration: InputDecoration(
                      labelText: 'Withdrawal Method',
                      border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                      filled: true,
                      fillColor: widget.theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: WithdrawalMethod.upi,
                        child: Row(
                          children: [
                            Icon(Icons.qr_code_scanner_rounded, size: 18),
                            SizedBox(width: 8),
                            Text('UPI (QR Code)'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: WithdrawalMethod.upiId,
                        child: Row(
                          children: [
                            Icon(Icons.person_outline, size: 18),
                            SizedBox(width: 8),
                            Text('UPI ID'),
                          ],
                        ),
                      ),
                      DropdownMenuItem(
                        value: WithdrawalMethod.paytm,
                        child: Row(
                          children: [
                            Icon(Icons.account_balance_wallet_outlined, size: 18),
                            SizedBox(width: 8),
                            Text('Paytm'),
                          ],
                        ),
                      ),
                    ],
                    onChanged: (value) {
                      if (value != null) setState(() => _selectedMethod = value);
                    },
                  ),
                  const SizedBox(height: 16),

                  // Account Details — hidden when using UPI (QR Code)
                  if (_selectedMethod != WithdrawalMethod.upi)
                    TextFormField(
                      controller: _accountDetailsController,
                      decoration: InputDecoration(
                        labelText: _getAccountLabel(),
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12)),
                        hintText: _getAccountHint(),
                        filled: true,
                        fillColor: widget.theme.colorScheme.surfaceContainerHighest
                            .withValues(alpha: 0.3),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your ${_getAccountLabel().toLowerCase()}';
                        }
                        return null;
                      },
                    ),
                  const SizedBox(height: 24),

                  // Submit Button
                  GradientButton(
                    onPressed: canSubmit ? _submitRequest : null,
                    label: needsQrCode && !hasQrCode
                        ? 'Upload QR Code First'
                        : wp.hasPendingWithdrawal
                            ? 'Pending Request Exists'
                            : wp.isSubmitting
                                ? 'Submitting...'
                                : 'Submit Withdrawal Request',
                    isLoading: wp.isSubmitting,
                    icon: Icons.send_rounded,
                  ),

                  if (needsQrCode && !hasQrCode)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'Please upload your UPI QR Code before requesting a withdrawal.',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.error,
                        ),
                      ),
                    ),
                  if (wp.hasPendingWithdrawal)
                    Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        'You have a pending withdrawal request. Wait for it to be processed.',
                        style: widget.theme.textTheme.bodySmall?.copyWith(
                          color: widget.theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  String _getAccountLabel() {
    switch (_selectedMethod) {
      case WithdrawalMethod.upi:
        return 'UPI ID';
      case WithdrawalMethod.upiId:
        return 'UPI ID';
      case WithdrawalMethod.paytm:
        return 'Paytm Number';
    }
  }

  String _getAccountHint() {
    switch (_selectedMethod) {
      case WithdrawalMethod.upi:
        return 'example@upi';
      case WithdrawalMethod.upiId:
        return 'Enter your UPI ID';
      case WithdrawalMethod.paytm:
        return 'Enter your Paytm registered number';
    }
  }

  String _methodDisplayName() {
    switch (_selectedMethod) {
      case WithdrawalMethod.upi:
        return 'UPI (QR Code)';
      case WithdrawalMethod.upiId:
        return 'UPI ID';
      case WithdrawalMethod.paytm:
        return 'Paytm';
    }
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
// WITHDRAWAL HISTORY TAB
// ═══════════════════════════════════════════════════════════════

class _WithdrawalHistoryTab extends StatelessWidget {
  final List<WithdrawalEntity> withdrawals;
  final ThemeData theme;
  final WithdrawalProvider withdrawalProvider;

  const _WithdrawalHistoryTab({
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
            Icon(Icons.receipt_long_outlined, size: 64,
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3)),
            const SizedBox(height: 16),
            Text('No withdrawal requests yet',
                style: theme.textTheme.titleMedium
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
            const SizedBox(height: 8),
            Text('Submit your first withdrawal request above',
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
          return _WithdrawalCard(
            withdrawal: withdrawal,
            theme: theme,
            onTap: () {
              withdrawalProvider.selectWithdrawal(withdrawal);
              _showWithdrawalDetail(context, withdrawal, theme);
            },
          );
        },
      ),
    );
  }

  void _showWithdrawalDetail(
      BuildContext context, WithdrawalEntity withdrawal, ThemeData theme) {
    showModalBottomSheet(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (context) => PremiumCard(
        margin: EdgeInsets.zero,
        borderRadius: 24,
        padding: const EdgeInsets.all(24),
        child: _WithdrawalDetailSheet(withdrawal: withdrawal, theme: theme),
      ),
    );
  }
}

class _WithdrawalCard extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;
  final VoidCallback onTap;

  const _WithdrawalCard({
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
                icon: Icons.phone_android_outlined,
                color: statusColor,
                containerSize: 44),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('UPI Transfer',
                      style: theme.textTheme.bodyMedium
                          ?.copyWith(fontWeight: FontWeight.w600)),
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
                    color: theme.colorScheme.error,
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
        return 'Paid';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }
}

class _WithdrawalDetailSheet extends StatelessWidget {
  final WithdrawalEntity withdrawal;
  final ThemeData theme;

  const _WithdrawalDetailSheet({required this.withdrawal, required this.theme});

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
              color: theme.colorScheme.error,
            ),
          ),
        ),
        const SizedBox(height: 4),
        Center(
          child: Text(
            'UPI Transfer',
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
          ),
        ),
        const SizedBox(height: 24),

        const Divider(),
        const SizedBox(height: 12),

        if (withdrawal.qrCodeUrl != null) ...[
          Center(
            child: GestureDetector(
              onTap: () => _showQrPreviewDialog(context, withdrawal.qrCodeUrl!),
              child: Container(
                height: 100,
                width: 100,
                margin: const EdgeInsets.only(bottom: 16),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                      color: theme.colorScheme.primary.withValues(alpha: 0.2)),
                ),
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(11),
                  child: CachedNetworkImage(
                    imageUrl: withdrawal.qrCodeUrl!,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => const Padding(
                      padding: EdgeInsets.all(20),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    errorWidget: (_, __, ___) => const Icon(Icons.broken_image_outlined),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),
        ],

        _DetailRow(
            label: 'Withdrawal ID',
            value: withdrawal.withdrawalId,
            theme: theme),
        const SizedBox(height: 8),
        _DetailRow(
            label: 'Account Details',
            value: withdrawal.accountDetails,
            theme: theme),
        const SizedBox(height: 8),
        if (withdrawal.transactionId != null) ...[
          _DetailRow(
              label: 'Transaction ID',
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

  void _showQrPreviewDialog(BuildContext context, String url) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(24),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
              ),
              child: InteractiveViewer(
                minScale: 0.5,
                maxScale: 4.0,
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(16),
                  child: CachedNetworkImage(
                    imageUrl: url,
                    fit: BoxFit.contain,
                    placeholder: (_, __) => Container(
                      height: 300,
                      color: theme.colorScheme.surfaceContainerHighest,
                      child:
                          const Center(child: CircularProgressIndicator()),
                    ),
                  ),
                ),
              ),
            ),
            Positioned(
              right: 4,
              top: 4,
              child: IconButton(
                onPressed: () => Navigator.pop(ctx),
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: const BoxDecoration(
                    color: Colors.black54,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
              ),
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
        return 'Paid';
      case WithdrawalStatus.approved:
        return 'Approved';
      case WithdrawalStatus.rejected:
        return 'Rejected';
    }
  }
}

class _LimitRow extends StatelessWidget {
  final String label;
  final String value;
  final ThemeData theme;

  const _LimitRow(
      {required this.label, required this.value, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label,
            style: theme.textTheme.bodyMedium
                ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: theme.colorScheme.primary.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Text(value,
              style: theme.textTheme.bodyMedium?.copyWith(
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.primary,
              )),
        ),
      ],
    );
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
