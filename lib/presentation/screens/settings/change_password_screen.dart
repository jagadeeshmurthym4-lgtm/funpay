import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class ChangePasswordScreen extends StatefulWidget {
  const ChangePasswordScreen({super.key});

  @override
  State<ChangePasswordScreen> createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  final _formKey = GlobalKey<FormState>();
  final _currentPwController = TextEditingController();
  final _newPwController = TextEditingController();
  final _confirmPwController = TextEditingController();
  bool _showCurrent = false;
  bool _showNew = false;
  bool _showConfirm = false;

  @override
  void dispose() {
    _currentPwController.dispose();
    _newPwController.dispose();
    _confirmPwController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: PremiumAppBar(title: 'Change Password', onBack: () => Navigator.pop(context)),
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
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Form(
                key: _formKey,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Header
                    PremiumGlass(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        children: [
                          Container(
                            width: 64, height: 64,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: [AppTheme.accentPurple, AppTheme.accentBlue],
                              ),
                            ),
                            child: const Icon(Icons.lock_outline_rounded, size: 28, color: Colors.white),
                          ),
                          const SizedBox(height: 16),
                          Text('Update your password',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold)),
                          const SizedBox(height: 8),
                          Text('Choose a strong password with at least ${AppConstants.minPasswordLength} characters',
                              textAlign: TextAlign.center,
                              style: TextStyle(fontSize: 13,
                                  color: isDark ? AppTheme.textMuted : const Color(0xFF64748B))),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Current password
                    Text('Current Password', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    PremiumGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 14,
                      child: TextFormField(
                        controller: _currentPwController,
                        obscureText: !_showCurrent,
                        decoration: InputDecoration(
                          hintText: 'Enter your current password',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_showCurrent ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _showCurrent = !_showCurrent),
                          ),
                        ),
                        validator: (v) => (v == null || v.isEmpty) ? 'Required' : null,
                      ),
                    ),
                    const SizedBox(height: 20),

                    // New password
                    Text('New Password', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    PremiumGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 14,
                      child: TextFormField(
                        controller: _newPwController,
                        obscureText: !_showNew,
                        decoration: InputDecoration(
                          hintText: 'Enter new password',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_showNew ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _showNew = !_showNew),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v.length < AppConstants.minPasswordLength) {
                            return 'Min ${AppConstants.minPasswordLength} characters';
                          }
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 12),

                    // Password strength indicator
                    PremiumGlass(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        children: [
                          Icon(_passwordStrengthIcon, size: 18, color: _passwordStrengthColor),
                          const SizedBox(width: 8),
                          Text(_passwordStrengthLabel,
                              style: TextStyle(fontSize: 12, color: _passwordStrengthColor)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),

                    // Confirm password
                    Text('Confirm New Password', style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w600)),
                    const SizedBox(height: 8),
                    PremiumGlass(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      borderRadius: 14,
                      child: TextFormField(
                        controller: _confirmPwController,
                        obscureText: !_showConfirm,
                        decoration: InputDecoration(
                          hintText: 'Re-enter new password',
                          border: InputBorder.none,
                          suffixIcon: IconButton(
                            icon: Icon(_showConfirm ? Icons.visibility_off : Icons.visibility, size: 20),
                            onPressed: () => setState(() => _showConfirm = !_showConfirm),
                          ),
                        ),
                        validator: (v) {
                          if (v == null || v.isEmpty) return 'Required';
                          if (v != _newPwController.text) return 'Passwords do not match';
                          return null;
                        },
                      ),
                    ),
                    const SizedBox(height: 28),

                    // Submit
                    GradientButton(
                      onPressed: auth.isLoading ? null : () => _changePassword(context, auth),
                      label: auth.isLoading ? 'Changing...' : 'Change Password',
                      icon: auth.isLoading ? Icons.hourglass_top : Icons.lock_outline_rounded,
                      isLoading: auth.isLoading,
                    ),

                    if (auth.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(top: 12),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: theme.colorScheme.error.withValues(alpha: 0.1),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline, size: 18, color: theme.colorScheme.error),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Text(auth.errorMessage!,
                                    style: TextStyle(fontSize: 13, color: theme.colorScheme.error)),
                              ),
                            ],
                          ),
                        ),
                      ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  IconData get _passwordStrengthIcon {
    final pw = _newPwController.text;
    if (pw.length < AppConstants.minPasswordLength) return Icons.info_outline;
    if (pw.length < 8) return Icons.warning_amber_rounded;
    return Icons.check_circle_outline;
  }

  Color get _passwordStrengthColor {
    final pw = _newPwController.text;
    if (pw.isEmpty) return AppTheme.textMuted;
    if (pw.length < AppConstants.minPasswordLength) return AppTheme.accentOrange;
    if (pw.length < 8) return Colors.amber;
    return AppTheme.accentGreen;
  }

  String get _passwordStrengthLabel {
    final pw = _newPwController.text;
    if (pw.isEmpty) return 'Enter a new password';
    if (pw.length < AppConstants.minPasswordLength) return 'Too short (min ${AppConstants.minPasswordLength})';
    if (pw.length < 8) return 'Fair — could be stronger';
    return 'Strong password!';
  }

  Future<void> _changePassword(BuildContext context, AuthProvider auth) async {
    if (!_formKey.currentState!.validate()) return;

    // Capture context-dependent references before async gap
    final messenger = ScaffoldMessenger.of(context);
    final navigator = Navigator.of(context);

    try {
      await auth.changePassword(
        currentPassword: _currentPwController.text,
        newPassword: _newPwController.text,
      );
      if (mounted) {
        messenger.showSnackBar(
          const SnackBar(content: Text('Password changed successfully!'), behavior: SnackBarBehavior.floating),
        );
        navigator.pop();
      }
    } catch (_) {
      // Error is shown via auth.errorMessage in the UI
    }
  }
}
