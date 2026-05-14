import 'dart:async';
import 'dart:ui';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/admob_service.dart';
import 'package:nightingale_heart/features/compatibility/services/compatibility_service.dart';
import 'package:nightingale_heart/features/messages/providers/message_providers.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ─── Firestore Data Models ──────────────────────────────────────────────────

/// Lightweight model representing a like document from the `likes` collection.
class _LikeDoc {
  const _LikeDoc({
    required this.id,
    required this.likerId,
    required this.likedUserId,
    required this.likeType,
    required this.createdAt,
    required this.isMatched,
  });

  final String id;
  final String likerId;
  final String likedUserId;
  final String likeType;
  final DateTime? createdAt;
  final bool isMatched;

  factory _LikeDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return _LikeDoc(
      id: doc.id,
      likerId: data['likerId'] as String? ?? '',
      likedUserId: data['likedUserId'] as String? ?? '',
      likeType: data['likeType'] as String? ?? 'like',
      createdAt: _toDateTime(data['createdAt']),
      isMatched: data['isMatched'] as bool? ?? false,
    );
  }

  bool get isSuperlike => likeType == 'superlike';

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

/// Lightweight model representing a match document from the `matches` collection.
class _MatchDoc {
  const _MatchDoc({
    required this.id,
    required this.users,
    required this.user1Id,
    required this.user2Id,
    required this.matchedAt,
    this.lastMessage,
    this.lastMessageAt,
  });

  final String id;
  final List<String> users;
  final String user1Id;
  final String user2Id;
  final DateTime? matchedAt;
  final String? lastMessage;
  final DateTime? lastMessageAt;

  factory _MatchDoc.fromDoc(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return _MatchDoc(
      id: doc.id,
      users: List<String>.from(data['users'] ?? []),
      user1Id: data['user1'] as String? ?? data['user1Id'] as String? ?? '',
      user2Id: data['user2'] as String? ?? data['user2Id'] as String? ?? '',
      matchedAt: _toDateTime(data['matchedAt'] ?? data['createdAt']),
      lastMessage: data['lastMessage'] as String?,
      lastMessageAt: _toDateTime(data['lastMessageAt']),
    );
  }

  String otherUserId(String myId) => user1Id == myId ? user2Id : user1Id;

  static DateTime? _toDateTime(dynamic v) {
    if (v == null) return null;
    if (v is Timestamp) return v.toDate();
    if (v is DateTime) return v;
    return null;
  }
}

int _compareDateDesc(DateTime? a, DateTime? b) {
  if (a == null && b == null) return 0;
  if (a == null) return 1;
  if (b == null) return -1;
  return b.compareTo(a);
}

int _compareLikesDesc(_LikeDoc a, _LikeDoc b) {
  return _compareDateDesc(a.createdAt, b.createdAt);
}

int _compareMatchesDesc(_MatchDoc a, _MatchDoc b) {
  return _compareDateDesc(a.matchedAt, b.matchedAt);
}

// ─── Page Widget ────────────────────────────────────────────────────────────

/// Displays three tabs: **Likes** (outgoing), **Liked** (incoming), and
/// **Matches** (mutual).  Incoming likes are blurred for Free/Tech/College
/// tiers and can be revealed by watching 2 rewarded ads per profile.
class MatchesPage extends ConsumerStatefulWidget {
  const MatchesPage({super.key});

  @override
  ConsumerState<MatchesPage> createState() => _MatchesPageState();
}

class _MatchesPageState extends ConsumerState<MatchesPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  /// Profile IDs that the user has unblurred by watching ads.
  final Set<String> _unblurredIds = {};

  /// Tracks how many ads have been watched toward unblurring a specific profile.
  /// Key = userId, Value = number of ads watched (needs 2 to unblur).
  final Map<String, int> _adProgressMap = {};

  /// Cache of user profiles so we don't re-fetch the same profile repeatedly.
  final Map<String, UserModel> _userCache = {};

  /// Whether an ad is currently being shown (to prevent double-taps).
  bool _isShowingAd = false;
  String? _openingChatForUserId;

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ─── Tier check ──────────────────────────────────────────────────────────

  /// Returns `true` when the user's subscription allows them to see who liked
  /// them without watching ads (Nurse or Doctor tiers).
  bool _canSeeIncomingLikes(SubscriptionPlan plan) {
    return plan == SubscriptionPlan.nurse || plan == SubscriptionPlan.doctor;
  }

  // ─── Fetch a user snippet ────────────────────────────────────────────────

  Future<UserModel> _fetchUser(String userId) async {
    if (_userCache.containsKey(userId)) return _userCache[userId]!;

    try {
      final doc = await FirebaseFirestore.instance
          .collection(AppConstants.usersCollection)
          .doc(userId)
          .get();

      if (!doc.exists || doc.data() == null) {
        final fallback = UserModel(id: userId, name: 'User', email: '');
        _userCache[userId] = fallback;
        return fallback;
      }

      final user = UserModel.fromFirestore(doc);
      _userCache[userId] = user;
      return user;
    } catch (_) {
      final fallback = UserModel(id: userId, name: 'User', email: '');
      _userCache[userId] = fallback;
      return fallback;
    }
  }

  // ─── Ad flow ─────────────────────────────────────────────────────────────

  Future<void> _watchAdToReveal(String profileId) async {
    if (_isShowingAd) return;
    setState(() => _isShowingAd = true);

    final adService = ref.read(adMobServiceProvider);

    final shown = await adService.showRewardedAdWithCallback(
      onReward: (type, amount) {
        if (!mounted) return;
        setState(() {
          final current = _adProgressMap[profileId] ?? 0;
          _adProgressMap[profileId] = current + 1;
          if (_adProgressMap[profileId]! >= 2) {
            _unblurredIds.add(profileId);
            _adProgressMap.remove(profileId);
          }
        });
      },
    );

    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('no_ad_available'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF1C1917),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    }

    if (mounted) setState(() => _isShowingAd = false);
  }

  Future<void> _openMatchedChat(
    String currentUserId,
    String otherUserId,
  ) async {
    if (otherUserId.isEmpty || _openingChatForUserId == otherUserId) return;

    setState(() => _openingChatForUserId = otherUserId);
    try {
      final chatId = await ref
          .read(messageServiceProvider)
          .getOrCreateChat(currentUserId, otherUserId);
      if (!mounted) return;
      context.push('/messages/$chatId');
    } catch (error) {
      debugPrint('[MatchesPage] Failed to open matched chat: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _t('error_generic'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: const Color(0xFF1C1917),
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      );
    } finally {
      if (mounted) setState(() => _openingChatForUserId = null);
    }
  }

  // ─── Build ───────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final currentUser = ref.watch(currentUserProvider).valueOrNull;
    ref.watch(localeProvider);

    if (currentUser == null) {
      return Scaffold(
        backgroundColor: const Color(0xFF0F0B15),
        body: Center(
          child: CircularProgressIndicator(color: const Color(0xFF0F766E)),
        ),
      );
    }

    final plan = currentUser.plan;

    return Scaffold(
      backgroundColor: const Color(0xFF0F0B15),
      appBar: AppBar(
        backgroundColor: const Color(0xFF0F0B15),
        elevation: 0,
        centerTitle: true,
        title: Text(
          _t('connections'),
          style: GoogleFonts.playfairDisplay(
            fontSize: 24,
            fontWeight: FontWeight.w700,
            color: Colors.white,
          ),
        ),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(48),
          child: _buildTabBar(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildLikesTab(currentUser),
          _buildLikedTab(currentUser, plan),
          _buildMatchesTab(currentUser),
        ],
      ),
    );
  }

  // ─── Tab Bar ─────────────────────────────────────────────────────────────

  Widget _buildTabBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.06),
        borderRadius: BorderRadius.circular(14),
      ),
      child: TabBar(
        controller: _tabController,
        indicator: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        indicatorSize: TabBarIndicatorSize.tab,
        dividerColor: Colors.transparent,
        labelColor: Colors.white,
        unselectedLabelColor: Colors.white.withValues(alpha: 0.45),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w700,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 13,
          fontWeight: FontWeight.w500,
        ),
        labelPadding: EdgeInsets.zero,
        padding: const EdgeInsets.all(3),
        tabs: [
          Tab(text: _t('likes')),
          Tab(text: _t('liked')),
          Tab(text: _t('nav_matches')),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 1: LIKES (outgoing - users YOU liked)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLikesTab(UserModel currentUser) {
    final userId = currentUser.id;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.likesCollection)
          .where('likerId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }
        final docs = snapshot.data?.docs ?? [];
        final likes = docs.map((d) => _LikeDoc.fromDoc(d)).toList()
          ..sort(_compareLikesDesc);

        if (likes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_border_rounded,
            title: _t('no_likes_yet'),
            subtitle: _t('start_swiping_healthcare'),
          );
        }

        return _buildLikeGrid(
          currentUser: currentUser,
          likes: likes,
          resolveUserId: (like) => like.likedUserId,
          isBlurred: false,
          plan: SubscriptionPlan.free, // irrelevant, blur is off
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 2: LIKED (incoming - users who liked YOU)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildLikedTab(UserModel currentUser, SubscriptionPlan plan) {
    final userId = currentUser.id;
    return StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
      stream: FirebaseFirestore.instance
          .collection(AppConstants.likesCollection)
          .where('likedUserId', isEqualTo: userId)
          .snapshots(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }
        final docs = snapshot.data?.docs ?? [];
        final likes = docs.map((d) => _LikeDoc.fromDoc(d)).toList()
          ..sort(_compareLikesDesc);

        if (likes.isEmpty) {
          return _buildEmptyState(
            icon: Icons.person_search_rounded,
            title: _t('no_one_liked_yet'),
            subtitle: _t('profile_active_attention'),
          );
        }

        final shouldBlur = !_canSeeIncomingLikes(plan);

        return _buildLikeGrid(
          currentUser: currentUser,
          likes: likes,
          resolveUserId: (like) => like.likerId,
          isBlurred: shouldBlur,
          plan: plan,
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  TAB 3: MATCHES (mutual likes)
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildMatchesTab(UserModel currentUser) {
    final userId = currentUser.id;
    return StreamBuilder<List<_MatchDoc>>(
      stream: _watchMatchesForUser(userId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildShimmerGrid();
        }
        if (snapshot.hasError) {
          return _buildErrorState(snapshot.error!);
        }
        final matches = snapshot.data ?? [];

        if (matches.isEmpty) {
          return _buildEmptyState(
            icon: Icons.favorite_rounded,
            title: _t('no_matches_yet'),
            subtitle: _t('matches_explain'),
          );
        }

        return _buildMatchGrid(matches, currentUser);
      },
    );
  }

  Stream<List<_MatchDoc>> _watchMatchesForUser(String userId) {
    final controller = StreamController<List<_MatchDoc>>();
    final matchesById = <String, _MatchDoc>{};
    var firstSnapshotsPending = 2;
    var isClosed = false;

    void emit() {
      if (isClosed || firstSnapshotsPending > 0) return;
      final matches = matchesById.values.toList()..sort(_compareMatchesDesc);
      controller.add(matches);
    }

    void handleSnapshot(QuerySnapshot<Map<String, dynamic>> snapshot) {
      for (final change in snapshot.docChanges) {
        if (change.type == DocumentChangeType.removed) {
          matchesById.remove(change.doc.id);
        } else {
          matchesById[change.doc.id] = _MatchDoc.fromDoc(change.doc);
        }
      }
      if (firstSnapshotsPending > 0) firstSnapshotsPending -= 1;
      emit();
    }

    void handleError(Object error, StackTrace stackTrace) {
      if (!isClosed) controller.addError(error, stackTrace);
    }

    final collection = FirebaseFirestore.instance.collection(
      AppConstants.matchesCollection,
    );
    final subscriptions = <StreamSubscription>[
      collection
          .where('user1', isEqualTo: userId)
          .limit(50)
          .snapshots()
          .listen(handleSnapshot, onError: handleError),
      collection
          .where('user2', isEqualTo: userId)
          .limit(50)
          .snapshots()
          .listen(handleSnapshot, onError: handleError),
    ];

    controller.onCancel = () async {
      isClosed = true;
      await Future.wait(subscriptions.map((subscription) => subscription.cancel()));
    };

    return controller.stream;
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  GRID BUILDERS
  // ═══════════════════════════════════════════════════════════════════════════

  /// Builds a 2-column grid of like cards.
  Widget _buildLikeGrid({
    required UserModel currentUser,
    required List<_LikeDoc> likes,
    required String Function(_LikeDoc) resolveUserId,
    required bool isBlurred,
    required SubscriptionPlan plan,
  }) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: likes.length,
      itemBuilder: (context, index) {
        final like = likes[index];
        final otherUserId = resolveUserId(like);
        final profileBlurred =
            isBlurred && !_unblurredIds.contains(otherUserId);

        return FutureBuilder<UserModel>(
          future: _fetchUser(otherUserId),
          builder: (context, snap) {
            final user = snap.data;
            final compatibility = user == null
                ? null
                : CompatibilityService.score(currentUser, user);
            return _ProfileCard(
                  userId: otherUserId,
                  name: user?.name ?? '',
                  photoUrl: user?.photoUrl,
                  age: user?.age,
                  compatibility: compatibility,
                  department: user?.department,
                  shiftLabel: user?.shiftType?.displayName,
                  workplaceLabel: user?.workplaceDisplayLabel,
                  isVerified: user?.isVerified ?? false,
                  isSuperlike: like.isSuperlike,
                  isBlurred: profileBlurred,
                  adProgress: _adProgressMap[otherUserId] ?? 0,
                  showMessageButton: false,
                  isLoading: snap.connectionState == ConnectionState.waiting,
                  onTap: profileBlurred
                      ? null
                      : () => context.push('/discover/profile/$otherUserId'),
                  onWatchAd: profileBlurred
                      ? () => _watchAdToReveal(otherUserId)
                      : null,
                )
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                );
          },
        );
      },
    );
  }

  /// Builds a 2-column grid of match cards.
  Widget _buildMatchGrid(List<_MatchDoc> matches, UserModel currentUser) {
    final userId = currentUser.id;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: matches.length,
      itemBuilder: (context, index) {
        final match = matches[index];
        final otherUserId = match.otherUserId(userId);

        return FutureBuilder<UserModel>(
          future: _fetchUser(otherUserId),
          builder: (context, snap) {
            final user = snap.data;
            final compatibility = user == null
                ? null
                : CompatibilityService.score(currentUser, user);
            return _ProfileCard(
                  userId: otherUserId,
                  name: user?.name ?? '',
                  photoUrl: user?.photoUrl,
                  age: user?.age,
                  compatibility: compatibility,
                  department: user?.department,
                  shiftLabel: user?.shiftType?.displayName,
                  workplaceLabel: user?.workplaceDisplayLabel,
                  isVerified: user?.isVerified ?? false,
                  isSuperlike: false,
                  isBlurred: false,
                  adProgress: 0,
                  showMessageButton: true,
                  isLoading: snap.connectionState == ConnectionState.waiting,
                  onTap: () => context.push('/discover/profile/$otherUserId'),
                  onMessage: () => _openMatchedChat(userId, otherUserId),
                )
                .animate()
                .fadeIn(delay: (index * 60).ms, duration: 350.ms)
                .scale(
                  begin: const Offset(0.92, 0.92),
                  duration: 350.ms,
                  curve: Curves.easeOutBack,
                );
          },
        );
      },
    );
  }

  // ═══════════════════════════════════════════════════════════════════════════
  //  STATES
  // ═══════════════════════════════════════════════════════════════════════════

  Widget _buildShimmerGrid() {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 0.72,
      ),
      itemCount: 6,
      itemBuilder: (_, index) {
        return Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.white.withValues(alpha: 0.06),
              ),
            )
            .animate(onPlay: (c) => c.repeat())
            .shimmer(
              duration: 1200.ms,
              color: Colors.white.withValues(alpha: 0.06),
            );
      },
    );
  }

  Widget _buildEmptyState({
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
                  width: 100,
                  height: 100,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        const Color(0xFF0F766E).withValues(alpha: 0.15),
                        const Color(0xFFDC2626).withValues(alpha: 0.10),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Icon(
                    icon,
                    size: 48,
                    color: Colors.white.withValues(alpha: 0.3),
                  ),
                )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.8, 0.8)),
            const SizedBox(height: 24),
            Text(
              title,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 10),
            Text(
              subtitle,
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white.withValues(alpha: 0.35),
                height: 1.6,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline_rounded,
              size: 56,
              color: const Color(0xFFDC2626).withValues(alpha: 0.7),
            ),
            const SizedBox(height: 16),
            Text(
              _t('something_went_wrong'),
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white.withValues(alpha: 0.8),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              error.toString(),
              textAlign: TextAlign.center,
              maxLines: 3,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.35),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════════
//  _ProfileCard – stateless card used in every grid
// ═══════════════════════════════════════════════════════════════════════════════

class _ProfileCard extends StatelessWidget {
  const _ProfileCard({
    required this.userId,
    required this.name,
    required this.photoUrl,
    required this.age,
    required this.compatibility,
    required this.department,
    required this.shiftLabel,
    required this.workplaceLabel,
    required this.isVerified,
    required this.isSuperlike,
    required this.isBlurred,
    required this.adProgress,
    required this.showMessageButton,
    required this.isLoading,
    this.onTap,
    this.onMessage,
    this.onWatchAd,
  });

  final String userId;
  final String name;
  final String? photoUrl;
  final int? age;
  final CompatibilityResult? compatibility;
  final String? department;
  final String? shiftLabel;
  final String? workplaceLabel;
  final bool isVerified;
  final bool isSuperlike;
  final bool isBlurred;
  final int adProgress;
  final bool showMessageButton;
  final bool isLoading;
  final VoidCallback? onTap;
  final VoidCallback? onMessage;
  final VoidCallback? onWatchAd;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFF0F766E).withValues(alpha: 0.12),
              blurRadius: 20,
              offset: const Offset(0, 8),
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Photo ─────────────────────────────────────────────────
              _buildPhoto(),

              // ── Blur overlay for locked profiles ──────────────────────
              if (isBlurred) _buildBlurOverlay(),

              // ── Gradient for name readability ─────────────────────────
              if (!isBlurred) _buildGradientOverlay(),

              // ── Superlike badge ───────────────────────────────────────
              if (isSuperlike && !isBlurred) _buildSuperlikeBadge(),

              if (compatibility != null && !isBlurred && !isLoading)
                _buildCareFitBadge(),

              // ── Loading indicator ─────────────────────────────────────
              if (isLoading && !isBlurred)
                const Positioned.fill(
                  child: Center(
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white54,
                      ),
                    ),
                  ),
                ),

              // ── Bottom info (name, age) ───────────────────────────────
              if (!isBlurred && !isLoading) _buildBottomInfo(),

              // ── Message button for matches ────────────────────────────
              if (showMessageButton && !isBlurred && !isLoading)
                _buildMessageButton(context),

              // ── Blur lock overlay content ─────────────────────────────
              if (isBlurred) _buildLockOverlay(context),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildPhoto() {
    if (photoUrl != null && photoUrl!.isNotEmpty) {
      return CachedNetworkImage(
        imageUrl: photoUrl!,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          color: const Color(0xFF1A1523),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          color: const Color(0xFF1A1523),
          child: Center(
            child: Icon(
              Icons.person_rounded,
              size: 40,
              color: Colors.white.withValues(alpha: 0.15),
            ),
          ),
        ),
      );
    }

    return Container(
      color: const Color(0xFF1A1523),
      child: Center(
        child: Icon(
          Icons.person_rounded,
          size: 48,
          color: Colors.white.withValues(alpha: 0.15),
        ),
      ),
    );
  }

  Widget _buildBlurOverlay() {
    return Positioned.fill(
      child: Stack(
        fit: StackFit.expand,
        children: [
          // Apply blur to the image underneath
          ClipRRect(
            borderRadius: BorderRadius.circular(20),
            child: ImageFiltered(
              imageFilter: ImageFilter.blur(sigmaX: 15, sigmaY: 15),
              child: _buildPhoto(),
            ),
          ),
          // Dark tinted overlay
          Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              color: const Color(0xFF0F0B15).withValues(alpha: 0.4),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGradientOverlay() {
    return Positioned.fill(
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
            stops: const [0.0, 0.35, 0.6, 1.0],
          ),
        ),
      ),
    );
  }

  Widget _buildSuperlikeBadge() {
    return Positioned(
      top: 10,
      right: 10,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFF59E0B), Color(0xFFF97316)],
          ),
          borderRadius: BorderRadius.circular(10),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFF59E0B).withValues(alpha: 0.4),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: const Icon(Icons.star_rounded, color: Colors.white, size: 16),
      ),
    );
  }

  Widget _buildCareFitBadge() {
    final result = compatibility!;
    final verifiedTint = isVerified
        ? const Color(0xFF67E8F9)
        : Colors.white.withValues(alpha: 0.72);

    return Positioned(
      top: 10,
      left: 10,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 126),
        padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.58),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: const Color(0xFF67E8F9).withValues(alpha: 0.36),
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.health_and_safety_outlined,
              color: verifiedTint,
              size: 14,
            ),
            const SizedBox(width: 5),
            Flexible(
              child: Text(
                '${result.totalScore} Care Fit',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10.5,
                  fontWeight: FontWeight.w800,
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomInfo() {
    final clinicalDetails = [department, shiftLabel, workplaceLabel]
        .whereType<String>()
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .take(2)
        .join(' • ');
    final careSignal =
        compatibility != null && compatibility!.careSignals.isNotEmpty
        ? compatibility!.careSignals.first
        : compatibility?.matchTier;

    return Positioned(
      left: 12,
      right: 12,
      bottom: showMessageButton ? 50 : 12,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            age != null ? '$name, $age' : name,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w700,
              color: Colors.white,
              shadows: [
                Shadow(
                  blurRadius: 8,
                  color: Colors.black.withValues(alpha: 0.5),
                ),
              ],
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          if (clinicalDetails.isNotEmpty) ...[
            const SizedBox(height: 4),
            Text(
              clinicalDetails,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10.5,
                fontWeight: FontWeight.w700,
                color: const Color(0xFF67E8F9),
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
          if (careSignal != null && careSignal.isNotEmpty) ...[
            const SizedBox(height: 3),
            Text(
              careSignal,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                color: Colors.white.withValues(alpha: 0.78),
                shadows: [
                  Shadow(
                    blurRadius: 8,
                    color: Colors.black.withValues(alpha: 0.55),
                  ),
                ],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildMessageButton(BuildContext context) {
    return Positioned(
      left: 10,
      right: 10,
      bottom: 10,
      child: GestureDetector(
        onTap: onMessage,
        child: Container(
          height: 34,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
            ),
            borderRadius: BorderRadius.circular(10),
          ),
          alignment: Alignment.center,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.chat_bubble_rounded,
                color: Colors.white,
                size: 14,
              ),
              const SizedBox(width: 6),
              Text(
                AppLocalizations.translate(
                  'message',
                  Localizations.localeOf(context),
                ),
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: Colors.white,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLockOverlay(BuildContext context) {
    return Positioned.fill(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Lock icon
          Container(
            width: 56,
            height: 56,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.12),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.2),
                width: 1.5,
              ),
            ),
            child: Icon(
              Icons.lock_rounded,
              color: Colors.white.withValues(alpha: 0.7),
              size: 26,
            ),
          ),
          const SizedBox(height: 12),

          // Ad progress text
          if (adProgress > 0)
            Text(
              AppLocalizations.format(
                'ads_watched',
                Localizations.localeOf(context),
                {'count': adProgress},
              ),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: const Color(0xFFF59E0B),
              ),
            ),

          const SizedBox(height: 8),

          // Watch Ad button
          GestureDetector(
            onTap: onWatchAd,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xFF0F766E), Color(0xFFDC2626)],
                ),
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFF0F766E).withValues(alpha: 0.4),
                    blurRadius: 10,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.play_circle_fill_rounded,
                    color: Colors.white.withValues(alpha: 0.9),
                    size: 16,
                  ),
                  const SizedBox(width: 6),
                  Text(
                    AppLocalizations.translate(
                      'watch_ad_to_reveal',
                      Localizations.localeOf(context),
                    ),
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
