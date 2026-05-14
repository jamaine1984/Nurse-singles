import 'dart:math';

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/widgets/app_network_image.dart';
import 'package:nightingale_heart/features/compatibility/services/compatibility_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// A single swipe card displaying a user's photo, name, age, job,
/// shift badge, verification status, and online indicator.
class ProfileCard extends StatelessWidget {
  const ProfileCard({
    super.key,
    required this.user,
    this.currentUser,
    this.compatibility,
    this.onTap,
  });

  final UserModel user;
  final UserModel? currentUser;
  final CompatibilityResult? compatibility;
  final VoidCallback? onTap;

  int get _fallbackCompatibilityPercent {
    final seed = user.id.hashCode;
    return 60 + Random(seed).nextInt(40); // 60-99
  }

  CompatibilityResult? get _careFit {
    final viewer = currentUser;
    if (compatibility != null) return compatibility;
    if (viewer == null || viewer.id == user.id) return null;
    return CompatibilityService.score(viewer, user);
  }

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final photoUrl = user.displayPhoto;
    final galleryCount = user.gallery.length + (user.photoUrl != null ? 1 : 0);
    final workplaceLabel = user.hideWorkplace
        ? null
        : user.workplaceDisplayLabel;
    final isWorkplacePrivate = user.hideWorkplace && user.hasWorkplace;
    final professionBadge = user.publicProfessionBadge;
    final careFit = _careFit;
    final compatibilityPercent =
        careFit?.totalScore ?? _fallbackCompatibilityPercent;
    final careSignal = careFit != null && careFit.careSignals.isNotEmpty
        ? careFit.careSignals.first
        : AppLocalizations.translate('healthcare_community', locale);
    final verificationBadge = AppLocalizations.healthcareCredentialLabel(
      user.healthcareCredentialType?.value,
      locale,
      fallback: user.healthcareVerificationBadge,
    );

    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(24),
          boxShadow: AppTheme.softShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(24),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Background photo ──────────────────────────────────────
              if (photoUrl != null && photoUrl.isNotEmpty)
                AppNetworkImage(
                  imageUrl: photoUrl,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.softLavender,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: AppTheme.warmGray,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.softLavender,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 80,
                        color: AppTheme.warmGray,
                      ),
                    ),
                  ),
                )
              else
                Container(
                  color: AppTheme.softLavender,
                  child: const Center(
                    child: Icon(
                      Icons.person,
                      size: 80,
                      color: AppTheme.warmGray,
                    ),
                  ),
                ),

              // ── Gradient overlay ──────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.25),
                        Colors.black.withValues(alpha: 0.85),
                      ],
                      stops: const [0.0, 0.4, 0.65, 1.0],
                    ),
                  ),
                ),
              ),

              // ── Compatibility badge (top-right) ──────────────────────
              Positioned(
                top: 16,
                right: 16,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: const Color(0xFF155E75).withValues(alpha: 0.88),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: const Color(0xFF67E8F9).withValues(alpha: 0.35),
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.monitor_heart_rounded,
                        color: Color(0xFF67E8F9),
                        size: 14,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        AppLocalizations.format('care_fit', locale, {
                          'percent': compatibilityPercent,
                        }),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // ── Online indicator (top-left) ──────────────────────────
              Positioned(
                top: 16,
                left: 16,
                right: 120,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if (professionBadge != null)
                      _StatusPill(
                        icon: Icons.badge_rounded,
                        label: professionBadge,
                        color: const Color(0xFF67E8F9),
                      ),
                    if (professionBadge != null &&
                        (user.isOnline || user.isVerified))
                      const SizedBox(height: 6),
                    if (user.isOnline)
                      _StatusPill(
                        icon: Icons.circle,
                        label: AppLocalizations.translate('online', locale),
                        color: const Color(0xFF22C55E),
                      ),
                    if (user.isOnline && user.isVerified)
                      const SizedBox(height: 6),
                    if (user.isVerified)
                      _StatusPill(
                        icon: Icons.verified_rounded,
                        label: verificationBadge,
                        color: AppTheme.softAmber,
                      ),
                  ],
                ),
              ),

              // ── Bottom info section ───────────────────────────────────
              Positioned(
                left: 20,
                right: 20,
                bottom: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name + age + verified
                    Row(
                      children: [
                        Flexible(
                          child: Text(
                            '${user.name}${user.age != null ? ', ${user.age}' : ''}',
                            style: GoogleFonts.playfairDisplay(
                              fontSize: 28,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        if (user.isVerified) ...[
                          const SizedBox(width: 8),
                          const Icon(
                            Icons.verified,
                            color: AppTheme.softAmber,
                            size: 22,
                          ),
                        ],
                      ],
                    ),

                    const SizedBox(height: 6),

                    // Job title + hospital
                    if (user.jobTitle != null && user.jobTitle!.isNotEmpty)
                      Text(
                        '${user.jobTitle}'
                        '${workplaceLabel != null ? ' at $workplaceLabel' : ''}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),

                    const SizedBox(height: 10),

                    // Shift badge + location
                    Wrap(
                      spacing: 8,
                      runSpacing: 6,
                      children: [
                        if (user.shiftType != null)
                          _ShiftBadge(shiftType: user.shiftType!),
                        if (user.preferredDatingWindow != null)
                          _InfoChip(
                            icon: Icons.event_available_outlined,
                            label: AppLocalizations.datingWindowLabel(
                              user.preferredDatingWindow!.value,
                              locale,
                            ),
                          ),
                        if (user.department != null &&
                            user.department!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.local_hospital_outlined,
                            label: user.department!,
                          ),
                        if (isWorkplacePrivate)
                          _InfoChip(
                            icon: Icons.lock_outline,
                            label: AppLocalizations.translate(
                              'workplace_private',
                              locale,
                            ),
                          ),
                        _InfoChip(
                          icon: Icons.monitor_heart_outlined,
                          label: careSignal,
                        ),
                        if (user.location != null && user.location!.isNotEmpty)
                          _InfoChip(
                            icon: Icons.location_on_outlined,
                            label: user.location!,
                          ),
                      ],
                    ),

                    // Gallery dots
                    if (galleryCount > 1) ...[
                      const SizedBox(height: 12),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: List.generate(
                          galleryCount.clamp(0, 6),
                          (i) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 3),
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: i == 0
                                  ? Colors.white
                                  : Colors.white.withValues(alpha: 0.4),
                            ),
                          ),
                        ),
                      ),
                    ],
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

// ─── Small helper widgets ────────────────────────────────────────────────────

class _ShiftBadge extends StatelessWidget {
  const _ShiftBadge({required this.shiftType});

  final ShiftType shiftType;

  @override
  Widget build(BuildContext context) {
    late final Color bgColor;
    late final IconData icon;

    switch (shiftType) {
      case ShiftType.dayShift:
        bgColor = AppTheme.softAmber;
        icon = Icons.wb_sunny_rounded;
        break;
      case ShiftType.nightShift:
        bgColor = AppTheme.deepPlum;
        icon = Icons.nightlight_round;
        break;
      case ShiftType.rotatingShift:
        bgColor = AppTheme.warmRose;
        icon = Icons.sync;
        break;
      case ShiftType.flexible:
        bgColor = AppTheme.emerald;
        icon = Icons.schedule;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: bgColor.withValues(alpha: 0.85),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: Colors.white),
          const SizedBox(width: 4),
          Text(
            AppLocalizations.shiftTypeLabel(
              shiftType.value,
              Localizations.localeOf(context),
            ),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  const _InfoChip({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: Colors.white.withValues(alpha: 0.9)),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w500,
                color: Colors.white.withValues(alpha: 0.9),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({
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
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withValues(alpha: 0.28)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 10, color: color),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
