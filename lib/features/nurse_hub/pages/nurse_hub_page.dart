import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/widgets/desktop_app_header.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

String _t(BuildContext context, String key) {
  return AppLocalizations.translate(key, Localizations.localeOf(context));
}

class NurseHubPage extends StatelessWidget {
  const NurseHubPage({super.key});

  static const _sections = [
    _HubSection(
      titleKey: 'nurse_hub_clinical_updates',
      subtitleKey: 'nurse_hub_clinical_updates_subtitle',
      icon: Icons.monitor_heart_outlined,
      color: Color(0xFF0F766E),
      items: [
        _HubItem(
          titleKey: 'nurse_hub_cdc_travel_title',
          descriptionKey: 'nurse_hub_cdc_travel_desc',
          source: 'CDC',
          url: 'https://wwwnc.cdc.gov/travel/page/rss',
          icon: Icons.public_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_cms_newsroom_title',
          descriptionKey: 'nurse_hub_cms_newsroom_desc',
          source: 'CMS',
          url:
              'https://www.cms.gov/about-cms/web-policies-important-links/rss-feeds?redirect=/cmsfeeds/',
          icon: Icons.policy_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_medline_title',
          descriptionKey: 'nurse_hub_medline_desc',
          source: 'NIH/NLM',
          url: 'https://medlineplus.gov/about/developers/webservices/',
          icon: Icons.library_books_outlined,
        ),
      ],
    ),
    _HubSection(
      titleKey: 'nurse_hub_school_scholarships',
      subtitleKey: 'nurse_hub_school_scholarships_subtitle',
      icon: Icons.school_outlined,
      color: Color(0xFF2563EB),
      items: [
        _HubItem(
          titleKey: 'nurse_hub_nurse_corps_title',
          descriptionKey: 'nurse_hub_nurse_corps_desc',
          source: 'HRSA',
          url: 'https://bhw.hrsa.gov/programs/nurse-corps/scholarship',
          icon: Icons.volunteer_activism_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_workforce_data_title',
          descriptionKey: 'nurse_hub_workforce_data_desc',
          source: 'HRSA',
          url:
              'https://data.hrsa.gov/data/download?data=nursing-workforce-survey-data',
          icon: Icons.analytics_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_nclex_title',
          descriptionKey: 'nurse_hub_nclex_desc',
          source: 'NCSBN',
          url: 'https://www.ncsbn.org/exams',
          icon: Icons.fact_check_outlined,
        ),
      ],
    ),
    _HubSection(
      titleKey: 'nurse_hub_ceu_training',
      subtitleKey: 'nurse_hub_ceu_training_subtitle',
      icon: Icons.menu_book_outlined,
      color: Color(0xFF7C2D12),
      items: [
        _HubItem(
          titleKey: 'nurse_hub_cdc_train_title',
          descriptionKey: 'nurse_hub_cdc_train_desc',
          source: 'CDC',
          url: 'https://www.cdc.gov/cdc-train/about/index.html',
          icon: Icons.cast_for_education_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_cdc_ce_title',
          descriptionKey: 'nurse_hub_cdc_ce_desc',
          source: 'CDC',
          url:
              'https://www.cdc.gov/continuing-education/php/types-of-ce/index.html',
          icon: Icons.workspace_premium_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_nhsn_title',
          descriptionKey: 'nurse_hub_nhsn_desc',
          source: 'CDC NHSN',
          url: 'https://www.cdc.gov/nhsn/training/continuing-edu.html',
          icon: Icons.health_and_safety_outlined,
        ),
      ],
    ),
    _HubSection(
      titleKey: 'nurse_hub_jobs_staffing',
      subtitleKey: 'nurse_hub_jobs_staffing_subtitle',
      icon: Icons.badge_outlined,
      color: Color(0xFF0284C7),
      items: [
        _HubItem(
          titleKey: 'nurse_hub_workforce_connector_title',
          descriptionKey: 'nurse_hub_workforce_connector_desc',
          source: 'HRSA',
          url: 'https://bhw.hrsa.gov/job-search/use-health-workforce-connector',
          icon: Icons.work_outline,
        ),
        _HubItem(
          titleKey: 'nurse_hub_rn_outlook_title',
          descriptionKey: 'nurse_hub_rn_outlook_desc',
          source: 'BLS',
          url: 'https://www.bls.gov/ooh/healthcare/registered-nurses.htm',
          icon: Icons.trending_up_outlined,
        ),
        _HubItem(
          titleKey: 'nurse_hub_ana_news_title',
          descriptionKey: 'nurse_hub_ana_news_desc',
          source: 'ANA Enterprise',
          url: 'https://www.nursingworld.org/news/news-releases/',
          icon: Icons.newspaper_outlined,
        ),
      ],
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 1000;
    final content = ListView(
      padding: EdgeInsets.fromLTRB(
        isDesktopWeb ? 24 : 16,
        isDesktopWeb ? 22 : 8,
        isDesktopWeb ? 24 : 16,
        28,
      ),
      children: [
        const _HeroPanel(),
        const SizedBox(height: 16),
        ..._sections.map((section) => _HubSectionView(section: section)),
        const SizedBox(height: 12),
        _SafetyPanel(theme: theme),
      ],
    );

    return Scaffold(
      backgroundColor: isDesktopWeb ? const Color(0xFFF1F7F6) : null,
      appBar: isDesktopWeb
          ? DesktopAppHeader(
              activeRoute: RoutePaths.nurseHub,
              onMenuPressed: () => showDesktopAppMenu(context),
            )
          : AppBar(
              title: Text(
                _t(context, 'nurse_hub'),
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
              ),
            ),
      body: isDesktopWeb
          ? Center(
              child: ConstrainedBox(
                constraints: const BoxConstraints(maxWidth: 1180),
                child: content,
              ),
            )
          : content,
    );
  }
}

class _HeroPanel extends StatelessWidget {
  const _HeroPanel();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFF2563EB)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: const Icon(
                  Icons.local_hospital_outlined,
                  color: Colors.white,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  _t(context, 'nurse_hub_hero_title'),
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            _t(context, 'nurse_hub_hero_body'),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.92),
              height: 1.35,
            ),
          ),
        ],
      ),
    );
  }
}

class _HubSectionView extends StatelessWidget {
  const _HubSectionView({required this.section});

  final _HubSection section;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(9),
                decoration: BoxDecoration(
                  color: section.color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(section.icon, color: section.color, size: 21),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t(context, section.titleKey),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 19,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    Text(
                      _t(context, section.subtitleKey),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...section.items.map(
            (item) => _HubItemCard(item: item, accent: section.color),
          ),
        ],
      ),
    );
  }
}

class _HubItemCard extends StatelessWidget {
  const _HubItemCard({required this.item, required this.accent});

  final _HubItem item;
  final Color accent;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return GlassCard(
      margin: const EdgeInsets.only(bottom: 10),
      padding: const EdgeInsets.all(14),
      borderRadius: AppTheme.borderRadiusMedium,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(item.icon, color: accent, size: 24),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        _t(context, item.titleKey),
                        style: GoogleFonts.plusJakartaSans(
                          fontWeight: FontWeight.w800,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Text(
                      item.source,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: accent,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Text(
                  _t(context, item.descriptionKey),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12.5,
                    height: 1.35,
                    color: theme.colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerLeft,
                  child: TextButton.icon(
                    onPressed: () => _openResource(context, item.url),
                    icon: const Icon(Icons.open_in_new_rounded, size: 16),
                    label: Text(_t(context, 'open_resource')),
                    style: TextButton.styleFrom(
                      foregroundColor: accent,
                      padding: EdgeInsets.zero,
                      visualDensity: VisualDensity.compact,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _openResource(BuildContext context, String url) async {
    final uri = Uri.parse(url);
    final opened = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!opened && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t(context, 'could_not_open_resource'))),
      );
    }
  }
}

class _SafetyPanel extends StatelessWidget {
  const _SafetyPanel({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return GlassCard(
      padding: const EdgeInsets.all(14),
      borderRadius: AppTheme.borderRadiusMedium,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.privacy_tip_outlined, color: AppTheme.warmRose),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _t(context, 'nurse_hub_privacy_reminder'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12.5,
                height: 1.35,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _HubSection {
  const _HubSection({
    required this.titleKey,
    required this.subtitleKey,
    required this.icon,
    required this.color,
    required this.items,
  });

  final String titleKey;
  final String subtitleKey;
  final IconData icon;
  final Color color;
  final List<_HubItem> items;
}

class _HubItem {
  const _HubItem({
    required this.titleKey,
    required this.descriptionKey,
    required this.source,
    required this.url,
    required this.icon,
  });

  final String titleKey;
  final String descriptionKey;
  final String source;
  final String url;
  final IconData icon;
}
