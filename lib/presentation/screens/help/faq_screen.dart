import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/help_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FaqScreen extends StatefulWidget {
  const FaqScreen({super.key});

  @override
  State<FaqScreen> createState() => _FaqScreenState();
}

class _FaqScreenState extends State<FaqScreen> {
  final _searchController = TextEditingController();
  int? _expandedIndex;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<HelpProvider>().loadFAQs();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(title: 'FAQ', onBack: () => Navigator.pop(context)),
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
        child: Consumer<HelpProvider>(
          builder: (context, hp, _) {
            return Column(
              children: [
                // Search bar
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                  child: PremiumGlass(
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    borderRadius: 14,
                    child: TextField(
                      controller: _searchController,
                      onChanged: hp.setFaqSearchQuery,
                      decoration: InputDecoration(
                        hintText: 'Search FAQs...',
                        prefixIcon: Icon(Icons.search_outlined,
                            color: theme.colorScheme.onSurfaceVariant, size: 20),
                        suffixIcon: _searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  _searchController.clear();
                                  hp.setFaqSearchQuery('');
                                },
                              )
                            : null,
                        border: InputBorder.none,
                        filled: false,
                      ),
                    ),
                  ),
                ),

                // Category chips
                SizedBox(
                  height: 42,
                  child: ListView.builder(
                    scrollDirection: Axis.horizontal,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    itemCount: HelpProvider.faqCategories.length,
                    itemBuilder: (context, index) {
                      final cat = HelpProvider.faqCategories[index];
                      final selected = hp.selectedFaqCategory == cat['key'];
                      return Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: GestureDetector(
                          onTap: () => hp.setFaqCategory(cat['key'] as String?),
                          child: AnimatedContainer(
                            duration: const Duration(milliseconds: 200),
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            decoration: BoxDecoration(
                              color: selected ? AppTheme.accentGreen : Colors.transparent,
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: selected
                                    ? AppTheme.accentGreen
                                    : (isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(cat['icon'] as IconData, size: 14,
                                    color: selected ? Colors.white : (isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                                const SizedBox(width: 6),
                                Text(cat['name'] as String,
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                        color: selected ? Colors.white : (isDark ? AppTheme.textMuted : const Color(0xFF64748B)))),
                              ],
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 8),

                // Results count
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Row(
                    children: [
                      Text('${hp.filteredFAQs.length} questions',
                          style: TextStyle(fontSize: 12,
                              color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                      const Spacer(),
                      if (hp.selectedFaqCategory != null)
                        GestureDetector(
                          onTap: () => hp.setFaqCategory(null),
                          child: Text('Clear filter',
                              style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                  color: theme.colorScheme.primary)),
                        ),
                    ],
                  ),
                ),

                const SizedBox(height: 8),

                // FAQ list
                Expanded(
                  child: hp.faqsLoading
                      ? const Center(child: PremiumLoader())
                      : hp.filteredFAQs.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  Icon(Icons.search_off_rounded, size: 48,
                                      color: isDark ? AppTheme.textMuted.withValues(alpha: 0.3) : const Color(0xFF94A3B8).withValues(alpha: 0.3)),
                                  const SizedBox(height: 12),
                                  Text('No matching questions',
                                      style: theme.textTheme.bodyMedium?.copyWith(
                                          color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))),
                                ],
                              ),
                            )
                          : ListView.builder(
                              padding: const EdgeInsets.symmetric(horizontal: 16),
                              itemCount: hp.filteredFAQs.length,
                              itemBuilder: (context, index) {
                                return _FaqItem(
                                  index: index,
                                  question: hp.filteredFAQs[index]['question'] as String,
                                  answer: hp.filteredFAQs[index]['answer'] as String,
                                  expandedIndex: _expandedIndex,
                                  theme: theme,
                                  onToggle: () {
                                    setState(() {
                                      _expandedIndex = _expandedIndex == index ? null : index;
                                    });
                                  },
                                );
                              },
                            ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }
}

class _FaqItem extends StatelessWidget {
  final int index;
  final String question;
  final String answer;
  final int? expandedIndex;
  final ThemeData theme;
  final VoidCallback onToggle;

  const _FaqItem({
    required this.index,
    required this.question,
    required this.answer,
    required this.expandedIndex,
    required this.theme,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final isExpanded = expandedIndex == index;
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumGlass(
        padding: const EdgeInsets.all(16),
        child: InkWell(
          onTap: onToggle,
          borderRadius: BorderRadius.circular(16),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(question,
                          style: theme.textTheme.bodyLarge?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: isDark ? Colors.white : const Color(0xFF0F172A))),
                    ),
                    Icon(
                      isExpanded ? Icons.expand_less : Icons.expand_more,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (isExpanded)
                  Padding(
                    padding: const EdgeInsets.only(top: 12),
                    child: Text(answer,
                        style: theme.textTheme.bodyMedium?.copyWith(
                            color: isDark ? AppTheme.textMuted : const Color(0xFF475569),
                            height: 1.5)),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
