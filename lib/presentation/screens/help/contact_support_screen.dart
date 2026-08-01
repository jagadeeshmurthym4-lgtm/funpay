import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/support_ticket_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/help_provider.dart';
import 'package:cashspark/services/device_fingerprint_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ContactSupportScreen extends StatefulWidget {
  const ContactSupportScreen({super.key});

  @override
  State<ContactSupportScreen> createState() => _ContactSupportScreenState();
}

class _ContactSupportScreenState extends State<ContactSupportScreen> {
  final _formKey = GlobalKey<FormState>();
  final _subjectController = TextEditingController();
  final _messageController = TextEditingController();
  TicketCategory _selectedCategory = TicketCategory.technical;
  String? _deviceInfo;
  String? _screenshotPath;

  @override
  void initState() {
    super.initState();
    _collectDeviceInfo();
  }

  Future<void> _collectDeviceInfo() async {
    try {
      final device = DeviceFingerprintService();
      final platform = await device.getPlatform();
      setState(() {
        _deviceInfo = 'Platform: $platform';
      });
    } catch (_) {}
  }

  @override
  void dispose() {
    _subjectController.dispose();
    _messageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(title: 'Contact Support', onBack: () => Navigator.pop(context)),
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
        child: Consumer<HelpProvider>(
          builder: (context, hp, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Category selector
                    Text('Category', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: TicketCategory.values.map((cat) {
                          final selected = _selectedCategory == cat;
                          return Padding(
                            padding: const EdgeInsets.only(right: 8),
                            child: GestureDetector(
                              onTap: () => setState(() => _selectedCategory = cat),
                              child: AnimatedContainer(
                                duration: const Duration(milliseconds: 200),
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                                decoration: BoxDecoration(
                                  color: selected ? AppTheme.accentBlue : Colors.transparent,
                                  borderRadius: BorderRadius.circular(10),
                                  border: Border.all(
                                    color: selected ? AppTheme.accentBlue : (isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
                                  ),
                                ),
                                child: Text(
                                  _categoryLabel(cat),
                                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                      color: selected ? Colors.white : (isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                                ),
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Subject
                    Text('Subject', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    PremiumGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 14,
                      child: TextFormField(
                        controller: _subjectController,
                        decoration: const InputDecoration(
                          hintText: 'Brief summary of your issue',
                          border: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please enter a subject' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Message
                    Text('Message', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    PremiumGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                      borderRadius: 14,
                      child: TextFormField(
                        controller: _messageController,
                        maxLines: 5,
                        decoration: const InputDecoration(
                          hintText: 'Describe your issue in detail...',
                          border: InputBorder.none,
                        ),
                        validator: (v) => (v == null || v.trim().isEmpty) ? 'Please describe your issue' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Screenshot attachment (placeholder)
                    PremiumGlass(
                      padding: const EdgeInsets.all(16),
                      child: InkWell(
                        onTap: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Screenshot attachment coming soon'),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        borderRadius: BorderRadius.circular(14),
                        child: Row(
                          children: [
                            Container(
                              width: 44, height: 44,
                              decoration: BoxDecoration(
                                color: AppTheme.accentOrange.withValues(alpha: 0.12),
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Icon(Icons.image_outlined, color: AppTheme.accentOrange, size: 22),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text('Attach Screenshot',
                                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                                          color: isDark ? Colors.white : const Color(0xFF0F172A))),
                                  Text('Optional: helps us understand the issue',
                                      style: TextStyle(fontSize: 11,
                                          color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                ],
                              ),
                            ),
                            Icon(Icons.add_photo_alternate_outlined, size: 20,
                                color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.4)),
                          ],
                        ),
                      ),
                    ),
                    if (_screenshotPath != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Chip(
                          label: const Text('Screenshot attached',
                              style: TextStyle(fontSize: 12)),
                          deleteIcon: const Icon(Icons.close, size: 16),
                          onDeleted: () => setState(() => _screenshotPath = null),
                        ),
                      ),
                    const SizedBox(height: 20),

                    // Device info
                    if (_deviceInfo != null)
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFF1F5F9),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.phone_android_outlined, size: 16,
                                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                            const SizedBox(width: 8),
                            Text(_deviceInfo!,
                                style: TextStyle(fontSize: 12,
                                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                          ],
                        ),
                      ),
                    const SizedBox(height: 24),

                    // Submit button
                    GradientButton(
                      onPressed: hp.submitting ? null : _submitTicket,
                      label: hp.submitting ? 'Submitting...' : 'Submit Ticket',
                      icon: hp.submitting ? Icons.hourglass_top : Icons.send_rounded,
                      isLoading: hp.submitting,
                    ),
                    const SizedBox(height: 8),

                    // Error / success messages
                    if (hp.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(hp.errorMessage!,
                            style: TextStyle(color: theme.colorScheme.error, fontSize: 13)),
                      ),
                    if (hp.successMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 8),
                        child: Text(hp.successMessage!,
                            style: const TextStyle(color: AppTheme.accentGreen, fontSize: 13)),
                      ),
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

  Future<void> _submitTicket() async {
    if (!_formKey.currentState!.validate()) return;

    final auth = context.read<AuthProvider>();
    final userId = auth.user?.uid;
    if (userId == null) return;

    final hp = context.read<HelpProvider>();
    hp.clearErrors();

    try {
      await hp.createTicket(
        userId: userId,
        subject: _subjectController.text.trim(),
        message: _messageController.text.trim(),
        category: _selectedCategory,
        deviceInfo: _deviceInfo,
      );
      _subjectController.clear();
      _messageController.clear();
      setState(() => _selectedCategory = TicketCategory.technical);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Ticket submitted successfully!'), behavior: SnackBarBehavior.floating),
        );
        Navigator.pop(context);
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(hp.errorMessage ?? 'Failed to submit ticket'),
              behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  String _categoryLabel(TicketCategory cat) {
    switch (cat) {
      case TicketCategory.account: return 'Account';
      case TicketCategory.withdrawal: return 'Redemption';
      case TicketCategory.task: return 'Task';
      case TicketCategory.reward: return 'Reward';
      case TicketCategory.referral: return 'Referral';
      case TicketCategory.technical: return 'Technical';
      case TicketCategory.feature: return 'Feature Request';
      case TicketCategory.other: return 'Other';
    }
  }
}
