import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/app_network_image.dart';
import 'package:nightingale_heart/features/matches/services/matches_service.dart';
import 'package:timeago/timeago.dart' as timeago;

/// A card that displays a matched user's photo, name, online status,
/// "New" badge, and last interaction time.
///
/// Used in the grid view on the matches page.
class MatchCard extends StatelessWidget {
  const MatchCard({
    super.key,
    required this.match,
    required this.currentUserId,
    this.onTap,
    this.onLongPress,
    this.onMessage,
  });

  final MatchModel match;
  final String currentUserId;
  final VoidCallback? onTap;
  final VoidCallback? onLongPress;
  final VoidCallback? onMessage;

  @override
  Widget build(BuildContext context) {
    final otherName = match.otherUserName(currentUserId);
    final otherPhoto = match.otherUserPhoto(currentUserId);
    final isNewMatch = match.isNew;

    return GestureDetector(
      onTap: onTap,
      onLongPress: () => _showOptions(context),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          boxShadow: AppTheme.cardShadow,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(20),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Photo ────────────────────────────────────────────────
              if (otherPhoto.isNotEmpty)
                AppNetworkImage(
                  imageUrl: otherPhoto,
                  fit: BoxFit.cover,
                  placeholder: (_, __) => Container(
                    color: AppTheme.softLavender,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 40,
                        color: AppTheme.warmGray,
                      ),
                    ),
                  ),
                  errorWidget: (_, __, ___) => Container(
                    color: AppTheme.softLavender,
                    child: const Center(
                      child: Icon(
                        Icons.person,
                        size: 40,
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
                      size: 48,
                      color: AppTheme.warmGray,
                    ),
                  ),
                ),

              // ── Gradient overlay ─────────────────────────────────────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [
                        Colors.transparent,
                        Colors.transparent,
                        Colors.black.withValues(alpha: 0.3),
                        Colors.black.withValues(alpha: 0.8),
                      ],
                      stops: const [0.0, 0.35, 0.6, 1.0],
                    ),
                  ),
                ),
              ),

              // ── "New" badge ──────────────────────────────────────────
              if (isNewMatch)
                Positioned(
                  top: 10,
                  left: 10,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.softAmber,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Text(
                      'New',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // ── Bottom info ──────────────────────────────────────────
              Positioned(
                left: 10,
                right: 10,
                bottom: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Name
                    Text(
                      otherName,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 2),

                    // Last interaction
                    if (match.lastInteraction != null)
                      Text(
                        timeago.format(match.lastInteraction!),
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),

                    const SizedBox(height: 8),

                    // Message button
                    SizedBox(
                      width: double.infinity,
                      height: 32,
                      child: ElevatedButton(
                        onPressed: onMessage,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppTheme.deepPlum,
                          foregroundColor: Colors.white,
                          elevation: 0,
                          padding: EdgeInsets.zero,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(10),
                          ),
                          textStyle: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        child: const Text('Message'),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showOptions(BuildContext context) {
    if (onLongPress != null) {
      onLongPress!();
      return;
    }

    showModalBottomSheet(
      context: context,
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.person_remove_outlined,
                  color: AppTheme.warmRose),
              title: const Text('Unmatch'),
              onTap: () {
                Navigator.pop(context);
                _confirmUnmatch(context);
              },
            ),
            ListTile(
              leading:
                  const Icon(Icons.block_rounded, color: AppTheme.warmRose),
              title: const Text('Block'),
              onTap: () {
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
    );
  }

  void _confirmUnmatch(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Unmatch'),
        content: Text(
          'Are you sure you want to unmatch with ${match.otherUserName(currentUserId)}? This cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(ctx);
              // The parent widget handles the actual unmatch call
              onLongPress?.call();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.warmRose,
            ),
            child: const Text('Unmatch'),
          ),
        ],
      ),
    );
  }
}
