import 'package:flutter/material.dart';

class AppTheme {
  AppTheme._();

  // Dark Navy Theme (Primary)
  static const Color _bgDark = Color(0xFF081A2E);
  static const Color _bgCard = Color(0xFF0F2740);
  static const Color _bgCardLight = Color(0xFF1A3350);
  static const Color _accentGreen = Color(0xFF4ADE80);
  static const Color _accentGreenDark = Color(0xFF22C55E);
  static const Color _accentBlue = Color(0xFF3B82F6);
  static const Color _accentPurple = Color(0xFF8B5CF6);
  static const Color _accentOrange = Color(0xFFF59E0B);
  static const Color _accentPink = Color(0xFFEC4899);
  static const Color _textPrimary = Color(0xFFF1F5F9);
  static const Color _textSecondary = Color(0xFF94A3B8);
  static const Color _textMuted = Color(0xFF64748B);
  static const Color _borderColor = Color(0xFF1E3A5F);
  static const Color _white = Color(0xFFFFFFFF);
  static const Color _black = Color(0xFF000000);

  // Light Theme Colors
  static const Color _lightBg = Color(0xFFF0F5FF);
  static const Color _lightSurface = Color(0xFFFFFFFF);
  static const Color _lightText = Color(0xFF0F172A);
  static const Color _lightTextSec = Color(0xFF475569);

  // --- Glassmorphism Helpers ---
  static BoxDecoration glassContainer({
    required BuildContext context,
    double blur = 20,
    double opacity = 0.1,
    double radius = 20,
    Color? borderColor,
    Color? backgroundColor,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bg = backgroundColor ?? (isDark ? _bgCard : _white);
    final border = borderColor ?? (isDark ? _borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3));
    return BoxDecoration(
      color: bg.withValues(alpha: isDark ? 0.8 : 0.9),
      borderRadius: BorderRadius.circular(radius),
      border: Border.all(color: border, width: 0.5),
      boxShadow: [
        BoxShadow(
          color: isDark ? _black.withValues(alpha: 0.3) : _black.withValues(alpha: 0.05),
          blurRadius: blur,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static BoxDecoration glassGradient({
    required BuildContext context,
    List<Color>? colors,
    double radius = 20,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final defaultColors = colors ?? [
      isDark ? _bgCard : _white,
      isDark ? _bgCardLight.withValues(alpha: 0.7) : const Color(0xFFF0F5FF),
    ];
    return BoxDecoration(
      borderRadius: BorderRadius.circular(radius),
      gradient: LinearGradient(
        colors: defaultColors,
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
      ),
      border: Border.all(
        color: isDark ? _borderColor.withValues(alpha: 0.3) : const Color(0xFFCBD5E1).withValues(alpha: 0.3),
        width: 0.5,
      ),
      boxShadow: [
        BoxShadow(
          color: isDark ? _black.withValues(alpha: 0.3) : _black.withValues(alpha: 0.05),
          blurRadius: 20,
          offset: const Offset(0, 8),
        ),
      ],
    );
  }

  static ThemeData get premiumDarkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      scaffoldBackgroundColor: _bgDark,
      colorScheme: const ColorScheme.dark(
        primary: _accentGreen,
        onPrimary: _black,
        primaryContainer: Color(0xFF064E3B),
        onPrimaryContainer: _accentGreen,
        secondary: _accentBlue,
        onSecondary: _white,
        secondaryContainer: Color(0xFF1E3A5F),
        onSecondaryContainer: _accentBlue,
        tertiary: _accentPurple,
        onTertiary: _white,
        tertiaryContainer: Color(0xFF2E1065),
        onTertiaryContainer: _accentPurple,
        error: Color(0xFFEF4444),
        onError: _white,
        errorContainer: Color(0xFF450A0A),
        onErrorContainer: Color(0xFFFCA5A5),
        surface: _bgDark,
        onSurface: _textPrimary,
        surfaceContainerHighest: _bgCardLight,
        onSurfaceVariant: _textSecondary,
        outline: _borderColor,
        outlineVariant: Color(0xFF1E3A5F),
        inverseSurface: _white,
        onInverseSurface: _black,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _textPrimary,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: _bgCard,
        shadowColor: _black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _borderColor.withValues(alpha: 0.5)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: Color(0xFF0A1E36),
        selectedItemColor: _accentGreen,
        unselectedItemColor: _textMuted,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _bgCardLight,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: _borderColor.withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accentGreen, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFEF4444), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(color: _textSecondary, fontSize: 14),
        hintStyle: TextStyle(color: _textMuted.withValues(alpha: 0.7), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentGreen,
          foregroundColor: _black,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentGreen,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: _bgCardLight,
        contentTextStyle: const TextStyle(color: _textPrimary),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _bgCard,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentGreen,
        foregroundColor: _black,
        elevation: 8,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: _borderColor,
        thickness: 0.5,
        space: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accentGreen,
        linearTrackColor: _bgCardLight,
      ),
    );
  }

  static ThemeData get premiumLightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      scaffoldBackgroundColor: _lightBg,
      colorScheme: const ColorScheme.light(
        primary: _accentGreenDark,
        onPrimary: _white,
        primaryContainer: Color(0xFFD1FAE5),
        onPrimaryContainer: Color(0xFF052E16),
        secondary: _accentBlue,
        onSecondary: _white,
        secondaryContainer: Color(0xFFDBEAFE),
        onSecondaryContainer: Color(0xFF001D36),
        tertiary: _accentPurple,
        onTertiary: _white,
        tertiaryContainer: Color(0xFFEDE9FE),
        onTertiaryContainer: Color(0xFF1E0A3C),
        error: Color(0xFFDC2626),
        onError: _white,
        errorContainer: Color(0xFFFEE2E2),
        onErrorContainer: Color(0xFF410002),
        surface: _lightSurface,
        onSurface: _lightText,
        surfaceContainerHighest: Color(0xFFF1F5F9),
        onSurfaceVariant: _lightTextSec,
        outline: Color(0xFFCBD5E1),
        outlineVariant: Color(0xFFE2E8F0),
        inverseSurface: _black,
        onInverseSurface: _white,
      ),
      appBarTheme: const AppBarTheme(
        centerTitle: false,
        elevation: 0,
        backgroundColor: Colors.transparent,
        foregroundColor: _lightText,
        scrolledUnderElevation: 0,
      ),
      cardTheme: CardTheme(
        elevation: 0,
        color: _lightSurface,
        shadowColor: _black.withValues(alpha: 0.05),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(color: _borderColor.withValues(alpha: 0.2)),
        ),
      ),
      bottomNavigationBarTheme: const BottomNavigationBarThemeData(
        backgroundColor: _lightSurface,
        selectedItemColor: _accentGreenDark,
        unselectedItemColor: _lightTextSec,
        type: BottomNavigationBarType.fixed,
        elevation: 20,
        showUnselectedLabels: true,
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFFF1F5F9),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: BorderSide(color: const Color(0xFFCBD5E1).withValues(alpha: 0.5)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: _accentGreenDark, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(16),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 20, vertical: 18),
        labelStyle: const TextStyle(color: _lightTextSec, fontSize: 14),
        hintStyle: TextStyle(color: _lightTextSec.withValues(alpha: 0.7), fontSize: 14),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: _accentGreenDark,
          foregroundColor: _white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: _accentGreenDark,
          textStyle: const TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        backgroundColor: const Color(0xFF1E293B),
        contentTextStyle: const TextStyle(color: _white),
      ),
      dialogTheme: DialogTheme(
        backgroundColor: _lightSurface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(24),
        ),
      ),
      floatingActionButtonTheme: const FloatingActionButtonThemeData(
        backgroundColor: _accentGreenDark,
        foregroundColor: _white,
        elevation: 8,
        shape: CircleBorder(),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFFE2E8F0),
        thickness: 0.5,
        space: 0,
      ),
      progressIndicatorTheme: const ProgressIndicatorThemeData(
        color: _accentGreenDark,
        linearTrackColor: Color(0xFFE2E8F0),
      ),
    );
  }

  // Utility Colors
  static const Color accentGreen = _accentGreen;
  static const Color bgDark = _bgDark;
  static const Color bgCard = _bgCard;
  static const Color bgCardLight = _bgCardLight;
  static const Color textPrimary = _textPrimary;
  static const Color textSecondary = _textSecondary;
  static const Color textMuted = _textMuted;
  static const Color borderColor = _borderColor;
  static const Color accentBlue = _accentBlue;
  static const Color accentPurple = _accentPurple;
  static const Color accentOrange = _accentOrange;
  static const Color accentPink = _accentPink;
}
