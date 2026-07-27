import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PrivacySettingsScreen extends StatefulWidget {
  const PrivacySettingsScreen({super.key});

  @override
  State<PrivacySettingsScreen> createState() => _PrivacySettingsScreenState();
}

class _PrivacySettingsScreenState extends State<PrivacySettingsScreen> {
  bool _profileVisible = true;
  bool _shareAnalytics = true;
  bool _emailNotifications = true;
  bool _showOnlineStatus = true;
  bool _allowTagging = true;
  bool _dataForImprovement = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _profileVisible = prefs.getBool('privacy_profile_visible') ?? true;
      _shareAnalytics = prefs.getBool('privacy_share_analytics') ?? true;
      _emailNotifications = prefs.getBool('privacy_email_notifications') ?? true;
      _showOnlineStatus = prefs.getBool('privacy_show_online') ?? true;
      _allowTagging = prefs.getBool('privacy_allow_tagging') ?? true;
      _dataForImprovement = prefs.getBool('privacy_data_for_improvement') ?? true;
    });
  }

  Future<void> _save(String key, bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(key, value);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(title: 'Privacy Settings', onBack: () => Navigator.pop(context)),
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
            // Header
            PremiumGlass(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Container(
                    width: 48, height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.accentGreen.withValues(alpha: 0.12),
                    ),
                    child: const Icon(Icons.privacy_tip_rounded, color: AppTheme.accentGreen, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Privacy Controls',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Manage what data you share and how your profile appears',
                            style: TextStyle(fontSize: 12,
                                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Profile section
            _sectionHeader('Profile Visibility', Icons.visibility_outlined, theme),
            const SizedBox(height: 8),
            _buildToggle(theme, isDark,
              icon: Icons.person_outline,
              title: 'Profile Visible',
              subtitle: 'Allow others to see your profile',
              value: _profileVisible,
              onChanged: (v) => setState(() { _profileVisible = v; _save('privacy_profile_visible', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.circle_outlined,
              title: 'Show Online Status',
              subtitle: 'Display when you are active',
              value: _showOnlineStatus,
              onChanged: (v) => setState(() { _showOnlineStatus = v; _save('privacy_show_online', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.alternate_email_outlined,
              title: 'Allow Tagging',
              subtitle: 'Let others tag you in content',
              value: _allowTagging,
              onChanged: (v) => setState(() { _allowTagging = v; _save('privacy_allow_tagging', v); }),
            ),
            const SizedBox(height: 24),

            // Data section
            _sectionHeader('Data & Analytics', Icons.analytics_outlined, theme),
            const SizedBox(height: 8),
            _buildToggle(theme, isDark,
              icon: Icons.analytics_outlined,
              title: 'Share Usage Analytics',
              subtitle: 'Help us improve with anonymous usage data',
              value: _shareAnalytics,
              onChanged: (v) => setState(() { _shareAnalytics = v; _save('privacy_share_analytics', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.thumb_up_outlined,
              title: 'Data for Improvements',
              subtitle: 'Use my data to personalize features',
              value: _dataForImprovement,
              onChanged: (v) => setState(() { _dataForImprovement = v; _save('privacy_data_for_improvement', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.email_outlined,
              title: 'Email Notifications',
              subtitle: 'Receive account-related emails',
              value: _emailNotifications,
              onChanged: (v) => setState(() { _emailNotifications = v; _save('privacy_email_notifications', v); }),
            ),

            const SizedBox(height: 24),

            // Info card
            PremiumGlass(
              padding: const EdgeInsets.all(16),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Icon(Icons.info_outline, size: 18,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Your privacy is important to us. You can change these settings anytime. '
                      'Some changes may take up to 24 hours to take effect across our systems.',
                      style: TextStyle(fontSize: 12,
                          color: isDark ? AppTheme.textMuted : const Color(0xFF64748B)),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _sectionHeader(String title, IconData icon, ThemeData theme) {
    return Row(
      children: [
        Container(
          width: 4, height: 18,
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

  Widget _buildToggle(ThemeData theme, bool isDark, {
    required IconData icon,
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: EdgeInsets.zero,
      child: SwitchListTile(
        secondary: Container(
          width: 40, height: 40,
          decoration: BoxDecoration(
            color: AppTheme.accentGreen.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
        ),
        title: Text(title,
            style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A))),
        subtitle: Text(subtitle,
            style: TextStyle(fontSize: 12,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
        value: value,
        onChanged: onChanged,
        shape: const Border(),
      ),
    );
  }
}
