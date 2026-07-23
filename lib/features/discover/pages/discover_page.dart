import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_card_swiper/flutter_card_swiper.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/message_model.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/call_notification_service.dart';
import 'package:nightingale_heart/core/services/usage_limits_service.dart';
import 'package:nightingale_heart/core/widgets/app_network_image.dart';
import 'package:nightingale_heart/core/widgets/desktop_app_header.dart';
import 'package:nightingale_heart/core/widgets/limit_reached_dialog.dart';
import 'package:nightingale_heart/core/widgets/shimmer_loader.dart';
import 'package:nightingale_heart/features/discover/providers/discover_provider.dart';
import 'package:nightingale_heart/features/discover/services/discover_service.dart';
import 'package:nightingale_heart/features/discover/widgets/filter_sheet.dart';
import 'package:nightingale_heart/features/discover/widgets/profile_card.dart';
import 'package:nightingale_heart/features/messages/providers/message_providers.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

typedef _DiscoveryUsageRequest = ({
  String userId,
  SubscriptionPlan plan,
  int videoMinutes,
});

final _discoveryUsageProvider = StreamProvider.autoDispose
    .family<_DiscoveryUsage, _DiscoveryUsageRequest>((ref, request) {
      final now = DateTime.now().toUtc();
      final day =
          '${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
      final month = '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final dailyId = 'daily_$day';
      final monthlyId = 'monthly_$month';

      return FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(request.userId)
          .collection('usage')
          .where(FieldPath.documentId, whereIn: [dailyId, monthlyId])
          .snapshots()
          .map((snapshot) {
            var daily = const <String, dynamic>{};
            var monthly = const <String, dynamic>{};
            for (final doc in snapshot.docs) {
              if (doc.id == dailyId) daily = doc.data();
              if (doc.id == monthlyId) monthly = doc.data();
            }
            return _DiscoveryUsage.fromData(
              plan: request.plan,
              videoMinutes: request.videoMinutes,
              daily: daily,
              monthly: monthly,
            );
          });
    });

class _DiscoveryUsage {
  const _DiscoveryUsage({
    required this.likesRemaining,
    required this.superLikesRemaining,
    required this.rewindsRemaining,
    required this.videoMinutes,
  });

  final int likesRemaining;
  final int superLikesRemaining;
  final int rewindsRemaining;
  final int videoMinutes;

  factory _DiscoveryUsage.fromData({
    required SubscriptionPlan plan,
    required int videoMinutes,
    required Map<String, dynamic> daily,
    required Map<String, dynamic> monthly,
  }) {
    final features = AppConstants.planFeatures[plan]!;
    final likesLimit = features['dailyLikes'] as int;
    final rewindLimit = features['dailyRewinds'] as int? ?? 0;
    final dailySuperLikeLimit = features['dailySuperLikes'] as int?;
    final monthlySuperLikeLimit = features['monthlySuperLikes'] as int? ?? 0;

    int value(Map<String, dynamic> source, String key) {
      return (source[key] as num?)?.toInt() ?? 0;
    }

    int remaining(int limit, int used, [int refilled = 0]) {
      if (limit == -1) return -1;
      return max(0, limit + refilled - used);
    }

    final superLikesRemaining = dailySuperLikeLimit != null
        ? remaining(dailySuperLikeLimit, value(daily, 'superLikesSent'))
        : remaining(monthlySuperLikeLimit, value(monthly, 'superLikesSent'));

    return _DiscoveryUsage(
      likesRemaining: remaining(
        likesLimit,
        value(daily, 'likesSent'),
        value(daily, 'likesRefilled'),
      ),
      superLikesRemaining: superLikesRemaining,
      rewindsRemaining: remaining(
        rewindLimit,
        value(daily, 'rewindsUsed'),
        value(daily, 'rewindsRefilled'),
      ),
      videoMinutes: max(0, videoMinutes),
    );
  }
}

/// Main discover / swipe page.
///
/// Displays a stack of [ProfileCard]s that users swipe left (dislike),
/// right (like) or up (superlike).  Bottom action buttons provide
/// additional controls.  When a mutual match is detected an animated
/// overlay is shown.
class DiscoverPage extends ConsumerStatefulWidget {
  const DiscoverPage({super.key});

  @override
  ConsumerState<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends ConsumerState<DiscoverPage>
    with TickerProviderStateMixin {
  final CardSwiperController _swiperController = CardSwiperController();

  /// Local copy of profiles so we can track the current index.
  List<UserModel> _profiles = [];
  bool _showMatchOverlay = false;
  UserModel? _matchedUser;
  bool _openingMatchChat = false;
  bool _sendingShiftReport = false;
  bool _startingMatchVideoIntro = false;

  // For the swipe feedback overlays.
  bool _showLike = false;
  bool _showNope = false;
  bool _showSuperLike = false;

  bool _profilesLoaded = false;
  String? _profileStackKey;
  bool _rewindInFlight = false;
  bool _suppressNextSwipeRecord = false;
  CardSwiperDirection _lastSwipeDirection = CardSwiperDirection.left;
  final Set<String> _pendingSwipeProfileIds = {};
  final Set<String> _swipedThisSessionProfileIds = {};

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  @override
  void dispose() {
    _swiperController.dispose();
    super.dispose();
  }

  // ─── Swipe handler ──────────────────────────────────────────────────

  bool _onSwipe(int previousIndex, int? _, CardSwiperDirection direction) {
    if (previousIndex >= _profiles.length) return false;
    if (_suppressNextSwipeRecord) {
      _suppressNextSwipeRecord = false;
      return true;
    }

    final targetUser = _profiles[previousIndex];
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return false;
    _pendingSwipeProfileIds.add(targetUser.id);
    _swipedThisSessionProfileIds.add(targetUser.id);

    bool isLike = false;
    bool isSuperLike = false;

    switch (direction) {
      case CardSwiperDirection.right:
        isLike = true;
        break;
      case CardSwiperDirection.top:
        isSuperLike = true;
        break;
      case CardSwiperDirection.left:
        break;
      default:
        break;
    }

    // ── Check daily limit before recording like/superlike ──
    _lastSwipeDirection = direction;

    if (direction == CardSwiperDirection.right) {
      _flashOverlay('like');
    } else if (direction == CardSwiperDirection.top) {
      _flashOverlay('superlike');
    } else if (direction == CardSwiperDirection.left) {
      _flashOverlay('nope');
    }

    unawaited(
      _recordSwipeAfterAnimation(
        currentUser,
        targetUser,
        isLike: isLike,
        isSuperLike: isSuperLike,
      ),
    );

    return true;
  }

  Future<void> _recordSwipeAfterAnimation(
    UserModel currentUser,
    UserModel targetUser, {
    required bool isLike,
    required bool isSuperLike,
  }) async {
    try {
      final isMatch = await ref
          .read(discoverServiceProvider)
          .recordSwipe(
            currentUser.id,
            targetUser.id,
            isLike: isLike,
            isSuperLike: isSuperLike,
          );
      if (isMatch && mounted) {
        setState(() {
          _matchedUser = targetUser;
          _showMatchOverlay = true;
        });
      }
    } on SwipeUsageLimitException catch (error) {
      if (!mounted) return;
      _pendingSwipeProfileIds.remove(targetUser.id);
      _swipedThisSessionProfileIds.remove(targetUser.id);
      _swiperController.undo();
      unawaited(
        _handleSwipeLimit(
          currentUser,
          targetUser,
          isLike: isLike,
          isSuperLike: isSuperLike,
          usageType: error.usageType,
        ),
      );
    } catch (error) {
      debugPrint('[DiscoverPage] Swipe failed: $error');
      if (!mounted) return;
      _pendingSwipeProfileIds.remove(targetUser.id);
      _swipedThisSessionProfileIds.remove(targetUser.id);
      _swiperController.undo();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('something_went_wrong'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.warmRose,
        ),
      );
    } finally {
      _pendingSwipeProfileIds.remove(targetUser.id);
    }
  }

  Future<bool> _handleSwipeLimit(
    UserModel currentUser,
    UserModel targetUser, {
    required bool isLike,
    required bool isSuperLike,
    required String usageType,
  }) async {
    if (!mounted) return false;
    if (usageType == 'superlikes') {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('monthly_super_likes_used'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.warmRose,
        ),
      );
      return false;
    }

    final planFeatures =
        AppConstants.planFeatures[currentUser.plan] ??
        AppConstants.planFeatures[SubscriptionPlan.free]!;
    final refillAmount = planFeatures['adRefillLikes'] as int? ?? 0;
    if (refillAmount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('daily_likes_used'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: AppTheme.warmRose,
        ),
      );
      return false;
    }

    final refilled = await showLimitReachedDialog(
      context: context,
      userId: currentUser.id,
      limitType: 'likes',
      refillAmount: refillAmount,
    );
    if (!refilled) return false;

    try {
      final isMatch = await ref
          .read(discoverServiceProvider)
          .recordSwipe(
            currentUser.id,
            targetUser.id,
            isLike: isLike,
            isSuperLike: isSuperLike,
          );
      if (isSuperLike) {
        _flashOverlay('superlike');
      } else {
        _flashOverlay('like');
      }
      if (isMatch && mounted) {
        setState(() {
          _matchedUser = targetUser;
          _showMatchOverlay = true;
        });
      }
      return true;
    } on SwipeUsageLimitException {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _t('daily_likes_used'),
              style: GoogleFonts.plusJakartaSans(),
            ),
            behavior: SnackBarBehavior.floating,
            backgroundColor: AppTheme.warmRose,
          ),
        );
      }
      return false;
    }
  }

  void _flashOverlay(String type) {
    setState(() {
      _showLike = type == 'like';
      _showNope = type == 'nope';
      _showSuperLike = type == 'superlike';
    });
    Future.delayed(const Duration(milliseconds: 600), () {
      if (mounted) {
        setState(() {
          _showLike = false;
          _showNope = false;
          _showSuperLike = false;
        });
      }
    });
  }

  void _onTapLike() => _swiperController.swipe(CardSwiperDirection.right);
  void _onTapDislike() => _swiperController.swipe(CardSwiperDirection.left);
  void _onTapSuperLike() => _swiperController.swipe(CardSwiperDirection.top);

  Future<void> _onTapUndo() async {
    if (_rewindInFlight) return;
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    _swiperController.undo();
    setState(() => _rewindInFlight = true);

    final planFeatures =
        AppConstants.planFeatures[currentUser.plan] ??
        AppConstants.planFeatures[SubscriptionPlan.free]!;
    final rewindLimit = planFeatures['dailyRewinds'] as int? ?? 0;
    if (rewindLimit == -1) {
      try {
        await ref.read(usageLimitsServiceProvider).recordRewind(currentUser.id);
      } catch (error) {
        debugPrint('[DiscoverPage] Unlimited rewind usage failed: $error');
      } finally {
        if (mounted) setState(() => _rewindInFlight = false);
      }
      return;
    }

    try {
      await ref.read(usageLimitsServiceProvider).recordRewind(currentUser.id);
    } on FirebaseFunctionsException catch (error) {
      if (error.code != 'resource-exhausted') {
        _showRewindError(_t('something_went_wrong'));
        _restoreCardAfterDeniedRewind();
        return;
      }

      final refillAmount = planFeatures['adRefillRewinds'] as int? ?? 0;
      if (refillAmount <= 0) {
        _showRewindError('You have used all your daily rewinds.');
        _restoreCardAfterDeniedRewind();
        return;
      }

      if (!mounted) return;
      final refilled = await showLimitReachedDialog(
        context: context,
        userId: currentUser.id,
        limitType: 'rewinds',
        refillAmount: refillAmount,
        adsRequired: 2,
      );
      if (!refilled || !mounted) {
        _restoreCardAfterDeniedRewind();
        return;
      }

      try {
        await ref.read(usageLimitsServiceProvider).recordRewind(currentUser.id);
      } catch (retryError) {
        debugPrint('[DiscoverPage] Rewind retry failed: $retryError');
        _showRewindError(_t('something_went_wrong'));
        _restoreCardAfterDeniedRewind();
      }
    } catch (error) {
      debugPrint('[DiscoverPage] Rewind failed: $error');
      _showRewindError(_t('something_went_wrong'));
      _restoreCardAfterDeniedRewind();
    } finally {
      if (mounted) setState(() => _rewindInFlight = false);
    }
  }

  void _restoreCardAfterDeniedRewind() {
    _suppressNextSwipeRecord = true;
    _swiperController.swipe(_lastSwipeDirection);
  }

  void _showRewindError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: AppTheme.warmRose,
      ),
    );
  }

  Future<void> _onTapBoost() async {
    if (mounted) {
      context.go('/profile');
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('boost_from_profile'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.deepPlum,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  void _openFilters() {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const FilterSheet(),
    );
  }

  void _openMainMenu() {
    final items = [
      _MainMenuItem(
        icon: Icons.local_hospital_rounded,
        label: _t('nav_feed'),
        route: '/social',
      ),
      _MainMenuItem(
        icon: Icons.medical_services_rounded,
        label: _t('nurse_hub'),
        route: '/nurse-hub',
      ),
      _MainMenuItem(
        icon: Icons.favorite_rounded,
        label: _t('nav_matches'),
        route: '/matches',
      ),
      _MainMenuItem(
        icon: Icons.chat_bubble_rounded,
        label: _t('nav_messages'),
        route: '/messages',
      ),
      _MainMenuItem(
        icon: Icons.videocam_rounded,
        label: _t('speed_dating'),
        route: '/video',
      ),
      _MainMenuItem(
        icon: Icons.badge_rounded,
        label: _t('nav_profile'),
        route: '/profile',
      ),
      _MainMenuItem(
        icon: Icons.card_giftcard_rounded,
        label: _t('gift_store'),
        route: '/gifts',
      ),
      _MainMenuItem(
        icon: Icons.inventory_2_rounded,
        label: _t('gift_inventory'),
        route: '/gifts/inventory',
      ),
      _MainMenuItem(
        icon: Icons.workspace_premium_rounded,
        label: _t('subscription'),
        route: '/subscription/manage',
      ),
      _MainMenuItem(
        icon: Icons.timelapse_rounded,
        label: _t('video_minutes'),
        route: '/video/minutes',
      ),
      _MainMenuItem(
        icon: Icons.insights_rounded,
        label: _t('dashboard'),
        route: '/dashboard',
      ),
      _MainMenuItem(
        icon: Icons.nightlight_round,
        label: _t('night_owls'),
        route: '/night-owls',
      ),
      _MainMenuItem(
        icon: Icons.monitor_heart_rounded,
        label: _t('compatibility'),
        route: '/compatibility',
      ),
      _MainMenuItem(
        icon: Icons.sports_esports_rounded,
        label: _t('entertainment'),
        route: '/entertainment',
      ),
      _MainMenuItem(
        icon: Icons.settings_rounded,
        label: _t('settings'),
        route: '/settings',
      ),
    ];

    Widget menuPanel(BuildContext menuContext, {required bool desktop}) {
      final availableHeight = MediaQuery.sizeOf(menuContext).height;
      final gridHeight = min(
        availableHeight * (desktop ? 0.72 : 0.64),
        desktop ? 650.0 : 560.0,
      );

      return Container(
        width: desktop ? 440 : double.infinity,
        constraints: BoxConstraints(maxHeight: availableHeight - 112),
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.medical_services_rounded,
                      color: Color(0xFF2DD4BF),
                      size: 22,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        _t('main_menu'),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 21,
                          fontWeight: FontWeight.w800,
                          color: Colors.white,
                        ),
                      ),
                    ),
                    IconButton(
                      tooltip: MaterialLocalizations.of(
                        menuContext,
                      ).closeButtonTooltip,
                      onPressed: () => Navigator.of(menuContext).pop(),
                      icon: const Icon(Icons.close_rounded),
                      color: Colors.white70,
                    ),
                  ],
                ),
                Text(
                  _t('menu_quick_access'),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Colors.white60,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: gridHeight,
                  child: GridView.builder(
                    itemCount: items.length,
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          childAspectRatio: 2.55,
                          crossAxisSpacing: 10,
                          mainAxisSpacing: 10,
                        ),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      return _MainMenuTile(
                        item: item,
                        dark: true,
                        onTap: () {
                          Navigator.of(menuContext).pop();
                          if (mounted) this.context.push(item.route);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isDesktop = kIsWeb && MediaQuery.sizeOf(context).width >= 1000;
    if (isDesktop) {
      showDialog<void>(
        context: context,
        barrierColor: Colors.black.withValues(alpha: 0.36),
        builder: (dialogContext) => Dialog(
          alignment: Alignment.topRight,
          insetPadding: const EdgeInsets.fromLTRB(24, 88, 24, 24),
          backgroundColor: Colors.transparent,
          elevation: 0,
          child: menuPanel(dialogContext, desktop: true),
        ),
      );
      return;
    }

    showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      barrierColor: Colors.black.withValues(alpha: 0.44),
      builder: (sheetContext) => Padding(
        padding: const EdgeInsets.fromLTRB(8, 0, 8, 8),
        child: menuPanel(sheetContext, desktop: false),
      ),
    );
  }

  Future<void> _refreshDiscoveryDeck() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser != null) {
      ref
          .read(discoverServiceProvider)
          .clearProfileCacheForUser(currentUser.id);
    }
    _profilesLoaded = false;
    _profileStackKey = null;
    ref.invalidate(profilesProvider);
  }

  List<UserModel> _profilesReadyForDisplay(List<UserModel> profiles) {
    final excludedIds = {
      ..._swipedThisSessionProfileIds,
      ..._pendingSwipeProfileIds,
    };
    var visibleProfiles = profiles
        .where(
          (profile) =>
              profile.displayPhoto != null && !excludedIds.contains(profile.id),
        )
        .toList(growable: false);

    if (visibleProfiles.isEmpty &&
        profiles.isNotEmpty &&
        _pendingSwipeProfileIds.isEmpty) {
      _swipedThisSessionProfileIds.clear();
      visibleProfiles = profiles
          .where((profile) => profile.displayPhoto != null)
          .toList(growable: false);
    }

    return visibleProfiles;
  }

  void _dismissMatch() {
    setState(() {
      _showMatchOverlay = false;
      _matchedUser = null;
      _openingMatchChat = false;
      _sendingShiftReport = false;
      _startingMatchVideoIntro = false;
    });
  }

  bool get _isHandlingMatchAction =>
      _openingMatchChat || _sendingShiftReport || _startingMatchVideoIntro;

  Future<void> _openMatchedChat() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final matchedUser = _matchedUser;
    if (currentUser == null || matchedUser == null || _isHandlingMatchAction) {
      return;
    }

    setState(() => _openingMatchChat = true);
    try {
      final chatId = await ref
          .read(messageServiceProvider)
          .getOrCreateChat(currentUser.id, matchedUser.id);
      if (!mounted) return;
      _dismissMatch();
      context.push('/messages/$chatId');
    } catch (error) {
      debugPrint('[DiscoverPage] Failed to open match chat: $error');
      if (!mounted) return;
      setState(() => _openingMatchChat = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('could_not_open_chat'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.warmRose,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _sendShiftReport() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final matchedUser = _matchedUser;
    if (currentUser == null || matchedUser == null || _isHandlingMatchAction) {
      return;
    }

    setState(() => _sendingShiftReport = true);
    try {
      final messageService = ref.read(messageServiceProvider);
      final chatId = await messageService.getOrCreateChat(
        currentUser.id,
        matchedUser.id,
      );
      final reason = _matchReasonForMessage(currentUser, matchedUser);
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: _tf('shift_report_message', {'reason': reason}),
        type: MessageType.text,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await messageService.sendMessage(chatId, message);
      if (!mounted) return;
      _dismissMatch();
      context.push('/messages/$chatId');
    } catch (error) {
      debugPrint('[DiscoverPage] Failed to send shift report: $error');
      if (!mounted) return;
      setState(() => _sendingShiftReport = false);
      _showMatchActionError(_t('could_not_send_shift_report'));
    }
  }

  Future<void> _startMatchVideoIntro() async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final matchedUser = _matchedUser;
    if (currentUser == null || matchedUser == null || _isHandlingMatchAction) {
      return;
    }

    setState(() => _startingMatchVideoIntro = true);
    try {
      final messageService = ref.read(messageServiceProvider);
      final chatId = await messageService.getOrCreateChat(
        currentUser.id,
        matchedUser.id,
      );
      final callNotificationService = ref.read(callNotificationServiceProvider);
      final callNotificationId = callNotificationService.createNotificationId();
      final roomId = 'chat_${chatId}_${DateTime.now().millisecondsSinceEpoch}';
      final message = MessageModel(
        id: '',
        chatId: chatId,
        senderId: currentUser.id,
        senderName: currentUser.name,
        senderPhotoUrl: currentUser.photoUrl,
        content: 'room:$roomId;call:$callNotificationId',
        type: MessageType.videoCall,
        isRead: false,
        createdAt: DateTime.now(),
      );

      await messageService.sendMessage(chatId, message);
      try {
        await callNotificationService.createOneOnOneCallNotification(
          notificationId: callNotificationId,
          callerId: currentUser.id,
          callerName: currentUser.name,
          receiverId: matchedUser.id,
          roomId: roomId,
          chatId: chatId,
        );
      } catch (error) {
        debugPrint('[DiscoverPage] Failed to create match call alert: $error');
      }
      if (!mounted) return;
      final uri = Uri(
        path: '/video/call/$roomId',
        queryParameters: {
          'type': 'oneOnOne',
          'targetUserId': matchedUser.id,
          'targetUserName': matchedUser.name,
          'chatId': chatId,
          'callNotificationId': callNotificationId,
        },
      );
      _dismissMatch();
      context.push(uri.toString());
    } catch (error) {
      debugPrint('[DiscoverPage] Failed to start match video intro: $error');
      if (!mounted) return;
      setState(() => _startingMatchVideoIntro = false);
      _showMatchActionError(_t('could_not_start_video_intro'));
    }
  }

  String _matchReasonForMessage(UserModel currentUser, UserModel matchedUser) {
    if (currentUser.shiftType != null &&
        currentUser.shiftType == matchedUser.shiftType) {
      final shift = AppLocalizations.shiftTypeLabel(
        matchedUser.shiftType!.value,
        ref.read(localeProvider),
      );
      return _tf('match_reason_shift', {'shift': shift});
    }

    if (currentUser.department != null &&
        currentUser.department == matchedUser.department) {
      return _tf('match_reason_department', {
        'department': matchedUser.department,
      });
    }

    final sharedLanguages = currentUser.languages
        .where((language) => matchedUser.languages.contains(language))
        .toList(growable: false);
    if (sharedLanguages.isNotEmpty) {
      return _tf('match_reason_language', {'language': sharedLanguages.first});
    }

    if (currentUser.preferredDatingWindow != null &&
        currentUser.preferredDatingWindow ==
            matchedUser.preferredDatingWindow) {
      final window = AppLocalizations.datingWindowLabel(
        matchedUser.preferredDatingWindow!.value,
        ref.read(localeProvider),
      );
      return _tf('match_reason_dating_window', {'window': window});
    }

    return _t('match_reason_fallback');
  }

  void _showMatchActionError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        backgroundColor: AppTheme.warmRose,
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  // ─── Build ──────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final profilesAsync = ref.watch(profilesProvider);
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 1000;

    return Scaffold(
      appBar: isDesktopWeb
          ? DesktopAppHeader(
              activeRoute: '/discover',
              onFilterPressed: _openFilters,
              onMenuPressed: _openMainMenu,
            )
          : AppBar(
              title: Text(
                _t('nav_discover'),
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
              ),
              actions: [
                IconButton(
                  icon: Icon(Icons.tune_rounded, semanticLabel: _t('filters')),
                  tooltip: _t('filters'),
                  onPressed: _openFilters,
                ),
                IconButton(
                  icon: Icon(
                    Icons.menu_rounded,
                    semanticLabel: _t('main_menu'),
                  ),
                  tooltip: _t('main_menu'),
                  onPressed: _openMainMenu,
                ),
              ],
            ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final showWideBackdrop = constraints.maxWidth >= 700;
          final showDesktopShell = kIsWeb && constraints.maxWidth >= 1000;

          return Stack(
            children: [
              if (showWideBackdrop)
                const Positioned.fill(child: _DiscoverWideBackdrop()),

              // Main content
              profilesAsync.when(
                loading: () => _buildShimmerLoading(),
                error: (error, _) => _buildError(error, theme),
                data: (profiles) {
                  final visibleProfiles = _profilesReadyForDisplay(profiles);
                  final stackKey = visibleProfiles
                      .map((profile) => profile.id)
                      .join('|');
                  if (!_profilesLoaded || stackKey != _profileStackKey) {
                    _profiles = visibleProfiles;
                    _profilesLoaded = true;
                    _profileStackKey = stackKey;
                  }
                  if (_profiles.isEmpty) {
                    return _buildEmptyState(theme);
                  }
                  if (showDesktopShell) {
                    return _buildDesktopDiscovery(
                      _profiles,
                      theme,
                      currentUser,
                    );
                  }
                  return _buildSwiper(_profiles, theme, currentUser);
                },
              ),

              // Swipe feedback overlays
              if (_showLike)
                _SwipeFeedback(
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFF22C55E),
                  label: _t('like_action'),
                ),
              if (_showNope)
                _SwipeFeedback(
                  icon: Icons.close_rounded,
                  color: AppTheme.warmRose,
                  label: _t('nope_action'),
                ),
              if (_showSuperLike)
                _SwipeFeedback(
                  icon: Icons.star_rounded,
                  color: AppTheme.softAmber,
                  label: _t('super_like_action'),
                ),

              // Match overlay
              if (_showMatchOverlay && _matchedUser != null)
                _MatchOverlay(
                  matchedUser: _matchedUser!,
                  currentUser: currentUser,
                  isOpeningChat: _openingMatchChat,
                  isSendingShiftReport: _sendingShiftReport,
                  isStartingVideoIntro: _startingMatchVideoIntro,
                  onSendShiftReport: _sendShiftReport,
                  onStartChat: _openMatchedChat,
                  onScheduleVideoIntro: _startMatchVideoIntro,
                  onKeepSwiping: _dismissMatch,
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildDesktopDiscovery(
    List<UserModel> profiles,
    ThemeData theme,
    UserModel? currentUser,
  ) {
    final usageAsync = currentUser == null
        ? const AsyncValue<_DiscoveryUsage>.loading()
        : ref.watch(
            _discoveryUsageProvider((
              userId: currentUser.id,
              plan: currentUser.plan,
              videoMinutes: currentUser.videoMinutes,
            )),
          );

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 1280),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(child: _buildSwiper(profiles, theme, currentUser)),
              const SizedBox(width: 24),
              SizedBox(
                width: 310,
                child: _DiscoveryDesktopRail(
                  user: currentUser,
                  usageAsync: usageAsync,
                  onOpenRoute: (route) => context.push(route),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSwiper(
    List<UserModel> profiles,
    ThemeData theme,
    UserModel? currentUser,
  ) {
    return Column(
      children: [
        Expanded(
          child: LayoutBuilder(
            builder: (context, constraints) {
              final isWide = constraints.maxWidth >= 700;
              final horizontalPadding = isWide ? 24.0 : 16.0;
              final availableWidth = max(
                280.0,
                constraints.maxWidth - (horizontalPadding * 2),
              );
              final deckWidth = min(
                isWide ? 430.0 : availableWidth,
                availableWidth,
              );
              final idealHeight = deckWidth * (isWide ? 1.48 : 1.55);
              final deckHeight = min(
                constraints.maxHeight,
                max(isWide ? 520.0 : 360.0, idealHeight),
              );

              return Center(
                child: SizedBox(
                  width: deckWidth,
                  height: deckHeight,
                  child: CardSwiper(
                    key: ValueKey(_profileStackKey),
                    controller: _swiperController,
                    cardsCount: profiles.length,
                    numberOfCardsDisplayed: min(3, profiles.length),
                    duration: const Duration(milliseconds: 140),
                    threshold: 38,
                    maxAngle: 18,
                    backCardOffset: const Offset(0, -22),
                    scale: 0.94,
                    padding: EdgeInsets.zero,
                    isLoop: false,
                    showBackCardOnUndo: true,
                    undoSwipeThreshold: 32,
                    allowedSwipeDirection: const AllowedSwipeDirection.only(
                      left: true,
                      right: true,
                      up: true,
                    ),
                    onSwipe: _onSwipe,
                    onEnd: _refreshDiscoveryDeck,
                    cardBuilder:
                        (
                          context,
                          index,
                          horizontalOffsetPercentage,
                          verticalOffsetPercentage,
                        ) {
                          if (index >= profiles.length) {
                            return const SizedBox.shrink();
                          }
                          final user = profiles[index];
                          return Transform(
                            alignment: Alignment.center,
                            transform: Matrix4.identity()
                              ..setEntry(3, 2, 0.001)
                              ..rotateY(horizontalOffsetPercentage * 0.006),
                            child: ProfileCard(
                              user: user,
                              currentUser: currentUser,
                              onTap: () {
                                context.push('/discover/profile/${user.id}');
                              },
                            ),
                          );
                        },
                  ),
                ),
              );
            },
          ),
        ),

        Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: _ActionButtonRow(
              onUndo: _onTapUndo,
              isRewindBusy: _rewindInFlight,
              onDislike: _onTapDislike,
              onSuperLike: _onTapSuperLike,
              onLike: _onTapLike,
              onBoost: _onTapBoost,
            ),
          ),
        ),

        SizedBox(height: MediaQuery.of(context).padding.bottom + 8),
      ],
    );
  }

  Widget _buildShimmerLoading() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: ShimmerLoader(
              borderRadius: 24,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(24),
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: List.generate(5, (_) => ShimmerLoader.circle(radius: 26)),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildEmptyState(ThemeData theme) {
    return RefreshIndicator(
      onRefresh: _refreshDiscoveryDeck,
      color: AppTheme.deepPlum,
      child: ListView(
        children: [
          SizedBox(height: MediaQuery.of(context).size.height * 0.2),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                      Icons.explore_off_rounded,
                      size: 80,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                    )
                    .animate()
                    .fadeIn(duration: 600.ms)
                    .scale(begin: const Offset(0.8, 0.8)),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 48),
                  child: Text(
                    _t('no_profiles_nearby'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: theme.colorScheme.onSurface.withValues(alpha: 0.5),
                      height: 1.5,
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                OutlinedButton.icon(
                  onPressed: _openFilters,
                  icon: const Icon(Icons.tune_rounded, size: 18),
                  label: Text(_t('adjust_filters')),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildError(Object error, ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 64,
              color: theme.colorScheme.error.withValues(alpha: 0.6),
            ),
            const SizedBox(height: 16),
            Text(
              _t('something_went_wrong'),
              style: theme.textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              style: theme.textTheme.bodySmall,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => ref.invalidate(profilesProvider),
              icon: const Icon(Icons.refresh, size: 18),
              label: Text(_t('retry')),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Action button row ──────────────────────────────────────────────────────

class _DiscoveryDesktopRail extends StatelessWidget {
  const _DiscoveryDesktopRail({
    required this.user,
    required this.usageAsync,
    required this.onOpenRoute,
  });

  final UserModel? user;
  final AsyncValue<_DiscoveryUsage> usageAsync;
  final ValueChanged<String> onOpenRoute;

  String _t(BuildContext context, String key) {
    return AppLocalizations.translate(key, Localizations.localeOf(context));
  }

  String _remainingLabel(BuildContext context, int? value) {
    if (value == null) return '--';
    if (value == -1) return _t(context, 'unlimited');
    return '$value';
  }

  @override
  Widget build(BuildContext context) {
    final currentUser = user;
    final usage = usageAsync.valueOrNull;
    final role = currentUser?.careRoleBadge ?? _t(context, 'job_title');
    final planName = currentUser?.plan.displayName ?? 'Free';
    final privacyLabel = currentUser == null
        ? _t(context, 'workplace_privacy')
        : currentUser.hideWorkplace
        ? _t(context, 'hide_hospital_name')
        : currentUser.avoidSameWorkplace
        ? _t(context, 'avoid_same_workplace')
        : currentUser.avoidSameDepartment
        ? _t(context, 'avoid_same_department')
        : _t(context, 'workplace_privacy');
    final verificationLabel = currentUser?.isVerified == true
        ? currentUser!.healthcareVerificationBadge ?? _t(context, 'verified')
        : _t(context, 'profile_verification');

    return DecoratedBox(
      decoration: BoxDecoration(
        color: const Color(0xFF11191B).withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.white.withValues(alpha: 0.12)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.18),
            blurRadius: 24,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.24),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Icon(
                    Icons.monitor_heart_rounded,
                    color: Color(0xFF5EEAD4),
                    size: 23,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '$planName ${_t(context, 'subscription')}',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white,
                          fontSize: 15,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        role,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          color: Colors.white60,
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            Text(
              _t(context, 'todays_usage'),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 12,
              runSpacing: 14,
              children: [
                _UsageMetric(
                  icon: Icons.favorite_rounded,
                  color: const Color(0xFFFB7185),
                  label: _t(context, 'likes'),
                  value: _remainingLabel(context, usage?.likesRemaining),
                ),
                _UsageMetric(
                  icon: Icons.star_rounded,
                  color: const Color(0xFFFBBF24),
                  label: _t(context, 'superlikes_remaining'),
                  value: _remainingLabel(context, usage?.superLikesRemaining),
                ),
                _UsageMetric(
                  icon: Icons.replay_rounded,
                  color: const Color(0xFF60A5FA),
                  label: _t(context, 'rewinds'),
                  value: _remainingLabel(context, usage?.rewindsRemaining),
                ),
                _UsageMetric(
                  icon: Icons.video_camera_front_rounded,
                  color: const Color(0xFF5EEAD4),
                  label: _t(context, 'video_minutes'),
                  value: _remainingLabel(context, usage?.videoMinutes),
                ),
              ],
            ),
            if (usageAsync.hasError) ...[
              const SizedBox(height: 10),
              Text(
                _t(context, 'usage_unavailable'),
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFFFCA5A5),
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 42,
              child: OutlinedButton.icon(
                onPressed: () => onOpenRoute('/subscription/manage'),
                icon: const Icon(Icons.workspace_premium_outlined, size: 19),
                label: Text(_t(context, 'upgrade')),
                style: OutlinedButton.styleFrom(
                  foregroundColor: const Color(0xFF5EEAD4),
                  side: const BorderSide(color: Color(0xFF2DD4BF)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(6),
                  ),
                  textStyle: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 20),
              child: Divider(color: Colors.white12, height: 1),
            ),
            Text(
              _t(context, 'menu_quick_access'),
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 8),
            _RailAction(
              icon: Icons.video_call_outlined,
              label: _t(context, 'speed_dating'),
              onTap: () => onOpenRoute('/video'),
            ),
            _RailAction(
              icon: Icons.forum_outlined,
              label: _t(context, 'nav_feed'),
              onTap: () => onOpenRoute('/social'),
            ),
            _RailAction(
              icon: Icons.local_hospital_outlined,
              label: _t(context, 'nurse_hub'),
              onTap: () => onOpenRoute('/nurse-hub'),
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 16),
              child: Divider(color: Colors.white12, height: 1),
            ),
            _RailStatus(
              icon: currentUser?.isVerified == true
                  ? Icons.verified_rounded
                  : Icons.verified_user_outlined,
              color: currentUser?.isVerified == true
                  ? const Color(0xFF34D399)
                  : const Color(0xFFFBBF24),
              label: verificationLabel,
            ),
            const SizedBox(height: 12),
            _RailStatus(
              icon: Icons.shield_outlined,
              color: const Color(0xFF60A5FA),
              label: privacyLabel,
            ),
          ],
        ),
      ),
    );
  }
}

class _UsageMetric extends StatelessWidget {
  const _UsageMetric({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
  });

  final IconData icon;
  final Color color;
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 128,
      height: 72,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  height: 28,
                  child: FittedBox(
                    fit: BoxFit.scaleDown,
                    alignment: Alignment.centerLeft,
                    child: Text(
                      value,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white,
                        fontSize: 22,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white60,
                    fontSize: 10.5,
                    fontWeight: FontWeight.w600,
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

class _RailAction extends StatelessWidget {
  const _RailAction({
    required this.icon,
    required this.label,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(6),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 2, vertical: 10),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFF5EEAD4), size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  color: Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
            const Icon(
              Icons.chevron_right_rounded,
              color: Colors.white38,
              size: 20,
            ),
          ],
        ),
      ),
    );
  }
}

class _RailStatus extends StatelessWidget {
  const _RailStatus({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 19),
        const SizedBox(width: 10),
        Expanded(
          child: Text(
            label,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white70,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }
}

class _MainMenuItem {
  const _MainMenuItem({
    required this.icon,
    required this.label,
    required this.route,
  });

  final IconData icon;
  final String label;
  final String route;
}

class _MainMenuTile extends StatelessWidget {
  const _MainMenuTile({
    required this.item,
    required this.onTap,
    this.dark = false,
  });

  final _MainMenuItem item;
  final VoidCallback onTap;
  final bool dark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Ink(
          decoration: BoxDecoration(
            color: dark
                ? Colors.white.withValues(alpha: 0.06)
                : theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.58,
                  ),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: dark
                  ? Colors.white.withValues(alpha: 0.10)
                  : theme.colorScheme.outlineVariant.withValues(alpha: 0.55),
            ),
          ),
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Icon(
                item.icon,
                color: dark ? const Color(0xFF5EEAD4) : AppTheme.deepPlum,
                size: 22,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  item.label,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                    color: dark ? Colors.white : theme.colorScheme.onSurface,
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

class _ActionButtonRow extends StatelessWidget {
  const _ActionButtonRow({
    required this.onUndo,
    required this.isRewindBusy,
    required this.onDislike,
    required this.onSuperLike,
    required this.onLike,
    required this.onBoost,
  });

  final VoidCallback onUndo;
  final bool isRewindBusy;
  final VoidCallback onDislike;
  final VoidCallback onSuperLike;
  final VoidCallback onLike;
  final VoidCallback onBoost;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 380;
          final primarySize = compact ? 62.0 : 68.0;
          final secondarySize = compact ? 56.0 : 60.0;
          final utilitySize = compact ? 52.0 : 56.0;
          final gap = compact ? 8.0 : 10.0;

          return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _ActionButton(
                icon: Icons.undo_rounded,
                color: AppTheme.softAmber,
                size: utilitySize,
                iconSize: compact ? 24 : 26,
                onTap: isRewindBusy ? null : onUndo,
                tooltip: 'Undo',
                isBusy: isRewindBusy,
              ),
              SizedBox(width: gap),
              _ActionButton(
                icon: Icons.close_rounded,
                color: AppTheme.warmRose,
                size: primarySize,
                iconSize: compact ? 30 : 32,
                onTap: onDislike,
                tooltip: 'Dislike',
              ),
              SizedBox(width: gap),
              _ActionButton(
                icon: Icons.star_rounded,
                color: AppTheme.softAmber,
                size: secondarySize,
                iconSize: compact ? 27 : 29,
                onTap: onSuperLike,
                tooltip: 'Super Like',
              ),
              SizedBox(width: gap),
              _ActionButton(
                icon: Icons.favorite_rounded,
                color: const Color(0xFF22C55E),
                size: primarySize,
                iconSize: compact ? 30 : 32,
                onTap: onLike,
                tooltip: 'Like',
              ),
              SizedBox(width: gap),
              _ActionButton(
                icon: Icons.rocket_launch_rounded,
                color: AppTheme.deepPlum,
                size: secondarySize,
                iconSize: compact ? 27 : 29,
                onTap: onBoost,
                tooltip: 'Boost',
              ),
            ],
          );
        },
      ),
    );
  }
}

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.icon,
    required this.color,
    required this.size,
    required this.iconSize,
    required this.onTap,
    required this.tooltip,
    this.isBusy = false,
  });

  final IconData icon;
  final Color color;
  final double size;
  final double iconSize;
  final VoidCallback? onTap;
  final String tooltip;
  final bool isBusy;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: GestureDetector(
        onTap: onTap,
        child: Container(
          width: size,
          height: size,
          decoration: BoxDecoration(
            color: Colors.white,
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.25),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
            border: Border.all(color: color.withValues(alpha: 0.3), width: 2),
          ),
          child: isBusy
              ? Padding(
                  padding: EdgeInsets.all(size * 0.32),
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: color,
                  ),
                )
              : Icon(icon, color: color, size: iconSize),
        ),
      ),
    );
  }
}

// ─── Swipe feedback overlay ─────────────────────────────────────────────────

class _DiscoverWideBackdrop extends StatelessWidget {
  const _DiscoverWideBackdrop();

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: const BoxDecoration(color: Color(0xFFEAF6F6)),
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/images/discover/discover_desktop_bg.png',
            fit: BoxFit.cover,
            alignment: Alignment.center,
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.white.withValues(alpha: 0.60),
                  Colors.white.withValues(alpha: 0.26),
                  const Color(0xFF0F766E).withValues(alpha: 0.18),
                ],
                stops: const [0.0, 0.50, 1.0],
              ),
            ),
          ),
          DecoratedBox(
            decoration: BoxDecoration(
              gradient: RadialGradient(
                center: Alignment.center,
                radius: 0.68,
                colors: [
                  Colors.white.withValues(alpha: 0.58),
                  Colors.white.withValues(alpha: 0.16),
                  Colors.transparent,
                ],
                stops: const [0.0, 0.54, 1.0],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SwipeFeedback extends StatelessWidget {
  const _SwipeFeedback({
    required this.icon,
    required this.color,
    required this.label,
  });

  final IconData icon;
  final Color color;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(icon, size: 80, color: color)
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .scale(
                    begin: const Offset(0.5, 0.5),
                    end: const Offset(1.2, 1.2),
                    duration: 300.ms,
                  )
                  .then()
                  .fadeOut(delay: 200.ms, duration: 200.ms),
              const SizedBox(height: 8),
              Text(
                    label,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 24,
                      fontWeight: FontWeight.w900,
                      color: color,
                      letterSpacing: 2,
                      shadows: [
                        Shadow(
                          color: Colors.black.withValues(alpha: 0.3),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  )
                  .animate()
                  .fadeIn(duration: 200.ms)
                  .then()
                  .fadeOut(delay: 200.ms, duration: 200.ms),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Match overlay ──────────────────────────────────────────────────────────

class _MatchOverlay extends StatelessWidget {
  const _MatchOverlay({
    required this.matchedUser,
    required this.currentUser,
    required this.isOpeningChat,
    required this.isSendingShiftReport,
    required this.isStartingVideoIntro,
    required this.onSendShiftReport,
    required this.onStartChat,
    required this.onScheduleVideoIntro,
    required this.onKeepSwiping,
  });

  final UserModel matchedUser;
  final UserModel? currentUser;
  final bool isOpeningChat;
  final bool isSendingShiftReport;
  final bool isStartingVideoIntro;
  final VoidCallback onSendShiftReport;
  final VoidCallback onStartChat;
  final VoidCallback onScheduleVideoIntro;
  final VoidCallback onKeepSwiping;

  String _t(BuildContext context, String key) {
    return AppLocalizations.translate(key, Localizations.localeOf(context));
  }

  String _tf(BuildContext context, String key, Map<String, Object?> values) {
    return AppLocalizations.format(
      key,
      Localizations.localeOf(context),
      values,
    );
  }

  List<_ClinicalSignal> _signals(BuildContext context) {
    final current = currentUser;
    final signals = <_ClinicalSignal>[];

    if (current != null &&
        current.shiftType != null &&
        current.shiftType == matchedUser.shiftType) {
      final shift = AppLocalizations.shiftTypeLabel(
        matchedUser.shiftType!.value,
        Localizations.localeOf(context),
      );
      signals.add(
        _ClinicalSignal(
          icon: Icons.schedule_rounded,
          label: _tf(context, 'match_shift_signal', {'shift': shift}),
        ),
      );
    }

    if (current != null &&
        current.department != null &&
        current.department == matchedUser.department) {
      signals.add(
        _ClinicalSignal(
          icon: Icons.medical_services_rounded,
          label: _tf(context, 'match_department_signal', {
            'department': matchedUser.department,
          }),
        ),
      );
    }

    if (current != null &&
        current.languages.isNotEmpty &&
        matchedUser.languages.isNotEmpty) {
      final sharedLanguages = current.languages
          .where((language) => matchedUser.languages.contains(language))
          .toList(growable: false);
      if (sharedLanguages.isNotEmpty) {
        signals.add(
          _ClinicalSignal(
            icon: Icons.language_rounded,
            label: _tf(context, 'match_language_signal', {
              'language': sharedLanguages.first,
            }),
          ),
        );
      }
    }

    if (current != null &&
        current.preferredDatingWindow != null &&
        current.preferredDatingWindow == matchedUser.preferredDatingWindow) {
      final window = AppLocalizations.datingWindowLabel(
        matchedUser.preferredDatingWindow!.value,
        Localizations.localeOf(context),
      );
      signals.add(
        _ClinicalSignal(
          icon: Icons.event_available_rounded,
          label: _tf(context, 'match_dating_window_signal', {'window': window}),
        ),
      );
    }

    if (current?.isVerified == true && matchedUser.isVerified) {
      signals.add(
        _ClinicalSignal(
          icon: Icons.verified_rounded,
          label: _t(context, 'both_healthcare_verified'),
        ),
      );
    }

    if (current != null &&
        current.lookingFor != null &&
        current.lookingFor == matchedUser.lookingFor) {
      signals.add(
        _ClinicalSignal(
          icon: Icons.favorite_rounded,
          label: matchedUser.lookingFor!.displayName,
        ),
      );
    }

    final fallbackSignals = [
      _ClinicalSignal(
        icon: Icons.local_hospital_rounded,
        label: _t(context, 'healthcare_community'),
      ),
      _ClinicalSignal(
        icon: Icons.health_and_safety_rounded,
        label: _t(context, 'trust_first_match'),
      ),
      _ClinicalSignal(
        icon: Icons.nightlight_round,
        label: _t(context, 'shift_aware_connection'),
      ),
    ];

    for (final signal in fallbackSignals) {
      if (signals.length >= 3) break;
      if (!signals.any((item) => item.label == signal.label)) {
        signals.add(signal);
      }
    }

    return signals.take(4).toList(growable: false);
  }

  @override
  Widget build(BuildContext context) {
    final busy = isOpeningChat || isSendingShiftReport || isStartingVideoIntro;

    return Positioned.fill(
      child: Material(
        color: const Color(0xFF050A12).withValues(alpha: 0.94),
        child: Stack(
          children: [
            Positioned.fill(
              child: DecoratedBox(
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.topCenter,
                    radius: 1.1,
                    colors: [
                      const Color(0xFF0EA5A3).withValues(alpha: 0.22),
                      const Color(0xFF111827).withValues(alpha: 0.92),
                      const Color(0xFF050A12),
                    ],
                  ),
                ),
              ),
            ),
            ...List.generate(12, (index) {
              final random = Random(index + 32);
              final size = 3.0 + random.nextDouble() * 5;
              return Positioned(
                left: random.nextDouble() * MediaQuery.sizeOf(context).width,
                top: random.nextDouble() * MediaQuery.sizeOf(context).height,
                child: Container(
                  width: size,
                  height: size,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white.withValues(
                      alpha: 0.1 + random.nextDouble() * 0.18,
                    ),
                  ),
                ),
              ).animate().fadeIn(delay: (index * 70).ms);
            }),
            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 430),
                    child: Container(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 18),
                      decoration: BoxDecoration(
                        color: const Color(0xFF0B1220).withValues(alpha: 0.92),
                        borderRadius: BorderRadius.circular(28),
                        border: Border.all(
                          color: const Color(
                            0xFF67E8F9,
                          ).withValues(alpha: 0.22),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: AppTheme.deepPlum.withValues(alpha: 0.35),
                            blurRadius: 34,
                            offset: const Offset(0, 18),
                          ),
                        ],
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 7,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(
                                0xFF155E75,
                              ).withValues(alpha: 0.38),
                              borderRadius: BorderRadius.circular(999),
                              border: Border.all(
                                color: const Color(
                                  0xFF67E8F9,
                                ).withValues(alpha: 0.35),
                              ),
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.monitor_heart_rounded,
                                  color: Color(0xFF67E8F9),
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _t(context, 'healthcare_match'),
                                  style: GoogleFonts.plusJakartaSans(
                                    color: const Color(0xFFBAE6FD),
                                    fontSize: 11,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: 1.2,
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 260.ms),
                          const SizedBox(height: 14),
                          Text(
                                _t(context, 'code_heart_match_confirmed'),
                                textAlign: TextAlign.center,
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 32,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              )
                              .animate()
                              .fadeIn(duration: 350.ms)
                              .slideY(begin: 0.12, end: 0),
                          const SizedBox(height: 8),
                          Text(
                            _tf(context, 'match_confirmed_body', {
                              'name': matchedUser.name,
                            }),
                            textAlign: TextAlign.center,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              height: 1.45,
                              color: Colors.white.withValues(alpha: 0.76),
                            ),
                          ).animate().fadeIn(delay: 120.ms),
                          const SizedBox(height: 18),
                          SizedBox(
                                height: 52,
                                width: double.infinity,
                                child: CustomPaint(
                                  painter: _EcgLinePainter(
                                    color: const Color(0xFF67E8F9),
                                  ),
                                ),
                              )
                              .animate(
                                onPlay: (controller) => controller.repeat(),
                              )
                              .fadeIn(delay: 180.ms)
                              .shimmer(
                                duration: 1400.ms,
                                color: Colors.white.withValues(alpha: 0.28),
                              ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: _MatchIdBadge(
                                  imageUrl: currentUser?.displayPhoto,
                                  name: currentUser?.name ?? _t(context, 'you'),
                                  label: _t(context, 'match_you_label'),
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child:
                                    Container(
                                          width: 50,
                                          height: 50,
                                          decoration: BoxDecoration(
                                            shape: BoxShape.circle,
                                            gradient: const LinearGradient(
                                              colors: [
                                                Color(0xFF06B6D4),
                                                Color(0xFFDC2626),
                                              ],
                                            ),
                                            boxShadow: [
                                              BoxShadow(
                                                color: const Color(
                                                  0xFFDC2626,
                                                ).withValues(alpha: 0.35),
                                                blurRadius: 20,
                                              ),
                                            ],
                                          ),
                                          child: const Icon(
                                            Icons.favorite_rounded,
                                            color: Colors.white,
                                            size: 25,
                                          ),
                                        )
                                        .animate()
                                        .fadeIn(delay: 360.ms)
                                        .scale(
                                          begin: const Offset(0.6, 0.6),
                                          curve: Curves.easeOutBack,
                                        ),
                              ),
                              Flexible(
                                child: _MatchIdBadge(
                                  imageUrl: matchedUser.displayPhoto,
                                  name: matchedUser.name,
                                  label: _t(context, 'match_match_label'),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 8,
                            runSpacing: 8,
                            children: _signals(context)
                                .map((signal) => _ClinicalMatchChip(signal))
                                .toList(),
                          ).animate().fadeIn(delay: 420.ms),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(18),
                              border: Border.all(
                                color: Colors.white.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  color: Color(0xFF67E8F9),
                                  size: 20,
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: Text(
                                    _t(context, 'match_opener_hint'),
                                    style: GoogleFonts.plusJakartaSans(
                                      color: Colors.white.withValues(
                                        alpha: 0.76,
                                      ),
                                      fontSize: 12.5,
                                      height: 1.45,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ).animate().fadeIn(delay: 480.ms),
                          const SizedBox(height: 18),
                          Column(
                                children: [
                                  _MatchPrimaryActionButton(
                                    label: _t(context, 'send_shift_report'),
                                    loadingLabel: _t(context, 'sending_report'),
                                    icon: Icons.assignment_turned_in_rounded,
                                    isLoading: isSendingShiftReport,
                                    onPressed: busy ? null : onSendShiftReport,
                                  ),
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Expanded(
                                        child: _MatchSecondaryActionButton(
                                          label: _t(context, 'start_chat'),
                                          loadingLabel: _t(context, 'opening'),
                                          icon: Icons.chat_bubble_rounded,
                                          isLoading: isOpeningChat,
                                          onPressed: busy ? null : onStartChat,
                                        ),
                                      ),
                                      const SizedBox(width: 10),
                                      Expanded(
                                        child: _MatchSecondaryActionButton(
                                          label: _t(
                                            context,
                                            'schedule_video_intro',
                                          ),
                                          loadingLabel: _t(context, 'starting'),
                                          icon: Icons.videocam_rounded,
                                          isLoading: isStartingVideoIntro,
                                          onPressed: busy
                                              ? null
                                              : onScheduleVideoIntro,
                                        ),
                                      ),
                                    ],
                                  ),
                                ],
                              )
                              .animate()
                              .fadeIn(delay: 540.ms)
                              .slideY(begin: 0.16, end: 0),
                          const SizedBox(height: 10),
                          TextButton(
                            onPressed: busy ? null : onKeepSwiping,
                            child: Text(
                              _t(context, 'keep_discovering'),
                              style: GoogleFonts.plusJakartaSans(
                                color: Colors.white.withValues(alpha: 0.72),
                                fontSize: 14,
                                fontWeight: FontWeight.w700,
                              ),
                            ),
                          ).animate().fadeIn(delay: 620.ms),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MatchPrimaryActionButton extends StatelessWidget {
  const _MatchPrimaryActionButton({
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      height: 52,
      child: DecoratedBox(
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFDC2626), Color(0xFF0EA5A3)],
          ),
          borderRadius: BorderRadius.circular(18),
        ),
        child: ElevatedButton(
          onPressed: onPressed,
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.transparent,
            disabledBackgroundColor: Colors.transparent,
            foregroundColor: Colors.white,
            shadowColor: Colors.transparent,
            textStyle: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(18),
            ),
          ),
          child: _MatchActionContent(
            label: isLoading ? loadingLabel : label,
            icon: icon,
            isLoading: isLoading,
          ),
        ),
      ),
    );
  }
}

class _MatchSecondaryActionButton extends StatelessWidget {
  const _MatchSecondaryActionButton({
    required this.label,
    required this.loadingLabel,
    required this.icon,
    required this.isLoading,
    required this.onPressed,
  });

  final String label;
  final String loadingLabel;
  final IconData icon;
  final bool isLoading;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 58,
      child: OutlinedButton(
        onPressed: onPressed,
        style: OutlinedButton.styleFrom(
          foregroundColor: Colors.white,
          side: BorderSide(color: Colors.white.withValues(alpha: 0.22)),
          backgroundColor: Colors.white.withValues(alpha: 0.07),
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        child: _MatchActionContent(
          label: isLoading ? loadingLabel : label,
          icon: icon,
          isLoading: isLoading,
          allowWrap: true,
        ),
      ),
    );
  }
}

class _MatchActionContent extends StatelessWidget {
  const _MatchActionContent({
    required this.label,
    required this.icon,
    required this.isLoading,
    this.allowWrap = false,
  });

  final String label;
  final IconData icon;
  final bool isLoading;
  final bool allowWrap;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        if (isLoading)
          const SizedBox(
            width: 17,
            height: 17,
            child: CircularProgressIndicator(
              strokeWidth: 2,
              color: Colors.white,
            ),
          )
        else
          Icon(icon, size: allowWrap ? 18 : 20),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            label,
            maxLines: allowWrap ? 2 : 1,
            overflow: TextOverflow.ellipsis,
            textAlign: TextAlign.center,
          ),
        ),
      ],
    );
  }
}

class _ClinicalSignal {
  const _ClinicalSignal({required this.icon, required this.label});

  final IconData icon;
  final String label;
}

class _ClinicalMatchChip extends StatelessWidget {
  const _ClinicalMatchChip(this.signal);

  final _ClinicalSignal signal;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: const Color(0xFF0F766E).withValues(alpha: 0.24),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: const Color(0xFF5EEAD4).withValues(alpha: 0.24),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(signal.icon, color: const Color(0xFF99F6E4), size: 15),
          const SizedBox(width: 6),
          Text(
            signal.label,
            style: GoogleFonts.plusJakartaSans(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }
}

class _MatchIdBadge extends StatelessWidget {
  const _MatchIdBadge({
    required this.imageUrl,
    required this.name,
    required this.label,
  });

  final String? imageUrl;
  final String name;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 118,
      constraints: const BoxConstraints(minHeight: 150),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.96),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFBAE6FD), width: 2),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.22),
            blurRadius: 18,
            offset: const Offset(0, 10),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            height: 18,
            decoration: BoxDecoration(
              color: const Color(0xFF155E75),
              borderRadius: BorderRadius.circular(999),
            ),
            alignment: Alignment.center,
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                color: Colors.white,
                fontSize: 9,
                fontWeight: FontWeight.w900,
                letterSpacing: 0.9,
              ),
            ),
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              width: 86,
              height: 86,
              child: imageUrl != null && imageUrl!.isNotEmpty
                  ? AppNetworkImage(
                      imageUrl: imageUrl!,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => _badgeFallback(),
                      errorWidget: (_, __, ___) => _badgeFallback(),
                    )
                  : _badgeFallback(),
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: GoogleFonts.plusJakartaSans(
              color: const Color(0xFF111827),
              fontSize: 12,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }

  Widget _badgeFallback() {
    return Container(
      color: AppTheme.softLavender,
      child: const Icon(Icons.person, size: 34, color: AppTheme.warmGray),
    );
  }
}

class _EcgLinePainter extends CustomPainter {
  const _EcgLinePainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final baseline = size.height * 0.58;
    final path = Path()
      ..moveTo(0, baseline)
      ..lineTo(size.width * 0.15, baseline)
      ..lineTo(size.width * 0.2, baseline - 10)
      ..lineTo(size.width * 0.25, baseline + 12)
      ..lineTo(size.width * 0.31, baseline - 26)
      ..lineTo(size.width * 0.38, baseline + 18)
      ..lineTo(size.width * 0.45, baseline)
      ..lineTo(size.width * 0.58, baseline)
      ..lineTo(size.width * 0.63, baseline - 8)
      ..lineTo(size.width * 0.68, baseline + 10)
      ..lineTo(size.width * 0.73, baseline - 20)
      ..lineTo(size.width * 0.79, baseline)
      ..lineTo(size.width, baseline);

    final glowPaint = Paint()
      ..color = color.withValues(alpha: 0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    final linePaint = Paint()
      ..color = color
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.6
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round;

    canvas.drawPath(path, glowPaint);
    canvas.drawPath(path, linePaint);

    final heartPaint = Paint()
      ..color = AppTheme.warmRose
      ..style = PaintingStyle.fill;
    final center = Offset(size.width * 0.5, baseline);
    final heartPath = Path()
      ..moveTo(center.dx, center.dy + 8)
      ..cubicTo(
        center.dx - 24,
        center.dy - 6,
        center.dx - 10,
        center.dy - 24,
        center.dx,
        center.dy - 11,
      )
      ..cubicTo(
        center.dx + 10,
        center.dy - 24,
        center.dx + 24,
        center.dy - 6,
        center.dx,
        center.dy + 8,
      );
    canvas.drawPath(heartPath, heartPaint);
  }

  @override
  bool shouldRepaint(covariant _EcgLinePainter oldDelegate) {
    return oldDelegate.color != color;
  }
}
