import 'package:cashspark/core/utils/validators.dart';
import 'package:cashspark/core/widgets/custom_text_field.dart';
import 'package:cashspark/core/widgets/premium_widgets.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

/// Represents the state of the password reset flow
enum _PasswordResetState { idle, loading, success, error }

class ForgotPasswordScreen extends StatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen>
    with SingleTickerProviderStateMixin {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  _PasswordResetState _resetState = _PasswordResetState.idle;
  String? _errorMessage;
  late AnimationController _animController;
  late Animation<double> _fadeSlide;

  @override
  void initState() {
    super.initState();
    _animController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _fadeSlide = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animController, curve: Curves.easeOutCubic),
    );
    _animController.forward();
  }

  @override
  void dispose() {
    _emailController.dispose();
    _animController.dispose();
    super.dispose();
  }

  bool get _isProcessing => _resetState == _PasswordResetState.loading;

  Future<void> _handleResetPassword() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _emailController.text.trim();
    setState(() {
      _resetState = _PasswordResetState.loading;
      _errorMessage = null;
    });

    if (mounted) {
      final auth = context.read<AuthProvider>();
      final success = await auth.sendPasswordResetEmail(email);

      if (!mounted) return;

      if (success) {
        setState(() {
          _resetState = _PasswordResetState.success;
        });
        _animController.forward(from: 0.0);
      } else {
        setState(() {
          _resetState = _PasswordResetState.error;
          _errorMessage = auth.errorMessage;
        });
      }
    }
  }

  void _resetForm() {
    setState(() {
      _resetState = _PasswordResetState.idle;
      _errorMessage = null;
    });
    context.read<AuthProvider>().clearError();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text('Reset Password'),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
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
              children: [
                const SizedBox(height: 20),

                // ─── Icon ─────────────────────────────────
                if (_resetState != _PasswordResetState.success)
                  _buildIcon(theme, isDark)
                else
                  _buildSuccessIcon(theme),

                const SizedBox(height: 28),

                // ─── Content based on state ───────────────
                if (_resetState == _PasswordResetState.idle)
                  _buildIdleContent(theme, isDark)
                else if (_resetState == _PasswordResetState.loading)
                  _buildLoadingContent(theme)
                else if (_resetState == _PasswordResetState.success)
                  _buildSuccessContent(theme, isDark)
                else
                  _buildErrorContent(theme, isDark),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildIcon(ThemeData theme, bool isDark) {
    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: LinearGradient(
          colors: [theme.colorScheme.primary, theme.colorScheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
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
        Icons.lock_reset_outlined,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildSuccessIcon(ThemeData theme) {
    return Container(
      width: 88,
      height: 88,
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
      child: const Icon(
        Icons.check_circle_outlined,
        size: 44,
        color: Colors.white,
      ),
    );
  }

  Widget _buildIdleContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          'Forgot your password?',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          "No worries! Enter your email / Gmail address and we'll send you a reset link.",
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 32),
        Form(
          key: _formKey,
          child: Column(
            children: [
              CustomTextField(
                controller: _emailController,
                labelText: 'Email',
                hintText: 'Enter email / Gmail address',
                prefixIcon: Icons.email_outlined,
                isEmail: true,
                textInputAction: TextInputAction.done,
                validator: Validators.validateEmail,
                onSubmitted: (_) => _handleResetPassword(),
              ),
              const SizedBox(height: 24),
              GradientButton(
                label: 'Send Reset Link',
                onPressed: _isProcessing ? null : _handleResetPassword,
                icon: Icons.send_rounded,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingContent(ThemeData theme) {
    return Container(
      padding: const EdgeInsets.all(32),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.03),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Column(
        children: [
          const SizedBox(height: 20),
          SizedBox(
            width: 64,
            height: 64,
            child: CircularProgressIndicator(
              strokeWidth: 4,
              color: theme.colorScheme.primary,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            'Checking account...',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            'Verifying your email and sending a reset link.',
            style: theme.textTheme.bodyMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          LinearProgressIndicator(
            color: theme.colorScheme.primary,
            backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.15),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Text(
          'Email Sent!',
          style: theme.textTheme.headlineSmall?.copyWith(
            fontWeight: FontWeight.w800,
            color: const Color(0xFF4ADE80),
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Check your email for the password reset link.',
          style: theme.textTheme.bodyLarge?.copyWith(
            color: theme.colorScheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 12),
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: const Color(0xFF4ADE80).withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: const Color(0xFF4ADE80).withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline,
                size: 20,
                color: const Color(0xFF4ADE80),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  "If you don't see the email in your inbox, please also check your Spam or Promotions folder. It may take a few minutes to arrive.",
                  style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 32),
        GradientButton(
          label: 'Back to Sign In',
          onPressed: () => Navigator.pop(context),
          icon: Icons.arrow_back,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () {
            _resetForm();
          },
          child: const Text('Send again'),
        ),
      ],
    );
  }

  Widget _buildErrorContent(ThemeData theme, bool isDark) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: theme.colorScheme.error.withValues(alpha: 0.12),
          ),
          child: Icon(
            Icons.error_outline_rounded,
            size: 40,
            color: theme.colorScheme.error,
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Unable to Send Email',
          style: theme.textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w700,
            color: isDark ? Colors.white : const Color(0xFF0F172A),
          ),
        ),
        const SizedBox(height: 12),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: theme.colorScheme.errorContainer.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: theme.colorScheme.error.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(
                Icons.info_outline,
                size: 18,
                color: theme.colorScheme.error,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  _errorMessage ?? 'An unknown error occurred.',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: theme.colorScheme.onErrorContainer,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),
        GradientButton(
          label: 'Try Again',
          onPressed: _resetForm,
          icon: Icons.refresh_rounded,
          color: theme.colorScheme.error,
          textColor: Colors.white,
        ),
        const SizedBox(height: 12),
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Back to Sign In'),
        ),
      ],
    );
  }
}
