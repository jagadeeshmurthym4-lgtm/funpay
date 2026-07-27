import 'dart:async';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:cashspark/presentation/screens/projects/affiliate_project_detail_screen.dart';

class ProjectsScreen extends StatefulWidget {
  const ProjectsScreen({super.key});

  @override
  State<ProjectsScreen> createState() => _ProjectsScreenState();
}

class _ProjectsScreenState extends State<ProjectsScreen> {
  int _mainTabIndex = 0;

  // ─── Available Projects state ───
  final _searchController = TextEditingController();
  String _searchQuery = '';
  Timer? _searchDebounce;
  String _selectedCategory = 'All';
  bool _hasSearchText = false;

  static const List<String> _categories = [
    'All', 'Finance', 'Gaming', 'Apps', 'Shopping', 'Social', 'Surveys', 'Testing',
  ];

  // ─── My Projects state ───
  int _myTabIndex = 0;
  static const List<String> _myTabLabels = [
    'All', 'Pending', 'Under Review', 'Approved',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() {
      final hasText = _searchController.text.isNotEmpty;
      if (hasText != _hasSearchText) {
        setState(() => _hasSearchText = hasText);
      }
    });
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final p = context.read<AffiliateProjectProvider>();
      p.subscribeToActiveProjects();
      final uid = context.read<AuthProvider>().user?.uid ?? '';
      if (uid.isNotEmpty) p.subscribeToUserParticipations(uid);
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _searchDebounce?.cancel();
    super.dispose();
  }

  // ─── Available Projects helpers ───

  List<AffiliateProjectEntity> _availableFrom(
    List<AffiliateProjectEntity> all,
    List<ProjectParticipationEntity> parts,
  ) {
    final joined = parts.map((p) => p.projectId).toSet();
    var list = all.where((p) {
      if (p.lifecycleStatus != ProjectLifecycleStatus.active) return false;
      if (!joined.contains(p.projectId)) return true;
      if (p.allowRetry) {
        final userParts = parts.where((x) => x.projectId == p.projectId);
        return userParts.every((x) => x.status == ProjectStatus.rejected);
      }
      return false;
    }).toList();

    if (_selectedCategory != 'All') {
      final cat = _selectedCategory.toLowerCase();
      list = list.where((p) =>
          p.category.toLowerCase() == cat ||
          p.title.toLowerCase().contains(cat)).toList();
    }
    if (_searchQuery.isNotEmpty) {
      final q = _searchQuery.toLowerCase();
      list = list.where((p) =>
          p.title.toLowerCase().contains(q) ||
          p.description.toLowerCase().contains(q) ||
          p.category.toLowerCase().contains(q)).toList();
    }
    list.sort((a, b) => b.createdDate.compareTo(a.createdDate));
    return list;
  }

  // ─── My Projects helpers ───

  List<ProjectParticipationEntity> _filteredMyProjects(
    List<ProjectParticipationEntity> all,
  ) {
    final sorted = List<ProjectParticipationEntity>.from(all)
      ..sort((a, b) => b.startedAt.compareTo(a.startedAt));
    switch (_myTabIndex) {
      case 1:
        return sorted.where((p) =>
            p.status == ProjectStatus.applied ||
            p.status == ProjectStatus.inProgress ||
            p.status == ProjectStatus.notStarted).toList();
      case 2:
        return sorted.where((p) =>
            p.status == ProjectStatus.submitted ||
            p.status == ProjectStatus.pendingReview ||
            p.status == ProjectStatus.underReview).toList();
      case 3:
        return sorted.where((p) =>
            p.status == ProjectStatus.approved ||
            p.status == ProjectStatus.completed).toList();
      default:
        return sorted;
    }
  }

  int _countForTab(int tabIndex, List<ProjectParticipationEntity> all) {
    switch (tabIndex) {
      case 0:
        return all.length;
      case 1:
        return all.where((p) =>
            p.status == ProjectStatus.applied ||
            p.status == ProjectStatus.inProgress ||
            p.status == ProjectStatus.notStarted).length;
      case 2:
        return all.where((p) =>
            p.status == ProjectStatus.submitted ||
            p.status == ProjectStatus.pendingReview ||
            p.status == ProjectStatus.underReview).length;
      case 3:
        return all.where((p) =>
            p.status == ProjectStatus.approved ||
            p.status == ProjectStatus.completed).length;
      default:
        return 0;
    }
  }

  void _viewProjectDetail(ProjectParticipationEntity item) {
    final affProv = context.read<AffiliateProjectProvider>();
    final matching = affProv.allProjects
        .where((p) => p.projectId == item.projectId)
        .firstOrNull;
    if (matching != null) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => AffiliateProjectDetailScreen(project: matching),
        ),
      );
    }
  }

  // ─── Build ───

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF081A2E) : const Color(0xFFF0F5FF);

    return Scaffold(
      backgroundColor: bgColor,
      body: SafeArea(
        child: Column(
          children: [
            _header(isDark),
            _mainTabs(isDark),
            const SizedBox(height: 8),
            Expanded(
              child: _mainTabIndex == 0
                  ? _availableProjectsTab(isDark)
                  : _myProjectsTab(isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _header(bool isDark) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: AppTheme.accentGreen.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(Icons.assignment_outlined,
                size: 22, color: Color(0xFF4ADE80)),
          ),
          const SizedBox(width: 12),
          Text(
            'Projects',
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
        ],
      ),
    );
  }

  Widget _mainTabs(bool isDark) {
    return Container(
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
      child: Row(
        children: [
          _tabButton('Available Projects', 0, isDark),
          _tabButton('My Projects', 1, isDark),
        ],
      ),
    );
  }

  Widget _tabButton(String label, int index, bool isDark) {
    final selected = _mainTabIndex == index;
    return Expanded(
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          setState(() => _mainTabIndex = index);
        },
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 12),
          decoration: BoxDecoration(
            color: selected ? const Color(0xFF4ADE80) : Colors.transparent,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
              color: selected
                  ? Colors.black
                  : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
            ),
          ),
        ),
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  AVAILABLE PROJECTS TAB
  // ═══════════════════════════════════════════════════════════

  Widget _availableProjectsTab(bool isDark) {
    return Consumer<AffiliateProjectProvider>(
      builder: (context, prov, _) {
        final hasData = prov.allProjects.isNotEmpty;
        final isLoading = prov.isLoading;
        final hasError = prov.errorMessage != null;

        Widget content;
        if (hasData) {
          final available = _availableFrom(prov.allProjects, prov.participations);
          content = _projectList(available, isDark);
        } else if (isLoading) {
          content = const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                CircularProgressIndicator(),
                SizedBox(height: 12),
                Text('Loading projects...', style: TextStyle(fontSize: 14, color: Color(0xFF94A3B8))),
              ],
            ),
          );
        } else if (hasError) {
          content = _errorContent(isDark, prov.errorMessage!);
        } else {
          content = _emptyContent(isDark);
        }

        return Column(
          children: [
            _searchBar(isDark),
            _categoryRow(isDark),
            const SizedBox(height: 4),
            Expanded(child: content),
          ],
        );
      },
    );
  }

  Widget _searchBar(bool isDark) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9),
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
            _searchDebounce = Timer(const Duration(milliseconds: 300), () {
              if (mounted) setState(() => _searchQuery = v);
            });
          },
          decoration: InputDecoration(
            hintText: 'Search projects...',
            hintStyle: TextStyle(
              fontSize: 14,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
            prefixIcon: Icon(Icons.search_outlined,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
            suffixIcon: _hasSearchText
                ? IconButton(
                    icon: Icon(Icons.clear,
                        color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                    onPressed: () {
                      _searchController.clear();
                      setState(() {
                        _searchQuery = '';
                        _hasSearchText = false;
                      });
                    },
                  )
                : null,
            border: InputBorder.none,
            contentPadding: const EdgeInsets.symmetric(vertical: 12, horizontal: 16),
          ),
          style: TextStyle(
            fontSize: 14,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
      ),
    );
  }

  Widget _categoryRow(bool isDark) {
    return SizedBox(
      height: 38,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, __) => const SizedBox(width: 6),
        itemBuilder: (context, index) {
          final cat = _categories[index];
          final sel = _selectedCategory == cat;
          IconData? icon;
          switch (cat) {
            case 'All': icon = Icons.dashboard_rounded; break;
            case 'Finance': icon = Icons.account_balance_outlined; break;
            case 'Gaming': icon = Icons.sports_esports_outlined; break;
            case 'Apps': icon = Icons.smartphone_outlined; break;
            case 'Shopping': icon = Icons.shopping_bag_outlined; break;
            case 'Social': icon = Icons.people_outlined; break;
            case 'Surveys': icon = Icons.quiz_outlined; break;
            case 'Testing': icon = Icons.science_outlined; break;
          }
          return GestureDetector(
            onTap: () => setState(() => _selectedCategory = cat),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 200),
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: sel
                    ? const Color(0xFF3B82F6)
                    : (isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9)),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: sel
                      ? const Color(0xFF3B82F6)
                      : (isDark
                          ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                          : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (icon != null) ...[
                    Icon(icon, size: 13,
                        color: sel ? Colors.white : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B))),
                    const SizedBox(width: 4),
                  ],
                  Text(cat, style: TextStyle(
                    fontSize: 11,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.white : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                  )),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // ─── Project list ───

  Widget _projectList(List<AffiliateProjectEntity> projects, bool isDark) {
    if (projects.isEmpty) {
      final isSearch = _searchQuery.isNotEmpty;
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              isSearch ? Icons.search_off_rounded : Icons.inventory_2_outlined,
              size: 56,
              color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 12),
            Text(
              isSearch ? 'No matching projects' : 'No projects available',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              isSearch ? 'Try a different search' : 'Check back for new earning opportunities',
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              ),
            ),
          ],
        ),
      );
    }

    debugPrint('[ProjectsScreen] Rendering ${projects.length} available projects');
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
      itemCount: projects.length,
      itemBuilder: (context, index) => _projectCard(projects[index], isDark),
    );
  }

  Widget _projectCard(AffiliateProjectEntity project, bool isDark) {
    return GestureDetector(
      onTap: () async {
        HapticFeedback.lightImpact();
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => AffiliateProjectDetailScreen(project: project),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2740) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2D4A6F) : const Color(0xFFD1D5DB),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.12),
              blurRadius: 14,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: project.logoImage.isNotEmpty
                        ? ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              project.logoImage,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) =>
                                  const Icon(Icons.folder_outlined,
                                      size: 22, color: Color(0xFF22C55E)),
                            ),
                          )
                        : const Icon(Icons.folder_outlined,
                            size: 22, color: Color(0xFF22C55E)),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          project.title,
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          project.description,
                          style: TextStyle(
                            fontSize: 12,
                            color: isDark
                                ? AppTheme.textSecondary
                                : const Color(0xFF64748B),
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    constraints: const BoxConstraints(maxWidth: 90),
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: const Color(0xFF22C55E).withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      project.rewardText,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF22C55E),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _chip(project.category, const Color(0xFF8B5CF6), Icons.category_outlined),
                  const SizedBox(width: 6),
                  _typeBadge(project.isTask),
                  const Spacer(),
                  Text(
                    project.completionTimeText,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: double.infinity,
                height: 44,
                child: ElevatedButton(
                  onPressed: () async {
                    HapticFeedback.lightImpact();
                    await Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => AffiliateProjectDetailScreen(project: project),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                    elevation: 0,
                  ),
                  child: const Text(
                    'View Details',
                    style: TextStyle(fontSize: 14, fontWeight: FontWeight.w700),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _chip(String label, Color color, IconData icon) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 3),
          Text(label, style: TextStyle(fontSize: 9, fontWeight: FontWeight.w700, color: color)),
        ],
      ),
    );
  }

  Widget _typeBadge(bool isTask) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
      decoration: BoxDecoration(
        color: (isTask ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6)).withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            isTask ? Icons.task_alt_outlined : Icons.link_outlined,
            size: 10,
            color: isTask ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
          ),
          const SizedBox(width: 3),
          Text(
            isTask ? 'TASK' : 'AFFILIATE',
            style: TextStyle(
              fontSize: 9,
              fontWeight: FontWeight.w700,
              color: isTask ? const Color(0xFF8B5CF6) : const Color(0xFF3B82F6),
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyContent(bool isDark) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.inventory_2_outlined,
            size: 56,
            color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 12),
          Text(
            'No projects available',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Check back for new earning opportunities',
            style: TextStyle(
              fontSize: 13,
              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
    );
  }

  Widget _errorContent(bool isDark, String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.cloud_off_outlined,
            size: 56,
            color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFFEF4444).withValues(alpha: 0.4),
          ),
          const SizedBox(height: 16),
          Text(
            'Unable to load projects',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
            ),
          ),
          const SizedBox(height: 6),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 32),
            child: Text(
              message,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              ),
            ),
          ),
          const SizedBox(height: 24),
          Consumer<AffiliateProjectProvider>(
            builder: (ctx, prov, _) {
              final busy = prov.isLoading || prov.isInitialLoading;
              return SizedBox(
                width: 160,
                height: 42,
                child: ElevatedButton.icon(
                  onPressed: busy
                      ? null
                      : () {
                          HapticFeedback.lightImpact();
                          prov.subscribeToActiveProjects();
                          final uid = context.read<AuthProvider>().user?.uid ?? '';
                          if (uid.isNotEmpty) prov.subscribeToUserParticipations(uid);
                        },
                  icon: busy
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.black54),
                        )
                      : const Icon(Icons.refresh_rounded, size: 18),
                  label: Text(busy ? 'Loading...' : 'Retry'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: isDark ? const Color(0xFF1E3A5F) : const Color(0xFFE2E8F0),
                    foregroundColor: isDark ? Colors.white : const Color(0xFF0F172A),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    elevation: 0,
                    side: BorderSide(
                      color: isDark ? const Color(0xFF2D4A6F).withValues(alpha: 0.5) : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                    ),
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  //  MY PROJECTS TAB
  // ═══════════════════════════════════════════════════════════

  Widget _myProjectsTab(bool isDark) {
    return Column(
      children: [
        _myTabBar(isDark),
        const SizedBox(height: 8),
        Expanded(
          child: Consumer<AffiliateProjectProvider>(
            builder: (context, prov, _) {
              final loading = !prov.hasInitialParticipationsData && prov.participations.isEmpty;
              final items = _filteredMyProjects(prov.participations);

              if (loading) {
                return const Center(child: CircularProgressIndicator());
              }
              if (items.isEmpty) {
                return _myEmpty(isDark);
              }
              return ListView.builder(
                padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                itemCount: items.length,
                itemBuilder: (context, index) => _myCard(items[index], isDark),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _myTabBar(bool isDark) {
    final active = _myTabIndex;
    final prov = context.watch<AffiliateProjectProvider>();

    return Container(
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
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: List.generate(_myTabLabels.length, (i) {
            final sel = active == i;
            final count = _countForTab(i, prov.participations);
            return GestureDetector(
              onTap: () => setState(() => _myTabIndex = i),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: sel ? const Color(0xFF4ADE80) : Colors.transparent,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_myTabLabels[i]}${count > 0 ? ' ($count)' : ''}',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: sel ? FontWeight.w700 : FontWeight.w500,
                    color: sel ? Colors.black : (isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                  ),
                ),
              ),
            );
          }),
        ),
      ),
    );
  }

  Widget _myEmpty(bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.folder_open_outlined,
              size: 64,
              color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'No projects yet',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Start a project from Available Projects to see it here',
              textAlign: TextAlign.center,
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

  Widget _myCard(ProjectParticipationEntity item, bool isDark) {
    final sc = _statusColor(item.status);
    final sl = _statusLabel(item.status);

    return GestureDetector(
      onTap: () => _viewProjectDetail(item),
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0F2740) : Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: isDark ? const Color(0xFF2D4A6F) : const Color(0xFFCBD5E1),
            width: 1.0,
          ),
          boxShadow: [
            BoxShadow(
              color: isDark ? Colors.black.withValues(alpha: 0.3) : const Color(0xFF0F172A).withValues(alpha: 0.08),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(_statusIcon(item.status), color: sc, size: 22),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          item.projectTitle,
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                            color: isDark ? Colors.white : const Color(0xFF0F172A),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '₹${item.rewardAmount.toStringAsFixed(0)}',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                    decoration: BoxDecoration(
                      color: sc.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      sl,
                      style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700, color: sc),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              // ── Rejection reason ──
              if (item.status == ProjectStatus.rejected &&
                  item.rejectionReason != null &&
                  item.rejectionReason!.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.cancel, size: 14, color: Color(0xFFEF4444)),
                      const SizedBox(width: 6),
                      Flexible(
                        child: Text(
                          'Rejected: ${item.rejectionReason}',
                          style: const TextStyle(fontSize: 11, color: Color(0xFFEF4444)),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                ),
              // ── Action buttons ──
              Row(
                children: [
                  if (item.status == ProjectStatus.rejected ||
                      item.status == ProjectStatus.inProgress ||
                      item.status == ProjectStatus.applied)
                    Expanded(
                      child: SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          onPressed: () => _viewProjectDetail(item),
                          icon: const Icon(Icons.open_in_new_rounded, size: 14),
                          label: Text(
                            item.status == ProjectStatus.rejected ? 'Resubmit' : 'Submit Proof',
                            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w700),
                            overflow: TextOverflow.ellipsis,
                          ),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: item.status == ProjectStatus.rejected
                                ? const Color(0xFFF59E0B)
                                : const Color(0xFF22C55E),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            elevation: 0,
                          ),
                        ),
                      ),
                    ),
                  if (item.status == ProjectStatus.rejected ||
                      item.status == ProjectStatus.inProgress ||
                      item.status == ProjectStatus.applied)
                    const SizedBox(width: 8),
                  Expanded(
                    child: SizedBox(
                      height: 36,
                      child: OutlinedButton.icon(
                        onPressed: () => _viewProjectDetail(item),
                        icon: const Icon(Icons.visibility_outlined, size: 14),
                        label: Text('View Details',
                            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
                            overflow: TextOverflow.ellipsis),
                        style: OutlinedButton.styleFrom(
                          foregroundColor: isDark ? AppTheme.textSecondary : const Color(0xFF64748B),
                          side: BorderSide(
                            color: isDark ? AppTheme.borderColor : const Color(0xFFCBD5E1),
                          ),
                          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                _formatDate(item.startedAt),
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Color _statusColor(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.approved:
      case ProjectStatus.completed:
        return const Color(0xFF22C55E);
      case ProjectStatus.rejected:
        return const Color(0xFFEF4444);
      case ProjectStatus.underReview:
      case ProjectStatus.pendingReview:
      case ProjectStatus.submitted:
        return const Color(0xFFF59E0B);
      case ProjectStatus.inProgress:
      case ProjectStatus.applied:
      case ProjectStatus.notStarted:
        return const Color(0xFF3B82F6);
    }
  }

  String _statusLabel(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.approved: return 'Approved';
      case ProjectStatus.completed: return 'Completed';
      case ProjectStatus.rejected: return 'Rejected';
      case ProjectStatus.underReview: case ProjectStatus.pendingReview: return 'Under Review';
      case ProjectStatus.submitted: return 'Submitted';
      case ProjectStatus.inProgress: return 'In Progress';
      case ProjectStatus.applied: return 'Pending';
      case ProjectStatus.notStarted: return 'Not Started';
    }
  }

  IconData _statusIcon(ProjectStatus s) {
    switch (s) {
      case ProjectStatus.approved: case ProjectStatus.completed: return Icons.check_circle_outline;
      case ProjectStatus.rejected: return Icons.cancel_outlined;
      case ProjectStatus.underReview: case ProjectStatus.pendingReview: case ProjectStatus.submitted: return Icons.hourglass_empty;
      case ProjectStatus.inProgress: case ProjectStatus.applied: case ProjectStatus.notStarted: return Icons.play_circle_outline;
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
