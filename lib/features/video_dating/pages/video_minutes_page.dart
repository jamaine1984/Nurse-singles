import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/admob_service.dart';
import 'package:nightingale_heart/core/services/payment_service.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/features/video_dating/services/video_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Stream provider for video minutes
// ---------------------------------------------------------------------------

final _minutesProvider = StreamProvider.family<int, String>((ref, userId) {
  return ref.watch(videoServiceProvider).getUserVideoMinutes(userId);
});

final _dailyVideoAdUsageProvider =
    StreamProvider.family<Map<String, dynamic>, String>((ref, userId) {
      final now = DateTime.now().toUtc();
      final dateKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      return FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .collection('usage')
          .doc('daily_$dateKey')
          .snapshots()
          .map((doc) => doc.data() ?? const <String, dynamic>{});
    });

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// A page where users can see their current video minutes and earn more via
/// rewarded ads.
class VideoMinutesPage extends ConsumerStatefulWidget {
  const VideoMinutesPage({super.key});

  @override
  ConsumerState<VideoMinutesPage> createState() => _VideoMinutesPageState();
}

class _VideoMinutesPageState extends ConsumerState<VideoMinutesPage> {
  bool _adLoading = false;
  String? _purchasingProductId;
  late Future<List<StoreProduct>> _productsFuture;

  @override
  void initState() {
    super.initState();
    _productsFuture = ref.read(paymentServiceProvider).getVideoMinuteProducts();
  }

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  // ---- Actions -----------------------------------------------------------

  Future<void> _watchAd() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final admob = ref.read(admobServiceProvider);
    if (!admob.isRewardedAdReady) {
      setState(() => _adLoading = true);
      admob.loadRewardedAd();
      await Future.delayed(const Duration(seconds: 3));
      if (!mounted) return;
      setState(() => _adLoading = false);

      if (!admob.isRewardedAdReady) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text(_t('ad_not_available_retry'))));
        return;
      }
    }

    final reward = await admob.showRewardedAd();
    if (reward != null && reward > 0) {
      final minutesAdded = await ref
          .read(videoServiceProvider)
          .addVideoMinutes(user.id, 0);
      if (!mounted) return;
      final message = minutesAdded > 0
          ? _tf('video_minutes_earned_amount', {'minutes': minutesAdded})
          : _t('video_ad_counted');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
  }

  Future<void> _buyProduct(StoreProduct product) async {
    setState(() => _purchasingProductId = product.identifier);
    try {
      final result = await ref
          .read(paymentServiceProvider)
          .purchaseVideoMinuteProduct(product);
      if (!mounted) return;

      final credited = result?.creditedVideoMinutes ?? 0;
      final message = credited > 0
          ? _tf('video_minutes_purchase_success', {'minutes': credited})
          : _t('video_minutes_purchase_syncing');
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } finally {
      if (mounted) setState(() => _purchasingProductId = null);
    }
  }

  int _minutesForProduct(String id) {
    switch (id) {
      case AppConstants.videoMinutes400:
        return 400;
      case AppConstants.videoMinutes800:
        return 800;
      case AppConstants.videoMinutes2500:
        return 2500;
      default:
        return 0;
    }
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    ref.watch(localeProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(child: Text(_tf('error_loading_user', {'error': e}))),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(body: Center(child: Text(_t('please_sign_in'))));
        }

        final minutesAsync = ref.watch(_minutesProvider(user.id));
        final adUsageAsync = ref.watch(_dailyVideoAdUsageProvider(user.id));

        return Scaffold(
          appBar: AppBar(
            title: Text(
              _t('video_minutes'),
              style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
            ),
          ),
          body: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ---- Animated minute counter -----------------------------
                _MinutesHeader(
                  minutesAsync: minutesAsync,
                  availableLabel: _t('video_minutes_available'),
                ),
                const SizedBox(height: 28),

                // ---- Section title ---------------------------------------
                Text(
                  _t('ways_to_earn_minutes'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 16),

                // ---- Watch Ads -------------------------------------------
                _EarnCard(
                  index: 0,
                  icon: Icons.play_circle_filled_rounded,
                  iconColor: AppTheme.deepPlum,
                  title: _t('watch_short_ad'),
                  description: _t('watch_short_ad_body'),
                  actionLabel: _adLoading ? _t('loading') : _t('watch_ad'),
                  onAction: _adLoading ? null : _watchAd,
                ),
                adUsageAsync.when(
                  data: (usage) => _VideoAdProgressCard(
                    adsWatched:
                        (usage['videoAdRewardsClaimed'] as num?)?.toInt() ?? 0,
                    minutesEarned:
                        (usage['videoRewardMinutes'] as num?)?.toInt() ?? 0,
                    watchedTodayLabel: (watched) => _tf(
                      'video_ads_watched_today',
                      {'count': watched, 'total': 200},
                    ),
                    nextMilestoneLabel: (remaining, minutes) => _tf(
                      'video_ads_next_milestone',
                      {'remaining': remaining, 'minutes': minutes},
                    ),
                    unlockedLabel: (minutes) => _tf(
                      'video_ads_milestone_unlocked',
                      {'minutes': minutes},
                    ),
                    earnedLabel: (minutes) => _tf(
                      'video_ads_minutes_earned_today',
                      {'minutes': minutes},
                    ),
                  ),
                  loading: () => const LinearProgressIndicator(minHeight: 6),
                  error: (_, __) => const SizedBox.shrink(),
                ),
                const SizedBox(height: 24),
                Text(
                  _t('buy_extra_video_minutes'),
                  style: theme.textTheme.titleLarge,
                ),
                const SizedBox(height: 12),
                FutureBuilder<List<StoreProduct>>(
                  future: _productsFuture,
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }

                    final products = snapshot.data ?? const <StoreProduct>[];
                    if (products.isEmpty) {
                      return GlassCard(
                        borderRadius: AppTheme.borderRadiusMedium,
                        child: Text(_t('video_minute_store_unavailable')),
                      );
                    }

                    return Column(
                      children: [
                        for (var i = 0; i < products.length; i++)
                          _PurchaseCard(
                            index: i,
                            product: products[i],
                            minutes: _minutesForProduct(products[i].identifier),
                            isLoading:
                                _purchasingProductId == products[i].identifier,
                            onBuy: () => _buyProduct(products[i]),
                          ),
                      ],
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}

// ---------------------------------------------------------------------------
// Sub-widgets
// ---------------------------------------------------------------------------

class _MinutesHeader extends StatelessWidget {
  const _MinutesHeader({
    required this.minutesAsync,
    required this.availableLabel,
  });

  final AsyncValue<int> minutesAsync;
  final String availableLabel;

  @override
  Widget build(BuildContext context) {
    return Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 32, horizontal: 24),
          decoration: BoxDecoration(
            gradient: AppTheme.primaryGradient,
            borderRadius: BorderRadius.circular(AppTheme.borderRadiusLarge),
            boxShadow: [
              BoxShadow(
                color: AppTheme.deepPlum.withValues(alpha: 0.3),
                blurRadius: 24,
                offset: const Offset(0, 8),
              ),
            ],
          ),
          child: Column(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 40,
                color: Colors.white70,
              ),
              const SizedBox(height: 12),
              minutesAsync.when(
                data: (minutes) => TweenAnimationBuilder<int>(
                  tween: IntTween(begin: 0, end: minutes),
                  duration: const Duration(milliseconds: 1200),
                  curve: Curves.easeOutCubic,
                  builder: (context, value, _) {
                    return Text(
                      '$value',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 56,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
                loading: () => Text(
                  '...',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                ),
                error: (_, __) => Text(
                  '--',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 56,
                    fontWeight: FontWeight.w700,
                    color: Colors.white54,
                  ),
                ),
              ),
              Text(
                availableLabel,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 500.ms)
        .slideY(begin: -0.05, end: 0, duration: 500.ms);
  }
}

class _VideoAdProgressCard extends StatelessWidget {
  const _VideoAdProgressCard({
    required this.adsWatched,
    required this.minutesEarned,
    required this.watchedTodayLabel,
    required this.nextMilestoneLabel,
    required this.unlockedLabel,
    required this.earnedLabel,
  });

  final int adsWatched;
  final int minutesEarned;
  final String Function(int count) watchedTodayLabel;
  final String Function(int remaining, int minutes) nextMilestoneLabel;
  final String Function(int minutes) unlockedLabel;
  final String Function(int minutes) earnedLabel;

  static const _milestones = [
    _AdMilestone(10, 1),
    _AdMilestone(50, 7),
    _AdMilestone(200, 35),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final watchedToday = adsWatched.clamp(0, 200).toInt();

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            borderRadius: AppTheme.borderRadiusMedium,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: AppTheme.emerald.withValues(alpha: 0.12),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.monitor_heart_rounded,
                        color: AppTheme.emerald,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            watchedTodayLabel(watchedToday),
                            style: theme.textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            earnedLabel(minutesEarned),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                for (var i = 0; i < _milestones.length; i++) ...[
                  _VideoAdMilestoneRow(
                    milestone: _milestones[i],
                    previousAds: i == 0 ? 0 : _milestones[i - 1].ads,
                    adsWatched: adsWatched,
                    nextMilestoneLabel: nextMilestoneLabel,
                    unlockedLabel: unlockedLabel,
                  ),
                  if (i != _milestones.length - 1) const SizedBox(height: 12),
                ],
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: 80.ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: 80.ms);
  }
}

class _VideoAdMilestoneRow extends StatelessWidget {
  const _VideoAdMilestoneRow({
    required this.milestone,
    required this.previousAds,
    required this.adsWatched,
    required this.nextMilestoneLabel,
    required this.unlockedLabel,
  });

  final _AdMilestone milestone;
  final int previousAds;
  final int adsWatched;
  final String Function(int remaining, int minutes) nextMilestoneLabel;
  final String Function(int minutes) unlockedLabel;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final segmentTotal = milestone.ads - previousAds;
    final segmentWatched = (adsWatched - previousAds)
        .clamp(0, segmentTotal)
        .toInt();
    final progress = segmentTotal == 0 ? 0.0 : segmentWatched / segmentTotal;
    final isUnlocked = adsWatched >= milestone.ads;
    final remaining = (milestone.ads - adsWatched)
        .clamp(0, milestone.ads)
        .toInt();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                isUnlocked
                    ? unlockedLabel(milestone.minutes)
                    : nextMilestoneLabel(remaining, milestone.minutes),
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const SizedBox(width: 10),
            Text(
              '$segmentWatched/$segmentTotal',
              style: theme.textTheme.labelMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
        const SizedBox(height: 6),
        ClipRRect(
          borderRadius: BorderRadius.circular(999),
          child: LinearProgressIndicator(
            minHeight: 8,
            value: progress,
            color: isUnlocked ? AppTheme.emerald : AppTheme.cyan,
            backgroundColor: theme.colorScheme.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }
}

class _AdMilestone {
  const _AdMilestone(this.ads, this.minutes);

  final int ads;
  final int minutes;
}

class _PurchaseCard extends StatelessWidget {
  const _PurchaseCard({
    required this.index,
    required this.product,
    required this.minutes,
    required this.isLoading,
    required this.onBuy,
  });

  final int index;
  final StoreProduct product;
  final int minutes;
  final bool isLoading;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final title = minutes > 0 ? '$minutes Video Minutes' : product.title;

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            borderRadius: AppTheme.borderRadiusMedium,
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.add_call,
                    color: AppTheme.emerald,
                    size: 24,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        product.description,
                        style: Theme.of(context).textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),
                ElevatedButton(
                  onPressed: isLoading ? null : onBuy,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  child: isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : Text(product.priceString),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 80).ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: (index * 80).ms);
  }
}

/// A glass-card option for earning minutes.
class _EarnCard extends StatelessWidget {
  const _EarnCard({
    required this.index,
    required this.icon,
    required this.iconColor,
    required this.title,
    required this.description,
    required this.actionLabel,
    this.onAction,
  });

  final int index;
  final IconData icon;
  final Color iconColor;
  final String title;
  final String description;
  final String actionLabel;
  final VoidCallback? onAction;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassCard(
            borderRadius: AppTheme.borderRadiusMedium,
            child: Row(
              children: [
                // Icon
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    color: iconColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(icon, color: iconColor, size: 26),
                ),
                const SizedBox(width: 14),

                // Text
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: theme.textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        description,
                        style: theme.textTheme.bodySmall,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 10),

                // Action button
                ElevatedButton(
                  onPressed: onAction,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    textStyle: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  child: Text(actionLabel),
                ),
              ],
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms, delay: (index * 80).ms)
        .slideX(begin: 0.05, end: 0, duration: 400.ms, delay: (index * 80).ms);
  }
}
