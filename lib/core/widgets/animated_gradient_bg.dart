import 'package:flutter/material.dart';

/// Animated flowing gradient background widget.
///
/// Uses [AnimationController] with [TweenSequence] for smooth continuous
/// color transitions between clinical teal, sky blue, and soft amber.
/// Adapts automatically to light and dark modes.
class AnimatedGradientBg extends StatefulWidget {
  const AnimatedGradientBg({
    super.key,
    required this.child,
    this.colors,
    this.duration = const Duration(seconds: 8),
    this.intensity = 0.15,
  });

  /// The widget to display on top of the gradient.
  final Widget child;

  /// Override default brand colours. When null the widget picks theme-aware
  /// defaults derived from the hospital brand palette.
  final List<Color>? colors;

  /// Total duration of one full animation cycle (forward + reverse).
  final Duration duration;

  /// How visible the animated colours are (0.0 = transparent, 1.0 = opaque).
  /// Defaults to 0.15 for a subtle wash.
  final double intensity;

  @override
  State<AnimatedGradientBg> createState() => _AnimatedGradientBgState();
}

class _AnimatedGradientBgState extends State<AnimatedGradientBg>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  // TweenSequence animations for smooth multi-stop colour transitions.
  late final Animation<Color?> _colorA;
  late final Animation<Color?> _colorB;
  late final Animation<Color?> _colorC;
  late final Animation<Alignment> _beginAlignment;
  late final Animation<Alignment> _endAlignment;

  // ── Light-mode brand colours ──────────────────────────────────────────
  static const _lightPlum = Color(0xFF0F766E);
  static const _lightRose = Color(0xFF0284C7);
  static const _lightAmber = Color(0xFFF59E0B);
  static const _lightLavender = Color(0xFFDDF7F4);
  static const _lightCream = Color(0xFFF6FBFB);

  // ── Dark-mode brand colours (deeper, muted) ───────────────────────────
  static const _darkPlum = Color(0xFF0F766E);
  static const _darkRose = Color(0xFF0369A1);
  static const _darkAmber = Color(0xFF92400E);
  static const _darkMidnight = Color(0xFF061A23);
  static const _darkSurface = Color(0xFF082F3A);

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(vsync: this, duration: widget.duration)
      ..repeat(reverse: true);

    // ── Colour A: shifts from Plum → Rose → Plum ────────────────────────
    _colorA = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: _lightPlum, end: _lightRose),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _lightRose, end: _lightPlum),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // ── Colour B: shifts from Rose → Amber → Rose ───────────────────────
    _colorB = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: _lightRose, end: _lightAmber),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _lightAmber, end: _lightRose),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // ── Colour C: shifts from Amber → Plum → Amber ─────────────────────
    _colorC = TweenSequence<Color?>([
      TweenSequenceItem(
        tween: ColorTween(begin: _lightAmber, end: _lightPlum),
        weight: 50,
      ),
      TweenSequenceItem(
        tween: ColorTween(begin: _lightPlum, end: _lightAmber),
        weight: 50,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    // ── Alignment animation for subtle movement ─────────────────────────
    _beginAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topLeft, end: Alignment.topRight),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.topRight, end: Alignment.centerLeft),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.centerLeft, end: Alignment.topLeft),
        weight: 34,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));

    _endAlignment = TweenSequence<Alignment>([
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomRight, end: Alignment.bottomLeft),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.bottomLeft, end: Alignment.centerRight),
        weight: 33,
      ),
      TweenSequenceItem(
        tween: Tween(begin: Alignment.centerRight, end: Alignment.bottomRight),
        weight: 34,
      ),
    ]).animate(CurvedAnimation(parent: _controller, curve: Curves.easeInOut));
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final alpha = (widget.intensity * 255).round().clamp(0, 255);

    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        // If the caller supplied custom colours, use those directly.
        if (widget.colors != null && widget.colors!.length >= 2) {
          return Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: _beginAlignment.value,
                end: _endAlignment.value,
                colors: widget.colors!,
              ),
            ),
            child: child,
          );
        }

        // Theme-aware auto colours.
        final List<Color> gradientColors;
        if (isDark) {
          gradientColors = [
            _darkMidnight,
            Color.lerp(
              _darkPlum,
              _darkRose,
              _controller.value,
            )!.withAlpha(alpha + 40),
            Color.lerp(
              _darkRose,
              _darkAmber,
              _controller.value,
            )!.withAlpha(alpha + 30),
            _darkSurface,
          ];
        } else {
          gradientColors = [
            _lightCream,
            (_colorA.value ?? _lightPlum).withAlpha(alpha),
            (_colorB.value ?? _lightRose).withAlpha(alpha),
            (_colorC.value ?? _lightAmber).withAlpha(alpha ~/ 2),
            _lightLavender.withAlpha(alpha + 20),
          ];
        }

        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: _beginAlignment.value,
              end: _endAlignment.value,
              colors: gradientColors,
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}
