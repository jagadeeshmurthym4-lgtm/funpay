import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  List<_LeaderUser> _topEarners = [];
  bool _isLoading = true;
  String _currentUserId = '';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      if (!_tabController.indexIsChanging) {
        setState(() {});
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _currentUserId = context.read<AuthProvider>().user?.uid ?? '';
      _loadLeaderboard();
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadLeaderboard() async {
    setState(() => _isLoading = true);
    try {
      final snapshot = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .limit(50)
          .get();

      final users = snapshot.docs.map((doc) {
        final data = doc.data();
        return _LeaderUser(
          uid: data['uid'] as String? ?? '',
          fullName: data['fullName'] as String? ?? 'Unknown',
          totalEarnings: (data['totalEarnings'] as num?)?.toDouble() ?? 0.0,
          referralCode: data['referralCode'] as String? ?? '',
        );
      }).toList();

      // Sort by totalEarnings descending and take top 50
      users.sort((a, b) => b.totalEarnings.compareTo(a.totalEarnings));

      if (!mounted) return;
      setState(() {
        _topEarners = users.take(50).toList();
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Failed to load leaderboard: $e')),
      );
    }
  }

  int get _userRank {
    final idx = _topEarners.indexWhere((u) => u.uid == _currentUserId);
    return idx >= 0 ? idx + 1 : 0;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Leaderboard'),
        centerTitle: true,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: const Color(0xFF4ADE80),
          labelColor: const Color(0xFF4ADE80),
          unselectedLabelColor: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
          tabs: const [
            Tab(icon: Icon(Icons.emoji_events_outlined), text: 'Top Earners'),
            Tab(icon: Icon(Icons.trending_up_outlined), text: 'This Week'),
          ],
        ),
      ),
      body: _isLoading
          ? ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: 8,
              itemBuilder: (context, index) => const LeaderboardRowSkeleton(),
            )
          : _topEarners.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.emoji_events_outlined,
                          size: 64, color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
                      const SizedBox(height: 16),
                      Text('No data yet',
                          style: TextStyle(
                              fontSize: 16,
                              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B))),
                      const SizedBox(height: 8),
                      Text('Start earning to appear on the leaderboard!',
                          style: TextStyle(
                              fontSize: 13,
                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                    ],
                  ),
                )
              : Column(
                  children: [
                    // Top 3 podium
                    _buildPodium(isDark),
                    // User's rank
                    if (_userRank > 0 && _userRank <= 50)
                      _buildUserRank(isDark),
                    const SizedBox(height: 8),
                    // Leaderboard list
                    Expanded(
                      child: _tabController.index == 0
                          ? _buildTopEarnersList(isDark, theme)
                          : _buildWeeklyList(isDark),
                    ),
                  ],
                ),
    );
  }

  Widget _buildPodium(bool isDark) {
    if (_topEarners.length < 3) return const SizedBox.shrink();

    final top3 = _topEarners.take(3).toList();
    // Reorder: 2nd, 1st, 3rd for visual podium
    final podium = [
      _PodiumEntry(top3[1], 2, 100), // 2nd place
      _PodiumEntry(top3[0], 1, 120), // 1st place (tallest)
      _PodiumEntry(top3[2], 3, 80), // 3rd place
    ];

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      child: Column(
        children: [
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: podium.map((entry) {
              return Expanded(
                child: GestureDetector(
                  onTap: () => _showUserProfile(entry.user),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Trophy / crown for 1st
                      if (entry.rank == 1)
                        const Icon(Icons.emoji_events, color: Color(0xFFF59E0B), size: 28),
                      if (entry.rank == 1) const SizedBox(height: 4),
                      // Avatar
                      Container(
                        width: entry.rank == 1 ? 52 : 44,
                        height: entry.rank == 1 ? 52 : 44,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          gradient: LinearGradient(
                            colors: entry.rank == 1
                                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                : entry.rank == 2
                                    ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                                    : [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: entry.rank == 1
                                  ? const Color(0xFFF59E0B).withValues(alpha: 0.3)
                                  : Colors.black.withValues(alpha: 0.1),
                              blurRadius: 8,
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            entry.user.fullName.isNotEmpty
                                ? entry.user.fullName[0].toUpperCase()
                                : '?',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: entry.rank == 1 ? 22 : 18,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      // Name
                      Text(
                        entry.user.fullName.split(' ').first,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                        textAlign: TextAlign.center,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      // Earnings
                      Text(
                        '${entry.user.totalEarnings.toStringAsFixed(0)} pts',
                        style: TextStyle(
                          fontSize: entry.rank == 1 ? 14 : 12,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(height: 4),
                      // Podium bar
                      Container(
                        height: entry.height,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: entry.rank == 1
                                ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                                : entry.rank == 2
                                    ? [const Color(0xFF94A3B8), const Color(0xFF64748B)]
                                    : [const Color(0xFFCD7F32), const Color(0xFF8B4513)],
                            begin: Alignment.topCenter,
                            end: Alignment.bottomCenter,
                          ),
                          borderRadius:
                              const BorderRadius.vertical(top: Radius.circular(8)),
                        ),
                        child: Center(
                          child: Text(
                            '#${entry.rank}',
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 16,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildUserRank(bool isDark) {
    final user = _topEarners.firstWhere(
      (u) => u.uid == _currentUserId,
      orElse: () => _LeaderUser(uid: '', fullName: '', totalEarnings: 0, referralCode: ''),
    );
    if (user.uid.isEmpty) return const SizedBox.shrink();

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            const Color(0xFF4ADE80).withValues(alpha: 0.15),
            const Color(0xFF22C55E).withValues(alpha: 0.05),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: Text(
                '#$_userRank',
                style: const TextStyle(
                  color: Color(0xFF4ADE80),
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              user.fullName.isNotEmpty ? user.fullName : 'You',
              style: TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 14,
                color: isDark ? Colors.white : const Color(0xFF0F172A),
              ),
            ),
          ),
          Text(
            '${user.totalEarnings.toStringAsFixed(0)} pts',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              fontSize: 15,
              color: Color(0xFF4ADE80),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTopEarnersList(bool isDark, ThemeData theme) {
    // Skip top 3 since they're in the podium
    final rest = _topEarners.length > 3 ? _topEarners.skip(3).toList() : <_LeaderUser>[];

    if (rest.isEmpty) {
      return Center(
        child: Text(
          'No more entries',
          style: TextStyle(
            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      itemCount: rest.length,
      itemBuilder: (context, index) {
        final rank = index + 4;
        final user = rest[index];
        final isMe = user.uid == _currentUserId;

        return TweenAnimationBuilder<double>(
          tween: Tween(begin: 0.0, end: 1.0),
          duration: Duration(milliseconds: 200 + index * 30),
          builder: (context, value, child) {
            return Opacity(opacity: value, child: Transform.translate(
              offset: Offset(0, 20 * (1 - value)),
              child: child,
            ));
          },
          child: GestureDetector(
            onTap: () => _showUserProfile(user),
            child: Container(
              margin: const EdgeInsets.only(bottom: 6),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
              decoration: BoxDecoration(
                color: isMe
                    ? const Color(0xFF4ADE80).withValues(alpha: 0.08)
                    : isDark
                        ? const Color(0xFF0F2740)
                        : Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: isMe
                      ? const Color(0xFF4ADE80).withValues(alpha: 0.3)
                      : isDark
                          ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                          : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  // Rank
                  SizedBox(
                    width: 32,
                    child: Text(
                      '$rank',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                      ),
                    ),
                  ),
                  // Avatar
                  Container(
                    width: 34,
                    height: 34,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                    ),
                    child: Center(
                      child: Text(
                        user.fullName.isNotEmpty
                            ? user.fullName[0].toUpperCase()
                            : '?',
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                          color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      user.fullName,
                      style: TextStyle(
                        fontWeight: isMe ? FontWeight.w700 : FontWeight.w600,
                        fontSize: 13,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (isMe)
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: const Text(
                        'YOU',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  Text(
                    '${user.totalEarnings.toStringAsFixed(0)} pts',
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 14,
                      color: Color(0xFF4ADE80),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildWeeklyList(bool isDark) {
    // Week tab - same data for now since we track total, not weekly
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.trending_up_outlined,
              size: 48, color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
          const SizedBox(height: 12),
          Text(
            'Weekly rankings coming soon!',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Top earners this week will appear here',
            style: TextStyle(
              fontSize: 12,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  void _showUserProfile(_LeaderUser user) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final rank = _topEarners.indexWhere((u) => u.uid == user.uid) + 1;
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFCBD5E1),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 20),
              Container(
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: LinearGradient(
                    colors: rank <= 3
                        ? [const Color(0xFFF59E0B), const Color(0xFFD97706)]
                        : [const Color(0xFF4ADE80), const Color(0xFF22C55E)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Center(
                  child: Text(
                    user.fullName.isNotEmpty ? user.fullName[0].toUpperCase() : '?',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 28,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              Text(
                user.fullName,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                ),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.emoji_events_outlined, size: 16, color: const Color(0xFF4ADE80)),
                  const SizedBox(width: 6),
                  Text(
                    'Rank #$rank',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF4ADE80),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Icon(Icons.monetization_on_outlined, size: 16, color: const Color(0xFFF59E0B)),
                  const SizedBox(width: 6),
                  Text(
                    '${user.totalEarnings.toStringAsFixed(2)} pts',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: const Color(0xFFF59E0B),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(ctx),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF4ADE80),
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text('Close', style: TextStyle(fontWeight: FontWeight.w700)),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _LeaderUser {
  final String uid;
  final String fullName;
  final double totalEarnings;
  final String referralCode;

  const _LeaderUser({
    required this.uid,
    required this.fullName,
    required this.totalEarnings,
    required this.referralCode,
  });
}

class _PodiumEntry {
  final _LeaderUser user;
  final int rank;
  final double height;

  const _PodiumEntry(this.user, this.rank, this.height);
}
