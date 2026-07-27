import 'package:cashspark/core/utils/validators.dart';
import 'package:cashspark/core/widgets/custom_text_field.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/core/widgets/loading_widget.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SignupScreen extends StatefulWidget {
  const SignupScreen({super.key});

  @override
  State<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends State<SignupScreen> with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  final _referralController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeAnim;
  late Animation<Offset> _slideAnim;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeAnim = CurvedAnimation(parent: _animController, curve: Curves.easeIn);
    _slideAnim = Tween<Offset>(
      begin: const Offset(0, 0.1),
      end: Offset.zero,
    ).animate(CurvedAnimation(parent: _animController, curve: Curves.easeOut));
    _animController.forward();
  }

  @override
  void dispose() {
    _animController.dispose();
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _referralController.dispose();
    super.dispose();
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    await authProvider.signUpWithEmail(
      fullName: _nameController.text.trim(),
      email: _emailController.text.trim(),
      phone: _phoneController.text.trim(),
      password: _passwordController.text,
      referralCode: _referralController.text.trim().isEmpty
          ? null
          : _referralController.text.trim().toUpperCase(),
    );
    if (authProvider.isAuthenticated && mounted) {
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
            shape:
                RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
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
                          : (authProvider.successMessage ?? 'Already verified')),
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

      Navigator.pushReplacementNamed(context, '/home');
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              theme.colorScheme.primary.withValues(alpha: 0.08),
              theme.colorScheme.surface,
              theme.colorScheme.tertiary.withValues(alpha: 0.05),
            ],
          ),
        ),
        child: Consumer<AuthProvider>(
          builder: (context, auth, _) {
            return LoadingOverlay(
              isLoading: auth.isLoading,
              child: SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: FadeTransition(
                    opacity: _fadeAnim,
                    child: SlideTransition(
                      position: _slideAnim,
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.04),
                          // Header
                          PremiumGlass(
                            padding: const EdgeInsets.all(24),
                            child: Column(
                              children: [
                                Container(
                                  width: 64,
                                  height: 64,
                                  decoration: BoxDecoration(
                                    shape: BoxShape.circle,
                                    gradient: LinearGradient(
                                      colors: [
                                        theme.colorScheme.primary,
                                        theme.colorScheme.tertiary,
                                      ],
                                    ),
                                    boxShadow: [
                                      BoxShadow(
                                        color: theme.colorScheme.primary.withValues(alpha: 0.3),
                                        blurRadius: 20,
                                        offset: const Offset(0, 8),
                                      ),
                                    ],
                                  ),
                                  child: const Icon(
                                    Icons.person_add_rounded,
                                    size: 32,
                                    color: Colors.white,
                                  ),
                                ),
                                const SizedBox(height: 20),
                                Text(
                                  'Create Account',
                                  style: theme.textTheme.headlineMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    letterSpacing: -0.5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Join Fun Pay and start earning today',
                                  style: theme.textTheme.bodyLarge?.copyWith(
                                    color: theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),

                          // Error Banner
                          if (auth.errorMessage != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: PremiumGlass(
                                padding: const EdgeInsets.all(12),
                                gradient: LinearGradient(
                                  colors: [
                                    theme.colorScheme.error.withValues(alpha: 0.15),
                                    theme.colorScheme.error.withValues(alpha: 0.05),
                                  ],
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.error_outline,
                                      color: theme.colorScheme.error,
                                      size: 20,
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        auth.errorMessage!,
                                        style: theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                    IconButton(
                                      icon: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                      onPressed: auth.clearError,
                                      padding: EdgeInsets.zero,
                                      constraints: const BoxConstraints(),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // Signup Form
                          PremiumCard(
                            padding: const EdgeInsets.all(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  Text(
                                    'Personal Information',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _nameController,
                                    labelText: 'Full Name',
                                    hintText: 'Enter your full name',
                                    prefixIcon: Icons.person_outlined,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateFullName,
                                    onChanged: (_) => auth.clearError(),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _emailController,
                                    labelText: 'Email',
                                    hintText: 'Enter email / Gmail address',
                                    prefixIcon: Icons.email_outlined,
                                    isEmail: true,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateEmail,
                                    onChanged: (_) => auth.clearError(),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _phoneController,
                                    labelText: 'Phone Number',
                                    hintText: 'Enter your 10-digit mobile number',
                                    prefixIcon: Icons.phone_outlined,
                                    isPhone: true,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) {
                                      if (value == null || value.trim().isEmpty) {
                                        return 'Phone number is required';
                                      }
                                      final cleaned = value.trim().replaceAll(RegExp(r'[\s\-()]'), '');
                                      if (cleaned.length != 10) {
                                        return 'Enter a valid 10-digit mobile number';
                                      }
                                      if (!RegExp(r'^[6-9]\d{9}$').hasMatch(cleaned)) {
                                        return 'Enter a valid Indian mobile number starting with 6-9';
                                      }
                                      return null;
                                    },
                                  ),
                                  const SizedBox(height: 16),

                                  const Divider(),
                                  const SizedBox(height: 12),
                                  Text(
                                    'Security',
                                    style: theme.textTheme.titleSmall?.copyWith(
                                      fontWeight: FontWeight.w600,
                                      color: theme.colorScheme.primary,
                                    ),
                                  ),
                                  const SizedBox(height: 12),
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Create a strong password',
                                    prefixIcon: Icons.lock_outlined,
                                    isPassword: true,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validatePassword,
                                    onChanged: (_) => auth.clearError(),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _confirmPasswordController,
                                    labelText: 'Confirm Password',
                                    hintText: 'Re-enter your password',
                                    prefixIcon: Icons.lock_outlined,
                                    isPassword: true,
                                    textInputAction: TextInputAction.next,
                                    validator: (value) => Validators.validateConfirmPassword(
                                      _passwordController.text,
                                      value,
                                    ),
                                  ),
                                  const SizedBox(height: 16),
                                  CustomTextField(
                                    controller: _referralController,
                                    labelText: 'Referral Code (Optional)',
                                    hintText: 'Enter referral code',
                                    prefixIcon: Icons.card_giftcard_outlined,
                                    textInputAction: TextInputAction.done,
                                    validator: Validators.validateReferralCode,
                                  ),
                                  const SizedBox(height: 24),
                                  GradientButton(
                                    label: 'Create Account',
                                    onPressed: auth.isLoading ? null : _handleSignup,
                                    isLoading: auth.isLoading,
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 16),

                          // Terms & Privacy
                          PremiumGlass(
                            padding: const EdgeInsets.all(16),
                            child: Text(
                              'By creating an account, you agree to our Terms of Service and Privacy Policy.',
                              style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              textAlign: TextAlign.center,
                            ),
                          ),

                          const SizedBox(height: 24),

                          // Login link
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                'Already have an account? ',
                                style: theme.textTheme.bodyMedium?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              TextButton(
                                onPressed: () => Navigator.pop(context),
                                child: const Text('Sign In'),
                              ),
                            ],
                          ),

                          SizedBox(height: size.height * 0.02),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
