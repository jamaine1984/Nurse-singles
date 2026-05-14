import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/features/settings/pages/terms_of_service_page.dart';
import 'package:nightingale_heart/features/settings/pages/privacy_policy_page.dart';

class AboutPage extends StatelessWidget {
  const AboutPage({super.key});

  Future<void> _launchEmail() async {
    final uri = Uri(
      scheme: 'mailto',
      path: AppConstants.supportEmail,
      queryParameters: {
        'subject': 'Nurse Singles App Inquiry',
      },
    );
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri);
    }
  }

  Future<void> _launchWebsite() async {
    final uri = Uri.parse('https://nursesingles.com');
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'About',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        child: Column(
          children: [
            // ── Hero Section ──────────────────────────────────────────────
            const SizedBox(height: 16),
            _buildHeroSection(theme)
                .animate()
                .fadeIn(duration: 500.ms),
            const SizedBox(height: 24),

            // ── App Description ───────────────────────────────────────────
            _buildDescriptionCard(theme)
                .animate()
                .fadeIn(duration: 400.ms, delay: 100.ms),
            const SizedBox(height: 16),

            // ── Legal Section ─────────────────────────────────────────────
            _buildLegalSection(context, theme)
                .animate()
                .fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 16),

            // ── Contact Section ───────────────────────────────────────────
            _buildContactSection(theme)
                .animate()
                .fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 32),

            // ── Footer ────────────────────────────────────────────────────
            _buildFooter(theme)
                .animate()
                .fadeIn(duration: 400.ms, delay: 400.ms),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  // ── Hero Section ──────────────────────────────────────────────────────────

  Widget _buildHeroSection(ThemeData theme) {
    return Column(
      children: [
        Container(
          width: 80,
          height: 80,
          decoration: const BoxDecoration(
            color: AppTheme.warmRose,
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.favorite,
            color: Colors.white,
            size: 40,
          ),
        ),
        const SizedBox(height: 16),
        Text(
          AppConstants.appName,
          style: GoogleFonts.playfairDisplay(
            fontSize: 28,
            fontWeight: FontWeight.w700,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          'Version ${AppConstants.appVersion}',
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w500,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          AppConstants.appTagline,
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: AppTheme.deepPlum,
          ),
        ),
      ],
    );
  }

  // ── Description Card ──────────────────────────────────────────────────────

  Widget _buildDescriptionCard(ThemeData theme) {
    return GlassCard(
      showGradientOverlay: true,
      child: Text(
        'Nurse Singles is the premier dating app built exclusively for '
        'healthcare workers. Whether you are a nurse, doctor, paramedic, or '
        'any other medical professional, we understand the unique challenges '
        'of your schedule and lifestyle. Our platform is designed to help you '
        'find meaningful connections with people who truly get what it means '
        'to dedicate your life to caring for others.',
        textAlign: TextAlign.center,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          height: 1.7,
          color: theme.colorScheme.onSurface,
        ),
      ),
    );
  }

  // ── Legal Section ─────────────────────────────────────────────────────────

  Widget _buildLegalSection(BuildContext context, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Legal',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _AboutTile(
                icon: Icons.description_outlined,
                title: 'Terms of Service',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const TermsOfServicePage(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 52,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              _AboutTile(
                icon: Icons.privacy_tip_outlined,
                title: 'Privacy Policy',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => const PrivacyPolicyPage(),
                    ),
                  );
                },
              ),
              Divider(
                height: 1,
                indent: 52,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              _AboutTile(
                icon: Icons.code_outlined,
                title: 'Open-Source Licenses',
                trailing: const Icon(Icons.chevron_right, size: 20),
                onTap: () {
                  showLicensePage(
                    context: context,
                    applicationName: AppConstants.appName,
                    applicationVersion: AppConstants.appVersion,
                    applicationIcon: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Container(
                        width: 56,
                        height: 56,
                        decoration: const BoxDecoration(
                          color: AppTheme.warmRose,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.favorite,
                          color: Colors.white,
                          size: 28,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Contact Section ───────────────────────────────────────────────────────

  Widget _buildContactSection(ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 4, bottom: 8),
          child: Text(
            'Contact',
            style: GoogleFonts.playfairDisplay(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
        ),
        GlassCard(
          padding: EdgeInsets.zero,
          child: Column(
            children: [
              _AboutTile(
                icon: Icons.email_outlined,
                title: 'Email',
                trailing: Text(
                  AppConstants.supportEmail,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: _launchEmail,
              ),
              Divider(
                height: 1,
                indent: 52,
                color: theme.colorScheme.outline.withValues(alpha: 0.2),
              ),
              _AboutTile(
                icon: Icons.language,
                title: 'Website',
                trailing: Text(
                  'nursesingles.com',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                onTap: _launchWebsite,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Footer ────────────────────────────────────────────────────────────────

  Widget _buildFooter(ThemeData theme) {
    return Column(
      children: [
        Text(
          'Made with love for healthcare heroes worldwide',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            fontStyle: FontStyle.italic,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          '\u00a9 2026 Nurse Singles. All rights reserved.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }
}

// ── Reusable About Tile ─────────────────────────────────────────────────────

class _AboutTile extends StatelessWidget {
  const _AboutTile({
    required this.icon,
    required this.title,
    this.trailing,
    this.onTap,
  });

  final IconData icon;
  final String title;
  final Widget? trailing;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 22,
              color: theme.colorScheme.onSurfaceVariant,
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w500,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
            if (trailing != null) trailing!,
          ],
        ),
      ),
    );
  }
}
