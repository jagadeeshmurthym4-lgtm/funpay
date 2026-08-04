import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/cpx_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

/// Admin tab for the CPX Research offer wall.
///
/// Lets admins toggle the wall on/off and edit the `appSecureHash` (used for
/// the offer wall *entry link* `secure_hash` param) without touching Firestore
/// directly. The postback verification secret is deliberately NOT editable
/// here — it lives server-side only (CPX_SECRET on the backend).
class AdminCpxTab extends StatefulWidget {
  const AdminCpxTab({super.key});

  @override
  State<AdminCpxTab> createState() => _AdminCpxTabState();
}

class _AdminCpxTabState extends State<AdminCpxTab> {
  bool _initialized = false;
  bool _hashSeeded = false;
  bool _savingHash = false;

  final _hashController = TextEditingController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (!_initialized) {
      // Fresh fetch so the tab always shows the live config.
      context.read<CpxProvider>().loadConfig();
      _initialized = true;
    }
  }

  @override
  void dispose() {
    _hashController.dispose();
    super.dispose();
  }

  Future<void> _saveHash() async {
    final prov = context.read<CpxProvider>();
    final config = prov.config ?? CpxConfig.fallback;

    setState(() => _savingHash = true);
    final hash = _hashController.text.trim();
    final ok = await prov.saveConfig(config.copyWith(appSecureHash: hash));
    if (!mounted) return;
    setState(() => _savingHash = false);
    _showSnack(ok ? 'Secure hash saved' : prov.errorMessage ?? 'Failed to save — check admin access');
  }

  Future<void> _toggleEnabled(bool value) async {
    final prov = context.read<CpxProvider>();
    final config = prov.config ?? CpxConfig.fallback;
    final ok = await prov.saveConfig(config.copyWith(enabled: value));
    if (!mounted) return;
    _showSnack(
      ok
          ? (value ? 'Surveys offer wall is now LIVE' : 'Surveys offer wall is now PAUSED')
          : prov.errorMessage ?? 'Failed to update — check admin access',
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        duration: const Duration(seconds: 2),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final prov = context.watch<CpxProvider>();
    final config = prov.config;

    // Seed the hash field once the config arrives.
    if (!_hashSeeded && config != null) {
      _hashSeeded = true;
      _hashController.text = config.appSecureHash;
    }

    if (prov.isLoading && config == null) {
      return const Center(child: PremiumLoader());
    }

    final cfg = config ?? CpxConfig.fallback;
    final enabled = cfg.enabled;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // ── Status header ──────────────────────────────────
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: enabled
                        ? [const Color(0xFF22C55E), const Color(0xFF06B6D4)]
                        : [Colors.grey, theme.colorScheme.onSurfaceVariant],
                  ),
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: (enabled ? const Color(0xFF22C55E) : Colors.grey)
                          .withValues(alpha: 0.3),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Icon(
                  enabled ? Icons.rocket_launch_outlined : Icons.pause_circle_outline,
                  color: Colors.white,
                  size: 22,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('CPX Research Surveys',
                        style: theme.textTheme.titleMedium
                            ?.copyWith(fontWeight: FontWeight.bold)),
                    Text(
                      enabled
                          ? 'Offer wall is live — users can earn from surveys'
                          : 'Offer wall is paused — hidden from the Rewards hub',
                      style: theme.textTheme.bodySmall
                          ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: (enabled ? const Color(0xFF22C55E) : const Color(0xFFF59E0B))
                      .withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  enabled ? 'LIVE' : 'PAUSED',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w800,
                    letterSpacing: 0.8,
                    color: enabled ? const Color(0xFF22C55E) : const Color(0xFFF59E0B),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Enable / Disable toggle ────────────────────────
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.toggle_on_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('Wall Availability',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 8),
              SwitchListTile(
                title: const Text('Enable Surveys Offer Wall'),
                subtitle: const Text('Controls the Surveys card in the Rewards hub and the wall itself'),
                value: enabled,
                onChanged: (v) => _toggleEnabled(v),
                contentPadding: EdgeInsets.zero,
                secondary: Icon(
                  enabled ? Icons.check_circle_outline : Icons.visibility_off_outlined,
                  color: enabled ? const Color(0xFF22C55E) : theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── App Secure Hash ────────────────────────────────
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.vpn_key_outlined, color: theme.colorScheme.primary, size: 20),
                  const SizedBox(width: 8),
                  Text('App Secure Hash (entry link)',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                'Appended to the offer wall URL as secure_hash=md5("{user_id}-{hash}"). '
                'Optional — leave blank to send no hash.',
                style: theme.textTheme.bodySmall
                    ?.copyWith(color: theme.colorScheme.onSurfaceVariant),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _hashController,
                decoration: InputDecoration(
                  hintText: 'e.g. 4f8a2b1c...',
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  isDense: true,
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                  prefixIcon: const Icon(Icons.key_rounded, size: 18),
                ),
                onSubmitted: (_) => _savingHash ? null : _saveHash(),
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _hashController.text.isEmpty
                          ? null
                          : () {
                              Clipboard.setData(ClipboardData(text: _hashController.text.trim()));
                              _showSnack('Hash copied to clipboard');
                            },
                      icon: const Icon(Icons.copy_rounded, size: 16),
                      label: const Text('Copy'),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: _savingHash ? null : _saveHash,
                      icon: _savingHash
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save_outlined, size: 16),
                      label: Text(_savingHash ? 'Saving...' : 'Save Hash'),
                      style: FilledButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),

        // ── Info & integration ─────────────────────────────
        PremiumGlass(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.info_outline_rounded, color: const Color(0xFF06B6D4), size: 20),
                  const SizedBox(width: 8),
                  Text('Integration Info',
                      style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold)),
                ],
              ),
              const SizedBox(height: 12),
              _InfoRow(theme: theme, label: 'App ID', value: cfg.appId),
              const SizedBox(height: 6),
              _InfoRow(theme: theme, label: 'Wall URL', value: AppConstants.cpxOfferWallBaseUrl),
              const SizedBox(height: 6),
              _InfoRow(
                theme: theme,
                label: 'Postback URL',
                value: AppConstants.cpxPostbackUrl,
                monospace: true,
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: const Color(0xFFF59E0B).withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: const Color(0xFFF59E0B).withValues(alpha: 0.25)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.lock_outline_rounded, size: 16, color: Color(0xFFF59E0B)),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'The postback verification secret is server-side only (CPX_SECRET env var on '
                        'the backend) — it is never stored in Firestore and cannot be edited here.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          height: 1.4,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final ThemeData theme;
  final String label;
  final String value;
  final bool monospace;

  const _InfoRow({
    required this.theme,
    required this.label,
    required this.value,
    this.monospace = false,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 96,
          child: Text(label,
              style: theme.textTheme.bodySmall
                  ?.copyWith(color: theme.colorScheme.onSurfaceVariant)),
        ),
        Expanded(
          child: SelectableText(
            value,
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.w500,
              fontFamily: monospace ? 'monospace' : null,
            ),
          ),
        ),
      ],
    );
  }
}
