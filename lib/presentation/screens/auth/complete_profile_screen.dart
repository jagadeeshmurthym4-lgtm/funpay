import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class CompleteProfileScreen extends StatefulWidget {
  const CompleteProfileScreen({super.key});

  @override
  State<CompleteProfileScreen> createState() => _CompleteProfileScreenState();
}

class _CompleteProfileScreenState extends State<CompleteProfileScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _referralCtrl;

  bool _isSaving = false;
  String? _referralError;
  late AnimationController _animController;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    final user = context.read<AuthProvider>().user;

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController(text: user?.email ?? '');
    _phoneCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _referralCtrl = TextEditingController();
  }

  @override
  void dispose() {
    _animController.dispose();
    _firstNameCtrl.dispose();
    _lastNameCtrl.dispose();
    _emailCtrl.dispose();
    _phoneCtrl.dispose();
    _dobCtrl.dispose();
    _referralCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1940),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: Theme.of(context).colorScheme.copyWith(
                  primary: AppTheme.accentGreen,
                ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      _dobCtrl.text = '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSaving = true);
    _referralError = null;

    try {
      final authProvider = context.read<AuthProvider>();
      await authProvider.completeProfile(
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
        referralCode: _referralCtrl.text.trim().isEmpty
            ? null
            : _referralCtrl.text.trim(),
      );

      if (mounted) {
        // Navigate to Home and clear the navigation stack
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false,
        );
      }
    } on ReferralException catch (e) {
      setState(() => _referralError = e.message);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to complete profile: ${e.toString().replaceAll('Exception: ', '')}'),
            backgroundColor: const Color(0xFFEF4444),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final screenHeight = MediaQuery.of(context).size.height;
    final keyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(20, keyboardOpen ? 8 : screenHeight * 0.05, 20, 20 + bottomInset),
          child: AnimatedBuilder(
            animation: _fadeSlide,
            builder: (context, child) {
              return Opacity(
                opacity: _fadeSlide.value,
                child: Transform.translate(
                  offset: Offset(0, 20 * (1 - _fadeSlide.value)),
                  child: child,
                ),
              );
            },
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // ─── Header ────────────────────────────────
                if (!keyboardOpen) ...[
                  const SizedBox(height: 20),
                  // Icon
                  Container(
                    width: 72,
                    height: 72,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      gradient: const LinearGradient(
                        colors: [Color(0xFF4ADE80), Color(0xFF22C55E)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF4ADE80).withValues(alpha: 0.3),
                          blurRadius: 20,
                          offset: const Offset(0, 8),
                        ),
                      ],
                    ),
                    child: const Center(
                      child: Icon(Icons.person_outline_rounded, size: 32, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Complete Your Profile',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Just a few more details to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],

                // ─── Form ──────────────────────────────────
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // First Name
                      _buildLabel(theme, 'First Name *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _firstNameCtrl,
                        hint: 'Enter your first name',
                        icon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'First name is required';
                          if (v.trim().length < 2) return 'Name must be at least 2 characters';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Last Name
                      _buildLabel(theme, 'Last Name *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _lastNameCtrl,
                        hint: 'Enter your last name',
                        icon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return 'Last name is required';
                          if (v.trim().length < 2) return 'Name must be at least 2 characters';
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),

                      // Gmail (Read-Only)
                      _buildLabel(theme, 'Gmail Address *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _emailCtrl,
                        hint: 'Auto-filled from Google',
                        icon: Icons.email_outlined,
                        readOnly: true,
                      ),
                      const SizedBox(height: 16),

                      // Phone Number
                      _buildLabel(theme, 'Phone Number'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _phoneCtrl,
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) return null; // Optional
                          final cleaned = v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                          if (cleaned.length < 10) return 'Enter a valid 10-digit phone number';
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      // Date of Birth
                      _buildLabel(theme, 'Date of Birth *'),
                      const SizedBox(height: 8),
                      GestureDetector(
                        onTap: _pickDate,
                        child: AbsorbPointer(
                          child: _buildField(
                            controller: _dobCtrl,
                            hint: 'Select your date of birth',
                            icon: Icons.cake_outlined,
                            suffixIcon: Icons.calendar_today_outlined,
                            validator: (v) {
                              if (v == null || v.trim().isEmpty) return 'Date of birth is required';
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),

                      // Referral Code (Optional)
                      _buildLabel(theme, 'Referral Code', optional: true),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _referralCtrl,
                        hint: 'Enter referral code (optional)',
                        icon: Icons.card_giftcard_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _save(),
                        errorText: _referralError,
                      ),
                      if (_referralError != null) ...[
                        const SizedBox(height: 4),
                        Padding(
                          padding: const EdgeInsets.only(left: 12),
                          child: Text(
                            _referralError!,
                            style: TextStyle(
                              fontSize: 11,
                              color: theme.colorScheme.error,
                            ),
                          ),
                        ),
                      ],

                      const SizedBox(height: 28),

                      // Submit Button
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isSaving ? null : _save,
                          icon: _isSaving
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.check_circle_outline,
                                  size: 22,
                                ),
                          label: Text(
                            _isSaving ? 'Saving...' : 'Get Started',
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: const Color(0xFF4ADE80),
                            foregroundColor: Colors.black,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(18),
                            ),
                            elevation: 4,
                            shadowColor: const Color(0xFF4ADE80).withValues(alpha: 0.4),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Info text
                      Center(
                        child: Container(
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: (isDark ? AppTheme.accentGreen : AppTheme.accentGreen).withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(
                              color: (isDark ? AppTheme.accentGreen : AppTheme.accentGreen).withValues(alpha: 0.15),
                            ),
                          ),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Icon(
                                Icons.info_outline,
                                size: 18,
                                color: isDark ? AppTheme.accentGreen : AppTheme.accentGreen,
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  'Entering a referral code will reward both you and the person who referred you with a bonus!',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isDark ? AppTheme.textSecondary : const Color(0xFF475569),
                                    height: 1.4,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(ThemeData theme, String label, {bool optional = false}) {
    return Padding(
      padding: const EdgeInsets.only(left: 4),
      child: RichText(
        text: TextSpan(
          text: label,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: FontWeight.w600,
            color: theme.brightness == Brightness.dark
                ? Colors.white
                : const Color(0xFF0F172A),
          ),
          children: optional
              ? [
                  TextSpan(
                    text: ' (Optional)',
                    style: TextStyle(
                      fontSize: 11,
                      color: theme.brightness == Brightness.dark
                          ? AppTheme.textMuted
                          : const Color(0xFF94A3B8),
                      fontWeight: FontWeight.w400,
                    ),
                  ),
                ]
              : [],
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    IconData? suffixIcon,
    bool readOnly = false,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
    String? errorText,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      readOnly: readOnly,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      onFieldSubmitted: onSubmitted,
      validator: validator,
      style: TextStyle(
        color: readOnly
            ? (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8))
            : (isDark ? Colors.white : const Color(0xFF0F172A)),
        fontSize: 15,
        fontWeight: FontWeight.w500,
      ),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: isDark ? AppTheme.textMuted.withValues(alpha: 0.6) : const Color(0xFF94A3B8).withValues(alpha: 0.7),
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
        prefixIcon: Container(
          width: 48,
          alignment: Alignment.center,
          child: Icon(
            icon,
            size: 20,
            color: controller.text.isNotEmpty && !readOnly
                ? (isDark ? AppTheme.accentGreen : AppTheme.accentGreen)
                : (isDark ? AppTheme.textMuted : const Color(0xFF94A3B8)),
          ),
        ),
        suffixIcon: suffixIcon != null
            ? Icon(
                suffixIcon,
                size: 18,
                color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
              )
            : null,
        filled: true,
        fillColor: readOnly
            ? (isDark ? AppTheme.borderColor.withValues(alpha: 0.3) : const Color(0xFFF1F5F9))
            : (isDark ? AppTheme.bgCardLight : const Color(0xFFF1F5F9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark ? AppTheme.borderColor.withValues(alpha: 0.5) : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: AppTheme.accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFFEF4444),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
