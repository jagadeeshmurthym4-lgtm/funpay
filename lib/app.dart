import 'dart:async';
import 'package:cashspark/core/constants/app_constants.dart';
import 'package:cashspark/core/theme/app_theme.dart';
import 'package:cashspark/presentation/providers/auth_provider.dart';
import 'package:cashspark/presentation/providers/notification_provider.dart';
import 'package:cashspark/presentation/providers/theme_provider.dart';
import 'package:cashspark/presentation/routes/app_router.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

class FunPayApp extends StatefulWidget {
  const FunPayApp({super.key});

  @override
  State<FunPayApp> createState() => _FunPayAppState();
}

class _FunPayAppState extends State<FunPayApp> {
  AuthStatus _lastAuthStatus = AuthStatus.uninitialized;
  String? _lastUserId;
  bool _lastProfileCompleted = true;

  /// Called when auth state transitions to authenticated.
  /// Initializes FCM topics and Firestore notification listener for the current user.
  void _onAuthenticated(String userId) {
    unawaited(
      context.read<NotificationProvider>().setUser(userId),
    );
  }

  /// Called when auth state transitions to unauthenticated (signed out).
  void _onUnauthenticated(String? previousUserId) {
    if (previousUserId != null) {
      unawaited(
        context.read<NotificationProvider>().clearUser(previousUserId),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final themeProvider = context.watch<ThemeProvider>();

    // Reactively watch auth status and redirect on sign-out
    final auth = context.watch<AuthProvider>();
    if (_lastAuthStatus == AuthStatus.authenticated &&
        auth.status == AuthStatus.unauthenticated) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _onUnauthenticated(_lastUserId);
        Navigator.of(context).pushNamedAndRemoveUntil(
          AppRouter.landing,
          (route) => false,
        );
      });
    }

    // When auth state transitions to authenticated, initialize notifications
    if (auth.status == AuthStatus.authenticated &&
        _lastAuthStatus != AuthStatus.authenticated) {
      final uid = auth.user?.uid;
      if (uid != null && uid.isNotEmpty) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          _onAuthenticated(uid);
        });
      }
    }

    // Redirect users with incomplete profiles to complete-profile screen
    if (auth.isAuthenticated &&
        _lastProfileCompleted &&
        auth.needsProfileCompletion) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Avoid redirect if already on the complete-profile screen
        final currentRoute = ModalRoute.of(context)?.settings.name;
        if (currentRoute != AppRouter.completeProfile &&
            currentRoute != AppRouter.registration) {
          Navigator.of(context).pushNamedAndRemoveUntil(
            AppRouter.completeProfile,
            (route) => route.settings.name == AppRouter.home,
          );
        }
      });
    }

    _lastAuthStatus = auth.status;
    _lastUserId = auth.user?.uid;
    _lastProfileCompleted = !auth.needsProfileCompletion;

    return MaterialApp(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.premiumLightTheme,
      darkTheme: AppTheme.premiumDarkTheme,
      themeMode: themeProvider.themeMode,
      initialRoute: AppRouter.splash,
      onGenerateRoute: AppRouter.generateRoute,
    );
  }
}
