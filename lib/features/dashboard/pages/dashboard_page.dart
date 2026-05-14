import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/subscription/pages/paywall_page.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

class DashboardPage extends ConsumerStatefulWidget {
  const DashboardPage({super.key});

  @override
  ConsumerState<DashboardPage> createState() => _DashboardPageState();
}

class _DashboardPageState extends ConsumerState<DashboardPage> {
  Timer? _boostTimer;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _dailyUsageSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _monthlyUsageSub;
  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _matchCountSub;
  String? _usageUserId;
  Duration _boostRemaining = Duration.zero;

  // Daily usage data from Firestore
  int _dailyMessagesSent = 0;
  int _dailyLikesSent = 0;
  int _dailySuperLikesSent = 0;
  int _dailyMessagesRefilled = 0;
  int _dailyLikesRefilled = 0;

  // Monthly usage data from Firestore
  int _monthlySuperLikesSent = 0;
  int _monthlyVideoMinutesUsed = 0;
  int _matchCount = 0;

  bool _isLoadingUsage = true;

  String _t(String key) {
    return AppLocalizations.translate(key, Localizations.localeOf(context));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(
      key,
      Localizations.localeOf(context),
      values,
    );
  }

  @override
  void initState() {
    super.initState();
    _startBoostTimer();
  }

  @override
  void dispose() {
    _boostTimer?.cancel();
    _dailyUsageSub?.cancel();
    _monthlyUsageSub?.cancel();
    _matchCountSub?.cancel();
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

  Future<void> _loadUsageData() async {
    final uid = ref.read(currentUserIdProvider);
    if (uid == null) {
      setState(() => _isLoadingUsage = false);
      return;
    }

    try {
      final firestore = FirebaseFirestore.instance;
      final now = DateTime.now().toUtc();
      final todayKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';

      // Load daily usage
      final dailyDoc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('usage')
          .doc('daily_$todayKey')
          .get();

      if (dailyDoc.exists) {
        final data = dailyDoc.data()!;
        _dailyMessagesSent = (data['messagesSent'] as num?)?.toInt() ?? 0;
        _dailyLikesSent = (data['likesSent'] as num?)?.toInt() ?? 0;
        _dailySuperLikesSent = (data['superLikesSent'] as num?)?.toInt() ?? 0;
        _dailyMessagesRefilled =
            (data['messagesRefilled'] as num?)?.toInt() ?? 0;
        _dailyLikesRefilled = (data['likesRefilled'] as num?)?.toInt() ?? 0;
      }

      // Load monthly usage
      final monthlyDoc = await firestore
          .collection(AppConstants.usersCollection)
          .doc(uid)
          .collection('usage')
          .doc('monthly_$monthKey')
          .get();

      if (monthlyDoc.exists) {
        final data = monthlyDoc.data()!;
        _monthlySuperLikesSent = (data['superLikesSent'] as num?)?.toInt() ?? 0;
        _monthlyVideoMinutesUsed =
            (data['videoMinutesUsed'] as num?)?.toInt() ?? 0;
      }
    } catch (e) {
      debugPrint('[DashboardPage] Failed to load usage data: $e');
    } finally {
      if (mounted) setState(() => _isLoadingUsage = false);
    }
  }

  void _ensureUsageWatcher(String uid) {
    if (_usageUserId == uid) return;
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted || _usageUserId == uid) return;
      _watchUsageData(uid);
    });
  }

  void _watchUsageData(String uid) {
    _dailyUsageSub?.cancel();
    _monthlyUsageSub?.cancel();
    _matchCountSub?.cancel();
    _usageUserId = uid;

    if (mounted) {
      setState(() => _isLoadingUsage = true);
    }

    final firestore = FirebaseFirestore.instance;
    final now = DateTime.now().toUtc();
    final todayKey =
        '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
    final monthKey = '${now.year}-${now.month.toString().padLeft(2, '0')}';
    final usageRef = firestore
        .collection(AppConstants.usersCollection)
        .doc(uid)
        .collection('usage');

    _dailyUsageSub = usageRef
        .doc('daily_$todayKey')
        .snapshots()
        .listen(
          (doc) {
            final data = doc.data() ?? const <String, dynamic>{};
            if (!mounted) return;
            setState(() {
              _dailyMessagesSent = (data['messagesSent'] as num?)?.toInt() ?? 0;
              _dailyLikesSent = (data['likesSent'] as num?)?.toInt() ?? 0;
              _dailySuperLikesSent =
                  (data['superLikesSent'] as num?)?.toInt() ?? 0;
              _dailyMessagesRefilled =
                  (data['messagesRefilled'] as num?)?.toInt() ?? 0;
              _dailyLikesRefilled =
                  (data['likesRefilled'] as num?)?.toInt() ?? 0;
              _isLoadingUsage = false;
            });
          },
          onError: (Object error) {
            debugPrint('[DashboardPage] Daily usage stream failed: $error');
            if (mounted) setState(() => _isLoadingUsage = false);
          },
        );

    _monthlyUsageSub = usageRef
        .doc('monthly_$monthKey')
        .snapshots()
        .listen(
          (doc) {
            final data = doc.data() ?? const <String, dynamic>{};
            if (!mounted) return;
            setState(() {
              _monthlySuperLikesSent =
                  (data['superLikesSent'] as num?)?.toInt() ?? 0;
              _monthlyVideoMinutesUsed =
                  (data['videoMinutesUsed'] as num?)?.toInt() ?? 0;
              _isLoadingUsage = false;
            });
          },
          onError: (Object error) {
            debugPrint('[DashboardPage] Monthly usage stream failed: $error');
            if (mounted) setState(() => _isLoadingUsage = false);
          },
        );

    _matchCountSub = firestore
        .collection(AppConstants.matchesCollection)
        .where('users', arrayContains: uid)
        .snapshots()
        .listen(
          (snapshot) {
            if (!mounted) return;
            setState(() => _matchCount = snapshot.docs.length);
          },
          onError: (Object error) {
            debugPrint('[DashboardPage] Match count stream failed: $error');
          },
        );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0B15),
        title: Text(
          _t('dashboard'),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white70),
            onPressed: () {
              setState(() => _isLoadingUsage = true);
              _loadUsageData();
            },
          ),
        ],
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return Center(
              child: Text(
                _t('please_sign_in_dashboard'),
                style: GoogleFonts.plusJakartaSans(color: Colors.white54),
              ),
            );
          }
          _ensureUsageWatcher(user.id);
          return _buildDashboardContent(user, theme);
        },
        loading: () =>
            const Center(child: CircularProgressIndicator(color: Colors.white)),
        error: (err, _) => Center(
          child: Text(
            'Error: $err',
            style: GoogleFonts.plusJakartaSans(color: Colors.white54),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardContent(UserModel user, ThemeData theme) {
    final planFeatures =
        AppConstants.planFeatures[user.plan] ??
        AppConstants.planFeatures[SubscriptionPlan.free]!;

    final dailyMessagesLimit = planFeatures['dailyMessages'] as int;
    final dailyLikesLimit = planFeatures['dailyLikes'] as int;
    final dailySuperLikesLimit = planFeatures['dailySuperLikes'] as int?;
    final monthlySuperLikesLimit = planFeatures['monthlySuperLikes'] as int;
    final superLikesLimit = dailySuperLikesLimit ?? monthlySuperLikesLimit;
    final superLikesSent = dailySuperLikesLimit != null
        ? _dailySuperLikesSent
        : _monthlySuperLikesSent;

    // Calculate remaining values, accounting for refills
    // -1 means unlimited
    final messagesRemaining = dailyMessagesLimit == -1
        ? -1
        : (dailyMessagesLimit + _dailyMessagesRefilled - _dailyMessagesSent)
              .clamp(0, 999999);
    final likesRemaining = dailyLikesLimit == -1
        ? -1
        : (dailyLikesLimit + _dailyLikesRefilled - _dailyLikesSent).clamp(
            0,
            999999,
          );
    final superLikesRemaining = superLikesLimit == -1
        ? -1
        : (superLikesLimit - superLikesSent).clamp(0, 999999);
    final videoRemaining = user.videoMinutes.clamp(0, 999999);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Section 1: Today's Usage
          _buildSectionHeader(_t('todays_usage'), Icons.today),
          const SizedBox(height: 12),
          if (_isLoadingUsage)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            _buildTodayUsageGrid(
              messagesSent: _dailyMessagesSent,
              messagesRemaining: messagesRemaining,
              likesSent: _dailyLikesSent,
              likesRemaining: likesRemaining,
              superLikesSent: superLikesSent,
              superLikesRemaining: superLikesRemaining,
            ).animate().fadeIn(duration: 400.ms),
          const SizedBox(height: 24),

          // Section 2: Monthly Stats
          _buildSectionHeader(_t('monthly_stats'), Icons.calendar_month),
          const SizedBox(height: 12),
          if (_isLoadingUsage)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(20),
                child: CircularProgressIndicator(
                  color: Colors.white54,
                  strokeWidth: 2,
                ),
              ),
            )
          else
            _buildMonthlyStatsGrid(
              user: user,
              videoMinutesUsed: _monthlyVideoMinutesUsed,
              videoRemaining: videoRemaining,
              matchCount: _matchCount,
            ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),

          // Section 3: Subscription
          _buildSectionHeader(_t('subscription'), Icons.workspace_premium),
          const SizedBox(height: 12),
          _buildSubscriptionCard(
            user,
            planFeatures,
          ).animate().fadeIn(duration: 400.ms, delay: 200.ms),
          const SizedBox(height: 24),

          // Section 4: Boost Status
          _buildSectionHeader(_t('boost_status'), Icons.rocket_launch),
          const SizedBox(height: 12),
          _buildBoostStatusCard(
            user,
          ).animate().fadeIn(duration: 400.ms, delay: 300.ms),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, color: Colors.white54, size: 20),
        const SizedBox(width: 8),
        Text(
          title,
          style: GoogleFonts.playfairDisplay(
            fontSize: 20,
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
      ],
    );
  }

  // ─── Today's Usage ──────────────────────────────────────────────────────

  Widget _buildTodayUsageGrid({
    required int messagesSent,
    required int messagesRemaining,
    required int likesSent,
    required int likesRemaining,
    required int superLikesSent,
    required int superLikesRemaining,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _UsageCard(
                icon: Icons.message_rounded,
                iconColor: AppTheme.deepPlum,
                label: _t('messages'),
                sent: messagesSent,
                remaining: messagesRemaining,
                delay: 0,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _UsageCard(
                icon: Icons.favorite,
                iconColor: AppTheme.warmRose,
                label: _t('likes'),
                sent: likesSent,
                remaining: likesRemaining,
                delay: 100,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _UsageCard(
          icon: Icons.bolt,
          iconColor: AppTheme.softAmber,
          label: _t('superlikes_remaining'),
          sent: superLikesSent,
          remaining: superLikesRemaining,
          delay: 200,
          isWide: true,
        ),
      ],
    );
  }

  // ─── Monthly Stats ──────────────────────────────────────────────────────

  Widget _buildMonthlyStatsGrid({
    required UserModel user,
    required int videoMinutesUsed,
    required int videoRemaining,
    required int matchCount,
  }) {
    return Column(
      children: [
        Row(
          children: [
            Expanded(
              child: _MonthlyStatCard(
                icon: Icons.videocam_rounded,
                iconColor: AppTheme.emerald,
                label: _t('video_minutes'),
                used: videoMinutesUsed,
                remaining: videoRemaining,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _MonthlyStatCard(
                icon: Icons.card_giftcard,
                iconColor: AppTheme.softAmber,
                label: _t('gifts_sent'),
                used: user.stats.giftsSent,
                remaining: -2, // No limit, just show count
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _MonthlyStatCard(
          icon: Icons.people,
          iconColor: AppTheme.warmRose,
          label: _t('total_matches'),
          used: matchCount,
          remaining: -2,
          isWide: true,
        ),
      ],
    );
  }

  // ─── Subscription Card ──────────────────────────────────────────────────

  Widget _buildSubscriptionCard(UserModel user, Map<String, dynamic> features) {
    Color planColor;
    List<Color> gradientColors;
    switch (user.plan) {
      case SubscriptionPlan.tech:
        planColor = const Color(0xFF2563EB);
        gradientColors = [const Color(0xFF2563EB), const Color(0xFF60A5FA)];
        break;
      case SubscriptionPlan.college:
        planColor = AppTheme.emerald;
        gradientColors = [const Color(0xFF059669), const Color(0xFF34D399)];
        break;
      case SubscriptionPlan.nurse:
        planColor = AppTheme.warmRose;
        gradientColors = [const Color(0xFF0284C7), const Color(0xFFDC2626)];
        break;
      case SubscriptionPlan.doctor:
        planColor = AppTheme.softAmber;
        gradientColors = [const Color(0xFFF59E0B), const Color(0xFFFBBF24)];
        break;
      default:
        planColor = AppTheme.warmGray;
        gradientColors = [const Color(0xFF6B7280), const Color(0xFF9CA3AF)];
    }

    final dailyMsgs = features['dailyMessages'] as int;
    final dailyLikes = features['dailyLikes'] as int;
    final dailySuper = features['dailySuperLikes'] as int?;
    final monthlySuper = features['monthlySuperLikes'] as int;
    final monthlyVideo = features['monthlyVideoMinutes'] as int;
    final dailyRewinds = features['dailyRewinds'] as int? ?? 0;
    final freeBoost = features['freeBoost'] as bool;
    final unlimitedBoost = features['unlimitedBoost'] as bool? ?? false;

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        gradient: LinearGradient(
          colors: gradientColors,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: gradientColors.first.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                user.plan == SubscriptionPlan.doctor
                    ? Icons.diamond
                    : Icons.workspace_premium,
                color: Colors.white,
                size: 24,
              ),
              const SizedBox(width: 10),
              Text(
                _tf('plan_name', {'plan': user.plan.displayName}),
                style: GoogleFonts.playfairDisplay(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _subscriptionFeatureRow(
            _t('messages_per_day'),
            dailyMsgs == -1 ? _t('unlimited') : '$dailyMsgs',
          ),
          _subscriptionFeatureRow(
            _t('likes_per_day'),
            dailyLikes == -1 ? _t('unlimited') : '$dailyLikes',
          ),
          _subscriptionFeatureRow(
            dailySuper != null
                ? 'SuperLikes / day'
                : _t('superlikes_per_month'),
            (dailySuper ?? monthlySuper) == -1
                ? _t('unlimited')
                : '${dailySuper ?? monthlySuper}',
          ),
          _subscriptionFeatureRow(
            'Rewinds / day',
            dailyRewinds == -1 ? _t('unlimited') : '$dailyRewinds',
          ),
          _subscriptionFeatureRow(
            _t('video_minutes_per_month'),
            monthlyVideo == -1 ? _t('unlimited') : '$monthlyVideo',
          ),
          _subscriptionFeatureRow(
            _t('boost'),
            unlimitedBoost
                ? _t('unlimited')
                : freeBoost
                ? _t('free')
                : _t('watch_ads'),
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {
                Navigator.of(
                  context,
                ).push(MaterialPageRoute(builder: (_) => const PaywallPage()));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: planColor,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
                elevation: 0,
              ),
              child: Text(
                user.plan == SubscriptionPlan.doctor
                    ? _t('manage_plan')
                    : _t('upgrade'),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _subscriptionFeatureRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        children: [
          const Icon(Icons.check_circle, color: Colors.white, size: 16),
          const SizedBox(width: 8),
          Text(
            '$label: ',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: Colors.white.withValues(alpha: 0.8),
            ),
          ),
          Text(
            value,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              fontWeight: FontWeight.w700,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  // ─── Boost Status Card ──────────────────────────────────────────────────

  Widget _buildBoostStatusCard(UserModel user) {
    final isActive = user.isBoostActive;
    final minutes = _boostRemaining.inMinutes;
    final seconds = _boostRemaining.inSeconds % 60;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isActive
              ? AppTheme.softAmber.withValues(alpha: 0.4)
              : Colors.white.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isActive
                  ? AppTheme.softAmber.withValues(alpha: 0.2)
                  : Colors.white.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.rocket_launch,
              color: isActive ? AppTheme.softAmber : Colors.white38,
              size: 26,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isActive ? _t('boost_active') : _t('boost_inactive'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: isActive ? AppTheme.softAmber : Colors.white54,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  isActive
                      ? _tf('time_remaining', {
                          'time':
                              '${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}',
                        })
                      : _t('boost_profile_prompt'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: isActive ? Colors.white70 : Colors.white38,
                  ),
                ),
              ],
            ),
          ),
          if (isActive)
            Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.emerald.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    _t('live'),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppTheme.emerald,
                    ),
                  ),
                )
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .fadeIn(begin: 0.5, duration: 800.ms)
          else
            Icon(Icons.chevron_right, color: Colors.white24, size: 24),
        ],
      ),
    );
  }
}

// ─── Usage Card ───────────────────────────────────────────────────────────

class _UsageCard extends StatelessWidget {
  const _UsageCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.sent,
    required this.remaining,
    required this.delay,
    this.isWide = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int sent;
  final int remaining; // -1 = unlimited
  final int delay;
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);
    final remainingText = remaining == -1
        ? AppLocalizations.translate('unlimited', locale)
        : '$remaining';

    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalizations.translate('sent', locale),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                  TweenAnimationBuilder<int>(
                    tween: IntTween(begin: 0, end: sent),
                    duration: Duration(milliseconds: 800 + delay),
                    builder: (context, val, _) {
                      return Text(
                        '$val',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 22,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      );
                    },
                  ),
                ],
              ),
              Container(
                height: 36,
                width: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    AppLocalizations.translate('remaining', locale),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      color: Colors.white38,
                    ),
                  ),
                  remaining == -1
                      ? Text(
                          remainingText,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: AppTheme.emerald,
                          ),
                        )
                      : TweenAnimationBuilder<int>(
                          tween: IntTween(begin: 0, end: remaining),
                          duration: Duration(milliseconds: 800 + delay),
                          builder: (context, val, _) {
                            return Text(
                              '$val',
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: remaining > 0
                                    ? AppTheme.emerald
                                    : AppTheme.warmRose,
                              ),
                            );
                          },
                        ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ─── Monthly Stat Card ──────────────────────────────────────────────────

class _MonthlyStatCard extends StatelessWidget {
  const _MonthlyStatCard({
    required this.icon,
    required this.iconColor,
    required this.label,
    required this.used,
    required this.remaining,
    this.isWide = false,
  });

  final IconData icon;
  final Color iconColor;
  final String label;
  final int used;
  final int remaining; // -1 = unlimited, -2 = no limit concept (just count)
  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final locale = Localizations.localeOf(context);

    return Container(
      width: isWide ? double.infinity : null,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: iconColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icon, color: iconColor, size: 20),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white70,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (remaining == -2)
            // No limit concept - just show the count
            TweenAnimationBuilder<int>(
              tween: IntTween(begin: 0, end: used),
              duration: const Duration(milliseconds: 900),
              builder: (context, val, _) {
                return Text(
                  '$val',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 28,
                    fontWeight: FontWeight.w800,
                    color: Colors.white,
                  ),
                );
              },
            )
          else
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalizations.translate('used', locale),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    TweenAnimationBuilder<int>(
                      tween: IntTween(begin: 0, end: used),
                      duration: const Duration(milliseconds: 900),
                      builder: (context, val, _) {
                        return Text(
                          '$val',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 22,
                            fontWeight: FontWeight.w800,
                            color: Colors.white,
                          ),
                        );
                      },
                    ),
                  ],
                ),
                Container(
                  height: 36,
                  width: 1,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  children: [
                    Text(
                      AppLocalizations.translate('remaining', locale),
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 11,
                        color: Colors.white38,
                      ),
                    ),
                    remaining == -1
                        ? Text(
                            AppLocalizations.translate('unlimited', locale),
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              color: AppTheme.emerald,
                            ),
                          )
                        : TweenAnimationBuilder<int>(
                            tween: IntTween(begin: 0, end: remaining),
                            duration: const Duration(milliseconds: 900),
                            builder: (context, val, _) {
                              return Text(
                                '$val',
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 22,
                                  fontWeight: FontWeight.w800,
                                  color: remaining > 0
                                      ? AppTheme.emerald
                                      : AppTheme.warmRose,
                                ),
                              );
                            },
                          ),
                  ],
                ),
              ],
            ),
        ],
      ),
    );
  }
}
