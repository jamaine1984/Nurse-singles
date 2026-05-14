import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/admob_service.dart';
import 'package:nightingale_heart/core/widgets/app_network_image.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale_heart/features/settings/pages/settings_page.dart';
import 'package:nightingale_heart/features/settings/pages/edit_profile_page.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/features/video_dating/services/video_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';

class ProfilePage extends ConsumerStatefulWidget {
  const ProfilePage({super.key});

  @override
  ConsumerState<ProfilePage> createState() => _ProfilePageState();
}

class _ProfilePageState extends ConsumerState<ProfilePage> {
  Timer? _boostTimer;
  Duration _boostRemaining = Duration.zero;
  int _boostAdsWatched = 0;
  bool _isBoostingInProgress = false;

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  String _planLabel(SubscriptionPlan plan) => _t('plan_${plan.value}');

  String _lookingForLabel(LookingFor value) => _t('looking_${value.value}');

  String _healthcareBadgeLabel(UserModel user) {
    final rawBadge = user.healthcareVerificationBadge?.trim();
    final credentialType =
        user.healthcareCredentialType?.value ??
        _credentialTypeFromBadge(rawBadge);
    return AppLocalizations.healthcareCredentialLabel(
      credentialType,
      ref.read(localeProvider),
      fallback: rawBadge,
    );
  }

  void _goBackFromProfile() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RoutePaths.discover);
    }
  }

  String? _credentialTypeFromBadge(String? badge) {
    return switch (badge) {
      'Healthcare Worker' || 'Healthcare Worker Verified' => 'healthcareWorker',
      'Nursing Student' || 'Nursing Student Verified' => 'nursingStudent',
      'Travel Nurse' || 'Travel Nurse Verified' => 'travelNurse',
      'Agency Partner' || 'Agency Partner Verified' => 'agencyPartner',
      'College Partner' || 'College Partner Verified' => 'collegePartner',
      _ => null,
    };
  }

  @override
  void initState() {
    super.initState();
    _startBoostTimer();
  }

  @override
  void dispose() {
    _boostTimer?.cancel();
    super.dispose();
  }

  void _startBoostTimer() {
    _boostTimer?.cancel();
    _boostTimer = Timer.periodic(const Duration(seconds: 1), (_) {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user != null && user.isBoostActive) {
        final remaining = user.boostExpiresAt!.difference(DateTime.now());
        if (remaining.isNegative) {
          setState(() => _boostRemaining = Duration.zero);
          _boostTimer?.cancel();
        } else {
          setState(() => _boostRemaining = remaining);
        }
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    ref.watch(localeProvider);

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          tooltip: _t('go_back'),
          icon: const Icon(Icons.arrow_back_rounded),
          onPressed: _goBackFromProfile,
        ),
        title: Text(
          _t('my_profile'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const SettingsPage()));
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(child: Text(_t('please_sign_in')));
          }
          return _buildProfileContent(user, theme);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text(_t('something_went_wrong'))),
      ),
    );
  }

  Widget _buildProfileContent(UserModel user, ThemeData theme) {
    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          const SizedBox(height: 8),
          _buildProfileHeader(user, theme).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 16),
          _buildPlanBadge(
            user,
            theme,
          ).animate().fadeIn(duration: 400.ms, delay: 50.ms),
          const SizedBox(height: 16),
          // Boost section - always visible
          _buildBoostSection(
            user,
            theme,
          ).animate().fadeIn(duration: 400.ms, delay: 75.ms),
          const SizedBox(height: 16),
          _buildStatsRow(
            user,
            theme,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 16),
          _buildQuickActions(
            user,
            theme,
          ).animate().fadeIn(duration: 400.ms, delay: 150.ms),
          const SizedBox(height: 20),
          if (_hasShiftAvailability(user)) ...[
            _buildShiftAvailabilityCard(
              user,
              theme,
            ).animate().fadeIn(duration: 400.ms, delay: 175.ms),
            const SizedBox(height: 20),
          ],
          if (_allPhotos(user).isNotEmpty) ...[
            _buildPhotosSection(
              user,
              theme,
            ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
            const SizedBox(height: 20),
          ],
          _buildAboutSection(
            user,
            theme,
          ).animate().fadeIn(duration: 400.ms, delay: 250.ms),
          const SizedBox(height: 20),
          if (user.interests.isNotEmpty) ...[
            _buildInterestsSection(
              user,
              theme,
            ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
            const SizedBox(height: 20),
          ],
          if (user.languages.isNotEmpty) ...[
            _buildLanguagesSection(
              user,
              theme,
            ).animate().fadeIn(duration: 400.ms, delay: 350.ms),
            const SizedBox(height: 20),
          ],
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildProfileHeader(UserModel user, ThemeData theme) {
    final photos = _allPhotos(user);
    return Column(
      children: [
        Stack(
          alignment: Alignment.bottomRight,
          children: [
            GestureDetector(
              onTap: photos.isEmpty
                  ? null
                  : () => _showFullImageGallery(context, photos, 0),
              child: Container(
                padding: const EdgeInsets.all(4),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: user.isBoostActive
                      ? AppTheme.accentGradient
                      : AppTheme.primaryGradient,
                ),
                child: ClipOval(
                  child: SizedBox(
                    width: 120,
                    height: 120,
                    child: user.displayPhoto != null
                        ? AppNetworkImage(
                            imageUrl: user.displayPhoto!,
                            fit: BoxFit.cover,
                            placeholder: (_, __) => Container(
                              color: AppTheme.softLavender,
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.deepPlum,
                              ),
                            ),
                            errorWidget: (_, __, ___) => Container(
                              color: AppTheme.softLavender,
                              child: Icon(
                                Icons.person,
                                size: 48,
                                color: AppTheme.deepPlum,
                              ),
                            ),
                          )
                        : Container(
                            color: AppTheme.softLavender,
                            child: Icon(
                              Icons.person,
                              size: 48,
                              color: AppTheme.deepPlum,
                            ),
                          ),
                  ),
                ),
              ),
            ),
            GestureDetector(
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(builder: (_) => const EditProfilePage()),
                );
              },
              child: Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  gradient: AppTheme.primaryGradient,
                  border: Border.all(
                    color: theme.scaffoldBackgroundColor,
                    width: 3,
                  ),
                ),
                child: const Icon(Icons.edit, color: Colors.white, size: 16),
              ),
            ),
          ],
        ),
        const SizedBox(height: 14),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              user.name,
              style: GoogleFonts.playfairDisplay(
                fontSize: 26,
                fontWeight: FontWeight.bold,
                color: theme.colorScheme.onSurface,
              ),
            ),
            if (user.age != null) ...[
              Text(
                ', ${user.age}',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 22,
                  fontWeight: FontWeight.w400,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
            if (user.isVerified) ...[
              const SizedBox(width: 8),
              const Icon(Icons.verified, color: AppTheme.emerald, size: 22),
            ],
          ],
        ),
        if (user.jobTitle != null) ...[
          const SizedBox(height: 4),
          Text(
            user.jobTitle!,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
        if (user.healthcareVerificationBadge != null) ...[
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
            decoration: BoxDecoration(
              color: AppTheme.emerald.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(999),
            ),
            child: Text(
              _healthcareBadgeLabel(user),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppTheme.emerald,
              ),
            ),
          ),
        ],
      ],
    );
  }

  Widget _buildPlanBadge(UserModel user, ThemeData theme) {
    Color planColor;
    IconData planIcon;
    switch (user.plan) {
      case SubscriptionPlan.tech:
        planColor = const Color(0xFF2563EB);
        planIcon = Icons.computer;
        break;
      case SubscriptionPlan.college:
        planColor = AppTheme.emerald;
        planIcon = Icons.school;
        break;
      case SubscriptionPlan.nurse:
        planColor = AppTheme.warmRose;
        planIcon = Icons.favorite;
        break;
      case SubscriptionPlan.doctor:
        planColor = AppTheme.softAmber;
        planIcon = Icons.diamond;
        break;
      default:
        planColor = AppTheme.warmGray;
        planIcon = Icons.person;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: planColor.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: planColor.withValues(alpha: 0.3)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(planIcon, color: planColor, size: 18),
          const SizedBox(width: 6),
          Text(
            _planLabel(user.plan),
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: planColor,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Boost Section ──────────────────────────────────────────────────────

  Widget _buildBoostSection(UserModel user, ThemeData theme) {
    final isActive = user.isBoostActive;
    final hasFreeBoost =
        user.plan == SubscriptionPlan.nurse ||
        user.plan == SubscriptionPlan.doctor;

    if (isActive) {
      return _buildActiveBoostBanner(theme);
    }

    return _buildBoostButton(user, hasFreeBoost, theme);
  }

  Widget _buildActiveBoostBanner(ThemeData theme) {
    final minutes = _boostRemaining.inMinutes;
    final seconds = _boostRemaining.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        gradient: AppTheme.accentGradient,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: AppTheme.softAmber.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          const Icon(Icons.rocket_launch, color: Colors.white, size: 22)
              .animate(onPlay: (c) => c.repeat(reverse: true))
              .scaleXY(begin: 1.0, end: 1.15, duration: 600.ms),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  _t('profile_boosted'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                Text(
                  _t('appears_first_discover'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    color: Colors.white.withValues(alpha: 0.8),
                  ),
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Text(
              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: Colors.white,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBoostButton(UserModel user, bool hasFreeBoost, ThemeData theme) {
    final boostAdsWatched = _effectiveBoostCredits(user);

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: AppTheme.softAmber.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.rocket_launch,
                  color: AppTheme.softAmber,
                  size: 24,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _t('boost_profile'),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: theme.colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      hasFreeBoost
                          ? _t('tap_boost_30')
                          : _tf('watch_ads_to_boost', {
                              'count': boostAdsWatched,
                            }),
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
          const SizedBox(height: 12),
          // Ad progress indicators for non-premium users
          if (!hasFreeBoost) ...[
            Row(
              children: [
                Expanded(
                  child: _AdProgressDot(
                    filled: boostAdsWatched >= 1,
                    label: _t('ad_one'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _AdProgressDot(
                    filled: boostAdsWatched >= 2,
                    label: _t('ad_two'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
          ],
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _isBoostingInProgress
                  ? null
                  : () => _handleBoostTap(user, hasFreeBoost),
              icon: _isBoostingInProgress
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Icon(
                      hasFreeBoost
                          ? Icons.rocket_launch
                          : Icons.play_circle_filled,
                      size: 20,
                    ),
              label: Text(
                hasFreeBoost
                    ? _t('boost_now')
                    : boostAdsWatched >= 2
                    ? _t('activate_boost')
                    : _tf('watch_ad_count', {'count': boostAdsWatched}),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                ),
              ),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.softAmber,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _handleBoostTap(UserModel user, bool hasFreeBoost) async {
    if (hasFreeBoost) {
      await _activateBoost(user.id);
    } else if (_effectiveBoostCredits(user) >= 2) {
      await _activateBoost(user.id);
      setState(() => _boostAdsWatched = 0);
    } else {
      await _watchBoostAd(user);
    }
  }

  int _effectiveBoostCredits(UserModel user) {
    final credits = _boostAdsWatched > 0
        ? _boostAdsWatched
        : user.boostAdCredits;
    return credits.clamp(0, 2).toInt();
  }

  Future<void> _watchBoostAd(UserModel user) async {
    setState(() => _isBoostingInProgress = true);

    try {
      final adMobService = AdMobService.instance;

      // Ensure an ad is loaded
      if (!adMobService.isRewardedAdReady) {
        adMobService.loadRewardedAd();
        // Wait up to 5 seconds for the ad to load
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (adMobService.isRewardedAdReady) break;
        }
      }

      if (!adMobService.isRewardedAdReady) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _t('ad_not_available_retry'),
                style: GoogleFonts.plusJakartaSans(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }

      bool rewarded = false;
      final shown = await adMobService.showRewardedAdWithCallback(
        onReward: (type, amount) {
          rewarded = true;
        },
      );

      if (shown && rewarded && mounted) {
        final boostAdsWatched = await ref
            .read(videoServiceProvider)
            .recordBoostAdCredit(user.id);

        if (!mounted) return;
        setState(() {
          _boostAdsWatched = boostAdsWatched;
        });

        if (boostAdsWatched >= 2) {
          await _activateBoost(user.id);
          if (mounted) setState(() => _boostAdsWatched = 0);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                _tf('ad_watched_more', {'count': 2 - boostAdsWatched}),
                style: GoogleFonts.plusJakartaSans(),
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: AppTheme.softAmber,
            ),
          );
        }
      } else if (!shown && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('could_not_show_ad'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfilePage] Ad error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('failed_load_ad'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBoostingInProgress = false);
    }
  }

  Future<void> _activateBoost(String uid) async {
    setState(() => _isBoostingInProgress = true);

    try {
      final result = await ref
          .read(videoServiceProvider)
          .activateProfileBoost(uid);

      if (mounted) {
        setState(() {
          _boostRemaining = result.expiresAt.difference(DateTime.now());
          _boostAdsWatched = result.boostAdCredits;
        });
      }

      // Restart the countdown timer
      _startBoostTimer();

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('profile_boosted_30'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.emerald,
          ),
        );
      }
    } catch (e) {
      debugPrint('[ProfilePage] Boost activation error: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('failed_activate_boost'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.warmRose,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isBoostingInProgress = false);
    }
  }

  // ─── Stats Row ──────────────────────────────────────────────────────────

  Widget _buildStatsRow(UserModel user, ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          _StatColumn(
            value: user.stats.likesReceived,
            label: _t('likes'),
            color: AppTheme.warmRose,
          ),
          Container(
            height: 40,
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          _StatColumn(
            value: user.stats.matches,
            label: _t('matches'),
            color: AppTheme.softAmber,
          ),
          Container(
            height: 40,
            width: 1,
            color: theme.colorScheme.outline.withValues(alpha: 0.2),
          ),
          _StatColumn(
            value: user.stats.likesReceived + user.stats.matches,
            label: _t('profile_views'),
            color: AppTheme.deepPlum,
          ),
        ],
      ),
    );
  }

  // ─── Quick Actions ──────────────────────────────────────────────────────

  Widget _buildQuickActions(UserModel user, ThemeData theme) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.edit,
                label: _t('edit_profile'),
                color: AppTheme.deepPlum,
                onTap: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => const EditProfilePage()),
                  );
                },
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.card_giftcard,
                label: _t('gift_store'),
                color: AppTheme.warmRose,
                onTap: () => context.push('/gifts'),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: user.isVerified
                    ? Icons.verified
                    : Icons.verified_outlined,
                label: user.isVerified ? _t('verified') : _t('verify_now'),
                color: user.isVerified ? AppTheme.emerald : AppTheme.warmRose,
                onTap: () {
                  context.push(RoutePaths.verification);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Row(
          children: [
            Expanded(
              child: _QuickActionButton(
                icon: Icons.forum_outlined,
                label: _t('community'),
                color: const Color(0xFF0F766E),
                onTap: () => context.push(RoutePaths.social),
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _QuickActionButton(
                icon: Icons.local_hospital_outlined,
                label: _t('nurse_hub'),
                color: const Color(0xFF2563EB),
                onTap: () => context.push(RoutePaths.nurseHub),
              ),
            ),
          ],
        ),
      ],
    );
  }

  // ─── Photos Section ─────────────────────────────────────────────────────

  Widget _buildPhotosSection(UserModel user, ThemeData theme) {
    final photos = _allPhotos(user);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('my_photos'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        _ProfilePhotoCarousel(
          photos: photos,
          onPhotoTap: (index) => _showFullImageGallery(context, photos, index),
        ),
      ],
    );
  }

  bool _hasShiftAvailability(UserModel user) {
    return user.shiftType != null ||
        user.preferredDatingWindow != null ||
        user.availableAfterShift ||
        (user.quietHoursStart != null && user.quietHoursEnd != null);
  }

  Widget _buildShiftAvailabilityCard(UserModel user, ThemeData theme) {
    final locale = ref.read(localeProvider);
    final items = <_ShiftAvailabilityItem>[];

    if (user.shiftType != null) {
      items.add(
        _ShiftAvailabilityItem(
          icon: _shiftIcon(user.shiftType!),
          label: _t('shift_type'),
          value: AppLocalizations.shiftTypeLabel(user.shiftType!.value, locale),
          color: AppTheme.deepPlum,
        ),
      );
    }
    if (user.preferredDatingWindow != null) {
      items.add(
        _ShiftAvailabilityItem(
          icon: Icons.event_available_outlined,
          label: _t('preferred_dating_window'),
          value: AppLocalizations.datingWindowLabel(
            user.preferredDatingWindow!.value,
            locale,
          ),
          color: const Color(0xFF0284C7),
        ),
      );
    }
    if (user.availableAfterShift) {
      items.add(
        _ShiftAvailabilityItem(
          icon: Icons.local_cafe_outlined,
          label: _t('available_after_shift'),
          value: _t('open_after_shift'),
          color: AppTheme.emerald,
        ),
      );
    }
    if (user.quietHoursStart != null && user.quietHoursEnd != null) {
      items.add(
        _ShiftAvailabilityItem(
          icon: Icons.notifications_paused_outlined,
          label: _t('quiet_hours_label'),
          value: _tf('quiet_hours', {
            'start': user.quietHoursStart,
            'end': user.quietHoursEnd,
          }),
          color: AppTheme.softAmber,
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('shift_availability'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.all(14),
          child: Column(
            children: items.map((item) {
              return Padding(
                padding: const EdgeInsets.symmetric(vertical: 6),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: item.color.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(item.icon, color: item.color, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            item.value,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  IconData _shiftIcon(ShiftType shift) {
    return switch (shift) {
      ShiftType.dayShift => Icons.wb_sunny_outlined,
      ShiftType.nightShift => Icons.nightlight_round,
      ShiftType.rotatingShift => Icons.sync_rounded,
      ShiftType.flexible => Icons.event_available_outlined,
    };
  }

  List<String> _allPhotos(UserModel user) {
    final seen = <String>{};
    final photos = <String>[];
    void add(String? url) {
      final value = url?.trim();
      if (value == null || value.isEmpty || seen.contains(value)) return;
      seen.add(value);
      photos.add(value);
    }

    add(user.photoUrl);
    for (final url in user.gallery) {
      add(url);
    }
    return photos;
  }

  // ─── About Section ──────────────────────────────────────────────────────

  Widget _buildAboutSection(UserModel user, ThemeData theme) {
    final infoItems = <_InfoRow>[];

    if (user.bio != null && user.bio!.isNotEmpty) {
      infoItems.add(
        _InfoRow(icon: Icons.info_outline, label: _t('bio'), value: user.bio!),
      );
    }
    if (user.jobTitle != null) {
      infoItems.add(
        _InfoRow(
          icon: Icons.work_outline,
          label: _t('job'),
          value: user.jobTitle!,
        ),
      );
    }
    if (user.hospital != null && user.hospital!.isNotEmpty) {
      infoItems.add(
        _InfoRow(
          icon: Icons.local_hospital_outlined,
          label: _t('hospital'),
          value: user.hospital!,
        ),
      );
    }
    if (user.department != null && user.department!.isNotEmpty) {
      infoItems.add(
        _InfoRow(
          icon: Icons.business,
          label: _t('department'),
          value: user.department!,
        ),
      );
    }
    if (user.yearsExperience != null) {
      infoItems.add(
        _InfoRow(
          icon: Icons.timeline,
          label: _t('experience'),
          value: _tf('years_experience', {'years': user.yearsExperience}),
        ),
      );
    }
    if (user.shiftType != null) {
      infoItems.add(
        _InfoRow(
          icon: Icons.schedule,
          label: _t('shift'),
          value: AppLocalizations.shiftTypeLabel(
            user.shiftType!.value,
            ref.read(localeProvider),
          ),
        ),
      );
    }
    if (user.location != null && user.location!.isNotEmpty) {
      infoItems.add(
        _InfoRow(
          icon: Icons.location_on_outlined,
          label: _t('location'),
          value: user.location!,
        ),
      );
    }
    if (user.lookingFor != null) {
      infoItems.add(
        _InfoRow(
          icon: Icons.favorite_outline,
          label: _t('looking_for'),
          value: _lookingForLabel(user.lookingFor!),
        ),
      );
    }

    if (infoItems.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('about_me'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        GlassCard(
          padding: const EdgeInsets.symmetric(vertical: 8),
          child: Column(
            children: infoItems.asMap().entries.map((entry) {
              final item = entry.value;
              final isLast = entry.key == infoItems.length - 1;
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(item.icon, size: 20, color: AppTheme.deepPlum),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.label,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 12,
                                  color: theme.colorScheme.onSurfaceVariant,
                                ),
                              ),
                              Text(
                                item.value,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  fontWeight: FontWeight.w500,
                                  color: theme.colorScheme.onSurface,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!isLast)
                    Divider(
                      height: 1,
                      indent: 48,
                      color: theme.colorScheme.outline.withValues(alpha: 0.15),
                    ),
                ],
              );
            }).toList(),
          ),
        ),
      ],
    );
  }

  // ─── Interests Section ──────────────────────────────────────────────────

  Widget _buildInterestsSection(UserModel user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('my_interests'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.interests.map((interest) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.deepPlum.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.deepPlum.withValues(alpha: 0.2),
                ),
              ),
              child: Text(
                interest,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: AppTheme.deepPlum,
                ),
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  // ─── Languages Section ──────────────────────────────────────────────────

  Widget _buildLanguagesSection(UserModel user, ThemeData theme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          _t('languages_i_speak'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: theme.colorScheme.onSurface,
          ),
        ),
        const SizedBox(height: 10),
        Wrap(
          spacing: 8,
          runSpacing: 8,
          children: user.languages.map((lang) {
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: AppTheme.warmRose.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(
                  color: AppTheme.warmRose.withValues(alpha: 0.2),
                ),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.language,
                    size: 14,
                    color: AppTheme.warmRose,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    lang,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: AppTheme.warmRose,
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ],
    );
  }

  void _showFullImageGallery(
    BuildContext context,
    List<String> photos,
    int initialIndex,
  ) {
    showDialog(
      context: context,
      builder: (ctx) =>
          _FullScreenPhotoGallery(photos: photos, initialIndex: initialIndex),
    );
  }
}

class _ShiftAvailabilityItem {
  const _ShiftAvailabilityItem({
    required this.icon,
    required this.label,
    required this.value,
    required this.color,
  });

  final IconData icon;
  final String label;
  final String value;
  final Color color;
}

// ─── Profile Photo Carousel ───────────────────────────────────────────────

class _ProfilePhotoCarousel extends StatefulWidget {
  const _ProfilePhotoCarousel({required this.photos, required this.onPhotoTap});

  final List<String> photos;
  final ValueChanged<int> onPhotoTap;

  @override
  State<_ProfilePhotoCarousel> createState() => _ProfilePhotoCarouselState();
}

class _ProfilePhotoCarouselState extends State<_ProfilePhotoCarousel> {
  late final PageController _controller;
  int _currentIndex = 0;

  @override
  void initState() {
    super.initState();
    _controller = PageController(viewportFraction: 0.88);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Column(
      children: [
        SizedBox(
          height: 260,
          child: PageView.builder(
            controller: _controller,
            itemCount: widget.photos.length,
            onPageChanged: (index) => setState(() => _currentIndex = index),
            itemBuilder: (context, index) {
              final selected = index == _currentIndex;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 220),
                curve: Curves.easeOut,
                margin: EdgeInsets.only(
                  right: 10,
                  top: selected ? 0 : 12,
                  bottom: selected ? 0 : 12,
                ),
                child: GestureDetector(
                  onTap: () => widget.onPhotoTap(index),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(22),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        AppNetworkImage(
                          imageUrl: widget.photos[index],
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: AppTheme.softLavender,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.softLavender,
                            child: const Icon(Icons.broken_image, size: 42),
                          ),
                        ),
                        Positioned(
                          left: 12,
                          bottom: 12,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 10,
                              vertical: 5,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.black.withValues(alpha: 0.42),
                              borderRadius: BorderRadius.circular(999),
                            ),
                            child: Text(
                              '${index + 1}/${widget.photos.length}',
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
        ),
        if (widget.photos.length > 1) ...[
          const SizedBox(height: 12),
          SmoothPageIndicator(
            controller: _controller,
            count: widget.photos.length,
            effect: WormEffect(
              dotWidth: 7,
              dotHeight: 7,
              spacing: 6,
              activeDotColor: AppTheme.deepPlum,
              dotColor: theme.colorScheme.outline.withValues(alpha: 0.28),
            ),
          ),
        ],
      ],
    );
  }
}

class _FullScreenPhotoGallery extends StatefulWidget {
  const _FullScreenPhotoGallery({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_FullScreenPhotoGallery> createState() =>
      _FullScreenPhotoGalleryState();
}

class _FullScreenPhotoGalleryState extends State<_FullScreenPhotoGallery> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex.clamp(0, widget.photos.length - 1);
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Dialog.fullscreen(
      backgroundColor: Colors.black,
      child: SafeArea(
        child: Stack(
          children: [
            PageView.builder(
              controller: _controller,
              itemCount: widget.photos.length,
              onPageChanged: (index) => setState(() => _currentIndex = index),
              itemBuilder: (context, index) {
                return InteractiveViewer(
                  minScale: 1,
                  maxScale: 4,
                  child: Center(
                    child: AppNetworkImage(
                      imageUrl: widget.photos[index],
                      fit: BoxFit.contain,
                      placeholder: (_, __) => const Center(
                        child: CircularProgressIndicator(color: Colors.white),
                      ),
                      errorWidget: (_, __, ___) => const Icon(
                        Icons.broken_image,
                        color: Colors.white,
                        size: 56,
                      ),
                    ),
                  ),
                );
              },
            ),
            Positioned(
              top: 12,
              right: 12,
              child: IconButton.filled(
                onPressed: () => Navigator.of(context).pop(),
                style: IconButton.styleFrom(
                  backgroundColor: Colors.white.withValues(alpha: 0.16),
                ),
                icon: const Icon(Icons.close_rounded, color: Colors.white),
              ),
            ),
            Positioned(
              left: 20,
              bottom: 28,
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(999),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: Text(
                  '${_currentIndex + 1}/${widget.photos.length}',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
            if (widget.photos.length > 1)
              Positioned(
                right: 20,
                bottom: 34,
                child: SmoothPageIndicator(
                  controller: _controller,
                  count: widget.photos.length,
                  effect: WormEffect(
                    dotWidth: 7,
                    dotHeight: 7,
                    spacing: 6,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white.withValues(alpha: 0.32),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _AdProgressDot extends StatelessWidget {
  const _AdProgressDot({required this.filled, required this.label});

  final bool filled;
  final String label;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: filled
            ? AppTheme.softAmber.withValues(alpha: 0.15)
            : theme.colorScheme.outline.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(
          color: filled
              ? AppTheme.softAmber.withValues(alpha: 0.3)
              : theme.colorScheme.outline.withValues(alpha: 0.15),
        ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            filled ? Icons.check_circle : Icons.radio_button_unchecked,
            color: filled
                ? AppTheme.softAmber
                : theme.colorScheme.onSurfaceVariant,
            size: 16,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: filled
                  ? AppTheme.softAmber
                  : theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Supporting Widgets ─────────────────────────────────────────────────────

class _StatColumn extends StatelessWidget {
  const _StatColumn({
    required this.value,
    required this.label,
    required this.color,
  });

  final int value;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      children: [
        TweenAnimationBuilder<int>(
          tween: IntTween(begin: 0, end: value),
          duration: const Duration(milliseconds: 800),
          builder: (context, val, _) {
            return Text(
              '$val',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            );
          },
        ),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: theme.colorScheme.onSurfaceVariant,
          ),
        ),
      ],
    );
  }
}

class _QuickActionButton extends StatelessWidget {
  const _QuickActionButton({
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
    final theme = Theme.of(context);
    return GestureDetector(
      onTap: onTap,
      child: GlassCard(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: color, size: 22),
            ),
            const SizedBox(height: 6),
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: theme.colorScheme.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow {
  final IconData icon;
  final String label;
  final String value;

  _InfoRow({required this.icon, required this.label, required this.value});
}
