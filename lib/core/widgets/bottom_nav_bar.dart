import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/night_mode_wrapper.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Tab definitions
// ═══════════════════════════════════════════════════════════════════════════

enum NavTab {
  discover(Icons.favorite_rounded, 'Discover'),
  matches(Icons.auto_awesome_rounded, 'Matches'),
  messages(Icons.chat_bubble_rounded, 'Messages'),
  video(Icons.videocam_rounded, 'Video'),
  profile(Icons.person_rounded, 'Profile');

  const NavTab(this.icon, this.label);
  final IconData icon;
  final String label;
}

// ═══════════════════════════════════════════════════════════════════════════
// NurseSinglesBottomNavBar
// ═══════════════════════════════════════════════════════════════════════════

/// Custom animated bottom navigation bar for Nurse Singles.
///
/// Features:
/// - 5 tabs: Discover, Matches, Messages, Video, Profile.
/// - Active tab shows Deep Plum colour with a soft glow effect.
/// - Animated scale + fade on tab switch.
/// - Unread badge on Messages tab.
/// - Night-owl moon indicator when night mode is active.
/// - Floating heart FAB in the centre area (Rose colour) for quick actions
///   like superlike and boost.
class NightingaleBottomNavBar extends ConsumerStatefulWidget {
  const NightingaleBottomNavBar({
    super.key,
    required this.currentIndex,
    required this.onTabSelected,
    this.unreadMessageCount = 0,
    this.onFabPressed,
    this.onSuperLikePressed,
    this.onBoostPressed,
  });

  /// Currently active tab index (0-4).
  final int currentIndex;

  /// Called when the user taps a tab.
  final ValueChanged<int> onTabSelected;

  /// Badge count shown on the Messages tab. 0 hides the badge.
  final int unreadMessageCount;

  /// Called when the centre FAB is tapped (short press).
  final VoidCallback? onFabPressed;

  /// Called when the user selects "Super Like" from the FAB menu.
  final VoidCallback? onSuperLikePressed;

  /// Called when the user selects "Boost" from the FAB menu.
  final VoidCallback? onBoostPressed;

  @override
  ConsumerState<NightingaleBottomNavBar> createState() =>
      _NightingaleBottomNavBarState();
}

class _NightingaleBottomNavBarState
    extends ConsumerState<NightingaleBottomNavBar>
    with TickerProviderStateMixin {
  late final List<AnimationController> _scaleControllers;
  late final List<Animation<double>> _scaleAnimations;
  bool _fabMenuOpen = false;

  @override
  void initState() {
    super.initState();
    _scaleControllers = List.generate(NavTab.values.length, (i) {
      final c = AnimationController(
        vsync: this,
        duration: const Duration(milliseconds: 250),
      );
      if (i == widget.currentIndex) c.forward();
      return c;
    });
    _scaleAnimations = _scaleControllers
        .map(
          (c) => Tween<double>(
            begin: 1.0,
            end: 1.18,
          ).animate(CurvedAnimation(parent: c, curve: Curves.easeOutBack)),
        )
        .toList();
  }

  @override
  void didUpdateWidget(covariant NightingaleBottomNavBar oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.currentIndex != widget.currentIndex) {
      _scaleControllers[oldWidget.currentIndex].reverse();
      _scaleControllers[widget.currentIndex].forward();
    }
  }

  @override
  void dispose() {
    for (final c in _scaleControllers) {
      c.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final nightState = ref.watch(nightModeProvider);
    final isNightMode = nightState.isNightMode;

    final bgColor = isDark ? const Color(0xFF1A1523) : Colors.white;
    final activePlum = isDark ? const Color(0xFF0284C7) : AppTheme.deepPlum;
    final inactiveColor = isDark ? const Color(0xFFA8A29E) : AppTheme.warmGray;

    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.bottomCenter,
      children: [
        // ── FAB popup menu (shown above the bar) ───────────────────────
        if (_fabMenuOpen) ...[
          // Scrim
          Positioned.fill(
            child: GestureDetector(
              onTap: () => setState(() => _fabMenuOpen = false),
              child: const SizedBox.expand(),
            ),
          ),
          // Menu items
          Positioned(
            bottom: 80,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                _FabMenuItem(
                  icon: Icons.bolt_rounded,
                  label: 'Boost',
                  color: AppTheme.softAmber,
                  onTap: () {
                    setState(() => _fabMenuOpen = false);
                    widget.onBoostPressed?.call();
                  },
                ),
                const SizedBox(height: 10),
                _FabMenuItem(
                  icon: Icons.auto_awesome_rounded,
                  label: 'Super Like',
                  color: const Color(0xFF06B6D4),
                  onTap: () {
                    setState(() => _fabMenuOpen = false);
                    widget.onSuperLikePressed?.call();
                  },
                ),
                const SizedBox(height: 12),
              ],
            ),
          ),
        ],

        // ── Navigation bar ─────────────────────────────────────────────
        Container(
          height: 72,
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: isDark
                    ? Colors.black.withAlpha(60)
                    : AppTheme.deepPlum.withAlpha(15),
                blurRadius: 20,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              children: List.generate(NavTab.values.length, (i) {
                final tab = NavTab.values[i];
                final isActive = i == widget.currentIndex;

                return Expanded(
                  child: GestureDetector(
                    behavior: HitTestBehavior.opaque,
                    onTap: () => widget.onTabSelected(i),
                    child: AnimatedBuilder(
                      animation: _scaleAnimations[i],
                      builder: (context, child) {
                        return Transform.scale(
                          scale: _scaleAnimations[i].value,
                          child: child,
                        );
                      },
                      child: AnimatedOpacity(
                        opacity: isActive ? 1.0 : 0.6,
                        duration: const Duration(milliseconds: 200),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Icon with optional badge and glow
                            Stack(
                              clipBehavior: Clip.none,
                              children: [
                                // Glow behind active icon
                                if (isActive)
                                  Positioned.fill(
                                    child: Container(
                                      decoration: BoxDecoration(
                                        shape: BoxShape.circle,
                                        boxShadow: [
                                          BoxShadow(
                                            color: activePlum.withAlpha(60),
                                            blurRadius: 16,
                                            spreadRadius: 2,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                Icon(
                                  tab.icon,
                                  size: 26,
                                  color: isActive ? activePlum : inactiveColor,
                                ),
                                // Unread badge on Messages
                                if (tab == NavTab.messages &&
                                    widget.unreadMessageCount > 0)
                                  Positioned(
                                    top: -4,
                                    right: -8,
                                    child: Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 5,
                                        vertical: 1,
                                      ),
                                      decoration: BoxDecoration(
                                        color: AppTheme.warmRose,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      constraints: const BoxConstraints(
                                        minWidth: 18,
                                        minHeight: 14,
                                      ),
                                      child: Text(
                                        widget.unreadMessageCount > 99
                                            ? '99+'
                                            : '${widget.unreadMessageCount}',
                                        textAlign: TextAlign.center,
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            // Label + optional night owl indicator
                            Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (isNightMode && tab == NavTab.discover)
                                  Padding(
                                    padding: const EdgeInsets.only(right: 2),
                                    child: Icon(
                                      Icons.nightlight_round,
                                      size: 10,
                                      color: isActive
                                          ? AppTheme.softAmber
                                          : inactiveColor,
                                    ),
                                  ),
                                Text(
                                  tab.label,
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: isActive
                                        ? FontWeight.w700
                                        : FontWeight.w400,
                                    color: isActive
                                        ? activePlum
                                        : inactiveColor,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                );
              }),
            ),
          ),
        ),

        // ── Floating heart FAB ─────────────────────────────────────────
        Positioned(
          bottom: 42,
          child: GestureDetector(
            onTap: () {
              if (widget.onSuperLikePressed != null ||
                  widget.onBoostPressed != null) {
                setState(() => _fabMenuOpen = !_fabMenuOpen);
              } else {
                widget.onFabPressed?.call();
              }
            },
            child: Container(
              width: 56,
              height: 56,
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFFDC2626), Color(0xFFF43F5E)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.warmRose.withAlpha(80),
                    blurRadius: 16,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: AnimatedRotation(
                turns: _fabMenuOpen ? 0.125 : 0.0,
                duration: const Duration(milliseconds: 200),
                child: const Icon(
                  Icons.favorite_rounded,
                  color: Colors.white,
                  size: 28,
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// FAB Menu Item
// ═══════════════════════════════════════════════════════════════════════════

class _FabMenuItem extends StatelessWidget {
  const _FabMenuItem({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 10),
        decoration: BoxDecoration(
          color: Theme.of(context).brightness == Brightness.dark
              ? const Color(0xFF231E2E)
              : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: color.withAlpha(40),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
          border: Border.all(color: color.withAlpha(50), width: 1),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w600,
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
