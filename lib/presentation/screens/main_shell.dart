import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/presentation/screens/home/home_screen_new.dart';
import 'package:cashspark/presentation/screens/rewards/rewards_hub_screen.dart';
import 'package:cashspark/presentation/screens/projects/projects_screen.dart';
import 'package:cashspark/presentation/screens/wallet/wallet_dashboard_screen.dart';
import 'package:cashspark/presentation/screens/more/more_screen.dart';
import 'package:cashspark/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class MainShell extends StatefulWidget {
  const MainShell({super.key});

  @override
  State<MainShell> createState() => _MainShellState();
}

class _MainShellState extends State<MainShell> {
  int _currentIndex = 0;

  final List<Widget> _screens = const [
    HomeScreen(),
    RewardsHubScreen(),
    ProjectsScreen(),
    WalletDashboardScreen(),
    MoreScreen(),
  ];

  @override
  void initState() {
    super.initState();
    // Notification init is handled by app.dart auth state listener —
    // no need to call setUser() here to avoid duplicate async calls.
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    // Use try-catch to guard against accessing a disposed provider during
    // screen transitions. Default to 0 if the provider is unavailable.
    int unreadCount = 0;
    try {
      final notifProv = context.watch<NotificationProvider>();
      unreadCount = notifProv.unreadCount;
    } catch (e) {
      debugPrint('MainShell: notification provider unavailable ($e)');
    }

    final rs = context.responsive;
    return Scaffold(
      body: IndexedStack(
        index: _currentIndex,
        children: _screens,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1E36) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                  : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          child: Padding(
            padding: rs.padSym(h: 8, v: 6),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildNavItem(Icons.home_rounded, 'Home', 0, isDark),
                _buildNavItem(Icons.card_giftcard_outlined, 'Rewards', 1, isDark),
                _buildNavItem(Icons.folder_outlined, 'Projects', 2, isDark),
                _buildNavItem(Icons.account_balance_wallet_outlined, 'Wallet', 3, isDark),
                _buildNavItem(Icons.more_horiz_rounded, 'More', 4, isDark,
                    badgeCount: unreadCount > 0 ? unreadCount : null),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icon, String label, int index, bool isDark,
      {int? badgeCount}) {
    final selected = _currentIndex == index;
    return GestureDetector(
      onTap: () {
        HapticFeedback.lightImpact();
        setState(() => _currentIndex = index);
      },
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                icon,
                size: 24,
                color: selected
                    ? const Color(0xFF4ADE80)
                    : (isDark
                        ? const Color(0xFF64748B)
                        : const Color(0xFF94A3B8)),
              ),
              if (badgeCount != null && badgeCount > 0)
                Positioned(
                  right: -8,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: Color(0xFFEF4444),
                      shape: BoxShape.circle,
                    ),
                    constraints: const BoxConstraints(
                      minWidth: 18,
                      minHeight: 18,
                    ),
                    child: Text(
                      badgeCount > 9 ? '9+' : '$badgeCount',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                      ),
                      textAlign: TextAlign.center,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? const Color(0xFF4ADE80)
                  : (isDark
                      ? const Color(0xFF64748B)
                      : const Color(0xFF94A3B8)),
            ),
          ),
        ],
      ),
    );
  }
}
