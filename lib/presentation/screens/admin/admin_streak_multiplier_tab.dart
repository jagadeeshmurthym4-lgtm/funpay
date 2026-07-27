import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/domain/entities/streak_multiplier_entity.dart';
import 'package:cashspark/presentation/providers/streak_multiplier_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:uuid/uuid.dart';

class AdminStreakMultiplierTab extends StatefulWidget {
  const AdminStreakMultiplierTab({super.key});

  @override
  State<AdminStreakMultiplierTab> createState() => _AdminStreakMultiplierTabState();
}

class _AdminStreakMultiplierTabState extends State<AdminStreakMultiplierTab> {
  bool _initialized = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      context.read<StreakMultiplierProvider>().loadConfig();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<StreakMultiplierProvider>();

    if (prov.isLoading && prov.config == null) {
      return const Center(child: PremiumLoader());
    }

    final config = prov.config;
    if (config == null) {
      return const Center(child: Text('No configuration found'));
    }

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Enable/Disable Toggle
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.trending_up_rounded, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Streak Multiplier Settings',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text('Enable Streak Multiplier'),
                subtitle: const Text('Apply multipliers to daily check-in rewards based on streak length'),
                value: config.isEnabled,
                onChanged: (v) => _updateConfig(config.copyWith(isEnabled: v)),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Enable Streak Recovery'),
                subtitle: const Text('Allow users to recover a missed day by watching a rewarded ad'),
                value: config.streakRecoveryEnabled,
                onChanged: (v) => _updateConfig(config.copyWith(streakRecoveryEnabled: v)),
                contentPadding: EdgeInsets.zero,
              ),
              const Divider(),
              SwitchListTile(
                title: const Text('Streak Recovery Uses Ad'),
                subtitle: const Text('Users must watch a rewarded ad to recover their streak'),
                value: config.streakRecoveryUsesAd,
                onChanged: (v) => _updateConfig(config.copyWith(streakRecoveryUsesAd: v)),
                contentPadding: EdgeInsets.zero,
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Streak Milestones
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.emoji_events_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text('Milestone Multipliers',
                        style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                  ),
                  FilledButton.tonalIcon(
                    onPressed: () => _showAddMilestoneDialog(context),
                    icon: const Icon(Icons.add, size: 16),
                    label: const Text('Add'),
                    style: FilledButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      textStyle: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (config.milestones.isEmpty)
                Text('No milestones configured',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant))
              else
                ...config.milestones.map((m) => _buildMilestoneTile(theme, m, config)),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // Preview Card
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.preview_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Multiplier Preview',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _buildPreviewRow(theme, 1, config),
              _buildPreviewRow(theme, 7, config),
              _buildPreviewRow(theme, 15, config),
              _buildPreviewRow(theme, 30, config),
              _buildPreviewRow(theme, 60, config),
              _buildPreviewRow(theme, 90, config),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildMilestoneTile(ThemeData theme, StreakMilestoneEntity m, StreakMultiplierConfigEntity config) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: PremiumGlass(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: m.isActive
                    ? theme.colorScheme.primaryContainer
                    : theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Center(
                child: Text('${m.targetStreakDays}d',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: m.isActive ? theme.colorScheme.primary : Colors.grey,
                    )),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    m.label.isNotEmpty ? m.label : '${m.targetStreakDays}-Day Streak',
                    style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.w600),
                  ),
                  Text(
                    '${m.targetStreakDays} days → ${m.multiplier}x multiplier',
                    style: theme.textTheme.bodySmall
                        ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                  ),
                ],
              ),
            ),
            Column(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: m.isActive ? Colors.green.withValues(alpha: 0.1) : Colors.grey.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    m.isActive ? 'Active' : 'Inactive',
                    style: TextStyle(
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                      color: m.isActive ? Colors.green : Colors.grey,
                    ),
                  ),
                ),
              ],
            ),
            PopupMenuButton<String>(
              onSelected: (value) {
                if (value == 'edit') {
                  _showEditMilestoneDialog(context, m, config);
                } else if (value == 'toggle') {
                  final updated = config.copyWith(
                    milestones: config.milestones.map((mm) {
                      if (mm.id == m.id) return mm.copyWith(isActive: !mm.isActive);
                      return mm;
                    }).toList(),
                  );
                  _updateConfig(updated);
                } else if (value == 'delete') {
                  final updated = config.copyWith(
                    milestones: config.milestones.where((mm) => mm.id != m.id).toList(),
                  );
                  _updateConfig(updated);
                }
              },
              itemBuilder: (_) => [
                const PopupMenuItem(value: 'edit', child: Text('Edit')),
                PopupMenuItem(
                  value: 'toggle',
                  child: Text(m.isActive ? 'Disable' : 'Enable'),
                ),
                const PopupMenuItem(
                  value: 'delete',
                  child: Text('Delete', style: TextStyle(color: Colors.red)),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPreviewRow(ThemeData theme, int streak, StreakMultiplierConfigEntity config) {
    final mult = _getMultiplier(streak, config);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          SizedBox(
            width: 60,
            child: Text('$streak days', style: theme.textTheme.bodySmall),
          ),
          Expanded(
            child: LinearProgressIndicator(
              value: mult / 2.0,
              backgroundColor: theme.colorScheme.surfaceContainerHighest,
              valueColor: AlwaysStoppedAnimation<Color>(
                mult > 1.5 ? Colors.green : mult > 1.2 ? Colors.amber : theme.colorScheme.primary,
              ),
              minHeight: 6,
              borderRadius: BorderRadius.circular(3),
            ),
          ),
          const SizedBox(width: 12),
          Text('${mult}x',
              style: theme.textTheme.bodySmall
                  ?.copyWith(fontWeight: FontWeight.bold, color: mult > 1.0 ? Colors.green : null)),
        ],
      ),
    );
  }

  double _getMultiplier(int streak, StreakMultiplierConfigEntity config) {
    if (!config.isEnabled) return 1.0;
    double mult = 1.0;
    final sorted = [...config.milestones]..sort((a, b) => a.targetStreakDays.compareTo(b.targetStreakDays));
    for (final m in sorted) {
      if (m.isActive && streak >= m.targetStreakDays) mult = m.multiplier;
    }
    return mult;
  }

  void _updateConfig(StreakMultiplierConfigEntity config) {
    context.read<StreakMultiplierProvider>().saveConfig(config);
  }

  void _showAddMilestoneDialog(BuildContext context) {
    _showMilestoneDialog(context, null, null);
  }

  void _showEditMilestoneDialog(BuildContext context, StreakMilestoneEntity m, StreakMultiplierConfigEntity config) {
    _showMilestoneDialog(context, m, config);
  }

  void _showMilestoneDialog(BuildContext context, StreakMilestoneEntity? existing, StreakMultiplierConfigEntity? config) {
    final theme = Theme.of(context);
    final daysCtrl = TextEditingController(text: existing?.targetStreakDays.toString() ?? '');
    final multCtrl = TextEditingController(text: existing?.multiplier.toStringAsFixed(1) ?? '');
    final labelCtrl = TextEditingController(text: existing?.label ?? '');
    bool isActive = existing?.isActive ?? true;

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) => Dialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          child: PremiumCard(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  existing == null ? 'Add Milestone' : 'Edit Milestone',
                  style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: daysCtrl,
                  decoration: const InputDecoration(labelText: 'Target Streak Days', hintText: '7'),
                  keyboardType: TextInputType.number,
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: multCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Multiplier (e.g., 1.2)',
                    hintText: '1.2',
                    helperText: 'Base reward × multiplier',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(decimal: true),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: labelCtrl,
                  decoration: const InputDecoration(labelText: 'Label', hintText: '7-Day Streak'),
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
                        onPressed: () {
                          final days = int.tryParse(daysCtrl.text);
                          final mult = double.tryParse(multCtrl.text);
                          if (days == null || mult == null || days <= 0 || mult <= 0) {
                            ScaffoldMessenger.of(ctx).showSnackBar(
                              const SnackBar(content: Text('Invalid values')),
                            );
                            return;
                          }

                          final milestone = StreakMilestoneEntity(
                            id: existing?.id ?? const Uuid().v4(),
                            targetStreakDays: days,
                            multiplier: mult,
                            label: labelCtrl.text.trim(),
                            isActive: isActive,
                          );

                          final currentConfig = this.config;
                          if (currentConfig == null) return;

                          List<StreakMilestoneEntity> newMilestones;
                          if (existing != null) {
                            newMilestones = currentConfig.milestones.map((m) {
                              if (m.id == existing.id) return milestone;
                              return m;
                            }).toList();
                          } else {
                            newMilestones = [...currentConfig.milestones, milestone];
                          }

                          _updateConfig(currentConfig.copyWith(milestones: newMilestones));
                          Navigator.pop(ctx);
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
    );
  }

  StreakMultiplierConfigEntity? get config {
    return context.read<StreakMultiplierProvider>().config;
  }
}
