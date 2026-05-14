import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:go_router/go_router.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/services/safety_service.dart';
import 'package:nightingale_heart/core/widgets/app_network_image.dart';
import 'package:nightingale_heart/core/widgets/shimmer_loader.dart';
import 'package:nightingale_heart/features/messages/services/message_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:timeago/timeago.dart' as timeago;

/// Streams a single user document from Firestore.
final _userDetailProvider = StreamProvider.family<UserModel?, String>((
  ref,
  userId,
) {
  return FirebaseFirestore.instance
      .collection(AppConstants.usersCollection)
      .doc(userId)
      .snapshots()
      .map((snap) {
        if (!snap.exists || snap.data() == null) return null;
        return UserModel.fromFirestore(snap);
      });
});

/// Full profile detail page, opened when a user taps a card in Discover
/// or a match card.
class ProfileDetailPage extends ConsumerStatefulWidget {
  const ProfileDetailPage({super.key, required this.userId});

  final String userId;

  @override
  ConsumerState<ProfileDetailPage> createState() => _ProfileDetailPageState();
}

class _ProfileDetailPageState extends ConsumerState<ProfileDetailPage> {
  final PageController _galleryController = PageController();
  final ScrollController _scrollController = ScrollController();
  double _headerOpacity = 1.0;
  int _currentPhotoIndex = 0;

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  void _onScroll() {
    final offset = _scrollController.offset;
    final newOpacity = (1.0 - (offset / 300)).clamp(0.0, 1.0);
    if ((_headerOpacity - newOpacity).abs() > 0.01) {
      setState(() => _headerOpacity = newOpacity);
    }
  }

  @override
  void dispose() {
    _galleryController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  List<String> _getAllPhotos(UserModel user) {
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

  void _goBack() {
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go(RoutePaths.discover);
    }
  }

  void _goToPhoto(int index, int count) {
    if (count <= 0) return;
    final target = index.clamp(0, count - 1);
    _galleryController.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
  }

  void _showPhotoGallery(List<String> photos, int initialIndex) {
    if (photos.isEmpty) return;
    showDialog(
      context: context,
      builder: (_) => _ProfileDetailPhotoDialog(
        photos: photos,
        initialIndex: initialIndex.clamp(0, photos.length - 1),
      ),
    );
  }

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  String? _clinicalSummary(UserModel user) {
    final role = user.jobTitle?.trim();
    if (role == null || role.isEmpty) return null;

    final details = <String>[role];
    final workplace = user.workplaceDisplayLabel;
    if (workplace != null && workplace.isNotEmpty) {
      details.add(_tf('at_workplace', {'workplace': workplace}));
    }
    final department = user.department?.trim();
    if (department != null && department.isNotEmpty) {
      details.add(department);
    }
    return details.join(' - ');
  }

  String? _privacySummary(UserModel user) {
    final signals = <String>[];
    if (user.hideWorkplace && user.hasWorkplace) {
      signals.add(_t('hospital_name_hidden'));
    }
    if (user.avoidSameWorkplace) {
      signals.add(_t('same_workplace_filtered'));
    }
    if (user.avoidSameDepartment) {
      signals.add(_t('same_department_reduced'));
    }
    if (signals.isEmpty) return null;
    return signals.join(' • ');
  }

  Future<void> _onMessage(UserModel targetUser) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final messageService = ref.read(messageServiceProvider);
    final chatId = await messageService.getOrCreateChat(
      currentUser.id,
      targetUser.id,
    );

    if (mounted) {
      context.push('/messages/$chatId');
    }
  }

  void _showReportBlockMenu(UserModel user) {
    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(
                Icons.flag_outlined,
                color: AppTheme.warmRose,
              ),
              title: Text(_t('report_user')),
              onTap: () {
                Navigator.pop(context);
                _reportUser(user);
              },
            ),
            ListTile(
              leading: const Icon(
                Icons.block_rounded,
                color: AppTheme.warmRose,
              ),
              title: Text(_t('block_user')),
              onTap: () {
                Navigator.pop(context);
                _blockUser(user);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _reportUser(UserModel user) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    var selectedReason = ReportReason.harassment;
    final detailsController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            title: Text(_t('report_user')),
            content: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(_tf('report_user_body', {'name': user.name})),
                const SizedBox(height: 16),
                DropdownButtonFormField<ReportReason>(
                  value: selectedReason,
                  decoration: InputDecoration(
                    labelText: _t('report_reason'),
                    border: const OutlineInputBorder(),
                  ),
                  items: ReportReason.values
                      .map(
                        (reason) => DropdownMenuItem(
                          value: reason,
                          child: Text(_reportReasonLabel(reason)),
                        ),
                      )
                      .toList(),
                  onChanged: (reason) {
                    if (reason == null) return;
                    setDialogState(() => selectedReason = reason);
                  },
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: detailsController,
                  maxLines: 3,
                  maxLength: 500,
                  decoration: InputDecoration(
                    labelText: _t('report_details_optional'),
                    border: const OutlineInputBorder(),
                  ),
                ),
              ],
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(ctx).pop(false),
                child: Text(_t('cancel')),
              ),
              ElevatedButton(
                onPressed: () => Navigator.of(ctx).pop(true),
                child: Text(_t('submit_report')),
              ),
            ],
          );
        },
      ),
    );

    if (confirmed != true) {
      detailsController.dispose();
      return;
    }

    await ref
        .read(safetyServiceProvider)
        .reportUser(
          reporter: currentUser,
          reportedUserId: user.id,
          reportedUserName: user.name,
          reason: selectedReason,
          reasonLabel: _reportReasonLabel(selectedReason),
          source: 'profile',
          details: detailsController.text,
        );
    detailsController.dispose();

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('user_reported'))));
    }
  }

  Future<void> _blockUser(UserModel user) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('block_user')),
        content: Text(_tf('block_user_body', {'name': user.name})),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmRose,
              foregroundColor: Colors.white,
            ),
            child: Text(_t('block_user')),
          ),
        ],
      ),
    );

    if (confirmed != true) return;

    await ref
        .read(safetyServiceProvider)
        .blockUser(currentUserId: currentUser.id, blockedUserId: user.id);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tf('user_blocked', {'name': user.name}))),
      );
      Navigator.of(context).pop();
    }
  }

  String _reportReasonLabel(ReportReason reason) {
    return switch (reason) {
      ReportReason.inappropriate => _t('report_reason_inappropriate'),
      ReportReason.spam => _t('report_reason_spam'),
      ReportReason.harassment => _t('report_reason_harassment'),
      ReportReason.fakeProfile => _t('report_reason_fake_profile'),
      ReportReason.scam => _t('report_reason_scam'),
      ReportReason.underage => _t('report_reason_underage'),
      ReportReason.other => _t('report_reason_other'),
    };
  }

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(_userDetailProvider(widget.userId));
    ref.watch(localeProvider);
    final theme = Theme.of(context);
    final locale = ref.read(localeProvider);
    final screenSize = MediaQuery.of(context).size;

    return Scaffold(
      body: userAsync.when(
        loading: () => _buildLoading(),
        error: (e, _) => _buildErrorState(e, theme),
        data: (user) {
          if (user == null) return _buildNotFound(theme);
          final photos = _getAllPhotos(user);
          final verificationBadge = AppLocalizations.healthcareCredentialLabel(
            user.healthcareCredentialType?.value,
            locale,
            fallback: user.healthcareVerificationBadge,
          );
          final professionBadge = user.publicProfessionBadge;

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Parallax header with photo gallery ──────────────
                  SliverToBoxAdapter(
                    child: LayoutBuilder(
                      builder: (context, constraints) {
                        final isWide = constraints.maxWidth >= 700;
                        final galleryWidth = isWide
                            ? min(480.0, constraints.maxWidth - 48)
                            : constraints.maxWidth;
                        final galleryHeight = isWide
                            ? min(620.0, max(470.0, galleryWidth * 1.28))
                            : min(
                                screenSize.height * 0.52,
                                max(420.0, screenSize.width * 1.12),
                              );

                        return Padding(
                          padding: EdgeInsets.fromLTRB(
                            isWide ? 24 : 0,
                            isWide ? 76 : 0,
                            isWide ? 24 : 0,
                            isWide ? 18 : 0,
                          ),
                          child: Center(
                            child: SizedBox(
                              width: galleryWidth,
                              height: galleryHeight,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  isWide ? 26 : 0,
                                ),
                                child: _DetailPhotoGallery(
                                  photos: photos,
                                  controller: _galleryController,
                                  currentIndex: _currentPhotoIndex,
                                  onChanged: (index) => setState(
                                    () => _currentPhotoIndex = index,
                                  ),
                                  onPrevious: () => _goToPhoto(
                                    _currentPhotoIndex - 1,
                                    photos.length,
                                  ),
                                  onNext: () => _goToPhoto(
                                    _currentPhotoIndex + 1,
                                    photos.length,
                                  ),
                                  onOpenPhoto: (index) =>
                                      _showPhotoGallery(photos, index),
                                ),
                              ),
                            ),
                          ),
                        );
                      },
                    ),
                  ),

                  // ── Profile content ────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        Text(
                          '${user.name}${user.age != null ? ', ${user.age}' : ''}',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 30,
                            fontWeight: FontWeight.w700,
                          ),
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

                        const SizedBox(height: 8),

                        if (professionBadge != null || user.isVerified) ...[
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: [
                              if (professionBadge != null)
                                _ProfileBadgePill(
                                  icon: Icons.badge_rounded,
                                  label: professionBadge,
                                  color: const Color(0xFF155E75),
                                ),
                              if (user.isVerified)
                                _ProfileBadgePill(
                                  icon: Icons.verified_rounded,
                                  label: verificationBadge,
                                  color: AppTheme.softAmber,
                                ),
                            ],
                          ),
                          const SizedBox(height: 8),
                        ],

                        // Job title, privacy-safe workplace, department
                        if (_clinicalSummary(user) != null)
                          _InfoRow(
                            icon: Icons.medical_services_outlined,
                            text: _clinicalSummary(user)!,
                          ),

                        if (_privacySummary(user) != null)
                          _InfoRow(
                            icon: Icons.privacy_tip_outlined,
                            text: _privacySummary(user)!,
                          ),

                        if (user.yearsExperience != null &&
                            user.yearsExperience! > 0)
                          _InfoRow(
                            icon: Icons.workspace_premium_outlined,
                            text: _tf('years_experience', {
                              'years': user.yearsExperience,
                            }),
                          ),

                        if (user.shiftType != null)
                          _InfoRow(
                            icon: _shiftIcon(user.shiftType!),
                            text: AppLocalizations.shiftTypeLabel(
                              user.shiftType!.value,
                              locale,
                            ),
                          ),

                        if (user.preferredDatingWindow != null)
                          _InfoRow(
                            icon: Icons.event_available_outlined,
                            text: _tf('prefers_window', {
                              'window': AppLocalizations.datingWindowLabel(
                                user.preferredDatingWindow!.value,
                                locale,
                              ),
                            }),
                          ),

                        if (user.availableAfterShift)
                          _InfoRow(
                            icon: Icons.local_cafe_outlined,
                            text: _t('open_after_shift'),
                          ),

                        if (user.quietHoursStart != null &&
                            user.quietHoursEnd != null)
                          _InfoRow(
                            icon: Icons.notifications_paused_outlined,
                            text: _tf('quiet_hours', {
                              'start': user.quietHoursStart,
                              'end': user.quietHoursEnd,
                            }),
                          ),

                        if (user.location != null && user.location!.isNotEmpty)
                          _InfoRow(
                            icon: Icons.location_on_outlined,
                            text:
                                '${user.location}'
                                '${user.timezone != null && user.timezone!.isNotEmpty ? ' (${user.timezone})' : ''}',
                          ),

                        // Online / last seen
                        if (user.isOnline)
                          _InfoRow(
                            icon: Icons.circle,
                            iconColor: const Color(0xFF22C55E),
                            iconSize: 10,
                            text: _t('online_now'),
                          )
                        else if (user.lastSeen != null)
                          _InfoRow(
                            icon: Icons.access_time_rounded,
                            text: _tf('last_seen', {
                              'time': timeago.format(user.lastSeen!),
                            }),
                          ),

                        const SizedBox(height: 24),

                        // Bio
                        if (user.bio != null && user.bio!.isNotEmpty) ...[
                          _SectionTitle(title: _t('about_me')),
                          const SizedBox(height: 8),
                          Text(
                            user.bio!,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 15,
                              height: 1.6,
                              color: theme.colorScheme.onSurface.withValues(
                                alpha: 0.8,
                              ),
                            ),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Interests
                        if (user.interests.isNotEmpty) ...[
                          _SectionTitle(title: _t('interests')),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.interests
                                .map(
                                  (interest) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.softLavender,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Text(
                                      interest,
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 13,
                                        fontWeight: FontWeight.w500,
                                        color: AppTheme.deepPlum,
                                      ),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],

                        // Languages
                        if (user.languages.isNotEmpty) ...[
                          _SectionTitle(title: _t('languages_label')),
                          const SizedBox(height: 10),
                          Wrap(
                            spacing: 8,
                            runSpacing: 8,
                            children: user.languages
                                .map(
                                  (lang) => Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 14,
                                      vertical: 8,
                                    ),
                                    decoration: BoxDecoration(
                                      color: AppTheme.softAmber.withValues(
                                        alpha: 0.15,
                                      ),
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        const Icon(
                                          Icons.translate,
                                          size: 14,
                                          color: AppTheme.softAmber,
                                        ),
                                        const SizedBox(width: 6),
                                        Text(
                                          lang,
                                          style: GoogleFonts.plusJakartaSans(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                          const SizedBox(height: 24),
                        ],
                      ]),
                    ),
                  ),
                ],
              ),

              // ── Top bar ─────────────────────────────────────────────
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _CircleIconButton(
                          icon: Icons.arrow_back_rounded,
                          onTap: _goBack,
                        ),
                        _CircleIconButton(
                          icon: Icons.more_vert_rounded,
                          onTap: () => _showReportBlockMenu(user),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // ── Bottom action bar ───────────────────────────────────
              Positioned(
                left: 0,
                right: 0,
                bottom: 0,
                child: Container(
                  padding: EdgeInsets.fromLTRB(
                    24,
                    16,
                    24,
                    MediaQuery.of(context).padding.bottom + 16,
                  ),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        theme.scaffoldBackgroundColor.withValues(alpha: 0),
                        theme.scaffoldBackgroundColor,
                      ],
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      _BottomAction(
                        icon: Icons.message_rounded,
                        label: _t('message'),
                        color: AppTheme.deepPlum,
                        onTap: () => _onMessage(user),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _shiftIcon(ShiftType shift) {
    switch (shift) {
      case ShiftType.dayShift:
        return Icons.wb_sunny_rounded;
      case ShiftType.nightShift:
        return Icons.nightlight_round;
      case ShiftType.rotatingShift:
        return Icons.sync;
      case ShiftType.flexible:
        return Icons.schedule;
    }
  }

  Widget _buildLoading() {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          children: [
            ShimmerLoader(height: 440, borderRadius: 24),
            const SizedBox(height: 16),
            ShimmerLoader.line(width: 200, height: 24),
            const SizedBox(height: 12),
            ShimmerLoader.line(width: 160, height: 14),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState(Object error, ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 64, color: theme.colorScheme.error),
          const SizedBox(height: 16),
          Text(_t('failed_load_profile'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => ref.invalidate(_userDetailProvider(widget.userId)),
            child: Text(_t('retry')),
          ),
        ],
      ),
    );
  }

  Widget _buildNotFound(ThemeData theme) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.person_off_outlined,
            size: 64,
            color: AppTheme.warmGray,
          ),
          const SizedBox(height: 16),
          Text(_t('profile_not_found'), style: theme.textTheme.titleMedium),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: Text(_t('go_back')),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _DetailPhotoGallery extends StatelessWidget {
  const _DetailPhotoGallery({
    required this.photos,
    required this.controller,
    required this.currentIndex,
    required this.onChanged,
    required this.onPrevious,
    required this.onNext,
    required this.onOpenPhoto,
  });

  final List<String> photos;
  final PageController controller;
  final int currentIndex;
  final ValueChanged<int> onChanged;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final ValueChanged<int> onOpenPhoto;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Stack(
      fit: StackFit.expand,
      children: [
        DecoratedBox(
          decoration: BoxDecoration(
            color: const Color(0xFF052F34),
            border: Border.all(
              color: theme.colorScheme.outline.withValues(alpha: 0.12),
            ),
          ),
          child: photos.isNotEmpty
              ? PageView.builder(
                  controller: controller,
                  itemCount: photos.length,
                  onPageChanged: onChanged,
                  itemBuilder: (context, index) {
                    return GestureDetector(
                      behavior: HitTestBehavior.opaque,
                      onTap: () => onOpenPhoto(index),
                      child: Padding(
                        padding: const EdgeInsets.all(10),
                        child: AppNetworkImage(
                          imageUrl: photos[index],
                          fit: BoxFit.contain,
                          placeholder: (_, __) => Container(
                            color: AppTheme.softLavender,
                            child: const Center(
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: AppTheme.softLavender,
                            child: const Icon(
                              Icons.person,
                              size: 80,
                              color: AppTheme.warmGray,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                )
              : const Center(
                  child: Icon(
                    Icons.person,
                    size: 100,
                    color: AppTheme.warmGray,
                  ),
                ),
        ),
        Positioned.fill(
          child: IgnorePointer(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.34),
                    Colors.transparent,
                    Colors.transparent,
                    Colors.black.withValues(alpha: 0.42),
                  ],
                  stops: const [0.0, 0.18, 0.66, 1.0],
                ),
              ),
            ),
          ),
        ),
        if (photos.length > 1) ...[
          Positioned(
            left: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _GalleryArrowButton(
                icon: Icons.chevron_left_rounded,
                onPressed: currentIndex > 0 ? onPrevious : null,
              ),
            ),
          ),
          Positioned(
            right: 12,
            top: 0,
            bottom: 0,
            child: Center(
              child: _GalleryArrowButton(
                icon: Icons.chevron_right_rounded,
                onPressed: currentIndex < photos.length - 1 ? onNext : null,
              ),
            ),
          ),
          Positioned(
            left: 0,
            right: 0,
            bottom: 24,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 5,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.46),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    '${currentIndex + 1}/${photos.length}',
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                SmoothPageIndicator(
                  controller: controller,
                  count: photos.length,
                  effect: WormEffect(
                    dotWidth: 8,
                    dotHeight: 8,
                    spacing: 6,
                    activeDotColor: Colors.white,
                    dotColor: Colors.white.withValues(alpha: 0.38),
                  ),
                ),
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _GalleryArrowButton extends StatelessWidget {
  const _GalleryArrowButton({required this.icon, required this.onPressed});

  final IconData icon;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return IconButton.filled(
      onPressed: onPressed,
      style: IconButton.styleFrom(
        backgroundColor: Colors.black.withValues(alpha: 0.46),
        disabledBackgroundColor: Colors.black.withValues(alpha: 0.14),
        foregroundColor: Colors.white,
        disabledForegroundColor: Colors.white.withValues(alpha: 0.34),
        fixedSize: const Size.square(42),
      ),
      icon: Icon(icon, size: 28),
    );
  }
}

class _ProfileDetailPhotoDialog extends StatefulWidget {
  const _ProfileDetailPhotoDialog({
    required this.photos,
    required this.initialIndex,
  });

  final List<String> photos;
  final int initialIndex;

  @override
  State<_ProfileDetailPhotoDialog> createState() =>
      _ProfileDetailPhotoDialogState();
}

class _ProfileDetailPhotoDialogState extends State<_ProfileDetailPhotoDialog> {
  late final PageController _controller;
  late int _currentIndex;

  @override
  void initState() {
    super.initState();
    _currentIndex = widget.initialIndex;
    _controller = PageController(initialPage: _currentIndex);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goTo(int index) {
    final target = index.clamp(0, widget.photos.length - 1);
    _controller.animateToPage(
      target,
      duration: const Duration(milliseconds: 220),
      curve: Curves.easeOutCubic,
    );
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
            if (widget.photos.length > 1) ...[
              Positioned(
                left: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _GalleryArrowButton(
                    icon: Icons.chevron_left_rounded,
                    onPressed: _currentIndex > 0
                        ? () => _goTo(_currentIndex - 1)
                        : null,
                  ),
                ),
              ),
              Positioned(
                right: 16,
                top: 0,
                bottom: 0,
                child: Center(
                  child: _GalleryArrowButton(
                    icon: Icons.chevron_right_rounded,
                    onPressed: _currentIndex < widget.photos.length - 1
                        ? () => _goTo(_currentIndex + 1)
                        : null,
                  ),
                ),
              ),
            ],
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

class _SectionTitle extends StatelessWidget {
  const _SectionTitle({required this.title});
  final String title;

  @override
  Widget build(BuildContext context) {
    return Text(
      title,
      style: GoogleFonts.playfairDisplay(
        fontSize: 20,
        fontWeight: FontWeight.w600,
      ),
    );
  }
}

class _ProfileBadgePill extends StatelessWidget {
  const _ProfileBadgePill({
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
      constraints: const BoxConstraints(maxWidth: 220),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.13),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.32)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11.5,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  const _InfoRow({
    required this.icon,
    required this.text,
    this.iconColor,
    this.iconSize,
  });

  final IconData icon;
  final String text;
  final Color? iconColor;
  final double? iconSize;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Icon(
            icon,
            size: iconSize ?? 18,
            color:
                iconColor ?? theme.colorScheme.onSurface.withValues(alpha: 0.5),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              text,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({required this.icon, required this.onTap});
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.3),
          shape: BoxShape.circle,
        ),
        child: Icon(icon, color: Colors.white, size: 22),
      ),
    );
  }
}

class _BottomAction extends StatelessWidget {
  const _BottomAction({
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
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              shape: BoxShape.circle,
              border: Border.all(color: color.withValues(alpha: 0.3)),
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
