import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// Desktop-only navigation for the authenticated web experience.
///
/// Mobile and installed PWA layouts continue to use their compact page app bars.
class DesktopAppHeader extends StatelessWidget implements PreferredSizeWidget {
  const DesktopAppHeader({
    super.key,
    required this.activeRoute,
    required this.onMenuPressed,
    this.onFilterPressed,
    this.extraActions = const [],
  });

  final String activeRoute;
  final VoidCallback onMenuPressed;
  final VoidCallback? onFilterPressed;
  final List<Widget> extraActions;

  static const _background = Color(0xFF101719);
  static const _accent = Color(0xFF2DD4BF);

  String _t(BuildContext context, String key) {
    return AppLocalizations.translate(key, Localizations.localeOf(context));
  }

  @override
  Size get preferredSize => const Size.fromHeight(72);

  @override
  Widget build(BuildContext context) {
    final items = <_DesktopNavItem>[
      _DesktopNavItem(
        label: _t(context, 'nav_discover'),
        route: RoutePaths.discover,
        icon: Icons.monitor_heart_outlined,
      ),
      _DesktopNavItem(
        label: _t(context, 'speed_dating'),
        route: RoutePaths.video,
        icon: Icons.video_call_outlined,
      ),
      _DesktopNavItem(
        label: _t(context, 'nav_feed'),
        route: RoutePaths.social,
        icon: Icons.forum_outlined,
      ),
      _DesktopNavItem(
        label: _t(context, 'nurse_hub'),
        route: RoutePaths.nurseHub,
        icon: Icons.local_hospital_outlined,
      ),
      _DesktopNavItem(
        label: _t(context, 'nav_matches'),
        route: RoutePaths.matches,
        icon: Icons.favorite_border_rounded,
      ),
    ];

    return Material(
      color: _background,
      elevation: 0,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Row(
            children: [
              InkWell(
                onTap: () => context.go(RoutePaths.discover),
                borderRadius: BorderRadius.circular(8),
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 10,
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.medical_services_rounded,
                        color: _accent,
                        size: 25,
                      ),
                      const SizedBox(width: 10),
                      Text(
                        'Nurse Singles',
                        style: GoogleFonts.playfairDisplay(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 24),
              Expanded(
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: items
                      .map(
                        (item) => Flexible(
                          child: _DesktopNavButton(
                            item: item,
                            selected:
                                activeRoute == item.route ||
                                activeRoute.startsWith('${item.route}/'),
                          ),
                        ),
                      )
                      .toList(growable: false),
                ),
              ),
              const SizedBox(width: 16),
              ...extraActions,
              if (onFilterPressed != null)
                IconButton(
                  tooltip: _t(context, 'filters'),
                  onPressed: onFilterPressed,
                  icon: const Icon(Icons.tune_rounded),
                  color: Colors.white,
                ),
              IconButton(
                tooltip: _t(context, 'main_menu'),
                onPressed: onMenuPressed,
                icon: const Icon(Icons.menu_rounded),
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DesktopNavItem {
  const _DesktopNavItem({
    required this.label,
    required this.route,
    required this.icon,
  });

  final String label;
  final String route;
  final IconData icon;
}

class _DesktopNavButton extends StatelessWidget {
  const _DesktopNavButton({required this.item, required this.selected});

  final _DesktopNavItem item;
  final bool selected;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: item.label,
      child: InkWell(
        onTap: () => context.go(item.route),
        borderRadius: BorderRadius.circular(6),
        child: Container(
          constraints: const BoxConstraints(minHeight: 44),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
          decoration: BoxDecoration(
            color: selected
                ? Colors.white.withValues(alpha: 0.10)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(6),
            border: Border(
              bottom: BorderSide(
                color: selected ? DesktopAppHeader._accent : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                item.icon,
                size: 18,
                color: selected
                    ? DesktopAppHeader._accent
                    : Colors.white.withValues(alpha: 0.72),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  item.label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

Future<void> showDesktopAppMenu(BuildContext context) {
  String t(String key) {
    return AppLocalizations.translate(key, Localizations.localeOf(context));
  }

  final items = <_DesktopMenuItem>[
    _DesktopMenuItem(
      icon: Icons.forum_outlined,
      label: t('nav_feed'),
      route: RoutePaths.social,
    ),
    _DesktopMenuItem(
      icon: Icons.local_hospital_outlined,
      label: t('nurse_hub'),
      route: RoutePaths.nurseHub,
    ),
    _DesktopMenuItem(
      icon: Icons.favorite_border_rounded,
      label: t('nav_matches'),
      route: RoutePaths.matches,
    ),
    _DesktopMenuItem(
      icon: Icons.chat_bubble_outline_rounded,
      label: t('nav_messages'),
      route: RoutePaths.messages,
    ),
    _DesktopMenuItem(
      icon: Icons.video_call_outlined,
      label: t('speed_dating'),
      route: RoutePaths.video,
    ),
    _DesktopMenuItem(
      icon: Icons.badge_outlined,
      label: t('nav_profile'),
      route: RoutePaths.profile,
    ),
    _DesktopMenuItem(
      icon: Icons.card_giftcard_rounded,
      label: t('gift_store'),
      route: RoutePaths.gifts,
    ),
    _DesktopMenuItem(
      icon: Icons.inventory_2_outlined,
      label: t('gift_inventory'),
      route: RoutePaths.giftInventory,
    ),
    _DesktopMenuItem(
      icon: Icons.workspace_premium_outlined,
      label: t('subscription'),
      route: RoutePaths.subscriptionManage,
    ),
    _DesktopMenuItem(
      icon: Icons.timelapse_rounded,
      label: t('video_minutes'),
      route: RoutePaths.videoMinutes,
    ),
    _DesktopMenuItem(
      icon: Icons.insights_outlined,
      label: t('dashboard'),
      route: RoutePaths.dashboard,
    ),
    _DesktopMenuItem(
      icon: Icons.nightlight_outlined,
      label: t('night_owls'),
      route: RoutePaths.nightOwls,
    ),
    _DesktopMenuItem(
      icon: Icons.monitor_heart_outlined,
      label: t('compatibility'),
      route: RoutePaths.compatibility,
    ),
    _DesktopMenuItem(
      icon: Icons.sports_esports_outlined,
      label: t('entertainment'),
      route: RoutePaths.entertainment,
    ),
    _DesktopMenuItem(
      icon: Icons.settings_outlined,
      label: t('settings'),
      route: RoutePaths.settings,
    ),
  ];

  return showDialog<void>(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.36),
    builder: (dialogContext) {
      final height = MediaQuery.sizeOf(dialogContext).height;
      return Dialog(
        alignment: Alignment.topRight,
        insetPadding: const EdgeInsets.fromLTRB(24, 88, 24, 24),
        backgroundColor: Colors.transparent,
        elevation: 0,
        child: Container(
          width: 440,
          constraints: BoxConstraints(maxHeight: height - 112),
          padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
          decoration: BoxDecoration(
            color: const Color(0xFF11191B),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.white.withValues(alpha: 0.10)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.28),
                blurRadius: 28,
                offset: const Offset(0, 12),
              ),
            ],
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(
                    Icons.medical_services_rounded,
                    color: DesktopAppHeader._accent,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      t('main_menu'),
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 21,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: MaterialLocalizations.of(
                      dialogContext,
                    ).closeButtonTooltip,
                    onPressed: () => Navigator.of(dialogContext).pop(),
                    icon: const Icon(Icons.close_rounded),
                    color: Colors.white70,
                  ),
                ],
              ),
              Text(
                t('menu_quick_access'),
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white60,
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: GridView.builder(
                  itemCount: items.length,
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 2.55,
                    crossAxisSpacing: 10,
                    mainAxisSpacing: 10,
                  ),
                  itemBuilder: (_, index) {
                    final item = items[index];
                    return InkWell(
                      onTap: () {
                        Navigator.of(dialogContext).pop();
                        context.push(item.route);
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.06),
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.10),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              item.icon,
                              color: const Color(0xFF5EEAD4),
                              size: 21,
                            ),
                            const SizedBox(width: 9),
                            Expanded(
                              child: Text(
                                item.label,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white,
                                  fontSize: 12,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _DesktopMenuItem {
  const _DesktopMenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}
