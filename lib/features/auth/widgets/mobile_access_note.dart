import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

class MobileAccessNote extends StatelessWidget {
  const MobileAccessNote({
    super.key,
    required this.locale,
    this.compact = false,
    this.showAdsStatus = false,
  });

  final Locale locale;
  final bool compact;
  final bool showAdsStatus;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(compact ? 14 : 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.16)),
        boxShadow: [
          BoxShadow(
            color: AppTheme.midnight.withValues(alpha: 0.16),
            blurRadius: 20,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Container(
                width: compact ? 38 : 42,
                height: compact ? 38 : 42,
                decoration: BoxDecoration(
                  color: const Color(0xFF67E8F9).withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  Icons.phone_iphone_rounded,
                  color: const Color(0xFF67E8F9),
                  size: compact ? 21 : 23,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  AppLocalizations.translate('mobile_access_title', locale),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: compact ? 13 : 14,
                    fontWeight: FontWeight.w800,
                    height: 1.25,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            AppLocalizations.translate('mobile_access_body', locale),
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.74),
              fontSize: compact ? 12 : 13,
              fontWeight: FontWeight.w500,
              height: 1.45,
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AccessChip(
                icon: Icons.ios_share_rounded,
                label: AppLocalizations.translate(
                  'iphone_install_chip',
                  locale,
                ),
                color: const Color(0xFF67E8F9),
              ),
              _AccessChip(
                icon: Icons.shop_rounded,
                label: AppLocalizations.translate(
                  'google_play_available',
                  locale,
                ),
                color: AppTheme.softAmber,
              ),
            ],
          ),
          if (showAdsStatus) ...[
            const SizedBox(height: 12),
            Divider(color: Colors.white.withValues(alpha: 0.14), height: 1),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 30,
                  height: 30,
                  decoration: BoxDecoration(
                    color: AppTheme.softAmber.withValues(alpha: 0.13),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: const Icon(
                    Icons.ads_click_rounded,
                    color: AppTheme.softAmber,
                    size: 17,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppLocalizations.translate(
                          'web_ads_notice_title',
                          locale,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          height: 1.2,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        AppLocalizations.translate(
                          'web_ads_notice_body',
                          locale,
                        ),
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white.withValues(alpha: 0.66),
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.35,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _AccessChip extends StatelessWidget {
  const _AccessChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.26)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 14),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              color: color,
              fontSize: 11,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}
