import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/safety_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

class BlockedUsersPage extends ConsumerStatefulWidget {
  const BlockedUsersPage({super.key});

  @override
  ConsumerState<BlockedUsersPage> createState() => _BlockedUsersPageState();
}

class _BlockedUsersPageState extends ConsumerState<BlockedUsersPage> {
  Future<List<UserModel>>? _blockedUsersFuture;
  List<String> _lastBlockedIds = const [];

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  @override
  Widget build(BuildContext context) {
    final currentUserAsync = ref.watch(currentUserProvider);
    ref.watch(localeProvider);
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: Text(_t('blocked_users'))),
      body: currentUserAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (_, __) => Center(child: Text(_t('error_generic'))),
        data: (currentUser) {
          if (currentUser == null) {
            return Center(child: Text(_t('please_sign_in_continue')));
          }

          final blockedIds = currentUser.blocked;
          if (blockedIds.isEmpty) {
            return _EmptyBlockedUsers(theme: theme);
          }

          if (!_sameIds(blockedIds, _lastBlockedIds)) {
            _lastBlockedIds = List<String>.from(blockedIds);
            _blockedUsersFuture = ref
                .read(safetyServiceProvider)
                .fetchUsersByIds(blockedIds);
          }

          return FutureBuilder<List<UserModel>>(
            future: _blockedUsersFuture,
            builder: (context, snapshot) {
              if (snapshot.connectionState == ConnectionState.waiting) {
                return const Center(child: CircularProgressIndicator());
              }

              final users = snapshot.data ?? const <UserModel>[];
              if (users.isEmpty) {
                return _EmptyBlockedUsers(theme: theme);
              }

              return ListView.separated(
                padding: const EdgeInsets.all(16),
                itemCount: users.length,
                separatorBuilder: (_, __) => const SizedBox(height: 10),
                itemBuilder: (context, index) {
                  final user = users[index];
                  return _BlockedUserTile(
                    user: user,
                    unblockLabel: _t('unblock_user'),
                    onUnblock: () => _unblock(currentUser.id, user),
                  );
                },
              );
            },
          );
        },
      ),
    );
  }

  bool _sameIds(List<String> a, List<String> b) {
    if (a.length != b.length) return false;
    final aSet = a.toSet();
    final bSet = b.toSet();
    return aSet.length == bSet.length && aSet.containsAll(bSet);
  }

  Future<void> _unblock(String currentUserId, UserModel user) async {
    await ref
        .read(safetyServiceProvider)
        .unblockUser(currentUserId: currentUserId, blockedUserId: user.id);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          AppLocalizations.format('user_unblocked', ref.read(localeProvider), {
            'name': user.name,
          }),
        ),
      ),
    );
  }
}

class _EmptyBlockedUsers extends StatelessWidget {
  const _EmptyBlockedUsers({required this.theme});

  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.verified_user_outlined,
              size: 58,
              color: AppTheme.deepPlum.withValues(alpha: 0.45),
            ),
            const SizedBox(height: 16),
            Text(
              AppLocalizations.translate(
                'no_blocked_users',
                Localizations.localeOf(context),
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 24,
                fontWeight: FontWeight.w700,
                color: theme.colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              AppLocalizations.translate(
                'no_blocked_users_body',
                Localizations.localeOf(context),
              ),
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _BlockedUserTile extends StatelessWidget {
  const _BlockedUserTile({
    required this.user,
    required this.unblockLabel,
    required this.onUnblock,
  });

  final UserModel user;
  final String unblockLabel;
  final VoidCallback onUnblock;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DecoratedBox(
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: theme.colorScheme.outline.withValues(alpha: 0.16),
        ),
      ),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: AppTheme.softLavender,
          backgroundImage: user.photoUrl != null
              ? CachedNetworkImageProvider(user.photoUrl!)
              : null,
          child: user.photoUrl == null
              ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
              : null,
        ),
        title: Text(
          user.name,
          style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
        ),
        subtitle: user.jobTitle == null
            ? null
            : Text(
                user.jobTitle!,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
        trailing: TextButton(onPressed: onUnblock, child: Text(unblockLabel)),
      ),
    );
  }
}
