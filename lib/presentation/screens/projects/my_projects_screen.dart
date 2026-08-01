import 'dart:async';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class MyProjectsScreen extends StatefulWidget {
  const MyProjectsScreen({super.key});

  @override
  State<MyProjectsScreen> createState() => _MyProjectsScreenState();
}

class _MyProjectsScreenState extends State<MyProjectsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // ─── Search state ─────────────────────────────────────
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;

  // ─── Tab definitions ────────────────────────────────────
  static const int _tabCount = 4;
  static const List<String> _tabLabels = [
    'All Projects',
    'Pending',
    'Under Review',
    'Approved',
  ];

  @override
  void initState() {
    super.initState();
    // Restore last tab from provider (persists across push/pop within session)
    final provider = context.read<AffiliateProjectProvider>();
    _tabController = TabController(
      length: _tabCount,
      vsync: this,
      initialIndex: provider.myProjectsTabIndex.clamp(0, _tabCount - 1),
    );
    _tabController.addListener(_saveTab);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final userId = context.read<AuthProvider>().user?.uid ?? '';
      if (userId.isNotEmpty) {
        context
            .read<AffiliateProjectProvider>()
            .subscribeToUserParticipations(userId);
      }
    });
  }

  @override
  void dispose() {
    _tabController.removeListener(_saveTab);
    _tabController.dispose();
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ─── Tab persistence ────────────────────────────────────
  void _saveTab() {
    if (!_tabController.indexIsChanging) {
      context
          .read<AffiliateProjectProvider>()
          .setMyProjectsTabIndex(_tabController.index);
    }
  }

  // ─── Status filter groups ──────────────────────────────

  /// Returns the participation list for the given tab index.
  /// Rejected projects appear only in the "All" tab (case 0).
  List<ProjectParticipationEntity> _filteredByTab(
    int tabIndex,
    List<ProjectParticipationEntity> all,
  ) {
    switch (tabIndex) {
      case 0: // All Projects — includes every status including rejected
        return all;
      case 1: // Pending — applied, inProgress, notStarted
        return all
            .where((p) =>
                p.status == ProjectStatus.applied ||
                p.status == ProjectStatus.inProgress ||
                p.status == ProjectStatus.notStarted)
            .toList();
      case 2: // Under Review — submitted, pendingReview, underReview
        return all
            .where((p) =>
                p.status == ProjectStatus.submitted ||
                p.status == ProjectStatus.pendingReview ||
                p.status == ProjectStatus.underReview)
            .toList();
      case 3: // Approved — approved, completed
        return all
            .where((p) =>
                p.status == ProjectStatus.approved ||
                p.status == ProjectStatus.completed)
            .toList();
      default:
        return all;
    }
  }

  // ─── Count helpers ──────────────────────────────────────

  int _countForTab(int tabIndex, List<ProjectParticipationEntity> all) {
    switch (tabIndex) {
      case 0:
        return all.length;
      case 1:
        return all
            .where((p) =>
                p.status == ProjectStatus.applied ||
                p.status == ProjectStatus.inProgress ||
                p.status == ProjectStatus.notStarted)
            .length;
      case 2:
        return all
            .where((p) =>
                p.status == ProjectStatus.submitted ||
                p.status == ProjectStatus.pendingReview ||
                p.status == ProjectStatus.underReview)
            .length;
      case 3:
        return all
            .where((p) =>
                p.status == ProjectStatus.approved ||
                p.status == ProjectStatus.completed)
            .length;
      default:
        return 0;
    }
  }

  /// Apply both tab filter and search query filter.
  List<ProjectParticipationEntity> _filteredList(
    int tabIndex,
    List<ProjectParticipationEntity> all,
  ) {
    var byTab = _filteredByTab(tabIndex, all);
    if (_searchQuery.trim().isEmpty) return byTab;
    final q = _searchQuery.trim().toLowerCase();
    return byTab
        .where((p) => p.projectTitle.toLowerCase().contains(q))
        .toList();
  }

  // ─── Build ──────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AffiliateProjectProvider>();
    final participations = provider.participations;
    final activeTab = _tabController.index;

    // Filtered list – reactively computed on every build so tabs stay in sync
    final filtered = _filteredList(activeTab, participations);
    final totalCount = participations.length;

    return Scaffold(
      appBar: AppBar(
        title: const Text('My Projects'),
        centerTitle: true,
      ),
      body: Column(
        children: [
          // ─── Projects count ───────────────────────────────
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 12, 20, 0),
            child: Row(
              children: [
                Text(
                  activeTab == 0
                      ? '$totalCount total'
                      : '${filtered.length} of $totalCount',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color:
                        isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          // ─── Search bar ───────────────────────────────────
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Container(
              decoration: BoxDecoration(
                color: isDark
                    ? const Color(0xFF0F2740)
                    : const Color(0xFFF1F5F9),
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isDark
                      ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                      : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                ),
              ),
              child: TextField(
                controller: _searchController,
                onChanged: (v) {
                  _searchDebounce?.cancel();
                  _searchDebounce =
                      Timer(const Duration(milliseconds: 250), () {
                    setState(() => _searchQuery = v);
                  });
                },
                decoration: InputDecoration(
                  hintText: 'Search projects...',
                  hintStyle: TextStyle(
                    color: isDark
                        ? AppTheme.textMuted
                        : const Color(0xFF94A3B8),
                    fontSize: 14,
                  ),
                  prefixIcon: Icon(Icons.search_outlined,
                      color: isDark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8)),
                  suffixIcon: _searchController.text.isNotEmpty
                      ? IconButton(
                          icon: Icon(Icons.clear,
                              color: isDark
                                  ? AppTheme.textMuted
                                  : const Color(0xFF94A3B8)),
                          onPressed: () {
                            _searchController.clear();
                            setState(() => _searchQuery = '');
                          },
                        )
                      : null,
                  border: InputBorder.none,
                  filled: false,
                  contentPadding: const EdgeInsets.symmetric(
                      vertical: 14, horizontal: 16),
                ),
                style: TextStyle(
                  color: isDark ? Colors.white : const Color(0xFF0F172A),
                  fontSize: 14,
                ),
              ),
            ),
          ),
          const SizedBox(height: 8),

          // ─── Status tab bar ───────────────────────────────
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 16),
            decoration: BoxDecoration(
              color: isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: isDark
                    ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                    : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              isScrollable: true,
              tabAlignment: TabAlignment.start,
              indicator: BoxDecoration(
                color: const Color(0xFF4ADE80),
                borderRadius: BorderRadius.circular(12),
              ),
              indicatorSize: TabBarIndicatorSize.tab,
              labelColor: Colors.black,
              unselectedLabelColor:
                  isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
              labelStyle: const TextStyle(
                fontWeight: FontWeight.w700,
                fontSize: 13,
              ),
              unselectedLabelStyle: const TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 13,
              ),
              dividerColor: Colors.transparent,
              splashBorderRadius: BorderRadius.circular(12),
              onTap: (_) => setState(() {}),
              tabs: List.generate(_tabCount, (i) {
                final count = _countForTab(i, participations);
                return Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  child: Tab(
                    child: RichText(
                      text: TextSpan(
                        style: TextStyle(
                          fontWeight: i == activeTab
                              ? FontWeight.w700
                              : FontWeight.w500,
                          fontSize: 13,
                          color: i == activeTab
                              ? Colors.black
                              : (isDark
                                  ? AppTheme.textSecondary
                                  : const Color(0xFF64748B)),
                        ),
                        children: [
                          TextSpan(text: _tabLabels[i]),
                          if (count > 0)
                            TextSpan(
                              text: ' ($count)',
                              style: TextStyle(
                                fontWeight: FontWeight.w600,
                                fontSize: 11,
                                color: i == activeTab
                                    ? Colors.black87
                                    : (isDark
                                        ? AppTheme.textMuted
                                        : const Color(0xFF94A3B8)),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
          const SizedBox(height: 8),

          // ─── Content ──────────────────────────────────────
          Expanded(
            child: provider.isLoading && participations.isEmpty
                ? const PremiumLoader()
                : participations.isEmpty
                    ? PremiumEmptyState(
                        icon: Icons.folder_outlined,
                        title: 'No projects yet',
                        subtitle: 'Start your first affiliate project!',
                      )
                    : filtered.isEmpty
                        ? _emptyStateForTab(activeTab, isDark)
                        : ListView.builder(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 16, vertical: 4),
                            itemCount: filtered.length,
                            itemBuilder: (context, i) =>
                                _buildParticipationCard(
                                    filtered[i], isDark),
                          ),
          ),
        ],
      ),
    );
  }

  Widget _emptyStateForTab(int tabIndex, bool isDark) {
    final messages = [
      'No projects yet',
      'No pending projects',
      'No projects under review',
      'No approved projects',
    ];
    final icons = [
      Icons.folder_outlined,
      Icons.pending_outlined,
      Icons.hourglass_empty_outlined,
      Icons.check_circle_outline,
    ];
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icons[tabIndex],
              size: 52,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
            const SizedBox(height: 16),
            Text(
              messages[tabIndex],
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color:
                    isDark ? AppTheme.textSecondary : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tabIndex == 0
                  ? 'Start a project to see it here'
                  : 'No projects match this status',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildParticipationCard(
      ProjectParticipationEntity participation, bool isDark) {
    final status = participation.status;
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: status.color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              _statusIcon(status),
              color: status.color,
              size: 22,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  participation.projectTitle,
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Text(
                      '${participation.rewardAmount.toStringAsFixed(2)} pts',
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF4ADE80),
                      ),
                    ),
            const SizedBox(width: 8),
            Flexible(
              child: Text(
                _formatDate(participation.startedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark
                      ? AppTheme.textMuted
                      : const Color(0xFF94A3B8),
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ],
    ),
  ),
  const SizedBox(width: 8),
  Flexible(
    child: Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: status.color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        status.label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: status.color,
        ),
        overflow: TextOverflow.ellipsis,
      ),
    ),
  ),
        ],
      ),
    );
  }

  IconData _statusIcon(ProjectStatus status) {
    switch (status) {
      case ProjectStatus.applied:
        return Icons.task_alt_rounded;
      case ProjectStatus.inProgress:
        return Icons.play_circle_outline;
      case ProjectStatus.notStarted:
        return Icons.radio_button_unchecked_outlined;
      case ProjectStatus.submitted:
      case ProjectStatus.pendingReview:
      case ProjectStatus.underReview:
        return Icons.hourglass_empty;
      case ProjectStatus.approved:
        return Icons.check_circle_outline;
      case ProjectStatus.rejected:
        return Icons.cancel_outlined;
      case ProjectStatus.completed:
        return Icons.celebration_outlined;
    }
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final diff = now.difference(date);
    if (diff.inMinutes < 60) return '${diff.inMinutes}m ago';
    if (diff.inHours < 24) return '${diff.inHours}h ago';
    if (diff.inDays < 7) return '${diff.inDays}d ago';
    return '${date.day}/${date.month}/${date.year}';
  }
}
