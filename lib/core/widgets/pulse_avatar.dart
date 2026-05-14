import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';

/// Predefined avatar sizes.
enum AvatarSize {
  small(20),
  medium(32),
  large(52);

  const AvatarSize(this.radius);
  final double radius;
}

/// Animated circular avatar with online-status pulsing ring.
///
/// Features:
/// - [CachedNetworkImage] with shimmer loading placeholder.
/// - Pulsing green ring when the user is online.
/// - Three predefined sizes via [AvatarSize] or custom [radius].
/// - Graceful fallback to initials when no image is available.
class PulseAvatar extends StatefulWidget {
  const PulseAvatar({
    super.key,
    this.imageUrl,
    this.name,
    this.size = AvatarSize.medium,
    this.radius,
    this.isOnline = false,
    this.showPulse = true,
    this.onlineColor,
    this.offlineColor,
    this.borderWidth = 2.5,
    this.onTap,
  });

  /// Network URL for the profile image.
  final String? imageUrl;

  /// User display name; used to derive initials as a fallback.
  final String? name;

  /// Predefined size. Ignored if [radius] is non-null.
  final AvatarSize size;

  /// Custom radius override.
  final double? radius;

  /// Whether the user is currently online.
  final bool isOnline;

  /// Whether to show the pulse animation when online. Defaults to true.
  final bool showPulse;

  /// Override for the online ring colour. Defaults to emerald green.
  final Color? onlineColor;

  /// Override for the offline ring colour. Defaults to warm grey.
  final Color? offlineColor;

  /// Width of the border ring.
  final double borderWidth;

  /// Tap callback.
  final VoidCallback? onTap;

  @override
  State<PulseAvatar> createState() => _PulseAvatarState();
}

class _PulseAvatarState extends State<PulseAvatar>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;
  late final Animation<double> _scaleAnim;
  late final Animation<double> _opacityAnim;

  static const _defaultOnlineColor = Color(0xFF059669);
  static const _defaultOfflineColor = Color(0xFF78716C);

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1800),
    );
    _scaleAnim = Tween<double>(begin: 1.0, end: 1.5).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _opacityAnim = Tween<double>(begin: 0.7, end: 0.0).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeOut),
    );
    _syncAnimation();
  }

  @override
  void didUpdateWidget(covariant PulseAvatar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isOnline != oldWidget.isOnline ||
        widget.showPulse != oldWidget.showPulse) {
      _syncAnimation();
    }
  }

  void _syncAnimation() {
    if (widget.isOnline && widget.showPulse) {
      if (!_controller.isAnimating) _controller.repeat();
    } else {
      _controller.stop();
      _controller.reset();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  double get _effectiveRadius => widget.radius ?? widget.size.radius;

  Color get _ringColor {
    if (widget.isOnline) {
      return widget.onlineColor ?? _defaultOnlineColor;
    }
    return widget.offlineColor ?? _defaultOfflineColor;
  }

  String _initials() {
    final n = widget.name;
    if (n == null || n.trim().isEmpty) return '?';
    final parts = n.trim().split(RegExp(r'\s+'));
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final r = _effectiveRadius;
    final outerSize = r * 2 + widget.borderWidth * 2 + 12;

    return GestureDetector(
      onTap: widget.onTap,
      child: SizedBox(
        width: outerSize,
        height: outerSize,
        child: Stack(
          alignment: Alignment.center,
          children: [
            // ── Pulsing ring ──────────────────────────────────────────
            if (widget.isOnline && widget.showPulse)
              AnimatedBuilder(
                animation: _controller,
                builder: (context, _) {
                  return Container(
                    width: (r * 2 + widget.borderWidth * 2) *
                        _scaleAnim.value,
                    height: (r * 2 + widget.borderWidth * 2) *
                        _scaleAnim.value,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color:
                            _ringColor.withAlpha((_opacityAnim.value * 255).round()),
                        width: 3,
                      ),
                    ),
                  );
                },
              ),

            // ── Border ring ───────────────────────────────────────────
            Container(
              width: r * 2 + widget.borderWidth * 2,
              height: r * 2 + widget.borderWidth * 2,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: _ringColor,
                  width: widget.borderWidth,
                ),
              ),
              child: ClipOval(child: _buildImage(r)),
            ),

            // ── Online dot indicator ──────────────────────────────────
            if (widget.isOnline)
              Positioned(
                right: outerSize * 0.08,
                bottom: outerSize * 0.08,
                child: Container(
                  width: r * 0.45,
                  height: r * 0.45,
                  decoration: BoxDecoration(
                    color: _ringColor,
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: Theme.of(context).scaffoldBackgroundColor,
                      width: 2,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildImage(double r) {
    final url = widget.imageUrl;
    if (url != null && url.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: url,
        width: r * 2,
        height: r * 2,
        fit: BoxFit.cover,
        placeholder: (_, __) => _buildShimmer(r),
        errorWidget: (_, __, ___) => _buildInitials(r),
      );
    }
    return _buildInitials(r);
  }

  Widget _buildShimmer(double r) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Shimmer.fromColors(
      baseColor: isDark ? const Color(0xFF2D2640) : const Color(0xFFE7E5E4),
      highlightColor:
          isDark ? const Color(0xFF3D3554) : const Color(0xFFF5F5F4),
      child: Container(
        width: r * 2,
        height: r * 2,
        decoration: const BoxDecoration(
          color: Colors.white,
          shape: BoxShape.circle,
        ),
      ),
    );
  }

  Widget _buildInitials(double r) {
    return Container(
      width: r * 2,
      height: r * 2,
      color: AppTheme.softLavender,
      alignment: Alignment.center,
      child: Text(
        _initials(),
        style: TextStyle(
          color: AppTheme.deepPlum,
          fontWeight: FontWeight.w700,
          fontSize: r * 0.55,
        ),
      ),
    );
  }
}
