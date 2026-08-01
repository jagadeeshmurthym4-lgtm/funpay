import 'package:cashspark/core/utils/helpers.dart' show Helpers;
import 'package:cashspark/core/widgets/premium_widgets.dart' show IconContainer, PremiumAppBar, PremiumGlass;
import 'package:cashspark/core/widgets/shimmer_loading.dart' show NotificationTileSkeleton;
import 'package:cashspark/domain/entities/notification_entity.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

// ─── Label & Styling helpers (kept out of widget tree for reuse) ───

Map<NotificationType, ({String label, IconData icon, Color color})> get _typeMeta => {
      NotificationType.reward: (
        label: 'Rewards',
        icon: Icons.card_giftcard_outlined,
        color: Colors.amber,
      ),
      NotificationType.referral: (
        label: 'Referrals',
        icon: Icons.share_outlined,
        color: Colors.blue,
      ),
      NotificationType.withdrawal: (
        label: 'Redemptions',
        icon: Icons.logout_outlined,
        color: Colors.red,
      ),
      NotificationType.dailyBonus: (
        label: 'Daily Bonus',
        icon: Icons.calendar_today_outlined,
        color: Colors.green,
      ),
      NotificationType.announcement: (
        label: 'Announcements',
        icon: Icons.campaign_outlined,
        color: Colors.purple,
      ),
      NotificationType.promotional: (
        label: 'Promotions',
        icon: Icons.local_offer_outlined,
        color: Colors.orange,
      ),
      NotificationType.other: (
        label: 'Other',
        icon: Icons.notifications_outlined,
        color: Colors.grey,
      ),
    };

IconData _typeIcon(NotificationType type) => _typeMeta[type]?.icon ?? Icons.notifications_outlined;
Color _typeColor(NotificationType type) => _typeMeta[type]?.color ?? Colors.grey;

// ─── Screen ─────────────────────────────────────────────────

class NotificationCenterScreen extends StatefulWidget {
  const NotificationCenterScreen({super.key});

  @override
  State<NotificationCenterScreen> createState() =>
      _NotificationCenterScreenState();
}

class _NotificationCenterScreenState extends State<NotificationCenterScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _animController;
  late Animation<double> _fadeAnim;

  /// Tracks which notification-type groups are currently expanded.
  /// Unread groups are expanded by default (computed once after first data load).
  final Set<NotificationType> _expandedGroups = {};

  /// Whether initial expansion has been applied.
  bool _initialSyncDone = false;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _animController.forward();

    // Notification init is handled by app.dart auth state listener —
    // no need to call setUser() here to avoid duplicate async calls.
  }

  @override
  void dispose() {
    _animController.dispose();
    super.dispose();
  }

  /// Expands groups that have unread notifications. Runs once after first data load.
  void _syncExpandedGroups(List<NotificationGroup> groups) {
    if (_initialSyncDone) return;
    for (final g in groups) {
      if (g.unreadCount > 0) {
        _expandedGroups.add(g.type);
      }
    }
    _initialSyncDone = true;
  }

  void _toggleGroup(NotificationType type) {
    setState(() {
      if (_expandedGroups.contains(type)) {
        _expandedGroups.remove(type);
      } else {
        _expandedGroups.add(type);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Notifications',
        onBack: () => Navigator.pop(context),
        actions: [
          Consumer<NotificationProvider>(
            builder: (context, provider, _) {
              if (provider.notifications.isEmpty) return const SizedBox.shrink();
              return PopupMenuButton<String>(
                onSelected: (value) async {
                  final auth = context.read<AuthProvider>();
                  final userId = auth.user?.uid;
                  if (userId == null) return;
                  if (value == 'markAll' && provider.hasUnread) {
                    await provider.markAllAsRead(userId);
                  } else if (value == 'clearAll') {
                    await provider.clearAll(userId);
                  }
                },
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
                itemBuilder: (context) => [
                  if (context.read<NotificationProvider>().hasUnread)
                    const PopupMenuItem(
                        value: 'markAll', child: Text('Mark all as read')),
                  const PopupMenuItem(
                      value: 'clearAll', child: Text('Clear all')),
                ],
              );
            },
          ),
        ],
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
        child: Consumer<NotificationProvider>(
          builder: (context, provider, _) {
            // ── Loading state ──
            if (provider.isLoading) {
              return ListView.builder(
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                itemCount: 5,
                itemBuilder: (context, index) =>
                    const NotificationTileSkeleton(),
              );
            }

            final groups = provider.groupedNotifications;

            // ── Empty state ──
            if (groups.isEmpty) {
              return FadeTransition(
                opacity: _fadeAnim,
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      PremiumGlass(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          children: [
                            Container(
                              width: 80,
                              height: 80,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.1),
                              ),
                              child: Icon(
                                Icons.notifications_none_rounded,
                                size: 40,
                                color: theme.colorScheme.primary
                                    .withValues(alpha: 0.5),
                              ),
                            ),
                            const SizedBox(height: 20),
                            Text('No notifications yet',
                                style: theme.textTheme.titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w600)),
                            const SizedBox(height: 8),
                            Text("You're all caught up!",
                                style: theme.textTheme.bodyMedium?.copyWith(
                                    color: theme.colorScheme
                                        .onSurfaceVariant)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }

            // Sync expanded groups (expands any unread groups)
            _syncExpandedGroups(groups);

            // ── Grouped notification list ──
            return RefreshIndicator(
              onRefresh: () async {
                if (!context.mounted) return;
                final auth = context.read<AuthProvider>();
                final userId = auth.user?.uid;
                if (userId != null && userId.isNotEmpty) {
                  try {
                    await provider.setUser(userId);
                  } catch (e) {
                    debugPrint('NotificationCenter: refresh error: $e');
                  }
                }
              },
              child: FadeTransition(
                opacity: _fadeAnim,
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(
                      vertical: 8, horizontal: 12),
                  itemCount: groups.length,
                  itemBuilder: (context, groupIndex) {
                    final group = groups[groupIndex];
                    final isExpanded = _expandedGroups.contains(group.type);
                    final meta = _typeMeta[group.type] ??
                        (
                          label: 'Other',
                          icon: Icons.notifications_outlined,
                          color: Colors.grey,
                        );

                    return Column(
                      children: [
                        // ── Section Header (tappable) ──
                        _buildSectionHeader(
                          context: context,
                          theme: theme,
                          label: meta.label,
                          icon: meta.icon,
                          color: meta.color,
                          unreadCount: group.unreadCount,
                          totalCount: group.notifications.length,
                          isExpanded: isExpanded,
                          onTap: () => _toggleGroup(group.type),
                        ),

                        // ── Section Content (animated expand/collapse) ──
                        AnimatedCrossFade(
                          duration: const Duration(milliseconds: 300),
                          crossFadeState: isExpanded
                              ? CrossFadeState.showFirst
                              : CrossFadeState.showSecond,
                          firstChild: Column(
                            children: group.notifications
                                .map((notification) => _NotificationTile(
                                      notification: notification,
                                      theme: theme,
                                      onTap: () => provider.markAsRead(
                                          notification.notificationId),
                                      onDelete: () => provider
                                          .deleteNotification(
                                              notification.notificationId),
                                    ))
                                .toList(),
                          ),
                          secondChild: const SizedBox.shrink(),
                        ),
                      ],
                    );
                  },
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required BuildContext context,
    required ThemeData theme,
    required String label,
    required IconData icon,
    required Color color,
    required int unreadCount,
    required int totalCount,
    required bool isExpanded,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(top: 8, bottom: 4),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(14),
          child: PremiumGlass(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                // Type icon
                IconContainer(icon: icon, color: color, containerSize: 44),
                const SizedBox(width: 12),

                // Label
                Expanded(
                  child: Text(
                    label,
                    style: theme.textTheme.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),

                // Unread badge
                if (unreadCount > 0)
                  Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.primary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      '$unreadCount',
                      style: theme.textTheme.labelSmall?.copyWith(
                        color: theme.colorScheme.onPrimary,
                        fontWeight: FontWeight.w600,
                        fontSize: 11,
                      ),
                    ),
                  ),

                const SizedBox(width: 8),

                // Expand/collapse chevron
                AnimatedRotation(
                  turns: isExpanded ? 0.5 : 0,
                  duration: const Duration(milliseconds: 250),
                  child: Icon(
                    Icons.expand_more_rounded,
                    size: 22,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Notification Tile (unchanged from original) ──────────

class _NotificationTile extends StatelessWidget {
  final NotificationEntity notification;
  final ThemeData theme;
  final VoidCallback onTap;
  final VoidCallback onDelete;

  const _NotificationTile({
    required this.notification,
    required this.theme,
    required this.onTap,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final iconData = _typeIcon(notification.type);
    final color = _typeColor(notification.type);

    return Dismissible(
      key: Key(notification.notificationId),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.only(bottom: 8),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        decoration: BoxDecoration(
          color: theme.colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        child: const Icon(Icons.delete_outline, color: Colors.white),
      ),
      onDismissed: (_) => onDelete(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        margin: const EdgeInsets.only(bottom: 8),
        child: PremiumGlass(
          padding: const EdgeInsets.all(16),
          gradient: notification.isRead
              ? null
              : LinearGradient(
                  colors: [
                    theme.colorScheme.primaryContainer.withValues(alpha: 0.2),
                    Colors.transparent,
                  ],
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                ),
          child: InkWell(
            onTap: onTap,
            borderRadius: BorderRadius.circular(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                IconContainer(icon: iconData, color: color, containerSize: 44),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              notification.title,
                              style: theme.textTheme.bodyMedium?.copyWith(
                                fontWeight: notification.isRead
                                    ? FontWeight.normal
                                    : FontWeight.w600,
                              ),
                            ),
                          ),
                          if (!notification.isRead)
                            Container(
                              width: 10,
                              height: 10,
                              decoration: BoxDecoration(
                                color: theme.colorScheme.primary,
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: theme.colorScheme.primary
                                        .withValues(alpha: 0.4),
                                    blurRadius: 4,
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text(
                        notification.message,
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 6),
                      Row(
                        children: [
                          Icon(Icons.access_time_rounded,
                              size: 12,
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5)),
                          const SizedBox(width: 4),
                          Text(
                            Helpers.formatDateTime(notification.createdAt),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant
                                  .withValues(alpha: 0.5),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 4),
                Icon(Icons.chevron_right_rounded,
                    size: 20,
                    color: theme.colorScheme.onSurfaceVariant
                        .withValues(alpha: 0.3)),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
