import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class NotificationPreferencesScreen extends StatefulWidget {
  const NotificationPreferencesScreen({super.key});

  @override
  State<NotificationPreferencesScreen> createState() => _NotificationPreferencesScreenState();
}

class _NotificationPreferencesScreenState extends State<NotificationPreferencesScreen> {
  bool _earningsAlerts = true;
  bool _withdrawalUpdates = true;
  bool _taskReminders = true;
  bool _dailyBonusReminder = true;
  bool _referralUpdates = true;
  bool _promotionalOffers = true;
  bool _soundEnabled = true;
  bool _vibrationEnabled = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _earningsAlerts = prefs.getBool('notif_earnings') ?? true;
      _withdrawalUpdates = prefs.getBool('notif_withdrawals') ?? true;
      _taskReminders = prefs.getBool('notif_tasks') ?? true;
      _dailyBonusReminder = prefs.getBool('notif_daily_bonus') ?? true;
      _referralUpdates = prefs.getBool('notif_referrals') ?? true;
      _promotionalOffers = prefs.getBool('notif_promotional') ?? true;
      _soundEnabled = prefs.getBool('notif_sound') ?? true;
      _vibrationEnabled = prefs.getBool('notif_vibration') ?? true;
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
      appBar: PremiumAppBar(title: 'Notification Preferences', onBack: () => Navigator.pop(context)),
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
                    decoration: const BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: LinearGradient(
                        colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                      ),
                    ),
                    child: const Icon(Icons.notifications_rounded, color: Colors.white, size: 24),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Notification Preferences',
                            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                        Text('Choose which alerts you want to receive',
                            style: TextStyle(fontSize: 12,
                                color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),

            // Alerts section
            _sectionHeader('Alert Types', Icons.notifications_outlined, theme),
            const SizedBox(height: 8),
            _buildToggle(theme, isDark,
              icon: Icons.account_balance_wallet_outlined,
              iconColor: AppTheme.accentGreen,
              title: 'Earnings Alerts',
              subtitle: 'When you earn rewards or receive bonuses',
              value: _earningsAlerts,
              onChanged: (v) => setState(() { _earningsAlerts = v; _save('notif_earnings', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.logout_outlined,
              iconColor: AppTheme.accentOrange,
              title: 'Withdrawal Updates',
              subtitle: 'Status changes on your withdrawal requests',
              value: _withdrawalUpdates,
              onChanged: (v) => setState(() { _withdrawalUpdates = v; _save('notif_withdrawals', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.task_alt_outlined,
              iconColor: AppTheme.accentBlue,
              title: 'Task Reminders',
              subtitle: 'Reminders about available tasks and deadlines',
              value: _taskReminders,
              onChanged: (v) => setState(() { _taskReminders = v; _save('notif_tasks', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.calendar_today_outlined,
              iconColor: AppTheme.accentPurple,
              title: 'Daily Bonus Reminder',
              subtitle: 'Reminder to claim your daily check-in bonus',
              value: _dailyBonusReminder,
              onChanged: (v) => setState(() { _dailyBonusReminder = v; _save('notif_daily_bonus', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.share_outlined,
              iconColor: Colors.blue,
              title: 'Referral Updates',
              subtitle: 'When someone joins using your referral code',
              value: _referralUpdates,
              onChanged: (v) => setState(() { _referralUpdates = v; _save('notif_referrals', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.local_offer_outlined,
              iconColor: Colors.pink,
              title: 'Promotional Offers',
              subtitle: 'Special offers, promotions, and events',
              value: _promotionalOffers,
              onChanged: (v) => setState(() { _promotionalOffers = v; _save('notif_promotional', v); }),
            ),
            const SizedBox(height: 24),

            // Sound section
            _sectionHeader('Alert Method', Icons.volume_up_outlined, theme),
            const SizedBox(height: 8),
            _buildToggle(theme, isDark,
              icon: Icons.volume_up_outlined,
              iconColor: AppTheme.accentGreen,
              title: 'Sound',
              subtitle: 'Play a sound when notifications arrive',
              value: _soundEnabled,
              onChanged: (v) => setState(() { _soundEnabled = v; _save('notif_sound', v); }),
            ),
            _buildToggle(theme, isDark,
              icon: Icons.vibration_outlined,
              iconColor: AppTheme.accentBlue,
              title: 'Vibration',
              subtitle: 'Vibrate for incoming notifications',
              value: _vibrationEnabled,
              onChanged: (v) => setState(() { _vibrationEnabled = v; _save('notif_vibration', v); }),
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
                      'Notification preferences are saved locally on this device. '
                      'Changes apply immediately and only affect this device.',
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
    required Color iconColor,
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
            color: iconColor.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 20, color: iconColor),
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
