import 'package:cashspark/core/theme/app_theme.dart';
import 'package:flutter/material.dart';

// ─── PREMIUM GLASS (Alias for backward compatibility) ────────
class PremiumGlass extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final LinearGradient? gradient;
  final Color? backgroundColor;
  final Color? borderColor;
  final double blur;

  const PremiumGlass({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.gradient,
    this.backgroundColor,
    this.borderColor,
    this.blur = 20,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: margin,
      padding: padding ?? const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient,
        color: gradient == null
            ? (backgroundColor ?? (isDark ? AppTheme.bgCard : Colors.white)).withValues(alpha: 0.85)
            : null,
        border: Border.all(
          color: borderColor ??
              (isDark ? AppTheme.borderColor.withValues(alpha: 0.4) : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: blur,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── PREMIUM APP BAR ──────────────────────────────────────────
class PremiumAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onBack;
  final List<Widget>? actions;
  final Widget? bottom;
  final double? toolbarHeight;

  const PremiumAppBar({
    super.key,
    required this.title,
    this.onBack,
    this.actions,
    this.bottom,
    this.toolbarHeight,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return AppBar(
      title: Text(
        title,
        style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
      ),
      leading: onBack != null
          ? IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded),
              onPressed: onBack,
            )
          : null,
      actions: actions,
      bottom: bottom is PreferredSizeWidget
          ? bottom as PreferredSizeWidget?
          : bottom != null
              ? PreferredSize(
                  preferredSize: const Size.fromHeight(48),
                  child: bottom!,
                )
              : null,
      toolbarHeight: toolbarHeight,
    );
  }

  @override
  Size get preferredSize => Size.fromHeight(
        (toolbarHeight ?? kToolbarHeight) + (bottom != null ? (bottom is PreferredSizeWidget ? (bottom as PreferredSizeWidget).preferredSize.height : 48) : 0),
      );
}

// ─── PREMIUM LOADER ──────────────────────────────────────────
class PremiumLoader extends StatelessWidget {
  final double size;
  final String? message;

  const PremiumLoader({super.key, this.size = 36, this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          SizedBox(
            width: size,
            height: size,
            child: CircularProgressIndicator(
              strokeWidth: 3,
              color: theme.colorScheme.primary,
            ),
          ),
          if (message != null) ...[
            const SizedBox(height: 12),
            Text(
              message!,
              style: theme.textTheme.bodySmall?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SUCCESS ANIMATION ───────────────────────────────────────
class SuccessAnimation extends StatefulWidget {
  final double size;

  const SuccessAnimation({super.key, this.size = 60});

  @override
  State<SuccessAnimation> createState() => _SuccessAnimationState();
}

class _SuccessAnimationState extends State<SuccessAnimation>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnim;
  late Animation<double> _opacityAnim;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
    _scaleAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.elasticOut),
    );
    _opacityAnim = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _controller, curve: const Interval(0.0, 0.3, curve: Curves.easeIn)),
    );
    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: Container(
              width: widget.size,
              height: widget.size,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
                boxShadow: [
                  BoxShadow(
                    color: Colors.white.withValues(alpha: 0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Icon(
                Icons.check_circle_rounded,
                size: widget.size * 0.6,
                color: Colors.white,
              ),
            ),
          ),
        );
      },
    );
  }
}

// ─── GLASS CONTAINER ──────────────────────────────────────────
class GlassContainer extends StatelessWidget {
  final Widget child;
  final double? width;
  final double? height;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final double blur;
  final List<Color>? gradient;
  final Color? borderColor;

  const GlassContainer({
    super.key,
    required this.child,
    this.width,
    this.height,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.blur = 20,
    this.gradient,
    this.borderColor,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: width,
      height: height,
      margin: margin,
      padding: padding ?? const EdgeInsets.all(20),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(borderRadius),
        gradient: gradient != null
            ? LinearGradient(colors: gradient!, begin: Alignment.topLeft, end: Alignment.bottomRight)
            : null,
        color: gradient == null
            ? (isDark ? AppTheme.bgCard : Colors.white).withValues(alpha: 0.85)
            : null,
        border: Border.all(
          color: borderColor ??
              (isDark ? AppTheme.borderColor.withValues(alpha: 0.4) : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
          width: 0.5,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withValues(alpha: 0.25) : Colors.black.withValues(alpha: 0.04),
            blurRadius: blur,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: child,
    );
  }
}

// ─── PREMIUM CARD ─────────────────────────────────────────────
class PremiumCard extends StatelessWidget {
  final Widget child;
  final EdgeInsetsGeometry? padding;
  final EdgeInsetsGeometry? margin;
  final double borderRadius;
  final VoidCallback? onTap;
  final Color? gradientStart;
  final Color? gradientEnd;
  final Color? borderColor;
  final List<BoxShadow>? shadows;
  final LinearGradient? gradient;
  final BoxBorder? border;

  const PremiumCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 20,
    this.onTap,
    this.gradientStart,
    this.gradientEnd,
    this.borderColor,
    this.shadows,
    this.gradient,
    this.border,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final hasGradient = gradientStart != null && gradientEnd != null;

    return Padding(
      padding: margin ?? EdgeInsets.zero,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(borderRadius),
          child: Container(
            padding: padding ?? const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(borderRadius),
              gradient: gradient ?? (hasGradient
                  ? LinearGradient(
                      colors: [gradientStart!, gradientEnd!],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    )
                  : null),
              color: (gradient != null || hasGradient) ? null : (isDark ? AppTheme.bgCard : Colors.white),
              border: border ??
                  Border.all(
                    color: borderColor ??
                        (isDark ? AppTheme.borderColor.withValues(alpha: 0.5) : const Color(0xFFCBD5E1).withValues(alpha: 0.3)),
                  ),
              boxShadow: shadows ??
                  [
                    BoxShadow(
                      color: isDark ? Colors.black.withValues(alpha: 0.2) : Colors.black.withValues(alpha: 0.03),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                  ],
            ),
            child: child,
          ),
        ),
      ),
    );
  }
}

// ─── GRADIENT BUTTON ──────────────────────────────────────────
class GradientButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final IconData? icon;
  final Color? color;
  final LinearGradient? gradient;
  final Color? textColor;
  final double? width;
  final double height;
  final double borderRadius;
  final bool isLoading;
  final double? fontSize;
  final double? iconSize;

  const GradientButton({
    super.key,
    required this.label,
    this.onPressed,
    this.icon,
    this.color,
    this.gradient,
    this.textColor,
    this.width,
    this.height = 52,
    this.borderRadius = 16,
    this.isLoading = false,
    this.fontSize,
    this.iconSize,
  });

  @override
  Widget build(BuildContext context) {
    final btnColor = color ?? AppTheme.accentGreen;
    final txtColor = textColor ?? Colors.black;
    return SizedBox(
      width: width ?? double.infinity,
      height: height,
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(borderRadius),
          gradient: gradient ??
              LinearGradient(
                colors: [btnColor, btnColor.withValues(alpha: 0.8)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
          boxShadow: [
            BoxShadow(
              color: btnColor.withValues(alpha: 0.3),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: (onPressed != null && !isLoading) ? onPressed : null,
            borderRadius: BorderRadius.circular(borderRadius),
            child: Center(
              child: isLoading
                  ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2.5,
                        color: Colors.black,
                      ),
                    )
                  : FittedBox(
                      // Scales the label+icon down (never up) so the button
                      // content can't overflow its container on small screens.
                      fit: BoxFit.scaleDown,
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (icon != null) ...[
                            Icon(icon, size: iconSize ?? 20, color: txtColor),
                            const SizedBox(width: 8),
                          ],
                          Text(
                            label,
                            maxLines: 1,
                            softWrap: false,
                            style: TextStyle(
                              color: txtColor,
                              fontSize: fontSize ?? 16,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── ANIMATED COUNTER ─────────────────────────────────────────
class AnimatedCounter extends StatelessWidget {
  final double value;
  final String prefix;
  final String suffix;
  final TextStyle? style;
  final int decimals;
  final Duration duration;

  const AnimatedCounter({
    super.key,
    required this.value,
    this.prefix = '',
    this.suffix = '',
    this.style,
    this.decimals = 0,
    this.duration = const Duration(milliseconds: 800),
  });

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0, end: value),
      duration: duration,
      curve: Curves.easeOutCubic,
      builder: (context, val, child) {
        return Text(
          '$prefix${val.toStringAsFixed(decimals)}$suffix',
          style: style,
        );
      },
    );
  }
}

// ─── PREMIUM STAT CARD ────────────────────────────────────────
class PremiumStatCard extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final Color color;
  final VoidCallback? onTap;

  const PremiumStatCard({
    super.key,
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return PremiumCard(
      onTap: onTap,
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          IconContainer(icon: icon, color: color, containerSize: 44),
          const SizedBox(height: 12),
          AnimatedCounter(
            value: double.tryParse(value.replaceAll(RegExp(r'[^0-9.]'), '')) ?? 0,
            prefix: value.startsWith('₹') ? '₹' : '',
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: theme.textTheme.bodySmall?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── PREMIUM EMPTY STATE ──────────────────────────────────────
class PremiumEmptyState extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final String? actionLabel;
  final VoidCallback? onAction;

  const PremiumEmptyState({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle = '',
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.08),
            ),
            child: Icon(
              icon,
              size: 40,
              color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            title,
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            textAlign: TextAlign.center,
          ),
          if (subtitle.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
              ),
              textAlign: TextAlign.center,
            ),
          ],
          if (actionLabel != null && onAction != null) ...[
            const SizedBox(height: 24),
            GradientButton(
              label: actionLabel!,
              onPressed: onAction,
              width: 200,
              height: 44,
            ),
          ],
        ],
      ),
    );
  }
}

// ─── SECTION HEADER ───────────────────────────────────────────
class SectionHeader extends StatelessWidget {
  final String title;
  final String? actionLabel;
  final VoidCallback? onAction;

  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Padding(
      padding: const EdgeInsets.only(left: 4, bottom: 12),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w700,
              color: isDark ? Colors.white : const Color(0xFF0F172A),
            ),
          ),
          if (actionLabel != null)
            GestureDetector(
              onTap: onAction,
              child: Text(
                actionLabel!,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: isDark ? AppTheme.accentGreen : AppTheme.accentGreen,
                ),
              ),
            ),
        ],
      ),
    );
  }
}

// ─── SHIMMER CONTAINER ────────────────────────────────────────
class ShimmerContainer extends StatefulWidget {
  final double? width;
  final double height;
  final double borderRadius;

  const ShimmerContainer({
    super.key,
    this.width,
    required this.height,
    this.borderRadius = 12,
  });

  @override
  State<ShimmerContainer> createState() => _ShimmerContainerState();
}

class _ShimmerContainerState extends State<ShimmerContainer>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1500),
    )..repeat();
    _animation = Tween<double>(begin: -2, end: 2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOutSine),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final baseColor = isDark ? AppTheme.bgCardLight : const Color(0xFFE2E8F0);
    final highlightColor = isDark ? AppTheme.bgCard : const Color(0xFFF1F5F9);

    return AnimatedBuilder(
      animation: _animation,
      builder: (context, child) {
        return ShaderMask(
          blendMode: BlendMode.srcATop,
          shaderCallback: (bounds) {
            return LinearGradient(
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
              colors: [baseColor, highlightColor, highlightColor, baseColor],
              stops: [
                0.0,
                (0.5 + _animation.value * 0.25).clamp(0.0, 1.0),
                (0.6 + _animation.value * 0.25).clamp(0.0, 1.0),
                1.0,
              ],
            ).createShader(bounds);
          },
          child: child!,
        );
      },
      child: Container(
        width: widget.width ?? double.infinity,
        height: widget.height,
        decoration: BoxDecoration(
          color: baseColor,
          borderRadius: BorderRadius.circular(widget.borderRadius),
        ),
      ),
    );
  }
}

// ─── STATUS BADGE ─────────────────────────────────────────────
class StatusBadge extends StatelessWidget {
  final String label;
  final Color color;
  final double fontSize;
  final double horizontalPadding;

  const StatusBadge({
    super.key,
    required this.label,
    required this.color,
    this.fontSize = 10,
    this.horizontalPadding = 8,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: EdgeInsets.symmetric(
        horizontal: horizontalPadding,
        vertical: 3,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label.toUpperCase(),
        style: TextStyle(
          fontSize: fontSize,
          fontWeight: FontWeight.w700,
          color: color,
          letterSpacing: 0.5,
        ),
      ),
    );
  }}

// ─── STANDARDIZED ICON CONTAINER ─────────────────────────────
/// A consistent icon container used throughout the app.
/// Always 44×44 with border radius 12, icon size 24, and centered content.
/// The icon is perfectly centered both horizontally and vertically
/// with equal padding on all sides.
class IconContainer extends StatelessWidget {
  final IconData icon;
  final Color color;
  final double size;
  final double containerSize;
  final double borderRadius;

  const IconContainer({
    super.key,
    required this.icon,
    required this.color,
    this.size = 24,
    this.containerSize = 44,
    this.borderRadius = 12,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: containerSize,
      height: containerSize,
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(borderRadius),
      ),
      child: Center(
        child: Icon(icon, color: color, size: size),
      ),
    );
  }
}

class VerifiedBadge extends StatelessWidget {
  final double size;

  const VerifiedBadge({super.key, this.size = 18});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: const LinearGradient(
          colors: [Color(0xFF3B82F6), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF3B82F6).withValues(alpha: 0.3),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: const Icon(Icons.check, size: 12, color: Colors.white),
    );
  }
}

// ─── PROGRESS INDICATOR ───────────────────────────────────────
class PremiumProgressBar extends StatelessWidget {
  final double value;
  final double height;
  final Color? color;

  const PremiumProgressBar({
    super.key,
    required this.value,
    this.height = 8,
    this.color,
  });

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final barColor = color ?? (isDark ? AppTheme.accentGreen : AppTheme.accentGreen);

    return ClipRRect(
      borderRadius: BorderRadius.circular(height / 2),
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: isDark ? AppTheme.borderColor : const Color(0xFFE2E8F0),
        valueColor: AlwaysStoppedAnimation<Color>(barColor),
      ),
    );
  }
}
