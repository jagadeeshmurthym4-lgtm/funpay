import 'dart:async';
import 'package:cashspark/core/constants/app_constants.dart';
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
  late Animation<double> _fadeAnimation;
  late Animation<double> _scaleAnimation;
  late Animation<double> _glowAnimation;
  AuthProvider? _authProvider;
  VoidCallback? _authListener;
  Timer? _timeoutTimer;

  @override
  void initState() {
    super.initState();

    // ── Premium animation: 700ms fade-in + gentle zoom + pulse glow ──
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );

    _scaleAnimation = Tween<double>(begin: 0.82, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOutBack),
    );

    _glowAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.3, 1.0, curve: Curves.easeOut)),
    );

    _controller.forward();

    // Precache the logo image for zero flicker on first frame
    AssetImage('assets/images/app_icon.png')
        .resolve(ImageConfiguration.empty);

    // Start preloading App Open ad while splash is showing
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
        Navigator.pushReplacementNamed(context, '/landing');
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
          Navigator.pushReplacementNamed(context, '/landing');
        }
      }
    };
    _authProvider!.addListener(_authListener!);
    await Future.delayed(AppConstants.splashDuration);
    _timeoutTimer = Timer(const Duration(seconds: 5), () {
      if (!mounted || resolved) return;
      resolved = true;
      _authProvider!.removeListener(_authListener!);
      Navigator.pushReplacementNamed(context, '/landing');
    });
  }

  Future<void> _showAppOpenAndNavigate() async {
    if (!mounted) return;
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
      Navigator.pushReplacementNamed(context, '/landing');
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
    const bgColor = Color(0xFF0F172A); // Premium dark blue-slate
    const glowColor = Color(0xFF22C55E); // FunPay green accent

    return Scaffold(
      backgroundColor: bgColor,
      body: AnimatedBuilder(
        animation: _controller,
        builder: (context, _) {
          return Stack(
            children: [
              // ── Ambient gradient glow ──
              Positioned(
                left: 0,
                right: 0,
                top: 0,
                bottom: 0,
                child: IgnorePointer(
                  child: Opacity(
                    opacity: _glowAnimation.value * 0.15,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: RadialGradient(
                          center: const Alignment(0, -0.3),
                          radius: 1.0,
                          colors: [
                            glowColor,
                            glowColor.withValues(alpha: 0.0),
                            bgColor,
                          ],
                          stops: const [0.0, 0.5, 1.0],
                        ),
                      ),
                    ),
                  ),
                ),
              ),

              // ── Centered logo -- perfectly centered on any screen ──
              Center(
                child: Opacity(
                  opacity: _fadeAnimation.value,
                  child: Transform.scale(
                    scale: _scaleAnimation.value,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Logo container with glow
                        Container(
                          width: 200,
                          height: 200,
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: const Color(0xFF1E293B),
                            boxShadow: [
                              // Soft ambient shadow
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.2 * _glowAnimation.value),
                                blurRadius: 50,
                                spreadRadius: 8,
                                offset: const Offset(0, 10),
                              ),
                              // Inner glow
                              BoxShadow(
                                color: glowColor.withValues(alpha: 0.1 * _glowAnimation.value),
                                blurRadius: 100,
                                spreadRadius: 16,
                                offset: const Offset(0, 0),
                              ),
                              // Depth shadow
                              BoxShadow(
                                color: const Color(0xFF000000).withValues(alpha: 0.4),
                                blurRadius: 70,
                                spreadRadius: 4,
                                offset: const Offset(0, 20),
                              ),
                            ],
                            border: Border.all(
                              color: const Color(0xFF334155).withValues(alpha: 0.5),
                              width: 1,
                            ),
                          ),
                          child: ClipOval(
                            child: Image.asset(
                              'assets/images/app_icon.png',
                              width: 200,
                              height: 200,
                              fit: BoxFit.cover,
                              filterQuality: FilterQuality.high,
                              errorBuilder: (context, error, stackTrace) => Icon(
                                Icons.auto_awesome,
                                size: 80,
                                color: glowColor,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom tagline (subtle, not a loading indicator) ──
              Positioned(
                left: 0,
                right: 0,
                bottom: MediaQuery.of(context).size.height * 0.08,
                child: Opacity(
                  opacity: _fadeAnimation.value * 0.4,
                  child: Text(
                    'FUN PAY',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      letterSpacing: 6,
                      fontWeight: FontWeight.w300,
                      color: Colors.white.withValues(alpha: 0.3),
                    ),
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}
