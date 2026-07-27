import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/admin_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/language_provider.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/presentation/providers/theme_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AppSettingsScreen extends StatefulWidget {
  const AppSettingsScreen({super.key});

  @override
  State<AppSettingsScreen> createState() => _AppSettingsScreenState();
}

class _AppSettingsScreenState extends State<AppSettingsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) => _verifyAdmin());
  }

  Future<void> _verifyAdmin() async {
    final auth = context.read<AuthProvider>();
    final adminProv = context.read<AdminProvider>();
    if (auth.isAuthenticated && auth.user != null && !adminProv.isAdmin) {
      await adminProv.verifyAdminAccess(auth.user!.uid, email: auth.user!.email);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: PremiumAppBar(title: 'Settings', onBack: () => Navigator.pop(context)),
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
            // Appearance
            _SectionHeader(title: 'Appearance', icon: Icons.palette_outlined, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Consumer<ThemeProvider>(
                builder: (context, themeProvider, _) => SwitchListTile(
                  secondary: Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: themeProvider.isDarkMode
                          ? Colors.indigo.withValues(alpha: 0.1)
                          : Colors.amber.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Icon(
                      themeProvider.isDarkMode ? Icons.dark_mode_outlined : Icons.light_mode_outlined,
                      color: themeProvider.isDarkMode ? Colors.indigo : Colors.amber,
                      size: 22,
                    ),
                  ),
                  title: const Text('Dark Mode'),
                  subtitle: Text(themeProvider.isDarkMode ? 'Dark theme active' : 'Light theme active'),
                  value: themeProvider.isDarkMode,
                  onChanged: (_) => themeProvider.toggleTheme(),
                  shape: const Border(),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Notifications
            _SectionHeader(title: 'Notifications', icon: Icons.notifications_outlined, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Consumer<NotificationProvider>(
                builder: (context, notifProvider, _) => Column(
                  children: [
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.primary.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: Icon(Icons.notifications_outlined, color: theme.colorScheme.primary, size: 22),
                      ),
                      title: const Text('Push Notifications'),
                      subtitle: const Text('Receive notifications on this device'),
                      value: notifProvider.notificationsEnabled,
                      onChanged: (_) => notifProvider.toggleNotifications(),
                      shape: const Border(),
                    ),
                    const Divider(height: 1, indent: 72),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.amber.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.card_giftcard_outlined, color: Colors.amber, size: 22),
                      ),
                      title: const Text('Reward Notifications'),
                      subtitle: const Text('Get notified when you earn rewards'),
                      value: notifProvider.rewardNotificationsEnabled,
                      onChanged: (_) => notifProvider.toggleRewardNotifications(),
                      shape: const Border(),
                    ),
                    const Divider(height: 1, indent: 72),
                    SwitchListTile(
                      secondary: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.purple.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.campaign_outlined, color: Colors.purple, size: 22),
                      ),
                      title: const Text('Promotional Messages'),
                      subtitle: const Text('Receive offers and promotions'),
                      value: notifProvider.promotionalEnabled,
                      onChanged: (_) => notifProvider.togglePromotional(),
                      shape: const Border(),
                    ),
                    const Divider(height: 1, indent: 72),
                    _SettingsTile(
                      icon: Icons.tune_outlined,
                      iconColor: Colors.blue,
                      title: 'Notification Preferences',
                      subtitle: 'Granular control per notification type',
                      onTap: () => Navigator.pushNamed(context, AppRouter.notificationPreferences),
                      theme: theme,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Security
            _SectionHeader(title: 'Security', icon: Icons.security_outlined, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [

                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: AppTheme.accentGreen,
                    title: 'Privacy Settings',
                    subtitle: 'Profile visibility, data sharing, and more',
                    onTap: () => Navigator.pushNamed(context, AppRouter.privacySettings),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.language_outlined,
                    iconColor: AppTheme.accentPurple,
                    title: 'Language',
                    subtitle: 'Change app language',
                    onTap: () {
                      final lp = context.read<LanguageProvider>();
                      LanguageProvider.showLanguageSheet(context, lp);
                    },
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Legal
            _SectionHeader(title: 'Legal', icon: Icons.gavel_outlined, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.gavel_outlined,
                    iconColor: theme.colorScheme.primary,
                    title: 'Terms & Conditions',
                    onTap: () => Navigator.pushNamed(context, AppRouter.terms),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.green,
                    title: 'Privacy Policy',
                    onTap: () => Navigator.pushNamed(context, AppRouter.privacy),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.info_outline,
                    iconColor: Colors.blue,
                    title: 'Disclaimer',
                    onTap: () => Navigator.pushNamed(context, AppRouter.disclaimer),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Support
            _SectionHeader(title: 'Support', icon: Icons.support_outlined, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.headset_mic_outlined,
                    iconColor: Colors.indigo,
                    title: 'Help Center',
                    subtitle: 'FAQ, tickets, and live chat',
                    onTap: () => Navigator.pushNamed(context, AppRouter.helpCenter),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.question_answer_outlined,
                    iconColor: Colors.orange,
                    title: 'FAQ',
                    onTap: () => Navigator.pushNamed(context, AppRouter.faq),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.mail_outlined,
                    iconColor: Colors.red,
                    title: 'Contact Us',
                    onTap: () => Navigator.pushNamed(context, AppRouter.contact),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.info_outlined,
                    iconColor: Colors.purple,
                    title: 'About Us',
                    subtitle: 'v${const String.fromEnvironment("APP_VERSION", defaultValue: "1.0.0")}',
                    onTap: () => Navigator.pushNamed(context, AppRouter.about),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Admin Panel
            Consumer<AdminProvider>(
              builder: (context, adminProvider, _) {
                if (!adminProvider.isAdmin) return const SizedBox.shrink();
                return Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _SectionHeader(title: 'Administration', icon: Icons.admin_panel_settings_outlined, theme: theme),
                    const SizedBox(height: 12),
                    PremiumCard(
                      padding: EdgeInsets.zero,
                      child: _SettingsTile(
                        icon: Icons.admin_panel_settings_outlined,
                        iconColor: theme.colorScheme.primary,
                        title: 'Admin Dashboard',
                        subtitle: 'Manage users, rewards, and settings',
                        onTap: () => Navigator.pushNamed(context, AppRouter.admin),
                        theme: theme,
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                );
              },
            ),

            // Account
            _SectionHeader(title: 'Account', icon: Icons.person_outline, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _SettingsTile(
                    icon: Icons.manage_accounts_outlined,
                    iconColor: Colors.teal,
                    title: 'Account Management',
                    subtitle: 'Data export, deletion, and privacy',
                    onTap: () => Navigator.pushNamed(context, AppRouter.accountManagement),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _SettingsTile(
                    icon: Icons.person_outline,
                    iconColor: theme.colorScheme.primary,
                    title: 'Profile',
                    subtitle: user?.fullName ?? 'User',
                    onTap: () => Navigator.pushNamed(context, AppRouter.profile),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),

            // App Info
            Center(
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      children: [
                        Text(
                          'Fun Pay',
                          style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'v${const String.fromEnvironment("APP_VERSION", defaultValue: "1.0.0")}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                        Text(
                          'Build ${const String.fromEnvironment("BUILD_NUMBER", defaultValue: "1")}',
                          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final IconData icon;
  final ThemeData theme;

  const _SectionHeader({required this.title, required this.icon, required this.theme});

  @override
  Widget build(BuildContext context) {
    return Row(
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
        Icon(icon, size: 18, color: theme.colorScheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Text(title, style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
      ],
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String? subtitle;
  final VoidCallback onTap;
  final ThemeData theme;

  const _SettingsTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    this.subtitle,
    required this.onTap,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconContainer(icon: icon, color: iconColor, containerSize: 44),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: subtitle != null
          ? Text(subtitle!, style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant))
          : null,
      trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      onTap: onTap,
      shape: const Border(),
      visualDensity: VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
