import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

class ContactUsScreen extends StatelessWidget {
  const ContactUsScreen({super.key});

  static const String supportEmail = 'funpayer2026@gmail.com';
  static const String supportPhone = '+918660958837';
  static const String whatsappNumber = '918660958837'; // Without + for whatsapp://

  Future<void> _launchWhatsApp(BuildContext context, String number) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse('whatsapp://send?phone=$number&text=${Uri.encodeComponent('Hi Fun Pay team! I have a question about my account.')}');
    final fallbackUri = Uri.parse('https://wa.me/$number?text=${Uri.encodeComponent('Hi Fun Pay team! I have a question about my account.')}');
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else if (await canLaunchUrl(fallbackUri)) {
        await launchUrl(fallbackUri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: '+91${number.substring(2)}'));
        messenger.showSnackBar(
          SnackBar(
            content: const Text('📋 Phone number copied! Open WhatsApp manually.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: '+91${number.substring(2)}'));
      messenger.showSnackBar(
        SnackBar(
          content: const Text('📋 Number copied! Open WhatsApp and paste to start chat.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _launchPhone(BuildContext context, String phone) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(scheme: 'tel', path: phone);
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        await Clipboard.setData(ClipboardData(text: phone));
        messenger.showSnackBar(
          SnackBar(
            content: const Text('📋 Phone number copied to clipboard!'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } catch (_) {
      await Clipboard.setData(ClipboardData(text: phone));
      messenger.showSnackBar(
        SnackBar(
          content: const Text('📋 Number copied!'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _launchEmail(BuildContext context, String email) async {
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri(
      scheme: 'mailto',
      path: email,
      query: 'subject=${Uri.encodeComponent('Fun Pay Support Inquiry')}',
    );
    try {
      if (await canLaunchUrl(uri)) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        // Fallback: copy email to clipboard
        await Clipboard.setData(ClipboardData(text: email));
        messenger.showSnackBar(
          SnackBar(
            content: const Text('Email address copied to clipboard! Open your email app manually.'),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            action: SnackBarAction(
              label: 'Open Gmail',
              onPressed: () async {
                final gmailUri = Uri.parse('https://mail.google.com/mail/?view=cm&fs=1&to=$email&su=${Uri.encodeComponent('Fun Pay Support Inquiry')}');
                if (await canLaunchUrl(gmailUri)) {
                  await launchUrl(gmailUri, mode: LaunchMode.externalApplication);
                }
              },
            ),
          ),
        );
      }
    } catch (_) {
      // Ultimate fallback: copy email to clipboard
      await Clipboard.setData(ClipboardData(text: email));
      messenger.showSnackBar(
        SnackBar(
          content: const Text('📋 Email copied! Paste into your email app.'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: PremiumAppBar(title: 'Contact Us', onBack: () => Navigator.pop(context)),
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
        child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Email Card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _launchEmail(context, supportEmail),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.primary.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.email_outlined,
                        size: 32,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Email Us',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      supportEmail,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.primary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to send an email',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          // WhatsApp Card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _launchWhatsApp(context, whatsappNumber),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: const Color(0xFF25D366).withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.chat_bubble_outline_rounded,
                        size: 32,
                        color: const Color(0xFF25D366),
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'WhatsApp',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      supportPhone,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: const Color(0xFF25D366),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to chat on WhatsApp',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Call Us Card
          Card(
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () => _launchPhone(context, supportPhone),
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Column(
                  children: [
                    Container(
                      width: 64,
                      height: 64,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: theme.colorScheme.secondary.withValues(alpha: 0.1),
                      ),
                      child: Icon(
                        Icons.phone_outlined,
                        size: 32,
                        color: theme.colorScheme.secondary,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Call Us',
                      style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      supportPhone,
                      style: theme.textTheme.bodyLarge?.copyWith(
                        color: theme.colorScheme.secondary,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Tap to call',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Report Issue Card
          Card(
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.colorScheme.error.withValues(alpha: 0.1),
                    ),
                    child: Icon(
                      Icons.report_problem_outlined,
                      size: 32,
                      color: theme.colorScheme.error,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'Report an Issue',
                    style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Facing a problem? Please include your account email and a detailed description of the issue when contacting us.',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),

          // Response Times
          Text(
            'Response Times',
            style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 12),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  _infoRow(theme, 'General Inquiries', 'Within 24 hours'),
                  const Divider(height: 16),
                  _infoRow(theme, 'Account Issues', 'Within 12 hours'),
                  const Divider(height: 16),
                  _infoRow(theme, 'Withdrawal Issues', 'Within 6 hours'),
                  const Divider(height: 16),
                  _infoRow(theme, 'Urgent Security Issues', 'Within 2 hours'),
                ],
              ),
            ),
          ),
          const SizedBox(height: 32),
        ],
      ),
      ),
    );
  }

  Widget _infoRow(ThemeData theme, String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: theme.textTheme.bodyMedium),
          Text(
            value,
            style: theme.textTheme.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }
}
