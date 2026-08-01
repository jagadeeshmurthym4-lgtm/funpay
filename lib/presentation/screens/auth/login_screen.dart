import 'package:cashspark/core/utils/validators.dart';
import 'package:cashspark/core/widgets/custom_text_field.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:cashspark/presentation/screens/auth/forgot_password_screen.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:cashspark/core/utils/responsive.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  late AnimationController _animController;
  late Animation<double> _fadeSlide;

  /// When true, the user is signed in but their email is not verified,
  /// so we show a verification banner on this screen instead of navigating away.
  bool _showVerificationBanner = false;
  bool _isResending = false;

  @override
  void initState() {
    super.initState();
    AdMobServiceImpl.instance.setAppOpenEnabled(false);
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..forward();
    _fadeSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
  }

  @override
  void dispose() {
    _animController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleEmailSignIn() async {
    if (!_formKey.currentState!.validate()) return;

    final authProvider = context.read<AuthProvider>();
    
    // Normalize: trim spaces, lowercase email for case-insensitive auth
    final normalizedEmail = _emailController.text.trim().toLowerCase();
    final normalizedPassword = _passwordController.text.trim();
    
    debugPrint('[LoginScreen] Signing in with email: "$normalizedEmail"');
    
    await authProvider.signInWithEmail(
      email: normalizedEmail,
      password: normalizedPassword,
    );

    if (authProvider.isAuthenticated && mounted) {
      debugPrint('[LoginScreen] Sign-in successful for: $normalizedEmail');
      
      // Check if email needs verification
      final user = authProvider.user;
      if (user != null && !user.isEmailVerified) {
        // Don't navigate away — show verification banner on this screen
        setState(() => _showVerificationBanner = true);
        return;
      }
      
      if (authProvider.needsProfileCompletion) {
        Navigator.pushReplacementNamed(context, AppRouter.completeProfile);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    } else if (!authProvider.isAuthenticated && mounted) {
      debugPrint('[LoginScreen] Sign-in FAILED. Error: ${authProvider.errorMessage}');
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() => _isResending = true);
    final authProvider = context.read<AuthProvider>();
    final sent = await authProvider.sendEmailVerification();
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Row(
            children: [
              Icon(
                sent ? Icons.check_circle_outline : Icons.error_outline,
                color: Colors.white,
                size: 20,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  sent
                      ? 'Verification email sent! Check your inbox.'
                      : (authProvider.successMessage ??
                          authProvider.errorMessage ??
                          'Failed to send. Try again later.'),
                  style: const TextStyle(fontSize: 14),
                ),
              ),
            ],
          ),
          backgroundColor: sent ? const Color(0xFF16A34A) : const Color(0xFFEF4444),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
      setState(() => _isResending = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    final authProvider = context.read<AuthProvider>();
    authProvider.clearError();
    await authProvider.signInWithGoogle();
    if (authProvider.isAuthenticated && mounted) {
      if (authProvider.needsProfileCompletion) {
        Navigator.pushReplacementNamed(context, AppRouter.completeProfile);
      } else {
        Navigator.pushReplacementNamed(context, AppRouter.home);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Consumer<AuthProvider>(
        builder: (context, auth, _) {
          final rs = context.responsive;
          return SafeArea(
            child: LayoutBuilder(
              builder: (context, constraints) {
                return SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    constraints.maxHeight * 0.04,
                    24,
                    24 + bottomInset,
                  ),
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight: constraints.maxHeight * 0.96,
                    ),
                    child: AnimatedBuilder(
                      animation: _fadeSlide,
                      builder: (context, child) {
                        return Opacity(
                          opacity: _fadeSlide.value,
                          child: Transform.translate(
                            offset: Offset(
                              0,
                              30 * (1 - _fadeSlide.value),
                            ),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: size.height * 0.02),

                          // ── Back to Home ──────────────────────
                          Align(
                            alignment: Alignment.centerLeft,
                            child: IconButton(
                              onPressed: () {
                                if (Navigator.of(context).canPop()) {
                                  Navigator.of(context).maybePop();
                                } else {
                                  Navigator.of(context).pushReplacementNamed(
                                    AppRouter.landing,
                                  );
                                }
                              },
                              icon: Icon(
                                Icons.arrow_back_ios_new_rounded,
                                size: 18,
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                              tooltip: 'Back to Home',
                            ),
                          ),

                          // ── Logo ──────────────────────────────
                          Center(
                            child: Container(
                              width: rs.avatarLg,
                              height: rs.avatarLg,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                gradient: const LinearGradient(
                                  colors: [
                                    Color(0xFF4ADE80),
                                    Color(0xFF22C55E),
                                  ],
                                  begin: Alignment.topLeft,
                                  end: Alignment.bottomRight,
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: const Color(0xFF4ADE80)
                                        .withValues(alpha: 0.3),
                                    blurRadius: 20,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: const Center(
                                child: Icon(
                                  Icons.auto_awesome,
                                  size: 36,
                                  color: Colors.black,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),

                          // ── Welcome Text ──────────────────────
                          Center(
                            child: Text(
                              'Welcome Back',
                              style: rs.h2.copyWith(
                                color: isDark
                                    ? Colors.white
                                    : const Color(0xFF0F172A),
                              ),
                            ),
                          ),
                          SizedBox(height: rs.spaceSm),
                          Center(
                            child: Text(
                              'Sign in to continue earning rewards',
                              style: rs.body.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                          SizedBox(height: rs.spaceXl),

                          // ── Error Banner ──────────────────────
                          if (auth.errorMessage != null)
                            AnimatedContainer(
                              duration: const Duration(milliseconds: 300),
                              margin: const EdgeInsets.only(bottom: 16),
                              child: PremiumGlass(
                                padding: const EdgeInsets.all(14),
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
                                        style:
                                            theme.textTheme.bodyMedium?.copyWith(
                                          color: theme.colorScheme.error,
                                        ),
                                      ),
                                    ),
                                    GestureDetector(
                                      onTap: auth.clearError,
                                      child: Icon(
                                        Icons.close,
                                        size: 18,
                                        color: theme.colorScheme.error,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),

                          // ── Email Verification Banner ────────
                          if (_showVerificationBanner)
                            _buildVerificationBanner(theme, isDark),

                          // ── Sign-In Form ──────────────────────
                          PremiumCard(                              padding: rs.pad(24),
                            child: Form(
                              key: _formKey,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.stretch,
                                children: [
                                  // Email Field
                                  CustomTextField(
                                    controller: _emailController,
                                    labelText: 'Email Address',
                                    hintText: 'Enter email / Gmail address',
                                    prefixIcon: Icons.email_outlined,
                                    isEmail: true,
                                    textInputAction: TextInputAction.next,
                                    validator: Validators.validateEmail,
                                    onChanged: (_) => auth.clearError(),
                                    onSubmitted: (_) =>
                                        FocusScope.of(context).nextFocus(),
                                  ),
                                  SizedBox(height: rs.spaceLg),

                                  // Password Field
                                  CustomTextField(
                                    controller: _passwordController,
                                    labelText: 'Password',
                                    hintText: 'Enter your password',
                                    prefixIcon: Icons.lock_outlined,
                                    isPassword: true,
                                    textInputAction: TextInputAction.done,
                                    validator: (value) {
                                      if (value == null || value.isEmpty) {
                                        return 'Password is required';
                                      }
                                      return null;
                                    },
                                    onChanged: (_) => auth.clearError(),
                                    onSubmitted: (_) =>
                                        _handleEmailSignIn(),
                                  ),
                                  SizedBox(height: rs.spaceXxl),

                                  // ── Sign In Button ─────────────
                                  GradientButton(
                                    label: 'Sign In',
                                    onPressed:
                                        auth.isLoading
                                            ? null
                                            : _handleEmailSignIn,
                                    isLoading: auth.isLoading,
                                  ),
                                  SizedBox(height: rs.spaceMd),

                                  // ── Forgot Password ────────────
                                  Center(
                                    child: TextButton(
                                      onPressed: () {
                                        auth.clearError();
                                        Navigator.push(
                                          context,
                                          MaterialPageRoute(
                                            builder: (_) =>
                                                const ForgotPasswordScreen(),
                                          ),
                                        );
                                      },
                                      style: TextButton.styleFrom(
                                        minimumSize: Size.zero,
                                        tapTargetSize:
                                            MaterialTapTargetSize.shrinkWrap,
                                        padding:
                                            const EdgeInsets.symmetric(
                                              vertical: 6,
                                              horizontal: 12,
                                            ),
                                      ),
                                      child: Text(
                                        'Forgot Password?',
                                        style: TextStyle(
                                          fontSize: 13,
                                          fontWeight: FontWeight.w500,
                                          color: theme
                                              .colorScheme.onSurfaceVariant,
                                        ),
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),

                          const SizedBox(height: 20),

                          // ── Sign in with Google (secondary) ───
                          _GoogleSignInButton(
                            onTap: auth.isLoading
                                ? null
                                : _handleGoogleSignIn,
                            isLoading: auth.isLoading,
                          ),

                          const SizedBox(height: 32),

                          // ── New User / Sign Up ────────────────
                          Center(
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'New User? ',
                                  style: TextStyle(
                                    fontSize: 14,
                                    color:
                                        theme.colorScheme.onSurfaceVariant,
                                  ),
                                ),
                                TextButton(
                                  onPressed: () {
                                    auth.clearError();
                                    Navigator.pushNamed(
                                      context,
                                      AppRouter.registration,
                                    );
                                  },
                                  style: TextButton.styleFrom(
                                    minimumSize: Size.zero,
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                    padding: EdgeInsets.zero,
                                  ),
                                  child: Text(
                                    'Sign Up',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: isDark
                                          ? const Color(0xFF4ADE80)
                                          : const Color(0xFF16A34A),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 28),

                          // ── Legal Links ────────────────────────
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 4,
                            runSpacing: 4,
                            children: [
                              _legalLink(
                                context,
                                'Terms & Conditions',
                                AppRouter.terms,
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: theme
                                      .colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              _legalLink(
                                context,
                                'Privacy Policy',
                                AppRouter.privacy,
                              ),
                              Text(
                                '|',
                                style: TextStyle(
                                  color: theme
                                      .colorScheme.onSurfaceVariant
                                      .withValues(alpha: 0.5),
                                ),
                              ),
                              _legalLink(
                                context,
                                'Contact Us',
                                AppRouter.contact,
                              ),
                            ],
                          ),

                          SizedBox(height: bottomInset > 0 ? 12 : 24),
                        ],
                      ),
                    ),
                  ),
                );
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildVerificationBanner(ThemeData theme, bool isDark) {
    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      margin: const EdgeInsets.only(bottom: 16),
      child: PremiumGlass(
        padding: const EdgeInsets.all(16),
        gradient: LinearGradient(
          colors: [
            const Color(0xFFF59E0B).withValues(alpha: 0.15),
            const Color(0xFFF59E0B).withValues(alpha: 0.05),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    color: const Color(0xFFF59E0B).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.mark_email_unread_outlined,
                    color: Color(0xFFF59E0B),
                    size: 20,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Verify Your Email',
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                          color: isDark ? Colors.white : const Color(0xFF0F172A),
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Please check your inbox to verify your email address '
                        'before you can access all features.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          color: theme.colorScheme.onSurfaceVariant,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                GestureDetector(
                  onTap: () => setState(() => _showVerificationBanner = false),
                  child: Icon(
                    Icons.close,
                    size: 18,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: SizedBox(
                    height: 40,
                    child: OutlinedButton(
                      onPressed: _isResending ? null : _resendVerificationEmail,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: const Color(0xFFF59E0B),
                        side: BorderSide(
                          color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                      ),
                      child: _isResending
                          ? const SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Color(0xFFF59E0B),
                              ),
                            )
                          : const Text(
                              'Resend Email',
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                SizedBox(
                  height: 40,
                  child: TextButton(
                    onPressed: () {
                      setState(() => _showVerificationBanner = false);
                      if (context.read<AuthProvider>().needsProfileCompletion) {
                        Navigator.pushReplacementNamed(
                          context,
                          AppRouter.completeProfile,
                        );
                      } else {
                        Navigator.pushReplacementNamed(context, AppRouter.home);
                      }
                    },
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: Text(
                      'Skip',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legalLink(
    BuildContext context,
    String text,
    String route,
  ) {
    final theme = Theme.of(context);
    return TextButton(
      style: TextButton.styleFrom(
        minimumSize: Size.zero,
        tapTargetSize: MaterialTapTargetSize.shrinkWrap,
        padding: EdgeInsets.zero,
      ),
      onPressed: () => Navigator.pushNamed(context, route),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 12,
          color: theme.colorScheme.onSurfaceVariant,
        ),
      ),
    );
  }
}

// ─── Google Sign-In Button (Secondary) ────────────────────
class _GoogleSignInButton extends StatelessWidget {
  final VoidCallback? onTap;
  final bool isLoading;

  const _GoogleSignInButton({
    this.onTap,
    this.isLoading = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SizedBox(
      height: 44,
      child: OutlinedButton(
        onPressed: (onTap != null && !isLoading) ? onTap : null,
        style: OutlinedButton.styleFrom(
          foregroundColor: isDark
              ? Colors.white.withValues(alpha: 0.8)
              : const Color(0xFF1F1F1F),
          side: BorderSide(
            color: isDark
                ? Colors.white.withValues(alpha: 0.15)
                : const Color(0xFFDADCE0).withValues(alpha: 0.7),
          ),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(14),
          ),
          backgroundColor: isDark
              ? const Color(0xFF1E1E1E)
              : Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 16),
        ),
        child: isLoading
            ? SizedBox(
                width: 20,
                height: 20,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: theme.colorScheme.primary,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.g_mobiledata,
                    size: 22,
                    color: const Color(0xFFDB4437),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Sign in with Google',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: isDark
                          ? Colors.white.withValues(alpha: 0.8)
                          : const Color(0xFF1F1F1F),
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
