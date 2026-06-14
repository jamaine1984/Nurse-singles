import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/localization/app_language.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/auth/widgets/mobile_access_note.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// Three-page onboarding welcome screen with parallax and animated gradients.
class WelcomePage extends ConsumerStatefulWidget {
  const WelcomePage({super.key});

  @override
  ConsumerState<WelcomePage> createState() => _WelcomePageState();
}

class _WelcomePageState extends ConsumerState<WelcomePage> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  // Page data
  static const List<_WelcomePageData> _pages = [
    _WelcomePageData(
      icon: Icons.medical_information_rounded,
      iconColor: Color(0xFF0EA5A3),
      assetPath: 'assets/images/welcome/welcome_avatar.png',
      titleKey: 'welcome_title_1',
      descKey: 'welcome_desc_1',
    ),
    _WelcomePageData(
      icon: Icons.event_available_rounded,
      iconColor: Color(0xFF0284C7),
      assetPath: 'assets/images/welcome/welcome_shift_logo.png',
      titleKey: 'welcome_title_2',
      descKey: 'welcome_desc_2',
    ),
    _WelcomePageData(
      icon: Icons.health_and_safety_rounded,
      iconColor: Color(0xFFDC2626),
      assetPath: 'assets/images/welcome/welcome_video_logo.png',
      titleKey: 'welcome_title_3',
      descKey: 'welcome_desc_3',
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int page) {
    setState(() => _currentPage = page);
  }

  Color _topColorForPage(int page) {
    switch (page) {
      case 0:
        return const Color(0xFF0F766E);
      case 1:
        return const Color(0xFF075985);
      case 2:
        return const Color(0xFF0E7490);
      default:
        return const Color(0xFF0F766E);
    }
  }

  Color _bottomColorForPage(int page) {
    switch (page) {
      case 0:
        return const Color(0xFF061A23);
      case 1:
        return const Color(0xFF082F49);
      case 2:
        return const Color(0xFF083344);
      default:
        return const Color(0xFF061A23);
    }
  }

  void _showLanguagePicker() {
    final locale = ref.read(localeProvider);
    final languages = AppLanguages.fullySupported;

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF082F3A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Container(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(context).size.height * 0.6,
          ),
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              Text(
                AppLocalizations.translate('language', locale),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: languages.length,
                  itemBuilder: (ctx, index) {
                    final lang = languages[index];
                    final isSelected =
                        AppLanguages.normalizeFullySupportedCode(
                          locale.languageCode,
                        ) ==
                        lang.code;
                    return ListTile(
                      leading: Text(
                        lang.flag,
                        style: const TextStyle(fontSize: 24),
                      ),
                      title: Text(
                        lang.name,
                        style: GoogleFonts.plusJakartaSans(
                          color: isSelected
                              ? const Color(0xFF67E8F9)
                              : Colors.white.withValues(alpha: 0.9),
                          fontWeight: isSelected
                              ? FontWeight.w600
                              : FontWeight.w400,
                        ),
                      ),
                      trailing: isSelected
                          ? const Icon(
                              Icons.check_circle,
                              color: Color(0xFF67E8F9),
                            )
                          : null,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      onTap: () {
                        ref.read(localeProvider.notifier).setLocale(lang.code);
                        Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final locale = ref.watch(localeProvider);

    return Scaffold(
      body: AnimatedContainer(
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              _topColorForPage(_currentPage),
              _bottomColorForPage(_currentPage),
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // ── Top bar with language picker ──
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 8,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    IconButton(
                      onPressed: _showLanguagePicker,
                      icon: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: Colors.white.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: Colors.white.withValues(alpha: 0.2),
                          ),
                        ),
                        child: const Icon(
                          Icons.language_rounded,
                          color: Colors.white,
                          size: 22,
                        ),
                      ),
                    ),
                  ],
                ),
              ),

              // ── Page content ──
              Expanded(
                child: PageView.builder(
                  controller: _pageController,
                  onPageChanged: _onPageChanged,
                  itemCount: _pages.length,
                  itemBuilder: (context, index) {
                    final page = _pages[index];
                    return Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 32),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          _WelcomeArtwork(page: page, index: index)
                              .animate(key: ValueKey('icon_$index'))
                              .fadeIn(duration: 600.ms)
                              .scale(
                                begin: const Offset(0.8, 0.8),
                                end: const Offset(1.0, 1.0),
                                duration: 600.ms,
                                curve: Curves.easeOutBack,
                              ),
                          const SizedBox(height: 48),

                          // Title
                          Text(
                                AppLocalizations.translate(
                                  page.titleKey,
                                  locale,
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 28,
                                  fontWeight: FontWeight.w700,
                                  color: Colors.white,
                                  height: 1.2,
                                ),
                              )
                              .animate(key: ValueKey('title_$index'))
                              .fadeIn(duration: 600.ms, delay: 200.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                duration: 600.ms,
                                delay: 200.ms,
                                curve: Curves.easeOut,
                              ),
                          const SizedBox(height: 20),

                          // Description
                          Text(
                                AppLocalizations.translate(
                                  page.descKey,
                                  locale,
                                ),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w400,
                                  color: Colors.white.withValues(alpha: 0.75),
                                  height: 1.6,
                                ),
                              )
                              .animate(key: ValueKey('desc_$index'))
                              .fadeIn(duration: 600.ms, delay: 400.ms)
                              .slideY(
                                begin: 0.2,
                                end: 0,
                                duration: 600.ms,
                                delay: 400.ms,
                                curve: Curves.easeOut,
                              ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              // ── Bottom section: dots + buttons ──
              Padding(
                padding: const EdgeInsets.fromLTRB(32, 0, 32, 24),
                child: Column(
                  children: [
                    // Page indicator dots
                    SmoothPageIndicator(
                      controller: _pageController,
                      count: _pages.length,
                      effect: WormEffect(
                        dotHeight: 8,
                        dotWidth: 8,
                        activeDotColor: const Color(0xFF67E8F9),
                        dotColor: Colors.white.withValues(alpha: 0.3),
                        spacing: 12,
                      ),
                    ),
                    const SizedBox(height: 18),
                    MobileAccessNote(
                      locale: locale,
                      compact: true,
                      showAdsStatus: true,
                    ),
                    const SizedBox(height: 22),

                    // Get Started / Next button
                    SizedBox(
                      width: double.infinity,
                      height: 56,
                      child: _currentPage == _pages.length - 1
                          ? _GradientButton(
                              onPressed: () => context.go('/signup'),
                              label: AppLocalizations.translate(
                                'get_started',
                                locale,
                              ),
                            )
                          : _GradientButton(
                              onPressed: () {
                                _pageController.nextPage(
                                  duration: const Duration(milliseconds: 400),
                                  curve: Curves.easeInOut,
                                );
                              },
                              label: AppLocalizations.translate('next', locale),
                            ),
                    ),
                    const SizedBox(height: 16),

                    // Login link
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: Text(
                        AppLocalizations.translate('has_account', locale),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Data class for welcome page content.
class _WelcomePageData {
  const _WelcomePageData({
    required this.icon,
    required this.iconColor,
    required this.assetPath,
    required this.titleKey,
    required this.descKey,
  });

  final IconData icon;
  final Color iconColor;
  final String assetPath;
  final String titleKey;
  final String descKey;
}

class _WelcomeArtwork extends StatelessWidget {
  const _WelcomeArtwork({required this.page, required this.index});

  final _WelcomePageData page;
  final int index;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 238,
      height: 238,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: RadialGradient(
          colors: [
            page.iconColor.withValues(alpha: 0.36),
            Colors.white.withValues(alpha: 0.10),
            Colors.transparent,
          ],
        ),
        boxShadow: [
          BoxShadow(
            color: page.iconColor.withValues(alpha: 0.28),
            blurRadius: 42,
            spreadRadius: 4,
          ),
        ],
      ),
      child: Stack(
        alignment: Alignment.center,
        children: [
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                border: Border.all(
                  color: Colors.white.withValues(alpha: 0.18),
                  width: 1.4,
                ),
              ),
            ),
          ),
          ClipOval(
            child: Image.asset(
              page.assetPath,
              width: 214,
              height: 214,
              fit: BoxFit.cover,
              filterQuality: FilterQuality.high,
              errorBuilder: (_, __, ___) => Container(
                color: Colors.white.withValues(alpha: 0.12),
                child: Icon(page.icon, color: Colors.white, size: 76),
              ),
            ),
          ),
          Positioned(
            left: 18,
            right: 18,
            bottom: 10,
            child: Row(
              children: [
                Expanded(
                  child: _SignalPill(
                    label: index == 0
                        ? 'Verified'
                        : index == 1
                        ? 'Shift-aware'
                        : 'Video intro',
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _SignalPill(
                    label: index == 0
                        ? 'Private'
                        : index == 1
                        ? 'Care fit'
                        : 'Safe rooms',
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SignalPill extends StatelessWidget {
  const _SignalPill({required this.label});

  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.16),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
      ),
      child: Text(
        label,
        textAlign: TextAlign.center,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: GoogleFonts.plusJakartaSans(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w800,
        ),
      ),
    );
  }
}

/// Reusable gradient button.
class _GradientButton extends StatelessWidget {
  const _GradientButton({required this.onPressed, required this.label});

  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onPressed,
        borderRadius: BorderRadius.circular(20),
        child: Ink(
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
              begin: Alignment.centerLeft,
              end: Alignment.centerRight,
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: [
              BoxShadow(
                color: AppTheme.warmRose.withValues(alpha: 0.3),
                blurRadius: 16,
                offset: const Offset(0, 6),
              ),
            ],
          ),
          child: Center(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: Colors.white,
                letterSpacing: 0.5,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
