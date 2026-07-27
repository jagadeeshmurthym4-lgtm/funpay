import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/domain/entities/affiliate_project_entity.dart';
import 'package:cashspark/presentation/providers/affiliate_project_provider.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/screens/projects/submit_proof_screen.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

class AffiliateProjectDetailScreen extends StatefulWidget {
  final AffiliateProjectEntity project;

  const AffiliateProjectDetailScreen({super.key, required this.project});

  @override
  State<AffiliateProjectDetailScreen> createState() =>
      _AffiliateProjectDetailScreenState();
}

class _AffiliateProjectDetailScreenState
    extends State<AffiliateProjectDetailScreen> {
  ProjectParticipationEntity? _participation;
  bool _isChecking = true;
  bool _listenerAdded = false;
  bool _isStarting = false;

  // Track whether we just applied (to show success screen)
  bool _showAppliedSuccess = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _subscribeToParticipation();
    });
  }

  @override
  void dispose() {
    if (_listenerAdded) {
      try {
        context
            .read<AffiliateProjectProvider>()
            .removeListener(_onParticipationChanged);
      } catch (_) {}
    }
    super.dispose();
  }

  void _subscribeToParticipation() {
    final provider = context.read<AffiliateProjectProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? '';
    if (userId.isNotEmpty) {
      provider.subscribeToUserParticipations(userId);
      _checkParticipation();
      provider.addListener(_onParticipationChanged);
      _listenerAdded = true;
    } else {
      if (mounted) setState(() => _isChecking = false);
    }
  }

  void _onParticipationChanged() {
    if (!mounted) return;
    final provider = context.read<AffiliateProjectProvider>();
    final updated = provider.participations
        .where((p) => p.projectId == widget.project.projectId)
        .toList();
    if (updated.isNotEmpty) {
      setState(() {
        _participation = updated.first;
        _isChecking = false;
      });
    } else if (_participation != null && updated.isEmpty) {
      setState(() {
        _participation = null;
        _isChecking = false;
      });
    }
  }

  Future<void> _checkParticipation() async {
    final provider = context.read<AffiliateProjectProvider>();
    final authProvider = context.read<AuthProvider>();
    final userId = authProvider.user?.uid ?? '';
    if (userId.isNotEmpty) {
      final participation =
          await provider.checkParticipation(userId, widget.project.projectId);
      if (mounted) {
        setState(() {
          _participation = participation;
          _isChecking = false;
        });
      }
    } else {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _startProject() async {
    final provider = context.read<AffiliateProjectProvider>();
    final authProvider = context.read<AuthProvider>();
    final user = authProvider.user;
    if (user == null) return;

    // For Task projects, skip the affiliate link validation
    if (widget.project.isAffiliateOffer && widget.project.affiliateTrackingLink.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Affiliate link not configured.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    // Capture needed references before async gap
    final messenger = ScaffoldMessenger.of(context);

    // Disable button immediately — prevent double-taps
    setState(() => _isStarting = true);

    // Wait for the backend response before updating UI
    final success = await provider.startProject(
      projectId: widget.project.projectId,
      projectTitle: widget.project.title,
      userId: user.uid,
      userName: user.fullName,
      rewardAmount: widget.project.rewardAmount,
    );

    if (mounted) {
      // Re-check participation to sync UI with the actual backend state
      await _checkParticipation();

      // _checkParticipation() above already set _participation from the backend.
      // If it exists, treat as success regardless of the provider's return value
      if (_participation != null) {
        if (!success) {
          debugPrint('_startProject: Participation exists despite error — treating as success');
        }

        // For Task projects, navigate directly to Submit Proof screen
        if (widget.project.isTask) {
          setState(() => _isStarting = false);
          _navigateToSubmitProof();
          return;
        }

        // For Affiliate Offer projects, show the success/complete screen
        setState(() {
          _isStarting = false;
          _showAppliedSuccess = true;
        });
      } else if (success) {
        // Provider says success but no participation found
        if (widget.project.isTask) {
          setState(() => _isStarting = false);
          _navigateToSubmitProof();
          return;
        }
        setState(() {
          _isStarting = false;
          _showAppliedSuccess = true;
        });
      } else {
        // Genuine failure — no participation was created
        setState(() => _isStarting = false);
        final errorMsg = provider.errorMessage ?? 'Failed to start project';
        messenger.showSnackBar(
          SnackBar(
            content: Text(errorMsg),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  /// Opens the affiliate tracking link in the device browser (for Affiliate Offers)
  /// or navigates to the submit proof screen (for Tasks).
  /// Validates the URL before opening for Affiliate Offers.
  Future<void> _openTrackingLink() async {
    // For Task projects, navigate to submit proof screen instead
    if (widget.project.isTask) {
      _navigateToSubmitProof();
      return;
    }

    final link = widget.project.affiliateTrackingLink;
    if (link.isEmpty) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Affiliate link not configured.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    final uri = Uri.tryParse(link);
    if (uri == null || !uri.hasScheme || !uri.hasAuthority) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Invalid affiliate link.'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
      return;
    }

    try {
      final canLaunch = await canLaunchUrl(uri);
      if (canLaunch) {
        await launchUrl(uri, mode: LaunchMode.externalApplication);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('Could not open the link.'),
              behavior: SnackBarBehavior.floating,
              backgroundColor: Colors.red,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to open link: $e'),
            behavior: SnackBarBehavior.floating,
            backgroundColor: Colors.red,
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    }
  }

  Future<void> _navigateToSubmitProof() async {
    if (_participation == null) return;

    // If rejected, reset participation before navigating to submit proof
    if (_participation!.status == ProjectStatus.rejected) {
      final provider = context.read<AffiliateProjectProvider>();
      await provider.resubmitParticipation(_participation!.participationId);
      await _checkParticipation();
    }

    if (!mounted) return;
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => SubmitProofScreen(
          participation: _participation!,
          project: widget.project,
        ),
      ),
    ).then((_) {
      _checkParticipation();
    });
  }

  bool _canShowCompleteNow() {
    if (_participation == null) return false;
    final status = _participation!.status;
    return status == ProjectStatus.applied ||
        status == ProjectStatus.inProgress ||
        status == ProjectStatus.rejected;
  }

  bool _canShowSubmitProof() {
    if (_participation == null) return false;
    // For Task projects, the primary button already handles submission,
    // so we don't need a separate Submit Proof button.
    if (widget.project.isTask) return false;
    final status = _participation!.status;
    return status == ProjectStatus.inProgress ||
        status == ProjectStatus.applied ||
        status == ProjectStatus.rejected;
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final project = widget.project;
    final theme = Theme.of(context);

    // If we just applied, show the success screen
    if (_showAppliedSuccess && _participation != null) {
      return _buildAppliedSuccessScreen(isDark, theme);
    }

    // Determine the current action button state
    String buttonLabel;
    bool buttonEnabled = true;
    VoidCallback? buttonAction;

    if (_isChecking) {
      buttonLabel = 'LOADING...';
      buttonEnabled = false;
      buttonAction = null;
    } else if (_participation == null) {
      buttonLabel = 'EARN ${project.rewardText}';
      buttonAction = _startProject;
    } else {
      final status = _participation!.status;
      final isTask = project.isTask;
      switch (status) {
        case ProjectStatus.applied:
          buttonLabel = isTask ? 'SUBMIT PROOF' : 'COMPLETE NOW';
          buttonAction = isTask ? _navigateToSubmitProof : _openTrackingLink;
          break;
        case ProjectStatus.inProgress:
          buttonLabel = isTask ? 'SUBMIT PROOF' : 'COMPLETE NOW';
          buttonAction = isTask ? _navigateToSubmitProof : _openTrackingLink;
          break;
        case ProjectStatus.submitted:
        case ProjectStatus.pendingReview:
        case ProjectStatus.underReview:
          buttonLabel = 'UNDER REVIEW';
          buttonEnabled = false;
          buttonAction = null;
          break;
        case ProjectStatus.approved:
          buttonLabel = 'APPROVED ✓';
          buttonEnabled = false;
          buttonAction = null;
          break;
        case ProjectStatus.completed:
          buttonLabel = 'COMPLETED ✓';
          buttonEnabled = false;
          buttonAction = null;
          break;
        case ProjectStatus.rejected:
          buttonLabel = 'TRY AGAIN';
          buttonAction = isTask ? _navigateToSubmitProof : _openTrackingLink;
          break;
        default:
          buttonLabel = 'EARN ${project.rewardText}';
          buttonAction = _startProject;
      }
    }

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // Banner image
          SliverAppBar(
            expandedHeight: 220,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              background: project.bannerImage.isNotEmpty
                  ? Image.network(
                      project.bannerImage,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) =>
                          _buildDefaultBanner(project, isDark),
                    )
                  : _buildDefaultBanner(project, isDark),
            ),
            leading: IconButton(
              icon: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  shape: BoxShape.circle,
                ),
                child: const Icon(Icons.arrow_back, color: Colors.white),
              ),
              onPressed: () => Navigator.pop(context),
            ),
            actions: [
              if (project.featured)
                Container(
                  margin: const EdgeInsets.only(right: 12),
                  padding:
                      const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(Icons.star, size: 14, color: Colors.white),
                      SizedBox(width: 4),
                      Text('Featured',
                          style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              color: Colors.white)),
                    ],
                  ),
                ),
            ],
          ),

          // Content
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Logo + Title row
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      if (project.logoImage.isNotEmpty)
                        Container(
                          width: 56,
                          height: 56,
                          margin: const EdgeInsets.only(right: 12),
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: isDark
                                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                                  : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
                            ),
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(12),
                            child: Image.network(
                              project.logoImage,
                              width: 56,
                              height: 56,
                              fit: BoxFit.cover,
                              errorBuilder: (_, __, ___) => Container(
                                decoration: BoxDecoration(
                                  color: _categoryColor(project.category)
                                      .withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Icon(
                                  _categoryIcon(project.category),
                                  size: 28,
                                  color: _categoryColor(project.category),
                                ),
                              ),
                            ),
                          ),
                        ),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              project.title,
                              style: theme.textTheme.headlineSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                              maxLines: 2,
                              overflow: TextOverflow.ellipsis,
                            ),
                            if (project.subtitle.isNotEmpty)
                              Padding(
                                padding: const EdgeInsets.only(top: 4),
                                child: Text(
                                  project.subtitle,
                                  style: TextStyle(
                                    fontSize: 15,
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Stats row
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: isDark
                          ? const Color(0xFF0F2740)
                          : const Color(0xFFF1F5F9),
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Row(
                      children: [
                        _statItem(
                            Icons.monetization_on_outlined,
                            'Reward',
                            project.rewardText,
                            const Color(0xFF4ADE80),
                            isDark),
                        Container(
                            height: 40,
                            width: 1,
                            color: isDark
                                ? AppTheme.borderColor
                                : const Color(0xFFCBD5E1)),
                        _statItem(
                            Icons.timer_outlined,
                            'Est. Time',
                            project.completionTimeText,
                            const Color(0xFF3B82F6),
                            isDark),
                        Container(
                            height: 40,
                            width: 1,
                            color: isDark
                                ? AppTheme.borderColor
                                : const Color(0xFFCBD5E1)),
                        _statItem(
                            Icons.military_tech_outlined,
                            'Difficulty',
                            project.difficultyLabel,
                            project.difficultyColor,
                            isDark),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Status tracker
                  if (_participation != null) ...[
                    _buildStatusTracker(_participation!.status, isDark),
                    const SizedBox(height: 16),
                  ],

                  // Project Type, Category & badges
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Flexible(
                        child: Wrap(
                          spacing: 8,
                          runSpacing: 6,
                          crossAxisAlignment: WrapCrossAlignment.center,
                          children: [
                            // Project Type badge (Task vs Affiliate)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 10, vertical: 5),
                              decoration: BoxDecoration(
                                color: project.isTask
                                    ? const Color(0xFF8B5CF6).withValues(alpha: 0.15)
                                    : const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    project.isTask
                                        ? Icons.task_alt_outlined
                                        : Icons.link_outlined,
                                    size: 14,
                                    color: project.isTask
                                        ? const Color(0xFF8B5CF6)
                                        : const Color(0xFF3B82F6),
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    project.isTask ? 'Task' : 'Affiliate Offer',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: project.isTask
                                          ? const Color(0xFF8B5CF6)
                                          : const Color(0xFF3B82F6),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: _categoryColor(project.category)
                                    .withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(10),
                              ),
                              child: Text(
                                project.category,
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: _categoryColor(project.category),
                                ),
                              ),
                            ),
                            if (project.isNew)
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 12, vertical: 6),
                                decoration: BoxDecoration(
                                  color: const Color(0xFF3B82F6).withValues(alpha: 0.15),
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: const Text(
                                  'NEW',
                                  style: TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFF3B82F6),
                                  ),
                                ),
                              ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      Text(
                        '${project.currentParticipants} participants',
                        style: TextStyle(
                          fontSize: 12,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Description
                  Text(
                    'Description',
                    style: theme.textTheme.titleMedium
                        ?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    project.description,
                    style: TextStyle(
                      fontSize: 14,
                      height: 1.6,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Instructions
                  if (project.instructions.isNotEmpty) ...[
                    Text(
                      'Instructions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 12),
                    ...project.instructions.asMap().entries.map((entry) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 24,
                              height: 24,
                              decoration: BoxDecoration(
                                color: const Color(0xFF4ADE80).withValues(alpha: 0.15),
                                shape: BoxShape.circle,
                              ),
                              child: Center(
                                child: Text(
                                  '${entry.key + 1}',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: Color(0xFF4ADE80),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Text(
                                entry.value,
                                style: TextStyle(
                                  fontSize: 14,
                                  height: 1.5,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    }),
                    const SizedBox(height: 24),
                  ],

                  // Terms & Conditions
                  if (project.termsAndConditions.isNotEmpty) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
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
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Icon(Icons.description_outlined,
                                  size: 18,
                                  color: theme.colorScheme.primary),
                              const SizedBox(width: 8),
                              Text(
                                'Terms & Conditions',
                                style: theme.textTheme.titleSmall
                                    ?.copyWith(fontWeight: FontWeight.w600),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Text(
                            project.termsAndConditions,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Show rejection reason if rejected
                  if (_participation != null &&
                      _participation!.status == ProjectStatus.rejected &&
                      _participation!.rejectionReason != null) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: const Color(0xFFEF4444).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                            color: const Color(0xFFEF4444).withValues(alpha: 0.3)),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(Icons.cancel,
                              color: Color(0xFFEF4444), size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Text(
                                  'Submission Rejected',
                                  style: TextStyle(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w600,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'Reason: ${_participation!.rejectionReason}',
                                  style: const TextStyle(
                                    fontSize: 13,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                                const SizedBox(height: 8),
                                const Text(
                                  'Tap "TRY AGAIN" below to retry.',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: Color(0xFFEF4444),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Show approved/completed status
                  if (_participation != null &&
                      (_participation!.status == ProjectStatus.approved ||
                          _participation!.status ==
                              ProjectStatus.completed)) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFF4ADE80).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFF4ADE80).withValues(alpha: 0.3)),
                      ),
                      child: Column(
                        children: [
                          if (_participation!.status == ProjectStatus.completed)
                            const Icon(Icons.celebration_outlined,
                                color: Color(0xFF4ADE80), size: 48)
                          else
                            const Icon(Icons.check_circle,
                                color: Color(0xFF4ADE80), size: 48),
                          const SizedBox(height: 12),
                          Text(
                            _participation!.status == ProjectStatus.completed
                                ? 'Completed!'
                                : 'Approved!',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _participation!.rewardCredited
                                ? 'Reward has been credited to your wallet.'
                                : 'Reward being processed.',
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF4ADE80),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Under Review banner
                  if (_participation != null &&
                      _participation!.status == ProjectStatus.underReview) ...[
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                            color: const Color(0xFFF59E0B).withValues(alpha: 0.3)),
                      ),
                      child: const Column(
                        children: [
                          Icon(Icons.hourglass_top_rounded,
                              color: Color(0xFFF59E0B), size: 48),
                          SizedBox(height: 12),
                          Text(
                            'Under Review',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                          SizedBox(height: 4),
                          Text(
                            'Your submission is being reviewed by an admin.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              color: Color(0xFFF59E0B),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // Extra bottom padding for the fixed buttons
                  const SizedBox(height: 100),
                ],
              ),
            ),
          ),
        ],
      ),
      // Fixed bottom bar with action buttons
      bottomNavigationBar: _buildBottomBar(buttonLabel, buttonEnabled,
          buttonAction, isDark, theme),
    );
  }

  /// Builds the "Project Applied Successfully" full-screen overlay.
  Widget _buildAppliedSuccessScreen(bool isDark, ThemeData theme) {
    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF0A1929) : Colors.white,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 2),
              // Success checkmark
              Container(
                padding: const EdgeInsets.all(28),
                decoration: BoxDecoration(
                  color: const Color(0xFF22C55E).withValues(alpha: 0.15),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_circle_rounded,
                  size: 80,
                  color: Color(0xFF22C55E),
                ),
              ),
              const SizedBox(height: 28),
              const Text(
                'Project Applied\nSuccessfully!',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF22C55E),
                  height: 1.3,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Complete the task to earn ${widget.project.rewardText} reward',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 15,
                  height: 1.5,
                  color: isDark
                      ? AppTheme.textSecondary
                      : const Color(0xFF475569),
                ),
              ),
              const Spacer(flex: 1),

              // Large Complete Now / Submit Proof button
              SizedBox(
                width: double.infinity,
                height: 64,
                child: ElevatedButton.icon(
                  onPressed: widget.project.isTask
                      ? _navigateToSubmitProof
                      : _openTrackingLink,
                  icon: Icon(
                    widget.project.isTask
                        ? Icons.cloud_upload_outlined
                        : Icons.open_in_new_rounded,
                    size: 24,
                  ),
                  label: Text(
                    widget.project.isTask
                        ? 'SUBMIT PROOF'
                        : 'COMPLETE NOW',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 1.0,
                    ),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF22C55E),
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    elevation: 4,
                    shadowColor: const Color(0xFF22C55E).withValues(alpha: 0.4),
                  ),
                ),
              ),
              const SizedBox(height: 16),

              // Submit Proof button (only shown for Affiliate Offer projects)
              if (!widget.project.isTask)
                SizedBox(
                  width: double.infinity,
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _navigateToSubmitProof,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: const Text(
                      'SUBMIT PROOF',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22C55E),
                      side: const BorderSide(color: Color(0xFF22C55E), width: 2),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 12),

              // Back to projects
              TextButton(
                onPressed: () => Navigator.pop(context),
                child: Text(
                  'Back to Projects',
                  style: TextStyle(
                    fontSize: 14,
                    color: isDark
                        ? AppTheme.textMuted
                        : const Color(0xFF94A3B8),
                  ),
                ),
              ),

              const Spacer(flex: 1),
            ],
          ),
        ),
      ),
    );
  }

  /// Bottom bar with action buttons.
  Widget _buildBottomBar(String label, bool enabled, VoidCallback? onPressed,
      bool isDark, ThemeData theme) {
    final showCompleteNow = _canShowCompleteNow();
    final showSubmitProof = _canShowSubmitProof();
    final isUnderReview = _participation?.status == ProjectStatus.underReview;
    final isApproved = _participation?.status == ProjectStatus.approved ||
        _participation?.status == ProjectStatus.completed;

    // For non-action states (under review, approved, completed), show a single status button
    if (isUnderReview || isApproved || _participation == null || _isChecking) {
      Color buttonColor;
      Color? bgColor;

      if (_isChecking) {
        buttonColor = const Color(0xFF94A3B8);
      } else if (_participation == null) {
        buttonColor = const Color(0xFF22C55E);
      } else if (isUnderReview) {
        buttonColor = const Color(0xFFF59E0B);
        bgColor = const Color(0xFFF59E0B).withValues(alpha: 0.1);
      } else if (isApproved) {
        buttonColor = const Color(0xFF22C55E);
        bgColor = const Color(0xFF22C55E).withValues(alpha: 0.1);
      } else {
        buttonColor = const Color(0xFF22C55E);
      }

      return Container(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF0A1929) : Colors.white,
          border: Border(
            top: BorderSide(
              color: isDark
                  ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                  : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
            ),
          ),
        ),
        child: SafeArea(
          top: false,
          child: SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: (!_isStarting && enabled && onPressed != null)
                  ? onPressed
                  : null,
              style: ElevatedButton.styleFrom(
                backgroundColor: bgColor ?? buttonColor,
                disabledBackgroundColor:
                    bgColor ?? buttonColor.withValues(alpha: 0.5),
                foregroundColor: Colors.white,
                disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: _isStarting
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
            ),
          ),
        ),
      );
    }

    // For action states (inProgress, applied, rejected): show two buttons
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0A1929) : Colors.white,
        border: Border(
          top: BorderSide(
            color: isDark
                ? const Color(0xFF1E3A5F).withValues(alpha: 0.3)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Row(
          children: [
            // Submit Proof button (secondary)
            if (showSubmitProof)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: OutlinedButton.icon(
                    onPressed: _navigateToSubmitProof,
                    icon: const Icon(Icons.cloud_upload_outlined, size: 20),
                    label: const Text(
                      'SUBMIT PROOF',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: const Color(0xFF22C55E),
                      side: const BorderSide(
                          color: Color(0xFF22C55E), width: 1.5),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ),
            if (showSubmitProof && showCompleteNow) const SizedBox(width: 12),

            // Complete Now / Try Again / Submit Proof button (primary)
            if (showCompleteNow)
              Expanded(
                flex: showSubmitProof ? 1 : 2,
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton.icon(
                    onPressed: widget.project.isTask
                        ? _navigateToSubmitProof
                        : _openTrackingLink,
                    icon: Icon(
                      widget.project.isTask
                          ? Icons.cloud_upload_outlined
                          : (_participation?.status == ProjectStatus.rejected
                              ? Icons.refresh_rounded
                              : Icons.open_in_new_rounded),
                      size: 20,
                    ),
                    label: Text(
                      widget.project.isTask
                          ? 'SUBMIT PROOF'
                          : (_participation?.status == ProjectStatus.rejected
                              ? 'TRY AGAIN'
                              : 'COMPLETE NOW'),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 0.5,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: widget.project.isTask
                          ? const Color(0xFF22C55E)
                          : (_participation?.status ==
                                  ProjectStatus.rejected
                              ? const Color(0xFFF59E0B)
                              : const Color(0xFF22C55E)),
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                  ),
                ),
              ),

            // If neither button is shown, fallback to single button
            if (!showCompleteNow && !showSubmitProof)
              Expanded(
                child: SizedBox(
                  height: 56,
                  child: ElevatedButton(
                    onPressed: (!_isStarting && enabled && onPressed != null)
                  ? onPressed
                  : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF22C55E),
                      disabledBackgroundColor:
                          const Color(0xFF22C55E).withValues(alpha: 0.5),
                      foregroundColor: Colors.white,
                      disabledForegroundColor: Colors.white.withValues(alpha: 0.7),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 0,
                    ),
                    child: Text(
                      label,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Builds a visual status tracker showing the current progress.
  Widget _buildStatusTracker(ProjectStatus status, bool isDark) {
    final steps = [
      ('Applied', ProjectStatus.applied),
      ('In Progress', ProjectStatus.inProgress),
      ('Under Review', ProjectStatus.underReview),
      ('Completed', ProjectStatus.completed),
    ];

    int currentStep = -1;
    for (int i = 0; i < steps.length; i++) {
      if (status.index >= steps[i].$2.index) {
        currentStep = i;
      }
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF0F2740) : const Color(0xFFF1F5F9),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: List.generate(steps.length * 2 - 1, (i) {
          if (i.isOdd) {
            // Connector line
            final stepIdx = i ~/ 2;
            final isCompleted = stepIdx < currentStep;
            return Expanded(
              child: Container(
                height: 2,
                color: isCompleted
                    ? const Color(0xFF22C55E)
                    : isDark
                        ? const Color(0xFF1E3A5F)
                        : const Color(0xFFCBD5E1),
              ),
            );
          }
          // Step dot + label
          final stepIdx = i ~/ 2;
          final isCompleted = stepIdx <= currentStep;
          final isCurrent = stepIdx == currentStep;
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: isCurrent ? 14 : 10,
                height: isCurrent ? 14 : 10,
                decoration: BoxDecoration(
                  color: isCompleted
                      ? const Color(0xFF22C55E)
                      : isDark
                          ? const Color(0xFF1E3A5F)
                          : const Color(0xFFCBD5E1),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                steps[stepIdx].$1,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight:
                      isCurrent ? FontWeight.w700 : FontWeight.w500,
                  color: isCompleted
                      ? const Color(0xFF22C55E)
                      : isDark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8),
                ),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildDefaultBanner(AffiliateProjectEntity project, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _categoryColor(project.category),
            _categoryColor(project.category).withValues(alpha: 0.6),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Icon(
          _categoryIcon(project.category),
          size: 80,
          color: Colors.white.withValues(alpha: 0.3),
        ),
      ),
    );
  }

  Widget _statItem(
      IconData icon, String label, String value, Color color, bool isDark) {
    return Expanded(
      child: Column(
        children: [
          Icon(icon, size: 22, color: color),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isDark
                  ? AppTheme.textMuted
                  : const Color(0xFF94A3B8),
            ),
          ),
        ],
      ),
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
