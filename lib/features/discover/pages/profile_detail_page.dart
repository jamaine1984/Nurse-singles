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
    final photos = <String>[];
    if (user.photoUrl != null && user.photoUrl!.isNotEmpty) {
      photos.add(user.photoUrl!);
    }
    photos.addAll(user.gallery.where((url) => url.isNotEmpty));
    return photos;
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
    final screenHeight = MediaQuery.of(context).size.height;

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

          return Stack(
            children: [
              CustomScrollView(
                controller: _scrollController,
                slivers: [
                  // ── Parallax header with photo gallery ──────────────
                  SliverToBoxAdapter(
                    child: SizedBox(
                      height: screenHeight * 0.55,
                      child: Stack(
                        fit: StackFit.expand,
                        children: [
                          // Photo gallery
                          if (photos.isNotEmpty)
                            PageView.builder(
                              controller: _galleryController,
                              itemCount: photos.length,
                              itemBuilder: (context, index) {
                                return AppNetworkImage(
                                  imageUrl: photos[index],
                                  fit: BoxFit.cover,
                                  placeholder: (_, __) =>
                                      Container(color: AppTheme.softLavender),
                                  errorWidget: (_, __, ___) => Container(
                                    color: AppTheme.softLavender,
                                    child: const Icon(
                                      Icons.person,
                                      size: 80,
                                      color: AppTheme.warmGray,
                                    ),
                                  ),
                                );
                              },
                            )
                          else
                            Container(
                              color: AppTheme.softLavender,
                              child: const Icon(
                                Icons.person,
                                size: 100,
                                color: AppTheme.warmGray,
                              ),
                            ),

                          // Gradient
                          Positioned.fill(
                            child: DecoratedBox(
                              decoration: BoxDecoration(
                                gradient: LinearGradient(
                                  begin: Alignment.topCenter,
                                  end: Alignment.bottomCenter,
                                  colors: [
                                    Colors.black.withValues(alpha: 0.3),
                                    Colors.transparent,
                                    Colors.transparent,
                                    theme.scaffoldBackgroundColor.withValues(
                                      alpha: 0.8,
                                    ),
                                    theme.scaffoldBackgroundColor,
                                  ],
                                  stops: const [0.0, 0.15, 0.5, 0.85, 1.0],
                                ),
                              ),
                            ),
                          ),

                          // Page indicator
                          if (photos.length > 1)
                            Positioned(
                              bottom: 60,
                              left: 0,
                              right: 0,
                              child: Center(
                                child: SmoothPageIndicator(
                                  controller: _galleryController,
                                  count: photos.length,
                                  effect: WormEffect(
                                    dotWidth: 8,
                                    dotHeight: 8,
                                    spacing: 6,
                                    activeDotColor: AppTheme.deepPlum,
                                    dotColor: Colors.white.withValues(
                                      alpha: 0.5,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),

                  // ── Profile content ────────────────────────────────
                  SliverPadding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                    sliver: SliverList(
                      delegate: SliverChildListDelegate([
                        // Name, age, verified
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                '${user.name}${user.age != null ? ', ${user.age}' : ''}',
                                style: GoogleFonts.playfairDisplay(
                                  fontSize: 30,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                            if (user.isVerified)
                              Container(
                                constraints: const BoxConstraints(
                                  maxWidth: 178,
                                ),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: AppTheme.softAmber.withValues(
                                    alpha: 0.15,
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    const Icon(
                                      Icons.verified,
                                      color: AppTheme.softAmber,
                                      size: 16,
                                    ),
                                    const SizedBox(width: 4),
                                    Flexible(
                                      child: Text(
                                        verificationBadge,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: GoogleFonts.plusJakartaSans(
                                          fontSize: 11.5,
                                          fontWeight: FontWeight.w700,
                                          color: AppTheme.softAmber,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ).animate().fadeIn(duration: 300.ms).slideY(begin: 0.1),

                        const SizedBox(height: 8),

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
                          onTap: () => Navigator.of(context).pop(),
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
            ShimmerLoader(
              height: MediaQuery.of(context).size.height * 0.5,
              borderRadius: 0,
            ),
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
