import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/search_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  final _searchController = TextEditingController();
  final _focusNode = FocusNode();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final sp = context.read<SearchProvider>();
      sp.loadSearchHistory();
      sp.loadAllData();
      _focusNode.requestFocus();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(
        title: 'Search',
        onBack: () => Navigator.pop(context),
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
        child: Consumer<SearchProvider>(
          builder: (context, sp, _) {
            return Column(
              children: [
                // ─── Search Bar ──────────────────────────
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                  child: PremiumGlass(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: 16,
                    child: TextField(
                      controller: _searchController,
                      focusNode: _focusNode,
                      onChanged: sp.onQueryChanged,
                      textInputAction: TextInputAction.search,
                      onSubmitted: (value) {
                        if (value.trim().isNotEmpty) sp.search(value);
                      },
                      decoration: InputDecoration(
                        hintText: 'Search offers, projects...',
                        prefixIcon: Icon(Icons.search_outlined,
                            color: theme.colorScheme.onSurfaceVariant),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  IconButton(
                                    icon: Icon(Icons.mic_outlined,
                                        color: theme.colorScheme.onSurfaceVariant),
                                    onPressed: () {
                                      ScaffoldMessenger.of(context).showSnackBar(
                                        const SnackBar(
                                          content: Text('Voice search coming soon!'),
                                          duration: Duration(seconds: 2),
                                          behavior: SnackBarBehavior.floating,
                                        ),
                                      );
                                    },
                                  ),
                                  IconButton(
                                    icon: const Icon(Icons.clear, size: 20),
                                    onPressed: () {
                                      _searchController.clear();
                                      sp.clearSearch();
                                      _focusNode.requestFocus();
                                    },
                                  ),
                                ],
                              )
                            : null,
                        border: InputBorder.none,
                        filled: false,
                      ),
                      style: TextStyle(
                        fontSize: 16,
                        color: isDark ? Colors.white : const Color(0xFF0F172A),
                      ),
                    ),
                  ),
                ),

                // ─── Category Filter Chips ────────────────
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _buildCategoryChip('All', SearchCategory.all, AppTheme.accentGreen, sp, theme),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Offers', SearchCategory.offers, AppTheme.accentPurple, sp, theme),
                        const SizedBox(width: 8),
                        _buildCategoryChip('Projects', SearchCategory.projects, AppTheme.accentBlue, sp, theme),
                        const SizedBox(width: 8),

                        const Spacer(),
                        GestureDetector(
                          onTap: sp.toggleFilters,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            decoration: BoxDecoration(
                              color: sp.showFilters
                                  ? theme.colorScheme.primary.withValues(alpha: 0.15)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: sp.showFilters
                                    ? theme.colorScheme.primary
                                    : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.tune_outlined, size: 16,
                                    color: sp.showFilters
                                        ? theme.colorScheme.primary
                                        : theme.colorScheme.onSurfaceVariant),
                                const SizedBox(width: 4),
                                Text('Filters',
                                    style: TextStyle(fontSize: 12,
                                        fontWeight: FontWeight.w600,
                                        color: sp.showFilters
                                            ? theme.colorScheme.primary
                                            : theme.colorScheme.onSurfaceVariant)),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                // ─── Filters Panel ─────────────────────────
                if (sp.showFilters)
                  _buildFiltersPanel(sp, theme, isDark),

                // ─── Content ───────────────────────────────
                Expanded(
                  child: _buildContent(sp, theme, isDark),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildCategoryChip(String label, SearchCategory category,
      Color color, SearchProvider sp, ThemeData theme) {
    final selected = sp.categoryFilter == category;
    return GestureDetector(
      onTap: () => sp.setCategoryFilter(category),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: selected ? color : Colors.transparent,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: selected ? color : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
          ),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: selected ? Colors.white : theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ),
    );
  }

  Widget _buildFiltersPanel(SearchProvider sp, ThemeData theme, bool isDark) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 4),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppTheme.bgCardLight.withValues(alpha: 0.5) : const Color(0xFFF8FAFC),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Time Range',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                      color: isDark ? Colors.white : const Color(0xFF0F172A))),
              GestureDetector(
                onTap: sp.clearFilters,
                child: Text('Clear',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: Row(
              children: SearchTimeFilter.values.map((filter) {
                final selected = sp.timeFilter == filter;
                return Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () => sp.setTimeFilter(filter),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: selected
                            ? theme.colorScheme.primary.withValues(alpha: 0.15)
                            : Colors.transparent,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.2),
                        ),
                      ),
                      child: Text(
                        _timeFilterLabel(filter),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: selected
                              ? theme.colorScheme.primary
                              : theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
          const SizedBox(height: 12),
          Text('Reward Range',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                  color: isDark ? Colors.white : const Color(0xFF0F172A))),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Min pts',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? 0;
                    sp.setRewardRange(val, sp.maxReward);
                  },
                ),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8),
                child: Text('—', style: TextStyle(color: Colors.grey)),
              ),
              Expanded(
                child: TextField(
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: 'Max pts',
                    isDense: true,
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  ),
                  onChanged: (v) {
                    final val = double.tryParse(v) ?? 1000;
                    sp.setRewardRange(sp.minReward, val);
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _timeFilterLabel(SearchTimeFilter filter) {
    switch (filter) {
      case SearchTimeFilter.allTime: return 'All Time';
      case SearchTimeFilter.today: return 'Today';
      case SearchTimeFilter.thisWeek: return 'This Week';
      case SearchTimeFilter.thisMonth: return 'This Month';
    }
  }

  Widget _buildContent(SearchProvider sp, ThemeData theme, bool isDark) {
    // State: Loading
    if (sp.isLoading) {
      return const Center(child: PremiumLoader(message: 'Loading data...'));
    }

    // State: No query yet — show history + suggestions
    if (sp.query.isEmpty) {
      return _buildIdleState(sp, theme, isDark);
    }

    // State: Show suggestions while typing (before search is executed)
    if (sp.results.isEmpty && sp.suggestions.isNotEmpty) {
      return _buildSuggestions(sp, theme, isDark);
    }

    // State: No results found
    if (sp.results.isEmpty) {
      return _buildNoResults(sp, theme, isDark);
    }

    // State: Results found
    return _buildResultsList(sp, theme, isDark);
  }

  Widget _buildIdleState(SearchProvider sp, ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        // Popular Searches
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 12),
          child: SectionHeader(title: 'Popular Searches'),
        ),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: SearchProvider.popularSearches.map((s) {
            return GestureDetector(
              onTap: () {
                _searchController.text = s;
                sp.search(s);
              },
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                decoration: BoxDecoration(
                  color: isDark ? AppTheme.borderColor.withValues(alpha: 0.5) : const Color(0xFFF1F5F9),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.trending_up_rounded, size: 16,
                        color: isDark ? AppTheme.textSecondary : const Color(0xFF64748B)),
                    const SizedBox(width: 6),
                    Text(s,
                        style: TextStyle(fontSize: 13,
                            color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ],
                ),
              ),
            );
          }).toList(),
        ),

        const SizedBox(height: 24),

        // Recent Searches
        if (sp.searchHistory.isNotEmpty) ...[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const SectionHeader(title: 'Recent Searches'),
              GestureDetector(
                onTap: sp.clearSearchHistory,
                child: Text('Clear All',
                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                        color: theme.colorScheme.primary)),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ...sp.searchHistory.asMap().entries.map((entry) {
            final i = entry.key;
            final s = entry.value;
            return Dismissible(
              key: Key('history_$i'),
              direction: DismissDirection.endToStart,
              background: Container(
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.only(right: 16),
                decoration: BoxDecoration(
                  color: theme.colorScheme.error.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(Icons.delete_outline, color: theme.colorScheme.error, size: 20),
              ),
              onDismissed: (_) => sp.removeSearchItem(i),
              child: GestureDetector(
                onTap: () {
                  _searchController.text = s;
                  sp.search(s);
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  margin: const EdgeInsets.only(bottom: 4),
                  decoration: BoxDecoration(
                    color: Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.history_outlined, size: 18,
                          color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(s,
                            style: TextStyle(fontSize: 14,
                                color: isDark ? Colors.white : const Color(0xFF0F172A))),
                      ),
                      GestureDetector(
                        onTap: () => sp.removeSearchItem(i),
                        child: Icon(Icons.close, size: 18,
                            color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                      ),
                    ],
                  ),
                ),
              ),
            );
          }),
        ],
      ],
    );
  }

  Widget _buildSuggestions(SearchProvider sp, ThemeData theme, bool isDark) {
    return ListView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      children: [
        const Padding(
          padding: EdgeInsets.only(top: 16, bottom: 8),
          child: SectionHeader(title: 'Suggestions'),
        ),
        ...sp.suggestions.map((s) {
          return GestureDetector(
            onTap: () {
              _searchController.text = s;
              sp.search(s);
            },
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.transparent,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  Icon(Icons.search_outlined, size: 18,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(s,
                        style: TextStyle(fontSize: 14,
                            color: isDark ? Colors.white : const Color(0xFF0F172A))),
                  ),
                  Icon(Icons.north_west_outlined, size: 16,
                      color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                ],
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildNoResults(SearchProvider sp, ThemeData theme, bool isDark) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.search_off_rounded, size: 64,
                color: isDark ? AppTheme.textMuted.withValues(alpha: 0.3) : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
            const SizedBox(height: 20),
            Text('No results found',
                style: theme.textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.w600,
                    color: isDark ? Colors.white : const Color(0xFF0F172A))),
            const SizedBox(height: 8),
            Text('No "${sp.query}" matches were found\nTry a different search term or adjust your filters',
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
            const SizedBox(height: 24),
            OutlinedButton.icon(
              onPressed: sp.clearSearch,
              icon: const Icon(Icons.refresh, size: 18),
              label: const Text('Clear Search'),
              style: OutlinedButton.styleFrom(
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsList(SearchProvider sp, ThemeData theme, bool isDark) {
    // Group results by type
    final grouped = <String, List<SearchResult>>{};
    for (final result in sp.results) {
      final typeLabel = _typeLabel(result.type);
      grouped.putIfAbsent(typeLabel, () => []);
      grouped[typeLabel]!.add(result);
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Text('${sp.results.length} results for "${sp.query}"',
              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w500,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
        ),
        ...grouped.entries.map((entry) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: SectionHeader(title: entry.key),
              ),
              ...entry.value.map((result) => _buildResultCard(result, theme, isDark, sp)),
              const SizedBox(height: 8),
            ],
          );
        }),
      ],
    );
  }

  Widget _buildResultCard(SearchResult result, ThemeData theme, bool isDark, SearchProvider sp) {
    final color = Color(result.colorValue);
    final icon = _typeIcon(result.type);

    return GestureDetector(
      onTap: () {
        _navigateToResult(result);
      },
      child: PremiumGlass(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Icon(icon, size: 22, color: color),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(result.title,
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14,
                          color: isDark ? Colors.white : const Color(0xFF0F172A)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Text(result.subtitle,
                      style: TextStyle(fontSize: 12,
                          color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  Row(
                    children: [
                      if (result.category != null)
                        Text(result.category!,
                            style: TextStyle(fontSize: 10,
                                color: isDark ? AppTheme.textMuted.withValues(alpha: 0.7) : const Color(0xFF94A3B8).withValues(alpha: 0.7))),
                      if (result.category != null && result.reward != null) ...[
                        Text(' · ',
                            style: TextStyle(fontSize: 10,
                                color: isDark ? AppTheme.textMuted.withValues(alpha: 0.7) : const Color(0xFF94A3B8).withValues(alpha: 0.7))),
                      ],
                      if (result.reward != null)
                        Text(result.reward!,
                            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                                color: AppTheme.accentGreen)),
                    ],
                  ),
                ],
              ),
            ),
            Icon(Icons.chevron_right, size: 18,
                color: isDark ? AppTheme.textMuted.withValues(alpha: 0.4) : const Color(0xFF94A3B8).withValues(alpha: 0.4)),
          ],
        ),
      ),
    );
  }

  void _navigateToResult(SearchResult result) {
    switch (result.type) {
      case 'offer':
        Navigator.pushNamed(context, AppRouter.offerWall);
      case 'project':
        Navigator.pushNamed(context, AppRouter.projects);

    }
  }

  IconData _typeIcon(String type) {
    switch (type) {
      case 'offer': return Icons.local_offer_outlined;
      case 'project': return Icons.grid_view_outlined;
      default: return Icons.search_outlined;
    }
  }

  String _typeLabel(String type) {
    switch (type) {
      case 'offer': return 'Offers';
      case 'project': return 'Projects';
      default: return 'Results';
    }
  }
}
