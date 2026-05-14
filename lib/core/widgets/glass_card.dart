import 'dart:ui';
import 'package:flutter/material.dart';

/// A frosted-glass card widget with backdrop blur, rounded corners, and an
/// optional gradient overlay.
///
/// Works beautifully in both light and dark modes by adapting its surface
/// colour, border, and gradient tints to the current [ThemeData.brightness].
class GlassCard extends StatelessWidget {
  const GlassCard({
    super.key,
    required this.child,
    this.padding,
    this.margin,
    this.borderRadius = 24,
    this.blur = 16,
    this.opacity = 0.12,
    this.borderColor,
    this.color,
    this.gradient,
    this.showGradientOverlay = false,
    this.width,
    this.height,
    this.onTap,
  });

  /// Content inside the card.
  final Widget child;

  /// Inner padding. Defaults to `EdgeInsets.all(20)`.
  final EdgeInsetsGeometry? padding;

  /// Outer margin.
  final EdgeInsetsGeometry? margin;

  /// Corner radius. Defaults to 24.
  final double borderRadius;

  /// Backdrop blur sigma. Defaults to 16.
  final double blur;

  /// Surface opacity (0.0 = fully transparent, 1.0 = fully opaque).
  final double opacity;

  /// Override for the thin border colour.
  final Color? borderColor;

  /// Override for the surface fill colour.
  final Color? color;

  /// An explicit gradient overlay. If non-null, takes precedence over
  /// [showGradientOverlay].
  final Gradient? gradient;

  /// When true, a subtle hospital-brand gradient overlay is drawn on top of
  /// the frosted surface. Ignored when [gradient] is non-null.
  final bool showGradientOverlay;

  /// Optional fixed width.
  final double? width;

  /// Optional fixed height.
  final double? height;

  /// Optional tap callback.
  final VoidCallback? onTap;

  // ── Brand colours ───────────────────────────────────────────────────
  static const _plum = Color(0xFF0F766E);
  static const _rose = Color(0xFF0284C7);

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;

    // Surface fill
    final effectiveColor =
        color ??
        (isDark
            ? Colors.white.withAlpha((opacity * 255).round())
            : Colors.white.withAlpha(
                ((opacity + 0.25) * 255).round().clamp(0, 255),
              ));

    // Border colour
    final effectiveBorder =
        borderColor ??
        (isDark ? Colors.white.withAlpha(30) : Colors.white.withAlpha(60));

    // Gradient overlay
    final effectiveGradient =
        gradient ??
        (showGradientOverlay
            ? LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: isDark
                    ? [_plum.withAlpha(25), _rose.withAlpha(15)]
                    : [_plum.withAlpha(12), _rose.withAlpha(8)],
              )
            : null);

    final card = ClipRRect(
      borderRadius: BorderRadius.circular(borderRadius),
      child: BackdropFilter(
        filter: ImageFilter.blur(sigmaX: blur, sigmaY: blur),
        child: Container(
          width: width,
          height: height,
          decoration: BoxDecoration(
            color: effectiveColor,
            gradient: effectiveGradient,
            borderRadius: BorderRadius.circular(borderRadius),
            border: Border.all(color: effectiveBorder, width: 1),
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(40)
                    : _plum.withAlpha(10),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          padding: padding ?? const EdgeInsets.all(20),
          child: child,
        ),
      ),
    );

    return Container(
      margin: margin,
      child: onTap != null ? GestureDetector(onTap: onTap, child: card) : card,
    );
  }
}
