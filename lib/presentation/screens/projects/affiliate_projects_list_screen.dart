import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/shimmer_loading.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/screens/projects/affiliate_project_detail_screen.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

class AffiliateProjectsListScreen extends StatefulWidget {
  const AffiliateProjectsListScreen({super.key});

  @override
  State<AffiliateProjectsListScreen> createState() =>
      _AffiliateProjectsListScreenState();
}

class _AffiliateProjectsListScreenState
    extends State<AffiliateProjectsListScreen>
    with SingleTickerProviderStateMixin {
  final _searchController = TextEditingController();
  late TabController _categoryTabController;

  @override
  void initState() {
    super.initState();
    _categoryTabController = TabController(
      length: AffiliateProjectProvider.categories.length,
      vsync: this,
    );

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AffiliateProjectProvider>();
      provider.subscribeToActiveProjects();
      provider.subscribeToFeaturedProjects();
      final userId = context.read<AuthProvider>().user?.uid ?? '';
      if (userId.isNotEmpty) {
        provider.subscribeToUserParticipations(userId);
      }
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _categoryTabController.dispose();
    super.dispose();
  }


  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final provider = context.watch<AffiliateProjectProvider>();
    final projects = provider.projects;
    final featured = provider.featuredProjects;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Affiliate Projects'),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: () => provider.refreshProjects(),
        color: const Color(0xFF4ADE80),
        backgroundColor: isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9),
        displacement: 80,
        edgeOffset: 8,
        strokeWidth: 3,
        child: Column(
          children: [
            // Search bar (skeleton while first page loads)
            if (provider.isLoading && projects.isEmpty)
              const SearchBarSkeleton()
            else
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: Container(
                  decoration: BoxDecoration(
                    color: isDark
                        ? const Color(0xFF0F2740)
                        : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: isDark
                          ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                          : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                    ),
                  ),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (v) => provider.setSearchQuery(v),
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
                                provider.setSearchQuery('');
                              },
                            )
                          : null,
                      border: InputBorder.none,
                      filled: false,
                      contentPadding:
                          const EdgeInsets.symmetric(vertical: 14, horizontal: 16),
                    ),
                    style: TextStyle(
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                      fontSize: 14,
                    ),
                  ),
                ),
              ),

            // Sort & Filter bar
            if (provider.isLoading && projects.isEmpty)
              const SortBarSkeleton()
            else
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                child: Row(
                  children: [
                    // Sort dropdown
                    Container(
                      padding:
                          const EdgeInsets.symmetric(horizontal: 10, vertical: 2),
                      decoration: BoxDecoration(
                        color: isDark
                            ? const Color(0xFF0F2740)
                            : const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: isDark
                              ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                              : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
                        ),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: provider.sortBy,
                          isDense: true,
                          icon: Icon(Icons.sort_outlined,
                              size: 18,
                              color: isDark
                                  ? AppTheme.textSecondary
                                  : const Color(0xFF64748B)),
                          items: const [
                            DropdownMenuItem(
                                value: 'newest', child: Text('Newest', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(
                                value: 'highestReward', child: Text('Highest Reward', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(
                                value: 'lowestReward', child: Text('Lowest Reward', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(
                                value: 'shortestTime', child: Text('Shortest Time', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(
                                value: 'featured', child: Text('Featured', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (v) {
                            if (v != null) provider.setSortBy(v);
                          },
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      '${projects.length} projects',
                      style: TextStyle(
                        fontSize: 12,
                        color: isDark
                            ? AppTheme.textMuted
                            : const Color(0xFF94A3B8),
                      ),
                    ),
                  ],
                ),
              ),

            // ─── Category tab bar ───────────────────────────────
            SizedBox(
              height: 44,
              child: TabBar(
                controller: _categoryTabController,
                isScrollable: true,
                tabAlignment: TabAlignment.start,
                indicator: BoxDecoration(
                  color: const Color(0xFF4ADE80),
                  borderRadius: BorderRadius.circular(20),
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
                splashBorderRadius: BorderRadius.circular(20),
                padding: const EdgeInsets.symmetric(horizontal: 16),
                onTap: (index) {
                  final cat = AffiliateProjectProvider.categories[index];
                  provider.setCategory(cat);
                },
                tabs: AffiliateProjectProvider.categories.map((cat) {
                  final idx = AffiliateProjectProvider.categories.indexOf(cat);
                  final selected = _categoryTabController.index == idx;
                  return Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 2),
                    child: Tab(
                      child: Text(
                        cat,
                        style: TextStyle(
                          fontWeight: selected ? FontWeight.w700 : FontWeight.w500,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  );
                }).toList(),
              ),
            ),

            // Featured projects carousel
            if (featured.isNotEmpty) ...[
              const SizedBox(height: 4),
              SizedBox(
                height: 180,
                child: ListView.builder(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: featured.length,
                  itemBuilder: (context, index) =>
                      _buildFeaturedCard(featured[index], isDark),
                ),
              ),
              const SizedBox(height: 8),
            ] else if (provider.isLoading) ...[
              const SizedBox(height: 4),
              _buildFeaturedSkeleton(isDark),
              const SizedBox(height: 8),
            ] else ...[
              const SizedBox(height: 4),
              const FeaturedProjectsEmptyState(),
              const SizedBox(height: 8),
            ],

            // All projects grid
            Expanded(
              child: _buildProjectGrid(projects, isDark),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFeaturedCard(AffiliateProjectEntity project, bool isDark) {
    return GestureDetector(
      onTap: () {
        HapticFeedback.mediumImpact();
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) =>
                AffiliateProjectDetailScreen(project: project),
          ),
        );
      },
      child: Container(
        width: 300,
        margin: const EdgeInsets.only(right: 12),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            colors: [
              const Color(0xFF4ADE80).withValues(alpha: 0.2),
              isDark
                  ? const Color(0xFF0F2740)
                  : Colors.white,
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: Stack(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        width: 36,
                        height: 36,
                        decoration: BoxDecoration(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: const Icon(Icons.star_rounded,
                            color: Color(0xFF4ADE80), size: 20),
                      ),
                      const Spacer(),
                      // Project type badge in featured card
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: project.isTask
                              ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                              : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(5),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              project.isTask
                                  ? Icons.task_alt_outlined
                                  : Icons.link_outlined,
                              size: 9,
                              color: project.isTask
                                  ? const Color(0xFF8B5CF6)
                                  : const Color(0xFF3B82F6),
                            ),
                            const SizedBox(width: 2),
                            Text(
                              project.isTask ? 'TASK' : 'AFFILIATE',
                              style: TextStyle(
                                fontSize: 7,
                                fontWeight: FontWeight.w700,
                                color: project.isTask
                                    ? const Color(0xFF8B5CF6)
                                    : const Color(0xFF3B82F6),
                              ),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 3),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Text(
                          'FEATURED',
                          style: TextStyle(
                            fontSize: 8,
                            fontWeight: FontWeight.w700,
                            color: Color(0xFFF59E0B),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  Text(
                    project.title,
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w700,
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    project.category,
                    style: TextStyle(
                      fontSize: 11,
                      color: isDark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        project.rewardText,
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF4ADE80),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Text(
                        'reward',
                        style: TextStyle(
                          fontSize: 10,
                          color: isDark
                              ? AppTheme.textMuted
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      Icon(Icons.timer_outlined,
                          size: 12,
                          color: isDark
                              ? AppTheme.textMuted
                              : const Color(0xFF94A3B8)),
                      const SizedBox(width: 4),
                      Text(
                        project.completionTimeText,
                        style: TextStyle(
                          fontSize: 11,
                          color: isDark
                              ? AppTheme.textMuted
                              : const Color(0xFF94A3B8),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildProjectCard(
      AffiliateProjectEntity project, bool isDark, int index) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: Duration(milliseconds: 300 + index * 50),
      curve: Curves.easeOutBack,
      builder: (context, value, child) {
        return Transform.scale(
          scale: value,
          child: Opacity(opacity: value.clamp(0.0, 1.0), child: child),
        );
      },
      child: GestureDetector(
        onTap: () {
          HapticFeedback.lightImpact();
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) =>
                  AffiliateProjectDetailScreen(project: project),
            ),
          );
        },
        child: Container(
          decoration: BoxDecoration(
            color: isDark
                ? const Color(0xFF0F2740)
                : Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isDark
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.5)
                  : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
            ),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withValues(alpha: 0.2)
                    : Colors.black.withValues(alpha: 0.03),
                blurRadius: 10,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Stack(
            children: [
              Padding(
                padding: const EdgeInsets.all(14),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Banner image (if available)
                    if (project.bannerImage.isNotEmpty)
                      ClipRRect(                          borderRadius: BorderRadius.circular(8),
                          child: Image.network(
                            project.bannerImage,
                            height: 48,
                            width: double.infinity,
                            fit: BoxFit.cover,
                            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                          ),
                        ),
                    if (project.bannerImage.isNotEmpty)
                      const SizedBox(height: 6),
                    // Logo + Title row
                    Row(
                      children: [
                        if (project.logoImage.isNotEmpty)
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(8),
                              child: Image.network(
                                project.logoImage,
                                width: 32,
                                height: 32,
                                fit: BoxFit.cover,
                                errorBuilder: (_, __, ___) => Container(
                                  width: 32,
                                  height: 32,
                                  decoration: BoxDecoration(
                                    color: _categoryColor(project.category).withValues(alpha: 0.15),
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Icon(
                                    _categoryIcon(project.category),
                                    size: 16,
                                    color: _categoryColor(project.category),
                                  ),
                                ),
                              ),
                            ),
                          )
                        else
                          Container(
                            width: 32,
                            height: 32,
                            decoration: BoxDecoration(
                              color: _categoryColor(project.category).withValues(alpha: 0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Icon(
                              _categoryIcon(project.category),
                              size: 16,
                              color: _categoryColor(project.category),
                            ),
                          ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                project.title,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              Text(
                                project.subtitle.isNotEmpty
                                    ? project.subtitle
                                    : project.category,
                                style: TextStyle(
                                  fontSize: 10,
                                  color: isDark
                                      ? AppTheme.textMuted
                                      : const Color(0xFF94A3B8),
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Reward
                    Row(
                      children: [
                        Text(
                          project.rewardText,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF4ADE80),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'reward',
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppTheme.textMuted
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    // Time + Difficulty + Category
                    Row(
                      children: [
                        Icon(Icons.timer_outlined,
                            size: 10,
                            color: isDark
                                ? AppTheme.textMuted
                                : const Color(0xFF94A3B8)),
                        const SizedBox(width: 3),
                        Text(
                          project.completionTimeText,
                          style: TextStyle(
                            fontSize: 10,
                            color: isDark
                                ? AppTheme.textMuted
                                : const Color(0xFF94A3B8),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: project.difficultyColor.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            project.difficultyLabel,
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.w700,
                              color: project.difficultyColor,
                            ),
                          ),
                        ),
                        const Spacer(),
                        Flexible(
                          child: Text(
                            project.category,
                            style: TextStyle(
                              fontSize: 9,
                              color: isDark
                                  ? AppTheme.textMuted
                                  : const Color(0xFF94A3B8),
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // View Details button
                    Container(
                      width: double.infinity,
                      height: 32,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        gradient: const LinearGradient(
                          colors: [
                            Color(0xFF4ADE80),
                            Color(0xFF22C55E)
                          ],
                        ),
                      ),
                      child: Center(
                        child: Text(
                          'VIEW DETAILS',
                          style: TextStyle(
                            color: Colors.black,
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              // Project Type badge (Task vs Affiliate)
              Positioned(
                top: 8,
                left: 8,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: project.isTask
                        ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                        : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(5),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        project.isTask
                            ? Icons.task_alt_outlined
                            : Icons.link_outlined,
                        size: 8,
                        color: project.isTask
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF3B82F6),
                      ),
                      const SizedBox(width: 2),
                      Text(
                        project.isTask ? 'TASK' : 'AFFILIATE',
                        style: TextStyle(
                          fontSize: 7,
                          fontWeight: FontWeight.w700,
                          color: project.isTask
                              ? const Color(0xFF8B5CF6)
                              : const Color(0xFF3B82F6),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              // Featured badge (below type badge, stacked vertically)
              if (project.featured)
                Positioned(
                  top: 30,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF59E0B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'FEATURED',
                      style: TextStyle(
                        fontSize: 7,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFFF59E0B),
                      ),
                    ),
                  ),
                ),
              // NEW badge (top-right)
              if (project.isNew)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Text(
                      'NEW',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: Color(0xFF3B82F6),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProjectGrid(List<AffiliateProjectEntity> projects, bool isDark) {
    final prov = context.read<AffiliateProjectProvider>();
    if (prov.isLoading && projects.isEmpty) {
      return _buildShimmerGrid(isDark);
    }
    if (projects.isEmpty) {
      return const ProjectsEmptyState();
    }

    return CustomScrollView(
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) =>
                  _buildProjectCard(projects[index], isDark, index),
              childCount: projects.length,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 16),
        ),
      ],
    );
  }

  /// Renders skeleton cards for the featured projects carousel while loading.
  Widget _buildFeaturedSkeleton(bool isDark) {
    return SizedBox(
      height: 180,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        physics: const NeverScrollableScrollPhysics(),
        itemCount: 2,
        itemBuilder: (context, index) =>
            const FeaturedProjectCardSkeleton(),
      ),
    );
  }

  /// Renders a shimmer skeleton grid while the first page loads.
  Widget _buildShimmerGrid(bool isDark) {
    return CustomScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      slivers: [
        SliverPadding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
          sliver: SliverGrid(
            gridDelegate:
                const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 2,
              childAspectRatio: 0.65,
              crossAxisSpacing: 12,
              mainAxisSpacing: 12,
            ),
            delegate: SliverChildBuilderDelegate(
              (context, index) => const ProjectCardSkeleton(),
              childCount: 6,
            ),
          ),
        ),
        const SliverToBoxAdapter(
          child: SizedBox(height: 80),
        ),
      ],
    );
  }

  Color _categoryColor(String category) {
    switch (category) {
      case 'Finance':
        return const Color(0xFF22C55E);
      case 'Shopping':
        return const Color(0xFFEC4899);
      case 'Gaming':
        return const Color(0xFF8B5CF6);
      case 'Surveys':
        return const Color(0xFF3B82F6);
      case 'Education':
        return const Color(0xFFF59E0B);
      case 'Technology':
        return const Color(0xFF06B6D4);
      case 'Social':
        return const Color(0xFF4ADE80);
      case 'Entertainment':
        return const Color(0xFFEF4444);
      default:
        return const Color(0xFF94A3B8);
    }
  }

  IconData _categoryIcon(String category) {
    switch (category) {
      case 'Finance':
        return Icons.account_balance_outlined;
      case 'Shopping':
        return Icons.shopping_bag_outlined;
      case 'Gaming':
        return Icons.sports_esports_outlined;
      case 'Surveys':
        return Icons.quiz_outlined;
      case 'Education':
        return Icons.school_outlined;
      case 'Technology':
        return Icons.computer_outlined;
      case 'Social':
        return Icons.people_outlined;
      case 'Entertainment':
        return Icons.movie_outlined;
      default:
        return Icons.app_shortcut_outlined;
    }
  }
}
