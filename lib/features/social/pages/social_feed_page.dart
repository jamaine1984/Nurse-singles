import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:image_picker/image_picker.dart';
import 'package:photo_view/photo_view.dart';

import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/services/storage_service.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/core/widgets/pulse_avatar.dart';
import 'package:nightingale_heart/core/widgets/shimmer_loader.dart';
import 'package:nightingale_heart/features/social/services/social_service.dart';
import 'package:nightingale_heart/features/social/widgets/post_card.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Providers
// ---------------------------------------------------------------------------

final _postsProvider = StreamProvider<List<PostModel>>((ref) {
  final channelId = ref.watch(_selectedCommunityChannelProvider);
  return ref.watch(socialServiceProvider).getPosts(channelId: channelId);
});

final _selectedCommunityChannelProvider = StateProvider<String>((ref) {
  return _communityChannels.first.id;
});

const _communityChannels = [
  _CommunityChannel(
    id: 'break_room',
    labelKey: 'community_channel_break_room',
    promptKey: 'community_prompt_break_room',
    icon: Icons.forum_outlined,
    color: Color(0xFF0891B2),
  ),
  _CommunityChannel(
    id: 'night_shift_coffee',
    labelKey: 'community_channel_night_shift_coffee',
    promptKey: 'community_prompt_night_shift_coffee',
    icon: Icons.local_cafe_outlined,
    color: Color(0xFF7C3AED),
  ),
  _CommunityChannel(
    id: 'wellness_checkin',
    labelKey: 'community_channel_wellness_checkin',
    promptKey: 'community_prompt_wellness_checkin',
    icon: Icons.spa_outlined,
    color: Color(0xFF059669),
  ),
  _CommunityChannel(
    id: 'student_alumni',
    labelKey: 'community_channel_student_alumni',
    promptKey: 'community_prompt_student_alumni',
    icon: Icons.school_outlined,
    color: Color(0xFFF59E0B),
  ),
  _CommunityChannel(
    id: 'travel_city_hub',
    labelKey: 'community_channel_travel_city_hub',
    promptKey: 'community_prompt_travel_city_hub',
    icon: Icons.location_city_outlined,
    color: Color(0xFFDC2626),
  ),
  _CommunityChannel(
    id: 'ceu_offers',
    labelKey: 'community_channel_ceu_offers',
    promptKey: 'community_prompt_ceu_offers',
    icon: Icons.menu_book_outlined,
    color: Color(0xFF2563EB),
  ),
];

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// Community feed page with a "create post" card at the top and a scrollable
/// list of [PostCard] items.
class SocialFeedPage extends ConsumerStatefulWidget {
  const SocialFeedPage({super.key});

  @override
  ConsumerState<SocialFeedPage> createState() => _SocialFeedPageState();
}

class _SocialFeedPageState extends ConsumerState<SocialFeedPage> {
  final _postController = TextEditingController();
  final _commentControllers = <String, TextEditingController>{};
  bool _composing = false;
  bool _posting = false;
  String? _selectedImagePath;

  _CommunityChannel get _selectedChannel {
    final id = ref.read(_selectedCommunityChannelProvider);
    return _communityChannels.firstWhere(
      (channel) => channel.id == id,
      orElse: () => _communityChannels.first,
    );
  }

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

  String _channelLabel(_CommunityChannel channel) => _t(channel.labelKey);

  String _channelPrompt(_CommunityChannel channel) => _t(channel.promptKey);

  @override
  void dispose() {
    _postController.dispose();
    for (final c in _commentControllers.values) {
      c.dispose();
    }
    super.dispose();
  }

  // ---- Actions -----------------------------------------------------------

  Future<void> _createPost() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final content = _postController.text.trim();
    if (content.isEmpty) return;

    setState(() => _posting = true);

    try {
      final channel = _selectedChannel;
      String? imageUrl;
      if (_selectedImagePath != null) {
        imageUrl = await ref
            .read(storageServiceProvider)
            .uploadPostImage(userId: user.id, file: File(_selectedImagePath!));
      }
      await ref
          .read(socialServiceProvider)
          .createPost(
            userId: user.id,
            userName: user.name,
            userPhotoUrl: user.photoUrl,
            content: content,
            imageUrl: imageUrl,
            channelId: channel.id,
            channelLabel: _channelLabel(channel),
          );

      _postController.clear();
      setState(() {
        _composing = false;
        _selectedImagePath = null;
      });
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_tf('create_post_failed', {'error': e}))),
      );
    } finally {
      if (mounted) setState(() => _posting = false);
    }
  }

  Future<void> _pickImage() async {
    final picker = ImagePicker();
    final picked = await picker.pickImage(
      source: ImageSource.gallery,
      maxWidth: 1200,
    );
    if (picked != null && mounted) {
      setState(() => _selectedImagePath = picked.path);
    }
  }

  Future<void> _likePost(String postId) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    await ref.read(socialServiceProvider).likePost(postId, user.id);
  }

  Future<void> _deletePost(String postId) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_t('delete_post')),
        content: Text(_t('delete_post_confirm')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('cancel')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.warmRose),
            child: Text(_t('delete')),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await ref.read(socialServiceProvider).deletePost(postId);
    }
  }

  Future<void> _addComment(String postId) async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;

    final controller = _commentControllers[postId];
    if (controller == null || controller.text.trim().isEmpty) return;

    final text = controller.text.trim();
    controller.clear();

    await ref
        .read(socialServiceProvider)
        .addComment(
          postId: postId,
          userId: user.id,
          userName: user.name,
          userPhotoUrl: user.photoUrl,
          comment: text,
        );
  }

  void _openImageViewer(String imageUrl) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => Scaffold(
          backgroundColor: Colors.black,
          appBar: AppBar(
            backgroundColor: Colors.black,
            iconTheme: const IconThemeData(color: Colors.white),
          ),
          body: PhotoView(
            imageProvider: NetworkImage(imageUrl),
            minScale: PhotoViewComputedScale.contained,
            maxScale: PhotoViewComputedScale.covered * 2,
          ),
        ),
      ),
    );
  }

  void _showCommentSheet(PostModel post) {
    _commentControllers.putIfAbsent(post.id, () => TextEditingController());

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(ctx).viewInsets.bottom,
          ),
          child: DraggableScrollableSheet(
            initialChildSize: 0.5,
            minChildSize: 0.3,
            maxChildSize: 0.85,
            expand: false,
            builder: (ctx, scrollController) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(16),
                    child: Text(
                      _t('comments'),
                      style: Theme.of(ctx).textTheme.titleMedium,
                    ),
                  ),
                  const Divider(height: 1),
                  Expanded(
                    child: post.comments.isEmpty
                        ? Center(
                            child: Text(
                              _t('no_comments_yet_first'),
                              style: Theme.of(ctx).textTheme.bodyMedium,
                            ),
                          )
                        : ListView.builder(
                            controller: scrollController,
                            padding: const EdgeInsets.all(16),
                            itemCount: post.comments.length,
                            itemBuilder: (_, i) {
                              final c = post.comments[i];
                              final name = c['userName'] as String? ?? '';
                              final text = c['comment'] as String? ?? '';
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 12),
                                child: Row(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    PulseAvatar(
                                      imageUrl: c['userPhotoUrl'] as String?,
                                      name: name,
                                      radius: 16,
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            name,
                                            style: Theme.of(ctx)
                                                .textTheme
                                                .bodySmall
                                                ?.copyWith(
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                          const SizedBox(height: 2),
                                          Text(
                                            text,
                                            style: Theme.of(
                                              ctx,
                                            ).textTheme.bodyMedium,
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                  const Divider(height: 1),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 8, 8, 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _commentControllers[post.id],
                              decoration: InputDecoration(
                                hintText: _t('write_comment'),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 16,
                                  vertical: 10,
                                ),
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(24),
                                ),
                              ),
                              maxLines: 1,
                            ),
                          ),
                          const SizedBox(width: 8),
                          IconButton(
                            onPressed: () {
                              _addComment(post.id);
                              Navigator.of(ctx).pop();
                            },
                            icon: const Icon(
                              Icons.send_rounded,
                              color: AppTheme.deepPlum,
                            ),
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
      },
    );
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final postsAsync = ref.watch(_postsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          _t('community'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        actions: [
          IconButton(
            tooltip: _t('nurse_hub'),
            icon: const Icon(Icons.local_hospital_outlined),
            onPressed: () => context.push(RoutePaths.nurseHub),
          ),
        ],
      ),
      body: RefreshIndicator(
        color: AppTheme.deepPlum,
        onRefresh: () async {
          ref.invalidate(_postsProvider);
          // Small delay so the indicator is visible.
          await Future.delayed(const Duration(milliseconds: 500));
        },
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(child: _buildChannelSelector(theme)),

            // ---- Create post card ----------------------------------------
            SliverToBoxAdapter(child: _buildCreatePostCard(theme, userAsync)),

            // ---- Post list -----------------------------------------------
            postsAsync.when(
              loading: () => SliverList(
                delegate: SliverChildBuilderDelegate(
                  (_, i) => Padding(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    child: ShimmerLoader(height: 200, width: double.infinity),
                  ),
                  childCount: 3,
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Text(_tf('error_loading_posts', {'error': e})),
                ),
              ),
              data: (posts) {
                if (posts.isEmpty) {
                  return SliverFillRemaining(child: _buildEmptyState(theme));
                }

                return SliverList(
                  delegate: SliverChildBuilderDelegate((_, i) {
                    final post = posts[i];
                    return PostCard(
                      post: post,
                      currentUserId: userAsync.valueOrNull?.id ?? '',
                      index: i,
                      onLike: () => _likePost(post.id),
                      onComment: () => _showCommentSheet(post),
                      onDelete: () => _deletePost(post.id),
                      onImageTap: post.imageUrl != null
                          ? () => _openImageViewer(post.imageUrl!)
                          : null,
                    );
                  }, childCount: posts.length),
                );
              },
            ),

            // Bottom padding
            const SliverToBoxAdapter(child: SizedBox(height: 100)),
          ],
        ),
      ),
    );
  }

  Widget _buildChannelSelector(ThemeData theme) {
    final selectedId = ref.watch(_selectedCommunityChannelProvider);

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 10, 16, 4),
      child: SizedBox(
        height: 52,
        child: ListView.separated(
          scrollDirection: Axis.horizontal,
          itemCount: _communityChannels.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (context, index) {
            final channel = _communityChannels[index];
            final selected = selectedId == channel.id;

            return ChoiceChip(
              selected: selected,
              onSelected: (_) {
                ref.read(_selectedCommunityChannelProvider.notifier).state =
                    channel.id;
              },
              avatar: Icon(
                channel.icon,
                size: 18,
                color: selected
                    ? Colors.white
                    : channel.color.withValues(alpha: 0.95),
              ),
              label: Text(_channelLabel(channel)),
              selectedColor: channel.color,
              backgroundColor: theme.colorScheme.surface,
              side: BorderSide(
                color: selected
                    ? channel.color
                    : theme.colorScheme.outlineVariant,
              ),
              labelStyle: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: selected ? Colors.white : theme.colorScheme.onSurface,
              ),
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
            );
          },
        ),
      ),
    );
  }

  // ---- Create post card --------------------------------------------------

  Widget _buildCreatePostCard(ThemeData theme, AsyncValue userAsync) {
    final user = userAsync.valueOrNull;
    final channel = ref.watch(_selectedCommunityChannelProvider);
    final selectedChannel = _communityChannels.firstWhere(
      (item) => item.id == channel,
      orElse: () => _communityChannels.first,
    );

    return Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
          child: GlassCard(
            borderRadius: AppTheme.borderRadiusMedium,
            padding: const EdgeInsets.all(14),
            child: AnimatedSize(
              duration: const Duration(milliseconds: 300),
              curve: Curves.easeInOut,
              alignment: Alignment.topCenter,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Top row: avatar + tap hint
                  GestureDetector(
                    onTap: () => setState(() => _composing = true),
                    child: Row(
                      children: [
                        PulseAvatar(
                          imageUrl: user?.photoUrl,
                          name: user?.name,
                          radius: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                            decoration: BoxDecoration(
                              color: theme.colorScheme.surface,
                              borderRadius: BorderRadius.circular(24),
                              border: Border.all(
                                color: theme.colorScheme.outline,
                                width: 1,
                              ),
                            ),
                            child: Text(
                              _channelPrompt(selectedChannel),
                              style: theme.textTheme.bodyMedium?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Expanded compose area
                  if (_composing) ...[
                    const SizedBox(height: 12),
                    TextField(
                      controller: _postController,
                      maxLines: 4,
                      maxLength: 500,
                      decoration: InputDecoration(
                        hintText: _channelPrompt(selectedChannel),
                        border: const OutlineInputBorder(),
                      ),
                      autofocus: true,
                    ),
                    const SizedBox(height: 10),

                    // Image preview placeholder
                    if (_selectedImagePath != null)
                      Container(
                        height: 100,
                        width: double.infinity,
                        decoration: BoxDecoration(
                          color: AppTheme.softLavender,
                          borderRadius: BorderRadius.circular(
                            AppTheme.borderRadiusSmall,
                          ),
                        ),
                        child: Stack(
                          children: [
                            Positioned.fill(
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(
                                  AppTheme.borderRadiusSmall,
                                ),
                                child: Image.file(
                                  File(_selectedImagePath!),
                                  fit: BoxFit.cover,
                                ),
                              ),
                            ),
                            Positioned(
                              top: 4,
                              right: 4,
                              child: GestureDetector(
                                onTap: () =>
                                    setState(() => _selectedImagePath = null),
                                child: const CircleAvatar(
                                  radius: 14,
                                  backgroundColor: Colors.black54,
                                  child: Icon(
                                    Icons.close,
                                    size: 16,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                    const SizedBox(height: 10),
                    Row(
                      children: [
                        IconButton(
                          icon: const Icon(Icons.image_outlined),
                          color: AppTheme.deepPlum,
                          onPressed: _pickImage,
                        ),
                        const Spacer(),
                        TextButton(
                          onPressed: () {
                            _postController.clear();
                            setState(() {
                              _composing = false;
                              _selectedImagePath = null;
                            });
                          },
                          child: Text(_t('cancel')),
                        ),
                        const SizedBox(width: 8),
                        ElevatedButton(
                          onPressed: _posting ? null : _createPost,
                          child: _posting
                              ? const SizedBox(
                                  width: 18,
                                  height: 18,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : Text(_t('post')),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 400.ms)
        .slideY(begin: -0.05, end: 0, duration: 400.ms);
  }

  // ---- Empty state -------------------------------------------------------

  Widget _buildEmptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(48),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 72,
              color: theme.colorScheme.primary.withValues(alpha: 0.3),
            ),
            const SizedBox(height: 20),
            Text(
              _t('be_first_to_post'),
              style: theme.textTheme.titleMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            Text(
              _t('share_nursing_adventures'),
              style: theme.textTheme.bodyMedium,
              textAlign: TextAlign.center,
            ),
          ],
        ),
      ),
    );
  }
}

class _CommunityChannel {
  const _CommunityChannel({
    required this.id,
    required this.labelKey,
    required this.promptKey,
    required this.icon,
    required this.color,
  });

  final String id;
  final String labelKey;
  final String promptKey;
  final IconData icon;
  final Color color;
}
