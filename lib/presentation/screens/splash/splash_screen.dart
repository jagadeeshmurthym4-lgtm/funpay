import 'dart:async';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/services/admob_service.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _logoFade;
  late Animation<double> _logoScale;
  late Animation<double> _logoGlow;
  late Animation<double> _titleSlide;
  late Animation<double> _titleFade;
  late Animation<double> _taglineFade;
  late Animation<double> _loaderFade;
  AuthProvider? _authProvider;
  VoidCallback? _authListener;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 2800),
    );

    // Logo: fade in + scale up + subtle pulse glow
    _logoFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.35, curve: Curves.easeOut),
      ),
    );
    _logoScale = Tween<double>(begin: 0.7, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.45, curve: Curves.easeOutBack),
      ),
    );
    _logoGlow = Tween<double>(begin: 0.3, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.1, 0.6, curve: Curves.easeInOut),
      ),
    );

    // Title: slide up + fade
    _titleSlide = Tween<double>(begin: 24, end: 0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOutCubic),
      ),
    );
    _titleFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.25, 0.55, curve: Curves.easeOut),
      ),
    );

    // Tagline: delayed fade
    _taglineFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.45, 0.7, curve: Curves.easeOut),
      ),
    );

    // Loader: delayed fade
    _loaderFade = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.6, 0.85, curve: Curves.easeOut),
      ),
    );

    _controller.forward();

    // Start preloading App Open ad while splash is showing
    // Safely handle web where AdMob is not available
    try {
      AdMobServiceImpl.instance.setAppOpenEnabled(true);
    } catch (_) {
      // AdMob not available on web — continue without ads
    }
    _navigateAfterDelay();
  }

  Future<void> _navigateAfterDelay() async {
    _authProvider = context.read<AuthProvider>();
    if (_authProvider!.status == AuthStatus.authenticated ||
        _authProvider!.status == AuthStatus.unauthenticated) {
      await Future.delayed(AppConstants.splashDuration);
      if (!mounted) return;
      if (_authProvider!.isAuthenticated) {
        await _showAppOpenAndNavigate();
      } else {
        Navigator.pushReplacementNamed(context, '/login');
      }
      return;
    }

    bool resolved = false;
    _authListener = () async {
      if (!mounted || resolved) return;
      if (_authProvider!.status != AuthStatus.uninitialized) {
        resolved = true;
        _timeoutTimer?.cancel();
        _authProvider!.removeListener(_authListener!);
        if (_authProvider!.isAuthenticated) {
          await _showAppOpenAndNavigate();
        } else {
          Navigator.pushReplacementNamed(context, '/login');
        }
      }
    };
    _authProvider!.addListener(_authListener!);
    await Future.delayed(AppConstants.splashDuration);
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || resolved) return;
      resolved = true;
      _authProvider!.removeListener(_authListener!);
      Navigator.pushReplacementNamed(context, '/login');
    });
  }

  Future<void> _showAppOpenAndNavigate() async {
    if (!mounted) return;
    // Safely attempt to show app open ad (may fail on web)
    bool adShown;
    try {
      adShown = await AdMobServiceImpl.instance.showAppOpenAd();
    } catch (_) {
      adShown = false;
    }
    if (!mounted) return;
    if (!adShown) {
      _navigateAfterAuth();
      return;
    }
    // Only reaches here on mobile (adShown=true)
    final deadline = DateTime.now().add(const Duration(seconds: 10));
    while (mounted &&
        AdMobServiceImpl.instance.isAppOpenShowing &&
        DateTime.now().isBefore(deadline)) {
      await Future.delayed(const Duration(milliseconds: 200));
    }
    if (mounted) _navigateAfterAuth();
  }

  void _navigateAfterAuth() {
    if (_authProvider!.isAuthenticated) {
      if (_authProvider!.needsProfileCompletion) {
        Navigator.pushReplacementNamed(context, '/complete-profile');
      } else {
        Navigator.pushReplacementNamed(context, '/home');
      }
    } else {
      Navigator.pushReplacementNamed(context, '/login');
    }
  }

  @override
  void dispose() {
    _timeoutTimer?.cancel();
    _controller.dispose();
    if (_authListener != null && _authProvider != null) {
      _authProvider!.removeListener(_authListener!);
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: isDark
                ? [
                    const Color(0xFF081A2E),
                    const Color(0xFF0D2844),
                    const Color(0xFF0F2740),
                    const Color(0xFF081A2E),
                  ]
                : [
                    const Color(0xFFF0F5FF),
                    const Color(0xFFE8F0FE),
                    const Color(0xFFF5F0FF),
                    const Color(0xFFF0F5FF),
                  ],
            stops: const [0.0, 0.3, 0.7, 1.0],
          ),
        ),
        child: Stack(
          children: [
            // ── Decorative Radial Gradients ──
            Positioned(
              top: -80,
              right: -60,
              child: Container(
                width: 260,
                height: 260,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? AppTheme.accentGreen : const Color(0xFF22C55E))
                          .withValues(alpha: 0.12),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),
            Positioned(
              bottom: -100,
              left: -80,
              child: Container(
                width: 300,
                height: 300,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: RadialGradient(
                    colors: [
                      (isDark ? AppTheme.accentBlue : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.08),
                      Colors.transparent,
                    ],
                  ),
                ),
              ),
            ),

            // ── Subtle Top Accent Line ──
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Container(
                height: 3,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [
                      Colors.transparent,
                      (isDark ? AppTheme.accentGreen : const Color(0xFF22C55E))
                          .withValues(alpha: 0.6),
                      (isDark ? AppTheme.accentBlue : const Color(0xFF3B82F6))
                          .withValues(alpha: 0.6),
                      Colors.transparent,
                    ],
                    stops: const [0.0, 0.3, 0.7, 1.0],
                  ),
                ),
              ),
            ),

            // ── Main Content ──
            Center(
              child: AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // ── Logo Container ──
                      Opacity(
                        opacity: _logoFade.value,
                        child: Transform.scale(
                          scale: _logoScale.value,
                          child: Container(
                            width: 128,
                            height: 128,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: LinearGradient(
                                colors: isDark
                                    ? [
                                        const Color(0xFF0F2740),
                                        const Color(0xFF1A3350),
                                      ]
                                    : [
                                        Colors.white,
                                        const Color(0xFFF8FAFC),
                                      ],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              boxShadow: [
                                BoxShadow(
                                  color: (isDark
                                          ? AppTheme.accentGreen
                                          : const Color(0xFF22C55E))
                                      .withValues(alpha: 0.15 * _logoGlow.value),
                                  blurRadius: 30 + (20 * (1 - _logoGlow.value)),
                                  spreadRadius: 2 * _logoGlow.value,
                                  offset: const Offset(0, 8),
                                ),
                                BoxShadow(
                                  color: (isDark
                                          ? AppTheme.accentBlue
                                          : const Color(0xFF3B82F6))
                                      .withValues(alpha: 0.06 * _logoGlow.value),
                                  blurRadius: 50,
                                  spreadRadius: 4,
                                  offset: const Offset(0, 0),
                                ),
                              ],
                              border: Border.all(
                                color: (isDark
                                        ? AppTheme.borderColor
                                        : const Color(0xFFCBD5E1))
                                    .withValues(alpha: 0.4),
                                width: 1,
                              ),
                            ),
                            child: ClipOval(
                              child: Image.asset(
                                'assets/images/app_icon.png',
                                width: 128,
                                height: 128,
                                fit: BoxFit.cover,
                                filterQuality: FilterQuality.high,
                                errorBuilder: (context, error, stackTrace) =>
                                    Icon(
                                  Icons.auto_awesome,
                                  size: 48,
                                  color: isDark
                                      ? AppTheme.accentGreen
                                      : const Color(0xFF22C55E),
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 32),

                      // ── App Name ──
                      Opacity(
                        opacity: _titleFade.value,
                        child: Transform.translate(
                          offset: Offset(0, _titleSlide.value),
                          child: Column(
                            children: [
                              Text(
                                AppConstants.appName,
                                style: TextStyle(
                                  fontSize: 38,
                                  fontWeight: FontWeight.w800,
                                  color: isDark
                                      ? Colors.white
                                      : const Color(0xFF0F172A),
                                  letterSpacing: -1.2,
                                  height: 1.1,
                                ),
                              ),
                              const SizedBox(height: 4),
                              // ── Subtle underline accent ──
                              Container(
                                width: 40,
                                height: 3,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(2),
                                  gradient: LinearGradient(
                                    colors: [
                                      isDark
                                          ? AppTheme.accentGreen
                                          : const Color(0xFF22C55E),
                                      isDark
                                          ? AppTheme.accentBlue
                                          : const Color(0xFF3B82F6),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // ── Tagline ──
                      Opacity(
                        opacity: _taglineFade.value,
                        child: Text(
                          'Play. Earn. Repeat.',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w500,
                            color: isDark
                                ? AppTheme.accentGreen
                                : const Color(0xFF22C55E),
                            letterSpacing: 2.4,
                          ),
                        ),
                      ),

                      const SizedBox(height: 56),

                      // ── Elegant Loading Indicator ──
                      Opacity(
                        opacity: _loaderFade.value,
                        child: _ClassicLoader(isDark: isDark),
                      ),
                    ],
                  );
                },
              ),
            ),

            // ── Bottom Version Text ──
            Positioned(
              bottom: 40,
              left: 0,
              right: 0,
              child: Center(
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, _) {
                    return Opacity(
                      opacity: _loaderFade.value * 0.5,
                      child: Text(
                        'v${AppConstants.appVersion}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w400,
                          color: isDark
                              ? AppTheme.textMuted
                              : const Color(0xFF94A3B8),
                          letterSpacing: 1,
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// A classic, elegant circular loading indicator with a pulsing ring.
class _ClassicLoader extends StatefulWidget {
  final bool isDark;

  const _ClassicLoader({required this.isDark});

  @override
  State<_ClassicLoader> createState() => _ClassicLoaderState();
}

class _ClassicLoaderState extends State<_ClassicLoader>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final color = widget.isDark
        ? AppTheme.accentGreen
        : const Color(0xFF22C55E);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Stack(
            alignment: Alignment.center,
            children: [
              // Outer pulsing ring
              AnimatedBuilder(
                animation: _pulseController,
                builder: (context, _) {
                  return Container(
                    width: 28 + (8 * _pulseController.value),
                    height: 28 + (8 * _pulseController.value),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: color.withValues(alpha: 0.15 * (1 - _pulseController.value * 0.5)),
                        width: 1.5,
                      ),
                    ),
                  );
                },
              ),
              // Inner spinning arc
              SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                  strokeCap: StrokeCap.round,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
