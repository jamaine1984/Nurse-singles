import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';

/// A collection of shimmer-based loading placeholder widgets using the
/// Nurse Singles brand palette (Plum / Lavender tones).
///
/// Provides ready-made skeletons for common UI patterns:
/// - [ShimmerCard] -- card-shaped placeholder.
/// - [ShimmerList] -- vertical list of placeholder items.
/// - [ShimmerProfile] -- full profile page skeleton.
/// - [ShimmerChat] -- chat / message list skeleton.
///
/// All widgets automatically adapt to the current brightness (light/dark).

// ── Helper ──────────────────────────────────────────────────────────────────

Color _baseColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2D2640)
        : const Color(0xFFF3E8FF); // Soft Lavender

Color _highlightColor(BuildContext context) =>
    Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3D3554)
        : const Color(0xFFFFFBEB); // Cream

Widget _shimmerWrap(BuildContext context, {required Widget child}) {
  return Shimmer.fromColors(
    baseColor: _baseColor(context),
    highlightColor: _highlightColor(context),
    child: child,
  );
}

Widget _box({
  double? width,
  double? height,
  double radius = 12,
  EdgeInsetsGeometry? margin,
}) {
  return Container(
    width: width,
    height: height,
    margin: margin,
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(radius),
    ),
  );
}

Widget _circle({double radius = 24}) {
  return Container(
    width: radius * 2,
    height: radius * 2,
    decoration: const BoxDecoration(
      color: Colors.white,
      shape: BoxShape.circle,
    ),
  );
}

// ═══════════════════════════════════════════════════════════════════════════
// ShimmerCard
// ═══════════════════════════════════════════════════════════════════════════

/// A card-shaped shimmer placeholder.
class ShimmerCard extends StatelessWidget {
  const ShimmerCard({
    super.key,
    this.height = 140,
    this.width,
    this.borderRadius = 20,
    this.margin = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final double height;
  final double? width;
  final double borderRadius;
  final EdgeInsetsGeometry margin;

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      context,
      child: Container(
        width: width,
        height: height,
        margin: margin,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ShimmerList
// ═══════════════════════════════════════════════════════════════════════════

/// A vertical list of shimmer placeholder items.
///
/// Each item consists of a leading circle (avatar), two text lines, and an
/// optional trailing block.
class ShimmerList extends StatelessWidget {
  const ShimmerList({
    super.key,
    this.itemCount = 6,
    this.showTrailing = false,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  /// Number of placeholder rows.
  final int itemCount;

  /// Whether to show a trailing shimmer block on each row.
  final bool showTrailing;

  /// Outer padding.
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      context,
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(itemCount, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                children: [
                  _circle(radius: 24),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(height: 14, width: 140),
                        const SizedBox(height: 8),
                        _box(height: 10, width: 200),
                      ],
                    ),
                  ),
                  if (showTrailing) ...[
                    const SizedBox(width: 10),
                    _box(height: 30, width: 60, radius: 8),
                  ],
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ShimmerProfile
// ═══════════════════════════════════════════════════════════════════════════

/// A full-page profile skeleton.
///
/// Layout:
/// - Large cover image placeholder
/// - Circular avatar overlapping the cover
/// - Name, subtitle, and bio text lines
/// - Row of stat boxes
/// - Grid of interest chips
class ShimmerProfile extends StatelessWidget {
  const ShimmerProfile({super.key});

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      context,
      child: SingleChildScrollView(
        physics: const NeverScrollableScrollPhysics(),
        child: Column(
          children: [
            // Cover image
            _box(height: 220, radius: 0),
            // Avatar + name
            Transform.translate(
              offset: const Offset(0, -40),
              child: Column(
                children: [
                  _circle(radius: 48),
                  const SizedBox(height: 14),
                  _box(height: 20, width: 160),
                  const SizedBox(height: 8),
                  _box(height: 14, width: 120),
                  const SizedBox(height: 20),
                  // Stats row
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: List.generate(3, (_) {
                        return Column(
                          children: [
                            _box(height: 28, width: 48, radius: 8),
                            const SizedBox(height: 6),
                            _box(height: 10, width: 48),
                          ],
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Bio lines
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _box(height: 12, width: double.infinity),
                        const SizedBox(height: 8),
                        _box(height: 12, width: double.infinity),
                        const SizedBox(height: 8),
                        _box(height: 12, width: 200),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Interest chips
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: List.generate(8, (i) {
                        final widths = [70.0, 90.0, 60.0, 100.0, 80.0, 75.0, 95.0, 65.0];
                        return _box(
                          height: 32,
                          width: widths[i % widths.length],
                          radius: 16,
                        );
                      }),
                    ),
                  ),
                  const SizedBox(height: 24),
                  // Photo grid
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 24),
                    child: Row(
                      children: [
                        Expanded(child: _box(height: 120)),
                        const SizedBox(width: 8),
                        Expanded(child: _box(height: 120)),
                        const SizedBox(width: 8),
                        Expanded(child: _box(height: 120)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// ShimmerChat
// ═══════════════════════════════════════════════════════════════════════════

/// A chat / conversation list skeleton.
///
/// Shows rows with an avatar circle, two text lines (name + last message),
/// and a trailing timestamp block.
class ShimmerChat extends StatelessWidget {
  const ShimmerChat({
    super.key,
    this.itemCount = 8,
    this.padding = const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
  });

  final int itemCount;
  final EdgeInsetsGeometry padding;

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      context,
      child: Padding(
        padding: padding,
        child: Column(
          children: List.generate(itemCount, (i) {
            return Padding(
              padding: const EdgeInsets.symmetric(vertical: 10),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Avatar
                  _circle(radius: 28),
                  const SizedBox(width: 14),
                  // Name + message preview
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const SizedBox(height: 4),
                        _box(height: 14, width: 120),
                        const SizedBox(height: 8),
                        _box(height: 10, width: 220),
                      ],
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Timestamp + unread badge
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      const SizedBox(height: 4),
                      _box(height: 10, width: 40, radius: 4),
                      const SizedBox(height: 8),
                      if (i % 3 == 0) _circle(radius: 10),
                    ],
                  ),
                ],
              ),
            );
          }),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Legacy ShimmerLoader (kept for backward compat)
// ═══════════════════════════════════════════════════════════════════════════

/// Generic shimmer box or wrapper. Retained for backward compatibility.
class ShimmerLoader extends StatelessWidget {
  const ShimmerLoader({
    super.key,
    this.width,
    this.height,
    this.borderRadius = 12,
    this.child,
  });

  final double? width;
  final double? height;
  final double borderRadius;
  final Widget? child;

  @override
  Widget build(BuildContext context) {
    return _shimmerWrap(
      context,
      child: child ??
          Container(
            width: width,
            height: height,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(borderRadius),
            ),
          ),
    );
  }

  /// Card-shaped shimmer.
  static Widget card({double height = 120}) => ShimmerCard(height: height);

  /// Circular shimmer (avatar).
  static Widget circle({double radius = 24}) {
    return Builder(builder: (context) {
      return _shimmerWrap(context, child: _circle(radius: radius));
    });
  }

  /// Text-line shimmer.
  static Widget line({double width = 120, double height = 14}) {
    return Builder(builder: (context) {
      return _shimmerWrap(context, child: _box(width: width, height: height));
    });
  }
}
