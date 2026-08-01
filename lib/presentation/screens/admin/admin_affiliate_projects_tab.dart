import 'dart:convert';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AdminAffiliateProjectsTab extends StatefulWidget {
  const AdminAffiliateProjectsTab({super.key});

  @override
  State<AdminAffiliateProjectsTab> createState() =>
      _AdminAffiliateProjectsTabState();
}

class _AdminAffiliateProjectsTabState extends State<AdminAffiliateProjectsTab>
    with SingleTickerProviderStateMixin {
  late TabController _subTabController;

  bool _migrationCalled = false;

  @override
  void initState() {
    super.initState();
    _subTabController = TabController(length: 4, vsync: this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = context.read<AffiliateProjectProvider>();
      provider.subscribeToAllProjects();
      provider.subscribeToPendingParticipations();
      provider.subscribeToAllParticipations();

      // Auto-migrate any remaining draft projects on first visit.
      // Uses direct Firestore writes — no Cloud Functions needed.
      _migrateDrafts(provider);
    });
  }

  /// Batch-activate all draft projects via direct Firestore updates.
  /// Fully compatible with the Spark (free) plan.
  Future<void> _migrateDrafts(AffiliateProjectProvider provider) async {
    if (_migrationCalled) return;
    _migrationCalled = true;

    final drafts = provider.allProjects
        .where((p) => p.lifecycleStatus == ProjectLifecycleStatus.draft)
        .toList();

    if (drafts.isEmpty) {
      debugPrint('AdminMigration: No draft projects to migrate');
      return;
    }

    debugPrint('AdminMigration: Activating ${drafts.length} draft project(s)');
    int activated = 0;

    for (final project in drafts) {
      try {
        await provider.toggleProjectStatus(
          project.projectId,
          ProjectLifecycleStatus.active,
        );
        activated++;
      } catch (e) {
        debugPrint('AdminMigration: Failed to activate ${project.projectId}: $e');
      }
    }

    debugPrint('AdminMigration: Activated $activated / ${drafts.length} project(s)');
  }

  @override
  void dispose() {
    _subTabController.dispose();
    context.read<AffiliateProjectProvider>().unsubscribeAll();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        Container(
          margin: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: TabBar(
            controller: _subTabController,
            indicator: BoxDecoration(
              color: theme.colorScheme.primary,
              borderRadius: BorderRadius.circular(12),
            ),
            indicatorSize: TabBarIndicatorSize.tab,
            labelColor: Colors.white,
            unselectedLabelColor: theme.colorScheme.onSurfaceVariant,
            tabs: const [
              Tab(text: 'Analytics', icon: Icon(Icons.bar_chart_outlined, size: 18)),
              Tab(text: 'Manage', icon: Icon(Icons.folder_outlined, size: 18)),
              Tab(text: 'Submissions', icon: Icon(Icons.rate_review_outlined, size: 18)),
              Tab(text: 'Participants', icon: Icon(Icons.people_outlined, size: 18)),
            ],
          ),
        ),
        Expanded(
          child: TabBarView(
            controller: _subTabController,
            children: [
              _AnalyticsTab(),
              _ManageProjectsTab(),
              _ReviewSubmissionsTab(),
              _ParticipantsTab(),
            ],
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// ANALYTICS TAB
// ═══════════════════════════════════════════════════════════
class _AnalyticsTab extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final analytics = context.watch<AffiliateProjectProvider>().analytics;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Project Analytics',
              style: Theme.of(context)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                  child: _AnalyticCard(
                      label: 'Total Projects',
                      value: analytics.totalProjects.toString(),
                      icon: Icons.folder_outlined,
                      color: const Color(0xFF3B82F6),
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _AnalyticCard(
                      label: 'Active',
                      value: analytics.activeProjects.toString(),
                      icon: Icons.play_circle_outlined,
                      color: const Color(0xFF22C55E),
                      isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _AnalyticCard(
                      label: 'Total Clicks',
                      value: analytics.totalClicks.toString(),
                      icon: Icons.touch_app_outlined,
                      color: const Color(0xFF8B5CF6),
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _AnalyticCard(
                      label: 'Participants',
                      value: analytics.totalParticipants.toString(),
                      icon: Icons.people_outlined,
                      color: const Color(0xFF06B6D4),
                      isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _AnalyticCard(
                      label: 'Pending',
                      value: analytics.pendingReviews.toString(),
                      icon: Icons.hourglass_empty,
                      color: const Color(0xFFF59E0B),
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _AnalyticCard(
                      label: 'Approved',
                      value: analytics.approvedRewards.toString(),
                      icon: Icons.check_circle_outlined,
                      color: const Color(0xFF22C55E),
                      isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                  child: _AnalyticCard(
                      label: 'Rejected',
                      value: analytics.rejectedRewards.toString(),
                      icon: Icons.cancel_outlined,
                      color: const Color(0xFFEF4444),
                      isDark: isDark)),
              const SizedBox(width: 12),
              Expanded(
                  child: _AnalyticCard(
                      label: 'Rewards Paid',
                      value: '${analytics.totalRewardsPaid.toStringAsFixed(0)} pts',
                      icon: Icons.monetization_on_outlined,
                      color: const Color(0xFF4ADE80),
                      isDark: isDark)),
            ],
          ),
          const SizedBox(height: 12),
          _AnalyticCard(
              label: 'Conversion Rate',
              value: '${(analytics.conversionRate * 100).toStringAsFixed(1)}%',
              icon: Icons.trending_up_rounded,
              color: const Color(0xFFEC4899),
              isDark: isDark,
              fullWidth: true),
        ],
      ),
    );
  }
}

class _AnalyticCard extends StatelessWidget {
  final String label;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;
  final bool fullWidth;

  const _AnalyticCard({
    required this.label,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
    this.fullWidth = false,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      padding: EdgeInsets.all(fullWidth ? 20 : 14),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icon, color: color, size: fullWidth ? 22 : 18),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                value,
                style: TextStyle(
                  fontSize: fullWidth ? 20 : 16,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                label,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// MANAGE PROJECTS TAB
// ═══════════════════════════════════════════════════════════
class _ManageProjectsTab extends StatefulWidget {
  @override
  State<_ManageProjectsTab> createState() => _ManageProjectsTabState();
}

class _ManageProjectsTabState extends State<_ManageProjectsTab> {
  bool _showForm = false;

  // Form controllers
  final _titleCtrl = TextEditingController();
  final _subtitleCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _rewardCtrl = TextEditingController();
  String _selectedCategory = 'Finance';
  String _selectedProjectCategory = 'affiliate_offer'; // 'affiliate_offer' or 'task'
  String _selectedProjectType = 'affiliateOffer';
  final _bannerUrlCtrl = TextEditingController();
  final _logoUrlCtrl = TextEditingController();
  final _affiliateLinkCtrl = TextEditingController();
  final _affiliateProviderCtrl = TextEditingController();
  String? _bannerUrlError;
  String? _logoUrlError;
  String? _affiliateLinkError;
  final _instructionsCtrl = TextEditingController();
  final _termsCtrl = TextEditingController();
  final _completionTimeCtrl = TextEditingController(text: '30');
  String _selectedDifficulty = 'easy';
  final _maxParticipantsCtrl = TextEditingController(text: '1000');
  bool _featured = false;
  bool _allowRetry = false;
  DateTime? _expiryDate;
  String _selectedLifecycleStatus = 'active';

  // Eligibility fields
  final _maxAttemptsCtrl = TextEditingController(text: '1');
  final _dailyLimitCtrl = TextEditingController(text: '0');
  final _totalUserLimitCtrl = TextEditingController(text: '0');
  bool _newUsersOnly = false;
  bool _existingUsersOnly = false;

  // Tags
  final _tagsCtrl = TextEditingController();

  String? _editingProjectId;

  static const _categories = [
    'Finance', 'Shopping', 'Gaming', 'Surveys',
    'Education', 'Technology', 'Social', 'Entertainment',
  ];

  @override
  void dispose() {
    _titleCtrl.dispose();
    _subtitleCtrl.dispose();
    _descCtrl.dispose();
    _rewardCtrl.dispose();
    _bannerUrlCtrl.dispose();
    _logoUrlCtrl.dispose();
    _affiliateLinkCtrl.dispose();
    _affiliateProviderCtrl.dispose();
    _instructionsCtrl.dispose();
    _termsCtrl.dispose();
    _completionTimeCtrl.dispose();
    _maxParticipantsCtrl.dispose();
    _maxAttemptsCtrl.dispose();
    _dailyLimitCtrl.dispose();
    _totalUserLimitCtrl.dispose();
    _tagsCtrl.dispose();
    super.dispose();
  }

  void _editProject(AffiliateProjectEntity project) {
    _titleCtrl.text = project.title;
    _subtitleCtrl.text = project.subtitle;
    _descCtrl.text = project.description;
    _rewardCtrl.text = project.rewardAmount.toString();
    _selectedCategory = project.category;
    _selectedProjectCategory =
        project.projectType == ProjectType.affiliateOffer ? 'affiliate_offer' : 'task';
    _selectedProjectType = project.projectType.name;
    _bannerUrlCtrl.text = project.bannerImage;
    _logoUrlCtrl.text = project.logoImage;
    _affiliateLinkCtrl.text = project.affiliateTrackingLink;
    _affiliateProviderCtrl.text = project.affiliateProvider;
    _bannerUrlError = null;
    _logoUrlError = null;
    _affiliateLinkError = null;
    _instructionsCtrl.text = project.instructions.join('\n');
    _termsCtrl.text = project.termsAndConditions;
    _completionTimeCtrl.text = project.completionTime.toString();
    _selectedDifficulty = project.difficulty.name;
    _maxParticipantsCtrl.text = project.maxParticipants.toString();
    _featured = project.featured;
    _allowRetry = project.allowRetry;
    _expiryDate = project.expiryDate;
    _selectedLifecycleStatus = project.lifecycleStatus.name;
    _maxAttemptsCtrl.text = project.eligibility.maxAttemptsPerUser.toString();
    _dailyLimitCtrl.text = project.eligibility.dailyLimit.toString();
    _totalUserLimitCtrl.text = project.eligibility.totalUserLimit.toString();
    _newUsersOnly = project.eligibility.newUsersOnly;
    _existingUsersOnly = project.eligibility.existingUsersOnly;
    _tagsCtrl.text = project.tags.join(', ');
    _editingProjectId = project.projectId;
    setState(() => _showForm = true);
  }

  void _resetForm() {
    _titleCtrl.clear();
    _subtitleCtrl.clear();
    _descCtrl.clear();
    _rewardCtrl.clear();
    _bannerUrlCtrl.clear();
    _logoUrlCtrl.clear();
    _affiliateLinkCtrl.clear();
    _affiliateProviderCtrl.clear();
    _bannerUrlError = null;
    _logoUrlError = null;
    _affiliateLinkError = null;
    _instructionsCtrl.clear();
    _termsCtrl.clear();
    _completionTimeCtrl.text = '30';
    _maxParticipantsCtrl.text = '1000';
    _maxAttemptsCtrl.text = '1';
    _dailyLimitCtrl.text = '0';
    _totalUserLimitCtrl.text = '0';
    _tagsCtrl.clear();
    _selectedCategory = 'Finance';
    _selectedProjectCategory = 'affiliate_offer';
    _selectedProjectType = 'affiliateOffer';
    _selectedDifficulty = 'easy';
    _selectedLifecycleStatus = 'active';
    _featured = false;
    _allowRetry = false;
    _newUsersOnly = false;
    _existingUsersOnly = false;
    _expiryDate = null;
    _editingProjectId = null;
    setState(() => _showForm = false);
  }

  Future<void> _saveProject() async {
    final provider = context.read<AffiliateProjectProvider>();
    final adminUid = context.read<AuthProvider>().user?.uid ?? 'admin';

    if (_titleCtrl.text.trim().isEmpty || _descCtrl.text.trim().isEmpty) {
      _showSnackBar('Title and description are required');
      return;
    }

    final bannerUrl = _bannerUrlCtrl.text.trim();
    if (bannerUrl.isNotEmpty) {
      if (!bannerUrl.startsWith('https://')) {
        setState(() => _bannerUrlError = 'Must be a valid HTTPS URL');
        return;
      }
      final bannerUri = Uri.tryParse(bannerUrl);
      if (bannerUri == null || !bannerUri.isAbsolute) {
        setState(() => _bannerUrlError = 'Enter a valid URL');
        return;
      }
    }

    final logoUrl = _logoUrlCtrl.text.trim();
    if (logoUrl.isNotEmpty) {
      if (!logoUrl.startsWith('https://')) {
        setState(() => _logoUrlError = 'Must be a valid HTTPS URL');
        return;
      }
      final logoUri = Uri.tryParse(logoUrl);
      if (logoUri == null || !logoUri.isAbsolute) {
        setState(() => _logoUrlError = 'Enter a valid URL');
        return;
      }
    }

    // Validate affiliate fields only for Affiliate Offer projects
    final isAffiliate = _selectedProjectCategory == 'affiliate_offer';

    final affiliateLink = _affiliateLinkCtrl.text.trim();
    if (isAffiliate && affiliateLink.isEmpty) {
      setState(() => _affiliateLinkError = 'Affiliate Install URL is required');
      return;
    }
    if (affiliateLink.isNotEmpty) {
      if (!affiliateLink.startsWith('https://')) {
        setState(() => _affiliateLinkError = 'Must be a valid HTTPS URL');
        return;
      }
      final affiliateUri = Uri.tryParse(affiliateLink);
      if (affiliateUri == null || !affiliateUri.isAbsolute) {
        setState(() => _affiliateLinkError = 'Enter a valid URL');
        return;
      }
    }
    if (isAffiliate && _affiliateProviderCtrl.text.trim().isEmpty) {
      _showSnackBar('Affiliate Provider is required for Affiliate Offer projects');
      return;
    }

    final reward = double.tryParse(_rewardCtrl.text);
    if (reward == null || reward <= 0) {
      _showSnackBar('Enter a valid reward amount');
      return;
    }

    final instructions = _instructionsCtrl.text
        .split('\n')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final tags = _tagsCtrl.text
        .split(',')
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();

    final now = DateTime.now();
    final expiry = _expiryDate ?? now.add(const Duration(days: 30));

    final eligibility = ProjectEligibility(
      maxAttemptsPerUser: int.tryParse(_maxAttemptsCtrl.text) ?? 1,
      dailyLimit: int.tryParse(_dailyLimitCtrl.text) ?? 0,
      totalUserLimit: int.tryParse(_totalUserLimitCtrl.text) ?? 0,
      newUsersOnly: _newUsersOnly,
      existingUsersOnly: _existingUsersOnly,
    );

    final lifecycleStatus = ProjectLifecycleStatus.values.firstWhere(
      (e) => e.name == _selectedLifecycleStatus,
      orElse: () => ProjectLifecycleStatus.draft,
    );

    bool success;
    if (_editingProjectId != null) {
      final existing = provider.allProjects
          .firstWhere((p) => p.projectId == _editingProjectId);
      final updated = existing.copyWith(
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        rewardAmount: reward,
        category: _selectedCategory,
        projectType: ProjectType.values.firstWhere(
          (e) => e.name == _selectedProjectType,
          orElse: () => ProjectType.affiliateOffer,
        ),
        bannerImage: _bannerUrlCtrl.text.trim(),
        logoImage: _logoUrlCtrl.text.trim(),
        affiliateTrackingLink: _affiliateLinkCtrl.text.trim(),
        affiliateProvider: _affiliateProviderCtrl.text.trim(),
        instructions: instructions,
        termsAndConditions: _termsCtrl.text.trim(),
        completionTime: int.tryParse(_completionTimeCtrl.text) ?? 30,
        difficulty: ProjectDifficulty.values.firstWhere(
          (e) => e.name == _selectedDifficulty,
          orElse: () => ProjectDifficulty.easy,
        ),
        maxParticipants: int.tryParse(_maxParticipantsCtrl.text) ?? 1000,
        lifecycleStatus: lifecycleStatus,
        featured: _featured,
        allowRetry: _allowRetry,
        expiryDate: expiry,
        updatedDate: now,
        eligibility: eligibility,
        tags: tags,
      );
      success = await provider.updateProject(updated);
    } else {
      success = await provider.createProject(
        title: _titleCtrl.text.trim(),
        subtitle: _subtitleCtrl.text.trim(),
        description: _descCtrl.text.trim(),
        rewardAmount: reward,
        category: _selectedCategory,
        projectType: _selectedProjectType,
        bannerImage: _bannerUrlCtrl.text.trim(),
        logoImage: _logoUrlCtrl.text.trim(),
        affiliateTrackingLink: isAffiliate ? affiliateLink : '',
        affiliateProvider: isAffiliate ? _affiliateProviderCtrl.text.trim() : '',
        instructions: instructions,
        termsAndConditions: _termsCtrl.text.trim(),
        completionTime: int.tryParse(_completionTimeCtrl.text) ?? 30,
        difficulty: _selectedDifficulty,
        maxParticipants: int.tryParse(_maxParticipantsCtrl.text) ?? 1000,
        expiryDate: expiry,
        createdBy: adminUid,
        featured: _featured,
        eligibility: eligibility,
        tags: tags,
      );
    }

    if (mounted) {
      if (success) {
        _resetForm();
        _showSnackBar(provider.successMessage ?? 'Saved!');
      } else {
        _showSnackBar(provider.errorMessage ?? 'Failed to save');
      }
    }
  }

  Future<void> _testAffiliateLink() async {
    final url = _affiliateLinkCtrl.text.trim();
    if (url.isEmpty) {
      _showSnackBar('Enter a URL first');
      return;
    }
    final uri = Uri.tryParse(url);
    if (uri == null || !uri.isAbsolute) {
      _showSnackBar('Invalid URL');
      return;
    }
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    } else if (context.mounted) {
      _showSnackBar('Could not open link');
    }
  }

  void _showSnackBar(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AffiliateProjectProvider>();
    final projects = provider.allProjects;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text('Projects',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              FilledButton.icon(
                onPressed: () {
                  if (_showForm) {
                    _resetForm();
                  } else {
                    setState(() => _showForm = true);
                  }
                },
                icon: Icon(_showForm ? Icons.close : Icons.add, size: 18),
                label: Text(_showForm ? 'Cancel' : 'New Project'),
                style: FilledButton.styleFrom(
                  backgroundColor: _showForm ? null : AppTheme.accentGreen,
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (_showForm) _buildForm(theme),

          Text('${projects.length} projects',
              style: TextStyle(
                  fontSize: 13,
                  color: theme.colorScheme.onSurfaceVariant)),
          const SizedBox(height: 8),

          if (projects.isEmpty)
            PremiumEmptyState(
              icon: Icons.folder_outlined,
              title: 'No projects yet',
              subtitle: 'Create your first affiliate project',
            )
          else
            ...projects.map((project) => _ProjectAdminCard(
                  project: project,
                  theme: theme,
                  onEdit: () => _editProject(project),
                  onDelete: () =>
                      _confirmDelete(context, project, provider),
                  onDuplicate: () => provider.duplicateProject(project.projectId),
                  onToggleStatus: (status) =>
                      provider.toggleProjectStatus(project.projectId, status),
                  onToggleFeatured: () {
                    provider.updateProject(
                        project.copyWith(featured: !project.featured));
                  },
                  onToggleRetry: () {
                    provider.updateProject(
                        project.copyWith(allowRetry: !project.allowRetry));
                  },
                )),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildForm(ThemeData theme) {
    final provider = context.read<AffiliateProjectProvider>();
    return PremiumGlass(
      padding: const EdgeInsets.all(16),
      gradient: LinearGradient(colors: [
        theme.colorScheme.primaryContainer.withValues(alpha: 0.3),
        Colors.transparent,
      ]),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
              _editingProjectId != null
                  ? 'Edit Project'
                  : 'Create New Project',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 12),

          // Row 1: Project Category (Affiliate Offer vs Task)
          DropdownButtonFormField<String>(
            value: _selectedProjectCategory,
            decoration: const InputDecoration(
                labelText: 'Project Category *',
                border: OutlineInputBorder(),
                isDense: true,
                contentPadding:
                    EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
            items: const [
              DropdownMenuItem(
                  value: 'affiliate_offer',
                  child: Row(
                    children: [
                      Icon(Icons.link_outlined, size: 16, color: Color(0xFF3B82F6)),
                      SizedBox(width: 8),
                      Text('Affiliate Offer', style: TextStyle(fontSize: 14)),
                    ],
                  )),
              DropdownMenuItem(
                  value: 'task',
                  child: Row(
                    children: [
                      Icon(Icons.task_alt_outlined, size: 16, color: Color(0xFF8B5CF6)),
                      SizedBox(width: 8),
                      Text('Task', style: TextStyle(fontSize: 14)),
                    ],
                  )),
            ],
            onChanged: (v) {
              if (v == null) return;
              setState(() {
                _selectedProjectCategory = v;
                if (v == 'task') {
                  _selectedProjectType = 'uploadScreenshot';
                  _affiliateLinkCtrl.clear();
                  _affiliateProviderCtrl.clear();
                  _affiliateLinkError = null;
                } else {
                  _selectedProjectType = 'affiliateOffer';
                }
              });
            },
          ),
          const SizedBox(height: 8),

          // Row 2: Title
          TextField(
              controller: _titleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Title *',
                  hintText: 'Project name',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),

          // Row 3: Subtitle
          TextField(
              controller: _subtitleCtrl,
              decoration: const InputDecoration(
                  labelText: 'Subtitle',
                  hintText: 'Short description',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),

          // Row 4: Description
          TextField(
              controller: _descCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Description *',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),

          // Row 5: Project type + Category
          Row(children: [
            Expanded(
                child: DropdownButtonFormField<String>(
              value: _selectedProjectCategory == 'task'
                  ? _selectedProjectType
                  : 'affiliateOffer',
              decoration: InputDecoration(
                  labelText: _selectedProjectCategory == 'task'
                      ? 'Task Type'
                      : 'Project Type',
                  border: const OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: _selectedProjectCategory == 'task'
                  ? ProjectType.values
                      .where((t) => t != ProjectType.affiliateOffer)
                      .map((t) => DropdownMenuItem(
                          value: t.name,
                          child: Text(t.label,
                              style: const TextStyle(fontSize: 12))))
                      .toList()
                  : [
                      const DropdownMenuItem(
                          value: 'affiliateOffer',
                          child: Text('Affiliate Offer',
                              style: TextStyle(fontSize: 12)))
                    ],
              onChanged: _selectedProjectCategory == 'task'
                  ? (v) => setState(() =>
                      _selectedProjectType = v ?? 'uploadScreenshot')
                  : null,
            )),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<String>(
              value: _selectedCategory,
              decoration: const InputDecoration(
                  labelText: 'Category',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: _categories
                  .map((c) => DropdownMenuItem(
                      value: c,
                      child: Text(c, style: const TextStyle(fontSize: 14))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedCategory = v ?? 'Finance'),
            )),
          ]),
          const SizedBox(height: 8),

          // Row 6: Reward + Completion time + Difficulty
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _rewardCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Reward (pts) *',
                        prefixText: 'pts ',
                        border: OutlineInputBorder(),
                        isDense: true))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _completionTimeCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Time (min)',
                        border: OutlineInputBorder(),
                        isDense: true))),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<String>(
              value: _selectedDifficulty,
              decoration: const InputDecoration(
                  labelText: 'Difficulty',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: ['easy', 'medium', 'hard']
                  .map((d) => DropdownMenuItem(
                      value: d,
                      child: Text(d[0].toUpperCase() + d.substring(1),
                          style: const TextStyle(fontSize: 13))))
                  .toList(),
              onChanged: (v) =>
                  setState(() => _selectedDifficulty = v ?? 'easy'),
            )),
          ]),
          const SizedBox(height: 8),

          // Row 7: Banner + Logo URLs
          TextField(
              controller: _bannerUrlCtrl,
              onChanged: (_) {
                if (_bannerUrlError != null) {
                  setState(() => _bannerUrlError = null);
                }
              },
              decoration: InputDecoration(
                  labelText: 'Banner Image URL',
                  hintText: 'https://...',
                  errorText: _bannerUrlError,
                  border: const OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: _logoUrlCtrl,
              onChanged: (_) {
                if (_logoUrlError != null) {
                  setState(() => _logoUrlError = null);
                }
              },
              decoration: InputDecoration(
                  labelText: 'Logo Image URL',
                  hintText: 'https://...',
                  errorText: _logoUrlError,
                  border: const OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),

          // Row 8: Affiliate Install URL + provider (only for Affiliate Offer)
          if (_selectedProjectCategory == 'affiliate_offer') ...[
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: TextField(
                      controller: _affiliateLinkCtrl,
                      onChanged: (_) {
                        if (_affiliateLinkError != null) {
                          setState(() => _affiliateLinkError = null);
                        }
                      },
                      decoration: InputDecoration(
                          labelText:
                              'Affiliate Install URL / Tracking Link *',
                          hintText: 'https://...',
                          errorText: _affiliateLinkError,
                          border: const OutlineInputBorder(),
                          isDense: true)),
                ),
                const SizedBox(width: 4),
                SizedBox(
                  height: 48,
                  child: IconButton(
                    onPressed: _testAffiliateLink,
                    icon: const Icon(Icons.open_in_new, size: 18),
                    tooltip: 'Test Link',
                    style: IconButton.styleFrom(
                      backgroundColor: theme
                          .colorScheme
                          .primaryContainer
                          .withValues(alpha: 0.5),
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10)),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            TextField(
                controller: _affiliateProviderCtrl,
                decoration: const InputDecoration(
                    labelText: 'Affiliate Provider (e.g. Angel One) *',
                    hintText: 'Provider name',
                    border: OutlineInputBorder(),
                    isDense: true)),
            const SizedBox(height: 8),
          ] else ...[
            // Show a hint that these fields are hidden for Task projects
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: const Color(0xFF8B5CF6).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                    color: const Color(0xFF8B5CF6).withValues(alpha: 0.2)),
              ),
              child: Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 18,
                      color: const Color(0xFF8B5CF6)),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      'Affiliate fields are not needed for Task projects. '
                      'Users will submit proof directly instead of visiting an external link.',
                      style: TextStyle(
                        fontSize: 12,
                        color: const Color(0xFF8B5CF6),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
          ],

          // Row 8: Instructions + Terms
          TextField(
              controller: _instructionsCtrl,
              maxLines: 3,
              decoration: const InputDecoration(
                  labelText: 'Instructions (one per line)',
                  hintText: 'Step 1: ...',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),
          TextField(
              controller: _termsCtrl,
              maxLines: 2,
              decoration: const InputDecoration(
                  labelText: 'Terms & Conditions',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 8),

          // Row 9: Max participants + Expiry + Lifecycle
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _maxParticipantsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max Participants',
                        border: OutlineInputBorder(),
                        isDense: true))),
            const SizedBox(width: 8),
            Expanded(
                child: InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _expiryDate ??
                      DateTime.now().add(const Duration(days: 30)),
                  firstDate: DateTime.now(),
                  lastDate: DateTime.now().add(const Duration(days: 365)),
                );
                if (picked != null) setState(() => _expiryDate = picked);
              },
              child: InputDecorator(
                decoration: const InputDecoration(
                    labelText: 'Expiry Date',
                    border: OutlineInputBorder(),
                    isDense: true,
                    contentPadding:
                        EdgeInsets.symmetric(horizontal: 10, vertical: 12)),
                child: Text(
                    _expiryDate != null
                        ? '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'
                        : 'Pick date',
                    style: TextStyle(
                        fontSize: 12,
                        color: _expiryDate == null
                            ? theme.colorScheme.onSurfaceVariant
                            : null)),
              ),
            )),
            const SizedBox(width: 8),
            Expanded(
                child: DropdownButtonFormField<String>(
              value: _selectedLifecycleStatus,
              decoration: const InputDecoration(
                  labelText: 'Status',
                  border: OutlineInputBorder(),
                  isDense: true,
                  contentPadding:
                      EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
              items: ProjectLifecycleStatus.values
                  .map((s) => DropdownMenuItem(
                      value: s.name,
                      child: Text(s.label,
                          style: const TextStyle(fontSize: 12))))
                  .toList(),
              onChanged: (v) => setState(
                  () => _selectedLifecycleStatus = v ?? 'draft'),
            )),
          ]),
          const SizedBox(height: 8),

          // Row 10: Tags
          TextField(
              controller: _tagsCtrl,
              decoration: const InputDecoration(
                  labelText: 'Tags (comma separated)',
                  hintText: 'popular, new, trending',
                  border: OutlineInputBorder(),
                  isDense: true)),
          const SizedBox(height: 12),

          // ─── Eligibility Section ────────────────────────
          Text('Eligibility Settings',
              style: theme.textTheme.titleSmall
                  ?.copyWith(fontWeight: FontWeight.w600)),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
                child: TextField(
                    controller: _maxAttemptsCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Max Attempts',
                        border: OutlineInputBorder(),
                        isDense: true))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _dailyLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'Daily Limit (0=unlimited)',
                        border: OutlineInputBorder(),
                        isDense: true))),
            const SizedBox(width: 8),
            Expanded(
                child: TextField(
                    controller: _totalUserLimitCtrl,
                    keyboardType: TextInputType.number,
                    decoration: const InputDecoration(
                        labelText: 'User Limit (0=unlimited)',
                        border: OutlineInputBorder(),
                        isDense: true))),
          ]),
          const SizedBox(height: 8),
          Row(children: [
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('New Users Only',
                    style: TextStyle(fontSize: 13)),
                value: _newUsersOnly,
                onChanged: (v) => setState(() => _newUsersOnly = v),
                dense: true,
                activeColor: AppTheme.accentGreen,
              ),
            ),
            Expanded(
              child: SwitchListTile(
                contentPadding: EdgeInsets.zero,
                title: const Text('Existing Users Only',
                    style: TextStyle(fontSize: 13)),
                value: _existingUsersOnly,
                onChanged: (v) => setState(() => _existingUsersOnly = v),
                dense: true,
                activeColor: AppTheme.accentGreen,
              ),
            ),
          ]),
          const SizedBox(height: 8),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title:
                const Text('Featured', style: TextStyle(fontSize: 14)),
            value: _featured,
            onChanged: (v) => setState(() => _featured = v),
            activeColor: AppTheme.accentGreen,
          ),
          SwitchListTile(
            contentPadding: EdgeInsets.zero,
            title: Row(
              children: [
                const Text('Allow Retry', style: TextStyle(fontSize: 14)),
                const SizedBox(width: 4),
                Icon(Icons.replay_outlined,
                    size: 16, color: _allowRetry ? const Color(0xFFF59E0B) : AppTheme.textMuted),
              ],
            ),
            subtitle: Text(
              _allowRetry
                  ? 'Rejected users can rejoin via Available Projects'
                  : 'Rejected projects stay hidden from Available Projects',
              style: const TextStyle(fontSize: 11),
            ),
            value: _allowRetry,
            onChanged: (v) => setState(() => _allowRetry = v),
            activeColor: const Color(0xFFF59E0B),
          ),
          const SizedBox(height: 12),
          GradientButton(
            onPressed: provider.isLoading ? null : _saveProject,
            label: provider.isLoading
                ? 'Saving...'
                : (_editingProjectId != null
                    ? 'Update Project'
                    : 'Create Project'),
            isLoading: provider.isLoading,
            gradient: const LinearGradient(
                colors: [AppTheme.accentGreen, Color(0xFF43A047)]),
            icon: _editingProjectId != null
                ? Icons.save_outlined
                : Icons.check,
          ),
        ],
      ),
    );
  }

  void _confirmDelete(BuildContext context, AffiliateProjectEntity project,
      AffiliateProjectProvider provider) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Project?'),
        content: Text('Delete "${project.title}"? This cannot be undone.'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          TextButton(
            onPressed: () {
              provider.deleteProject(project.projectId);
              Navigator.pop(ctx);
            },
            child:
                const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PROJECT ADMIN CARD
// ═══════════════════════════════════════════════════════════
class _ProjectAdminCard extends StatelessWidget {
  final AffiliateProjectEntity project;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;
  final VoidCallback onDuplicate;
  final ValueChanged<ProjectLifecycleStatus> onToggleStatus;
  final VoidCallback onToggleFeatured;
  final VoidCallback onToggleRetry;

  const _ProjectAdminCard({
    required this.project,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
    required this.onDuplicate,
    required this.onToggleStatus,
    required this.onToggleFeatured,
    required this.onToggleRetry,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = project.lifecycleStatus.color;

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: project.projectType.iconColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(project.projectType.icon,
                    color: project.projectType.iconColor, size: 18),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(project.title,
                        style: const TextStyle(
                            fontWeight: FontWeight.w600, fontSize: 14)),
                    Text(
                        '${project.rewardAmount.toStringAsFixed(0)} pts · ${project.projectType.label} · ${project.currentParticipants}/${project.maxParticipants}',
                        style: TextStyle(
                            fontSize: 11,
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  project.lifecycleStatus.label.toUpperCase(),
                  style: TextStyle(
                      fontSize: 9,
                      fontWeight: FontWeight.bold,
                      color: statusColor),
                ),
              ),
              const SizedBox(width: 4),
              // Category badge (Task vs Affiliate)
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
                decoration: BoxDecoration(
                  color: project.isTask
                      ? const Color(0xFF8B5CF6).withValues(alpha: 0.12)
                      : const Color(0xFF3B82F6).withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      project.isTask
                          ? Icons.task_alt_outlined
                          : Icons.link_outlined,
                      size: 10,
                      color: project.isTask
                          ? const Color(0xFF8B5CF6)
                          : const Color(0xFF3B82F6),
                    ),
                    const SizedBox(width: 2),
                    Text(
                      project.isTask ? 'TASK' : 'AFFILIATE',
                      style: TextStyle(
                        fontSize: 8,
                        fontWeight: FontWeight.w700,
                        color: project.isTask
                            ? const Color(0xFF8B5CF6)
                            : const Color(0xFF3B82F6),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              // Allow Retry toggle
              IconButton(
                icon: Icon(
                  project.allowRetry
                      ? Icons.replay_circle_filled_outlined
                      : Icons.replay_circle_filled_outlined,
                  size: 18,
                  color: project.allowRetry
                      ? const Color(0xFFF59E0B)
                      : theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                onPressed: onToggleRetry,
                tooltip: project.allowRetry ? 'Retry: ON' : 'Retry: OFF',
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              // Featured toggle
              IconButton(
                icon: Icon(
                  project.featured ? Icons.star : Icons.star_outline,
                  size: 18,
                  color: project.featured
                      ? const Color(0xFFF59E0B)
                      : theme.colorScheme.onSurfaceVariant,
                ),
                onPressed: onToggleFeatured,
                tooltip: 'Toggle Featured',
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              // Duplicate
              IconButton(
                icon: Icon(Icons.copy_outlined,
                    size: 18, color: theme.colorScheme.primary),
                onPressed: onDuplicate,
                tooltip: 'Duplicate',
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              // Status toggle
              PopupMenuButton<ProjectLifecycleStatus>(
                icon: Icon(Icons.more_vert,
                    size: 18, color: theme.colorScheme.onSurfaceVariant),
                constraints: const BoxConstraints(),
                onSelected: onToggleStatus,
                itemBuilder: (_) => [
                  if (project.lifecycleStatus != ProjectLifecycleStatus.active)
                    const PopupMenuItem(
                        value: ProjectLifecycleStatus.active,
                        child: Text('Activate',
                            style: TextStyle(fontSize: 13))),
                  if (project.lifecycleStatus != ProjectLifecycleStatus.paused)
                    const PopupMenuItem(
                        value: ProjectLifecycleStatus.paused,
                        child: Text('Pause',
                            style: TextStyle(fontSize: 13))),
                  if (project.lifecycleStatus != ProjectLifecycleStatus.draft)
                    const PopupMenuItem(
                        value: ProjectLifecycleStatus.draft,
                        child: Text('Draft',
                            style: TextStyle(fontSize: 13))),
                  if (project.lifecycleStatus != ProjectLifecycleStatus.expired)
                    const PopupMenuItem(
                        value: ProjectLifecycleStatus.expired,
                        child: Text('Expire',
                            style: TextStyle(fontSize: 13))),
                  if (project.lifecycleStatus != ProjectLifecycleStatus.archived)
                    const PopupMenuItem(
                        value: ProjectLifecycleStatus.archived,
                        child: Text('Archive',
                            style: TextStyle(fontSize: 13))),
                ],
              ),
              IconButton(
                icon: Icon(Icons.edit_outlined,
                    size: 18, color: theme.colorScheme.primary),
                onPressed: onEdit,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
              IconButton(
                icon: Icon(Icons.delete_outline,
                    size: 18, color: theme.colorScheme.error),
                onPressed: onDelete,
                constraints:
                    const BoxConstraints(minWidth: 36, minHeight: 36),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// REVIEW SUBMISSIONS TAB
// ═══════════════════════════════════════════════════════════
class _ReviewSubmissionsTab extends StatefulWidget {
  @override
  State<_ReviewSubmissionsTab> createState() =>
      _ReviewSubmissionsTabState();
}

class _ReviewSubmissionsTabState extends State<_ReviewSubmissionsTab> {
  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AffiliateProjectProvider>();
    final all = provider.pendingParticipations;
    final pending = all
        .where((p) =>
            p.status == ProjectStatus.pendingReview ||
            p.status == ProjectStatus.submitted ||
            p.status == ProjectStatus.underReview)
        .toList();
    final reviewed = all
        .where((p) =>
            p.status == ProjectStatus.approved ||
            p.status == ProjectStatus.rejected)
        .toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Text('Pending Review (${pending.length})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (pending.isEmpty)
          PremiumEmptyState(
            icon: Icons.inbox_outlined,
            title: 'No pending submissions',
            subtitle: 'Submissions will appear here for review',
          )
        else
          ...pending.map(
              (sub) => _SubmissionReviewCard(submission: sub, theme: theme)),
        const SizedBox(height: 24),
        Text('Reviewed (${reviewed.length})',
            style: theme.textTheme.titleMedium
                ?.copyWith(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (reviewed.isEmpty)
          const Padding(
              padding: EdgeInsets.all(16),
              child: Text('No reviewed submissions yet'))
        else
          ...reviewed.map(
              (sub) => _SubmissionReviewCard(submission: sub, theme: theme)),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════
// SUBMISSION REVIEW CARD
// ═══════════════════════════════════════════════════════════
class _SubmissionReviewCard extends StatelessWidget {
  final ProjectParticipationEntity submission;
  final ThemeData theme;

  const _SubmissionReviewCard(
      {required this.submission, required this.theme});

  @override
  Widget build(BuildContext context) {
    final isPending = submission.status == ProjectStatus.pendingReview ||
        submission.status == ProjectStatus.submitted ||
        submission.status == ProjectStatus.underReview;
    final isRejected = submission.status == ProjectStatus.rejected;
    final statusColor = submission.status == ProjectStatus.approved ||
            submission.status == ProjectStatus.completed
        ? Colors.green
        : isRejected
            ? theme.colorScheme.error
            : Colors.orange;

    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // User info row
          Row(
            children: [
              CircleAvatar(
                radius: 16,
                backgroundColor: theme.colorScheme.primaryContainer,
                child: Text(
                  (submission.userName.isNotEmpty
                          ? submission.userName[0]
                          : '?')
                      .toUpperCase(),
                  style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: theme.colorScheme.primary),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(submission.projectTitle,
                        style: theme.textTheme.bodyMedium
                            ?.copyWith(fontWeight: FontWeight.w600)),
                    Text(
                        'by ${submission.userName} · ${submission.rewardAmount.toStringAsFixed(2)} pts',
                        style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant)),
                  ],
                ),
              ),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(submission.status.label.toUpperCase(),
                    style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: statusColor)),
              ),
            ],
          ),
          // Screenshot thumbnails (supports multiple images via JSON array)
          if (submission.screenshotUrl != null &&
              submission.screenshotUrl!.isNotEmpty) ...[
            const SizedBox(height: 8),
            _buildScreenshotsSection(context, submission.screenshotUrl!),
          ],
          // Note/remarks
          if (submission.note != null && submission.note!.isNotEmpty) ...[
            const SizedBox(height: 6),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('User remarks:',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurfaceVariant)),
                  const SizedBox(height: 2),
                  Text(submission.note!,
                      style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant)),
                ],
              ),
            ),
          ],
          // Transaction ID
          if (submission.transactionId != null &&
              submission.transactionId!.isNotEmpty) ...[
            const SizedBox(height: 4),
            Row(
              children: [
                Icon(Icons.receipt_outlined,
                    size: 14, color: theme.colorScheme.onSurfaceVariant),
                const SizedBox(width: 4),
                Text('Txn: ${submission.transactionId}',
                    style: TextStyle(
                        fontSize: 11,
                        color: theme.colorScheme.onSurfaceVariant)),
              ],
            ),
          ],

          // Rejection reason
          if (submission.rejectionReason != null) ...[
            const SizedBox(height: 4),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: theme.colorScheme.errorContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(Icons.error_outline, size: 14, color: Colors.red),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text('${submission.rejectionReason}',
                        style: TextStyle(
                            fontSize: 12, color: theme.colorScheme.error)),
                  ),
                ],
              ),
            ),
          ],
          // Action buttons
          if (isPending) ...[
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: () => _showRejectDialog(context),
                  icon: const Icon(Icons.close, size: 16),
                  label: const Text('Reject'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: theme.colorScheme.error,
                    side: BorderSide(
                        color: theme.colorScheme.error.withValues(alpha: 0.5)),
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
                const SizedBox(width: 8),
                FilledButton.icon(
                  onPressed: () => _approveAndCredit(context),
                  icon: const Icon(Icons.check, size: 16),
                  label: const Text('Approve & Credit'),
                  style: FilledButton.styleFrom(
                    backgroundColor: Colors.green,
                    shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  /// Parse screenshot URLs — supports both single URL and JSON array format.
  List<String> _parseScreenshotUrls(String raw) {
    final trimmed = raw.trim();
    if (trimmed.startsWith('[')) {
      try {
        final list = jsonDecode(trimmed) as List<dynamic>;
        return list.map((e) => e.toString()).toList();
      } catch (_) {
        return [trimmed];
      }
    }
    return [trimmed];
  }

  /// Builds a grid of screenshot thumbnails with a count badge.
  Widget _buildScreenshotsSection(BuildContext context, String rawUrls) {
    final urls = _parseScreenshotUrls(rawUrls);
    if (urls.isEmpty) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(Icons.image_outlined,
                size: 14, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(width: 4),
            Text(
              '${urls.length} screenshot${urls.length > 1 ? 's' : ''}',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 100,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: urls.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              return GestureDetector(
                onTap: () => _viewScreenshotDialog(context, urls, index),
                child: Container(
                  width: 140,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                        color: theme.colorScheme.outlineVariant),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(7),
                    child: Stack(
                      children: [
                        Image.network(
                          urls[index],
                          width: 140,
                          height: 100,
                          fit: BoxFit.cover,
                          errorBuilder: (_, __, ___) => Container(
                            color: theme.colorScheme.surfaceContainerHighest,
                            child: const Center(
                              child: Icon(Icons.broken_image_outlined,
                                  size: 24, color: Colors.grey),
                            ),
                          ),
                        ),
                        if (urls.length > 1)
                          Positioned(
                            bottom: 4,
                            right: 4,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 5, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.black54,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                '${index + 1}/${urls.length}',
                                style: const TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 4),
        Text(
          'Tap to view full screenshot',
          style: TextStyle(
              fontSize: 10,
              color: theme.colorScheme.primary,
              decoration: TextDecoration.underline),
        ),
      ],
    );
  }

  /// Shows a full-screen dialog with swipeable screenshots.
  void _viewScreenshotDialog(BuildContext context, List<String> urls,
      [int initialIndex = 0]) {
    final pageController = PageController(initialPage: initialIndex);

    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(8),
        child: Stack(
          alignment: Alignment.topRight,
          children: [
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (urls.length > 1)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 8),
                    child: Text(
                      '${initialIndex + 1} of ${urls.length}',
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                SizedBox(
                  height: MediaQuery.of(context).size.height * 0.6,
                  child: PageView(
                    controller: pageController,
                    children: urls.map((url) {
                      return ClipRRect(
                        borderRadius: BorderRadius.circular(16),
                        child: InteractiveViewer(
                          child: Image.network(
                            url,
                            fit: BoxFit.contain,
                            errorBuilder: (_, __, ___) => Container(
                              height: 400,
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.7),
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: const Center(
                                child: Column(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Icon(Icons.broken_image_outlined,
                                        size: 48, color: Colors.white54),
                                    SizedBox(height: 8),
                                    Text('Unable to load image',
                                        style:
                                            TextStyle(color: Colors.white54)),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
              ],
            ),
            Positioned(
              top: 8,
              right: 8,
              child: IconButton(
                icon: Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.5),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.close, color: Colors.white, size: 20),
                ),
                onPressed: () => Navigator.pop(ctx),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _approveAndCredit(BuildContext context) {
    final provider = context.read<AffiliateProjectProvider>();
    final adminUid = context.read<AuthProvider>().user?.uid ?? 'admin';
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Approve & Credit Reward'),
        content: Text(
            'Approve ${submission.userName}\'s submission for ${submission.projectTitle} and credit ${submission.rewardAmount.toStringAsFixed(2)} pts?'),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Cancel')),
          FilledButton(
            onPressed: () async {
              Navigator.pop(ctx);
              final result = await provider.approveAndCreditReward(
                submission.participationId,
                submission.userId,
                reviewedBy: adminUid,
              );
              if (context.mounted) {
                if (result.approved) {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(
                      result.credited
                          ? 'Reward credited to ${submission.userName}'
                          : 'Approved. Reward was already credited.',
                    ),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.green,
                  ));
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                    content: Text(provider.errorMessage ?? 'Failed to approve submission'),
                    behavior: SnackBarBehavior.floating,
                    backgroundColor: Colors.red,
                  ));
                }
              }
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Approve & Credit'),
          ),
        ],
      ),
    );
  }

  void _showRejectDialog(BuildContext context) {
    final controller = TextEditingController();
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16)),
        child: PremiumCard(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('Reject Submission',
                  style: theme.textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 12),
              TextField(
                controller: controller,
                decoration: const InputDecoration(
                  labelText: 'Rejection reason',
                  hintText: 'Why was this rejected?',
                  border: OutlineInputBorder(),
                  isDense: true,
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => Navigator.pop(ctx),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton(
                      onPressed: () {
                        if (controller.text.trim().isNotEmpty) {
                          context
                              .read<AffiliateProjectProvider>()
                              .rejectParticipation(
                                  submission.participationId,
                                  controller.text.trim());
                          Navigator.pop(ctx);
                        }
                      },
                      style: FilledButton.styleFrom(
                          backgroundColor: theme.colorScheme.error),
                      child: const Text('Reject'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════
// PARTICIPANTS TAB
// ═══════════════════════════════════════════════════════════
class _ParticipantsTab extends StatefulWidget {
  @override
  State<_ParticipantsTab> createState() => _ParticipantsTabState();
}

class _ParticipantsTabState extends State<_ParticipantsTab> {
  String? _selectedProjectId;
  String _statusFilter = 'all';

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final provider = context.watch<AffiliateProjectProvider>();
    final projects = provider.allProjects;
    final all = provider.allParticipations;

    var participants = all;
    if (_selectedProjectId != null) {
      participants =
          participants.where((p) => p.projectId == _selectedProjectId).toList();
    }
    if (_statusFilter != 'all') {
      participants = participants
          .where((p) => p.status.name == _statusFilter)
          .toList();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: _selectedProjectId,
                  decoration: InputDecoration(
                    labelText: 'Select Project',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: null, child: Text('All Projects')),
                    ...projects.map((p) => DropdownMenuItem(
                        value: p.projectId,
                        child: Text(p.title,
                            style: const TextStyle(fontSize: 13)))),
                  ],
                  onChanged: (v) => setState(() => _selectedProjectId = v),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 100,
                child: DropdownButtonFormField<String>(
                  value: _statusFilter,
                  decoration: InputDecoration(
                    labelText: 'Status',
                    border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12)),
                    isDense: true,
                    filled: true,
                    fillColor: theme.colorScheme.surfaceContainerHighest
                        .withValues(alpha: 0.3),
                    contentPadding:
                        const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: [
                    const DropdownMenuItem(
                        value: 'all', child: Text('All', style: TextStyle(fontSize: 12))),
                    ...ProjectStatus.values.map((s) => DropdownMenuItem(
                        value: s.name,
                        child: Text(s.label,
                            style: const TextStyle(fontSize: 12)))),
                  ],
                  onChanged: (v) => setState(() => _statusFilter = v ?? 'all'),
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: participants.isEmpty
              ? const Center(child: Text('No participation data'))
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  itemCount: participants.length,
                  itemBuilder: (context, i) => PremiumGlass(
                    margin: const EdgeInsets.only(bottom: 6),
                    padding: const EdgeInsets.all(10),
                    child: Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor:
                              theme.colorScheme.primaryContainer,
                          child: Text(
                              participants[i].userName.isNotEmpty
                                  ? participants[i].userName[0].toUpperCase()
                                  : '?',
                              style: TextStyle(
                                  fontSize: 12,
                                  color: theme.colorScheme.primary)),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(participants[i].userName,
                                  style: const TextStyle(
                                      fontWeight: FontWeight.w600,
                                      fontSize: 13)),
                              Text(participants[i].projectTitle,
                                  style: TextStyle(
                                      fontSize: 11,
                                      color: theme.colorScheme
                                          .onSurfaceVariant)),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: participants[i]
                                .status.color
                                .withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Text(
                            participants[i].status.label,
                            style: TextStyle(
                                fontSize: 8,
                                fontWeight: FontWeight.w700,
                                color: participants[i].status.color),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
        ),
      ],
    );
  }
}
