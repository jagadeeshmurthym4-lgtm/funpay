import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/referral_level_entity.dart';
import 'package:cashspark/presentation/providers/referral_level_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AdminReferralLevelsTab extends StatefulWidget {
  const AdminReferralLevelsTab({super.key});

  @override
  State<AdminReferralLevelsTab> createState() => _AdminReferralLevelsTabState();
}

class _AdminReferralLevelsTabState extends State<AdminReferralLevelsTab> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReferralLevelProvider>().loadLevels();
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<ReferralLevelProvider>();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Expanded(
                child: Text('Referral Milestone Levels',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.bold)),
              ),
              FilledButton.tonalIcon(
                onPressed: () => _showAddEditDialog(context, null),
                icon: const Icon(Icons.add, size: 18),
                label: const Text('Add Level'),
              ),
            ],
          ),
        ),
        Expanded(
          child: prov.isLoading
              ? const Center(child: PremiumLoader())
              : prov.levels.isEmpty
                  ?                  PremiumEmptyState(
                      icon: Icons.emoji_events_outlined,
                      title: 'No Levels Configured',
                      subtitle: 'Create referral milestone levels to get started.',
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 12),
                      itemCount: prov.levels.length,
                      itemBuilder: (context, index) {
                        final level = prov.levels[index];
                        return _LevelCard(
                          level: level,
                          theme: theme,
                          onEdit: () => _showAddEditDialog(context, level),
                          onToggle: () => _toggleLevel(level),
                          onDelete: () => _deleteLevel(level),
                        );
                      },
                    ),
        ),
      ],
    );
  }

  void _toggleLevel(ReferralLevelEntity level) async {
    final messenger = ScaffoldMessenger.of(context);
    try {
      final prov = context.read<ReferralLevelProvider>();
      final success = await prov.toggleLevelActive(level);
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text(success ? 'Level toggled!' : 'Failed to toggle level')),
        );
      }
    } catch (e) {
      if (mounted) {
        messenger.showSnackBar(
          SnackBar(content: Text('Failed to toggle level: $e')),
        );
      }
    }
  }

  void _deleteLevel(ReferralLevelEntity level) async {
    final messenger = ScaffoldMessenger.of(context);
    final prov = context.read<ReferralLevelProvider>();
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Level?'),
        content: Text('Delete "${level.title}" (Level ${level.levelNumber})?'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
    if (confirmed == true) {
      if (!mounted) return;
      try {
        final success = await prov.deleteLevel(level.id);
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text(success ? 'Level deleted!' : 'Failed to delete level')),
          );
        }
      } catch (e) {
        if (mounted) {
          messenger.showSnackBar(
            SnackBar(content: Text('Delete failed: $e')),
          );
        }
      }
    }
  }

  void _showAddEditDialog(BuildContext context, ReferralLevelEntity? existing) {
    final theme = Theme.of(context);
    final titleCtrl = TextEditingController(text: existing?.title ?? '');
    final descCtrl = TextEditingController(text: existing?.description ?? '');
    final referralsCtrl = TextEditingController(
        text: existing?.requiredReferrals.toString() ?? '');
    final rewardCtrl = TextEditingController(
        text: existing?.rewardAmount.toStringAsFixed(2) ?? '');
    final iconCtrl = TextEditingController(text: existing?.badgeIcon ?? '🏆');
    final levelNumCtrl = TextEditingController(
        text: existing?.levelNumber.toString() ?? '');
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: PremiumCard(
            padding: const EdgeInsets.all(24),
            child: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(existing == null ? 'Add Milestone Level' : 'Edit Level',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 16),
                  TextField(
                    controller: levelNumCtrl,
                    decoration: const InputDecoration(labelText: 'Level Number', hintText: '1'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: titleCtrl,
                    decoration: const InputDecoration(labelText: 'Title', hintText: 'Bronze Referrer'),
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: descCtrl,
                    decoration: const InputDecoration(labelText: 'Description', hintText: 'Refer 5 friends...'),
                    maxLines: 2,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: referralsCtrl,
                    decoration: const InputDecoration(labelText: 'Required Referrals', hintText: '5'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: rewardCtrl,
                    decoration: const InputDecoration(labelText: 'Reward Amount (₹)', hintText: '10.00'),
                    keyboardType: TextInputType.number,
                  ),
                  const SizedBox(height: 12),
                  TextField(
                    controller: iconCtrl,
                    decoration: const InputDecoration(labelText: 'Badge Icon (emoji)', hintText: '🏆'),
                  ),
                  const SizedBox(height: 12),
                  SwitchListTile(
                    title: const Text('Active'),
                    value: isActive,
                    onChanged: (v) => setDialogState(() => isActive = v),
                    contentPadding: EdgeInsets.zero,
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
                      const SizedBox(width: 8),
                      Expanded(
                        child: FilledButton(
                          onPressed: () async {
                            final levelNum = int.tryParse(levelNumCtrl.text);
                            final reqRef = int.tryParse(referralsCtrl.text);
                            final reward = double.tryParse(rewardCtrl.text);
                            if (levelNum == null || reqRef == null || reward == null || titleCtrl.text.isEmpty) {
                              ScaffoldMessenger.of(ctx).showSnackBar(
                                const SnackBar(content: Text('Please fill all required fields')),
                              );
                              return;
                            }
                            final level = ReferralLevelEntity(
                              id: existing?.id ?? const Uuid().v4(),
                              levelNumber: levelNum,
                              title: titleCtrl.text.trim(),
                              description: descCtrl.text.trim(),
                              requiredReferrals: reqRef,
                              rewardAmount: reward,
                              badgeIcon: iconCtrl.text.trim(),
                              isActive: isActive,
                            );
                            final messenger = ScaffoldMessenger.of(ctx);
                            final prov = context.read<ReferralLevelProvider>();
                            final saveContext = context;
                            try {
                              final success = await prov.saveLevel(level);
                              if (ctx.mounted) Navigator.pop(ctx);
                              if (saveContext.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(
                                    content: Text(success
                                        ? (existing == null ? 'Level added!' : 'Level updated!')
                                        : 'Failed to save level'),
                                  ),
                                );
                              }
                            } catch (e) {
                              if (ctx.mounted) {
                                messenger.showSnackBar(
                                  SnackBar(content: Text('Failed: $e')),
                                );
                              }
                            }
                          },
                          child: Text(existing == null ? 'Add' : 'Update'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _LevelCard extends StatelessWidget {
  final ReferralLevelEntity level;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onToggle;
  final VoidCallback onDelete;

  const _LevelCard({
    required this.level,
    required this.theme,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    return PremiumGlass(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: level.isActive
                  ? theme.colorScheme.primaryContainer
                  : theme.colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(level.badgeIcon, style: const TextStyle(fontSize: 24)),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: level.isActive
                            ? Colors.green.withValues(alpha: 0.1)
                            : Colors.grey.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        'Lvl ${level.levelNumber}',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                          color: level.isActive ? Colors.green : Colors.grey,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(level.title,
                          style: theme.textTheme.bodyMedium
                              ?.copyWith(fontWeight: FontWeight.w600)),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  '${level.requiredReferrals} referrals • ₹${level.rewardAmount.toStringAsFixed(2)} reward',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                ),
              ],
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'edit': onEdit();
                case 'toggle': onToggle();
                case 'delete': onDelete();
              }
            },
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'edit', child: Text('Edit')),
              PopupMenuItem(
                value: 'toggle',
                child: Text(level.isActive ? 'Disable' : 'Enable'),
              ),
              const PopupMenuItem(
                value: 'delete',
                child: Text('Delete', style: TextStyle(color: Colors.red)),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
