import 'package:cashspark/core/errors/exceptions.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/core/utils/validators.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class RegistrationScreen extends StatefulWidget {
  const RegistrationScreen({super.key});

  @override
  State<RegistrationScreen> createState() => _RegistrationScreenState();
}

class _RegistrationScreenState extends State<RegistrationScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _firstNameCtrl;
  late final TextEditingController _lastNameCtrl;
  late final TextEditingController _emailCtrl;
  late final TextEditingController _phoneCtrl;
  late final TextEditingController _dobCtrl;
  late final TextEditingController _referralCtrl;
  late final TextEditingController _passwordCtrl;
  late final TextEditingController _confirmPasswordCtrl;

  bool _isSubmitting = false;
  String? _referralError;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  late AnimationController _animController;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();

    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    )..forward();

    _fadeSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );

    _firstNameCtrl = TextEditingController();
    _lastNameCtrl = TextEditingController();
    _emailCtrl = TextEditingController();
    _phoneCtrl = TextEditingController();
    _dobCtrl = TextEditingController();
    _referralCtrl = TextEditingController();
    _passwordCtrl = TextEditingController();
    _confirmPasswordCtrl = TextEditingController();
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
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
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
      _dobCtrl.text =
          '${picked.day.toString().padLeft(2, '0')}/${picked.month.toString().padLeft(2, '0')}/${picked.year}';
    }
  }

  Future<void> _onContinue() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _referralError = null;
    });

    try {
      final authProvider = context.read<AuthProvider>();

      final fullName = '${_firstNameCtrl.text.trim()} ${_lastNameCtrl.text.trim()}';

      await authProvider.signUpWithEmail(
        fullName: fullName,
        email: _emailCtrl.text.trim(),
        phone: _phoneCtrl.text.trim(),
        password: _passwordCtrl.text,
        firstName: _firstNameCtrl.text.trim(),
        lastName: _lastNameCtrl.text.trim(),
        dateOfBirth: _dobCtrl.text.trim(),
        referralCode: _referralCtrl.text.trim().isEmpty
            ? null
            : _referralCtrl.text.trim(),
      );

      if (mounted && authProvider.isAuthenticated) {
        // Show a success snackbar about email verification
        if (authProvider.successMessage != null) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Row(
                children: [
                  const Icon(Icons.mark_email_unread_outlined,
                      color: Colors.white, size: 20),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      authProvider.successMessage!,
                      style: const TextStyle(fontSize: 14),
                    ),
                  ),
                ],
              ),
              backgroundColor: const Color(0xFF2563EB),
              behavior: SnackBarBehavior.floating,
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
              duration: const Duration(seconds: 6),
              action: SnackBarAction(
                label: 'Resend',
                textColor: Colors.white,
                onPressed: () async {
                  final resent = await authProvider.sendEmailVerification();
                  if (mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(resent
                            ? 'Verification email resent!'
                            : (authProvider.successMessage ??
                                'Already verified')),
                        backgroundColor: resent
                            ? const Color(0xFF16A34A)
                            : const Color(0xFF6B7280),
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                      ),
                    );
                  }
                },
              ),
            ),
          );
        }

        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.home,
          (route) => false,
        );
      }
    } on ReferralException catch (e) {
      setState(() => _referralError = e.message);
    } catch (e) {
      if (mounted) {
        final authProvider = context.read<AuthProvider>();
        final message = authProvider.errorMessage ?? 'Sign-up failed. Please try again.';
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(message),
            backgroundColor: const Color(0xFFEF4444),
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final keyboardOpen = bottomInset > 0;

    return Scaffold(
      resizeToAvoidBottomInset: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: EdgeInsets.fromLTRB(
              20, keyboardOpen ? 8 : 0, 20, 20 + bottomInset),
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
                if (!keyboardOpen) ...[
                  const SizedBox(height: 8),
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
                      child: Icon(Icons.person_add_outlined,
                          size: 32, color: Colors.black),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'Create Account',
                    style: theme.textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                      color:
                          isDark ? Colors.white : const Color(0xFF0F172A),
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Fill in your details to get started',
                    style: theme.textTheme.bodyLarge?.copyWith(
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 32),
                ],
                Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildLabel(theme, 'First Name *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _firstNameCtrl,
                        hint: 'Enter your first name',
                        icon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'First name is required';
                          }
                          if (v.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(theme, 'Last Name *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _lastNameCtrl,
                        hint: 'Enter your last name',
                        icon: Icons.person_outline,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Last name is required';
                          }
                          if (v.trim().length < 2) {
                            return 'Name must be at least 2 characters';
                          }
                          return null;
                        },
                        textInputAction: TextInputAction.next,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(theme, 'Phone Number *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _phoneCtrl,
                        hint: 'Enter your phone number',
                        icon: Icons.phone_outlined,
                        keyboardType: TextInputType.phone,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Phone number is required';
                          }
                          final cleaned =
                              v.replaceAll(RegExp(r'[\s\-\(\)]'), '');
                          if (cleaned.length < 10) {
                            return 'Enter a valid 10-digit phone number';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(theme, 'Gmail Address *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _emailCtrl,
                        hint: 'Enter your Gmail address',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                        textInputAction: TextInputAction.next,
                        validator: (v) {
                          if (v == null || v.trim().isEmpty) {
                            return 'Gmail address is required';
                          }
                          if (!v.contains('@') || !v.contains('.')) {
                            return 'Enter a valid email address';
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),
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
                              if (v == null || v.trim().isEmpty) {
                                return 'Date of birth is required';
                              }
                              return null;
                            },
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(theme, 'Referral Code', optional: true),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _referralCtrl,
                        hint: 'Enter referral code (optional)',
                        icon: Icons.card_giftcard_outlined,
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onContinue(),
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
                      const SizedBox(height: 24),
                      _buildLabel(theme, 'Password *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _passwordCtrl,
                        hint: 'Create a strong password',
                        icon: Icons.lock_outlined,
                        isPassword: true,
                        obscureText: _obscurePassword,
                        onToggleObscure: () => setState(
                            () => _obscurePassword = !_obscurePassword),
                        textInputAction: TextInputAction.next,
                        validator: Validators.validatePassword,
                      ),
                      const SizedBox(height: 16),
                      _buildLabel(theme, 'Confirm Password *'),
                      const SizedBox(height: 8),
                      _buildField(
                        controller: _confirmPasswordCtrl,
                        hint: 'Re-enter your password',
                        icon: Icons.lock_outlined,
                        isPassword: true,
                        obscureText: _obscureConfirmPassword,
                        onToggleObscure: () => setState(
                            () => _obscureConfirmPassword =
                                !_obscureConfirmPassword),
                        textInputAction: TextInputAction.done,
                        onSubmitted: (_) => _onContinue(),
                        validator: (value) => Validators.validateConfirmPassword(
                          _passwordCtrl.text,
                          value,
                        ),
                      ),
                      const SizedBox(height: 28),
                      SizedBox(
                        height: 56,
                        child: FilledButton.icon(
                          onPressed: _isSubmitting ? null : _onContinue,
                          icon: _isSubmitting
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.5,
                                    color: Colors.black,
                                  ),
                                )
                              : const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 22,
                                ),
                          label: Text(
                            _isSubmitting
                                ? 'Creating Account...'
                                : 'Continue',
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
                            shadowColor:
                                const Color(0xFF4ADE80).withValues(alpha: 0.4),
                          ),
                        ),
                      ),
                      const SizedBox(height: 12),
                      Center(
                        child: TextButton(
                          onPressed: () => Navigator.of(context).pop(),
                          child: Text.rich(
                            TextSpan(
                              text: 'Already have an account? ',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              children: [
                                TextSpan(
                                  text: 'Sign In',
                                  style: TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w700,
                                    color: isDark
                                        ? const Color(0xFF4ADE80)
                                        : const Color(0xFF16A34A),
                                  ),
                                ),
                              ],
                            ),
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

  Widget _buildLabel(ThemeData theme, String label,
      {bool optional = false}) {
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
    bool isPassword = false,
    bool obscureText = false,
    VoidCallback? onToggleObscure,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    void Function(String)? onSubmitted,
    String? Function(String?)? validator,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return TextFormField(
      controller: controller,
      obscureText: isPassword ? obscureText : false,
      readOnly: readOnly,
      keyboardType: isPassword ? TextInputType.visiblePassword : keyboardType,
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
          color: isDark
              ? AppTheme.textMuted.withValues(alpha: 0.6)
              : const Color(0xFF94A3B8).withValues(alpha: 0.7),
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
        suffixIcon: isPassword
            ? IconButton(
                icon: Icon(
                  obscureText
                      ? Icons.visibility_off_outlined
                      : Icons.visibility_outlined,
                  size: 20,
                  color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                ),
                onPressed: onToggleObscure,
              )
            : suffixIcon != null
                ? Icon(
                    suffixIcon,
                    size: 18,
                    color: isDark ? AppTheme.textMuted : const Color(0xFF94A3B8),
                  )
                : null,
        filled: true,
        fillColor: readOnly
            ? (isDark
                ? AppTheme.borderColor.withValues(alpha: 0.3)
                : const Color(0xFFF1F5F9))
            : (isDark ? AppTheme.bgCardLight : const Color(0xFFF1F5F9)),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(
            color: isDark
                ? AppTheme.borderColor.withValues(alpha: 0.5)
                : const Color(0xFFCBD5E1).withValues(alpha: 0.5),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: AppTheme.accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide:
              const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        errorStyle: const TextStyle(
          fontSize: 11,
          color: Color(0xFFEF4444),
          fontWeight: FontWeight.w500,
        ),
      ),
    );
  }
}
