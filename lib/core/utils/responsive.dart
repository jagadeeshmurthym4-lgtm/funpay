import 'package:flutter/material.dart';

/// Provides responsive sizing and scaling for all UI elements.
///
/// Uses a reference screen width of 375dp (iPhone SE) as the baseline.
/// All dimensions are proportional to the actual screen width, and
/// font sizes can optionally respect the device's text scale factor.
///
/// Usage:
/// ```dart
/// final rs = ResponsiveSize(context);
/// Text('Hello', style: TextStyle(fontSize: rs.fs(16)));
/// SizedBox(height: rs.h(20));
/// ```
class ResponsiveSize {
  final BuildContext context;

  /// Reference width (iPhone SE / small Android ~ 375dp).
  static const double _referenceWidth = 375.0;

  /// Minimum scale factor to prevent elements from becoming too small.
  static const double _minScale = 0.85;

  /// Maximum scale factor to prevent elements from becoming too large.
  static const double _maxScale = 1.3;

  ResponsiveSize(this.context);

  // ─── Screen size ─────────────────────────────────────────

  double get screenWidth => MediaQuery.of(context).size.width;
  double get screenHeight => MediaQuery.of(context).size.height;
  double get textScaleFactor => MediaQuery.textScalerOf(context).scale(1.0);

  // ─── Raw scale factor (width-based) ───────────────────────

  /// The width-based scale factor, clamped between [_minScale] and [_maxScale].
  double get scale =>
      (screenWidth / _referenceWidth).clamp(_minScale, _maxScale);

  // ─── Scaled helpers ───────────────────────────────────────

  /// Scale a font [size] by the width-based scale factor AND the device's
  /// text scale factor. Use this for body text and labels so the user's
  /// system font size preference is respected.
  ///
  /// The text scale factor is squared to make it slightly less aggressive
  /// than the raw system setting, preventing absurd sizes on extreme settings.
  double fs(double size) {
    final textScale = textScaleFactor.clamp(0.8, 1.3);
    return size * scale * textScale;
  }

  /// Scale a font [size] by the width-based factor ONLY, ignoring the
  /// device text scale. Use this for fixed UI elements (badges, tab labels,
  /// button text) that should not balloon with system font settings.
  double ffs(double size) => size * scale;

  /// Scale a height/spacing dimension.
  double h(double size) => size * scale;

  /// Scale a width dimension.
  double w(double size) => size * scale;

  /// Scale a radius value.
  double r(double size) => size * scale;

  /// Scale padding or margin uniformly.
  EdgeInsets pad(double all) => EdgeInsets.all(all * scale);

  /// Scale horizontal + vertical padding.
  EdgeInsets padSym({double h = 0, double v = 0}) =>
      EdgeInsets.symmetric(horizontal: h * scale, vertical: v * scale);

  /// Scale only horizontal padding.
  EdgeInsets padH(double value) =>
      EdgeInsets.symmetric(horizontal: value * scale);

  /// Scale only vertical padding.
  EdgeInsets padV(double value) =>
      EdgeInsets.symmetric(vertical: value * scale);

  /// Scale width value.
  double width(double value) => value * scale;

  /// Scale height value.
  double height(double value) => value * scale;

  // ─── Convenience TextStyle builders ───────────────────────

  /// Build a responsive text style that respects user font size.
  TextStyle textStyle({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: fs(size),
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  /// Build a responsive text style that IGNORES user font size
  /// (for fixed UI elements).
  TextStyle fixedTextStyle({
    required double size,
    FontWeight weight = FontWeight.normal,
    Color? color,
    double? letterSpacing,
    double? height,
  }) {
    return TextStyle(
      fontSize: ffs(size),
      fontWeight: weight,
      color: color,
      letterSpacing: letterSpacing,
      height: height,
    );
  }

  // ─── Presets ──────────────────────────────────────────────

  /// Heading 1 — large title (e.g. screen title, wallet balance).
  TextStyle get h1 => textStyle(size: 32, weight: FontWeight.w800);

  /// Heading 2 — medium title (e.g. section headers).
  TextStyle get h2 => textStyle(size: 20, weight: FontWeight.w800);

  /// Heading 3 — small heading (e.g. card titles).
  TextStyle get h3 => textStyle(size: 16, weight: FontWeight.w700);

  /// Body — standard text.
  TextStyle get body => textStyle(size: 14, weight: FontWeight.w500);

  /// Body small — secondary text.
  TextStyle get bodySmall => textStyle(size: 12, weight: FontWeight.w500);

  /// Caption — tiny labels, timestamps, counts.
  TextStyle get caption => textStyle(size: 11, weight: FontWeight.w500);

  /// Tiny — badges, small chips.
  TextStyle get tiny => textStyle(size: 10, weight: FontWeight.w700);

  /// Micro — the smallest readable text (tab count badges).
  TextStyle get micro => textStyle(size: 9, weight: FontWeight.w700);

  /// Large button text.
  TextStyle get button => fixedTextStyle(size: 15, weight: FontWeight.w800);

  /// Small button text.
  TextStyle get buttonSmall =>
      fixedTextStyle(size: 13, weight: FontWeight.w700);

  // ── Spacing Presets ──────────────────────────────────────

  double get spaceXs => 4 * scale;
  double get spaceSm => 8 * scale;
  double get spaceMd => 12 * scale;
  double get spaceLg => 16 * scale;
  double get spaceXl => 20 * scale;
  double get spaceXxl => 24 * scale;
  double get spaceXxxl => 32 * scale;

  // ── Sizing Presets ───────────────────────────────────────

  double get iconXs => 16 * scale;
  double get iconSm => 20 * scale;
  double get iconMd => 24 * scale;
  double get iconLg => 36 * scale;

  double get avatarXs => 28 * scale;
  double get avatarSm => 34 * scale;
  double get avatarMd => 40 * scale;
  double get avatarLg => 72 * scale;

  double get cardRadiusSm => 10 * scale;
  double get cardRadiusMd => 14 * scale;
  double get cardRadiusLg => 16 * scale;
  double get cardRadiusXl => 24 * scale;
}

/// Extension on [BuildContext] for easy access.
///
/// Example: `context.responsive.fs(16)`
extension ResponsiveContext on BuildContext {
  ResponsiveSize get responsive => ResponsiveSize(this);
}
