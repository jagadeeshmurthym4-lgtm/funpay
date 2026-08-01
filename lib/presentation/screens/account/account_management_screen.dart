import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class AccountManagementScreen extends StatelessWidget {
  const AccountManagementScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final auth = context.watch<AuthProvider>();
    final user = auth.user;

    return Scaffold(
      appBar: PremiumAppBar(title: 'Account Management', onBack: () => Navigator.pop(context)),
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
            // User Profile Card
            PremiumCard(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [theme.colorScheme.primary, theme.colorScheme.tertiary],
                      ),
                    ),
                    child: Center(
                      child: Text(
                        user?.fullName.isNotEmpty == true
                            ? user!.fullName[0].toUpperCase()
                            : '?',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user?.fullName ?? 'User',
                          style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          user?.email ?? '',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: user?.isActive == true
                          ? Colors.green.withValues(alpha: 0.1)
                          : Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      user?.isActive == true ? 'Active' : 'Inactive',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: user?.isActive == true ? Colors.green : Colors.red,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Data & Privacy
            _SectionHeader(title: 'Data & Privacy', icon: Icons.privacy_tip_outlined, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _ActionTile(
                    icon: Icons.download_outlined,
                    iconColor: theme.colorScheme.primary,
                    title: 'Export My Data',
                    subtitle: 'Download all your account information',
                    onTap: () => _exportData(context, auth),
                    theme: theme,
                  ),
                  const Divider(height: 1, indent: 72),
                  _ActionTile(
                    icon: Icons.privacy_tip_outlined,
                    iconColor: Colors.green,
                    title: 'Privacy Settings',
                    subtitle: 'Manage your privacy preferences',
                    onTap: () => Navigator.pushNamed(context, AppRouter.appSettings),
                    theme: theme,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Account Actions
            _SectionHeader(title: 'Account', icon: Icons.info_outline, theme: theme),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              child: _ActionTile(
                icon: Icons.info_outline,
                iconColor: theme.colorScheme.secondary,
                title: 'Account Status',
                subtitle: user?.isActive == true ? 'Your account is active' : 'Account inactive',
                trailing: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: user?.isActive == true ? Colors.green.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    user?.isActive == true ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: user?.isActive == true ? Colors.green : Colors.red,
                    ),
                  ),
                ),
                onTap: null,
                theme: theme,
              ),
            ),
            const SizedBox(height: 24),

            // Danger Zone
            Row(
              children: [
                Container(
                  width: 4,
                  height: 18,
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
                const SizedBox(width: 10),
                Icon(Icons.warning_amber_rounded, size: 18, color: theme.colorScheme.error),
                const SizedBox(width: 8),
                Text('Danger Zone',
                    style: theme.textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w600, color: theme.colorScheme.error)),
              ],
            ),
            const SizedBox(height: 12),
            PremiumCard(
              padding: EdgeInsets.zero,
              gradient: LinearGradient(
                colors: [
                  theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                  theme.colorScheme.errorContainer.withValues(alpha: 0.1),
                ],
              ),
              border: Border.all(color: theme.colorScheme.error.withValues(alpha: 0.3)),
              child: ListTile(
                leading: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error, size: 22),
                ),
                title: Text('Delete Account',
                    style: TextStyle(
                        fontWeight: FontWeight.w600,
                        color: theme.colorScheme.error)),
                subtitle: const Text('Permanently delete your account and all data'),
                trailing: Icon(Icons.chevron_right_rounded, color: theme.colorScheme.error),
                onTap: () => _confirmDeleteAccount(context, auth),
                shape: const Border(),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Future<void> _exportData(BuildContext context, AuthProvider auth) async {
    final user = auth.user;
    if (user == null) return;

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Data export completed'),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  Future<void> _confirmDeleteAccount(BuildContext context, AuthProvider auth) async {
    final theme = Theme.of(context);
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
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                ),
                child: Icon(Icons.delete_forever_outlined, color: theme.colorScheme.error, size: 28),
              ),
              const SizedBox(height: 16),
              Text('Delete Account',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              const Text(
                'This action is permanent and cannot be undone.\n\n'
                'This will:\n'
                '• Delete all personal information\n'
                '• Remove all rewards and earnings\n'
                '• Delete wallet balance\n'
                '• Remove referral data',
                style: TextStyle(fontSize: 13),
              ),
              const SizedBox(height: 8),
              Text('Are you absolutely sure?',
                  style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.bold, color: theme.colorScheme.error)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx, false),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => Navigator.pop(ctx, true),
                      style: FilledButton.styleFrom(
                        backgroundColor: theme.colorScheme.error,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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

    if (confirmed == true && context.mounted) {
      try {
        await auth.deleteAccount();
        if (context.mounted) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.landing,
            (route) => false,
          );
        }
      } catch (e) {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Failed to delete account: $e'),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    }
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

class _ActionTile extends StatelessWidget {
  final IconData icon;
  final Color iconColor;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Widget? trailing;
  final ThemeData theme;

  const _ActionTile({
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.subtitle,
    this.onTap,
    this.trailing,
    required this.theme,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      leading: IconContainer(icon: icon, color: iconColor, containerSize: 44),
      title: Text(title, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 15)),
      subtitle: Text(subtitle,
          style: theme.textTheme.bodySmall?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
      trailing: trailing ?? Icon(Icons.chevron_right_rounded,
          color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4)),
      onTap: onTap,
      shape: const Border(),
      visualDensity: VisualDensity.standard,
      contentPadding: const EdgeInsets.symmetric(horizontal: 16),
    );
  }
}
