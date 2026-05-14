import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:timeago/timeago.dart' as timeago;

import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/features/video_dating/services/video_service.dart';

/// Displays a single speed-dating room inside the lobby grid.
///
/// Shows room name, host, duration badge, participant count and a join button.
/// Adapts its status badge colour to the room state: waiting (amber),
/// active (green), full (grey).
class RoomCard extends StatelessWidget {
  const RoomCard({
    super.key,
    required this.room,
    required this.currentUserId,
    required this.onJoin,
    this.index = 0,
  });

  final SpeedDatingRoom room;
  final String currentUserId;
  final VoidCallback onJoin;

  /// Position in the grid -- used to stagger the entrance animation.
  final int index;

  // ---- Duration badge colour mapping -------------------------------------

  Color _durationColor(int minutes) {
    if (minutes <= 5) return AppTheme.emerald;
    if (minutes <= 15) return AppTheme.softAmber;
    return AppTheme.warmRose;
  }

  // ---- Status helpers ----------------------------------------------------

  String _statusLabel() {
    if (room.isFull) return 'Full';
    if (room.isActive) return 'Active';
    return 'Waiting';
  }

  Color _statusColor() {
    if (room.isFull) return AppTheme.warmGray;
    if (room.isActive) return AppTheme.emerald;
    return AppTheme.softAmber;
  }

  bool get _canJoin =>
      room.isWaiting &&
      !room.isFull &&
      !room.currentParticipants.contains(currentUserId);

  bool get _alreadyJoined =>
      room.currentParticipants.contains(currentUserId);

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return GlassCard(
      padding: const EdgeInsets.all(14),
      margin: const EdgeInsets.all(4),
      borderRadius: AppTheme.borderRadiusMedium,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ---- Header: status + duration ---------------------------------
          Row(
            children: [
              _StatusBadge(
                label: _statusLabel(),
                color: _statusColor(),
              ),
              const Spacer(),
              _DurationChip(
                minutes: room.duration,
                color: _durationColor(room.duration),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---- Room name -------------------------------------------------
          Text(
            room.name,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: theme.textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w700,
            ),
          ),

          const SizedBox(height: 4),

          // ---- Host name -------------------------------------------------
          Row(
            children: [
              Icon(
                Icons.person_outline_rounded,
                size: 14,
                color: theme.colorScheme.onSurfaceVariant,
              ),
              const SizedBox(width: 4),
              Expanded(
                child: Text(
                  room.hostName,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: theme.textTheme.bodySmall,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---- Participants ----------------------------------------------
          Row(
            children: [
              // Stacked avatar placeholders
              SizedBox(
                width: _stackWidth(),
                height: 28,
                child: Stack(
                  children: List.generate(
                    room.participantCount.clamp(0, 4),
                    (i) => Positioned(
                      left: i * 16.0,
                      child: _MiniAvatar(index: i),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 6),
              Text(
                '${room.participantCount}/${room.maxParticipants} joined',
                style: theme.textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),

          const SizedBox(height: 10),

          // ---- Created time ----------------------------------------------
          if (room.createdAt != null)
            Text(
              timeago.format(room.createdAt!),
              style: theme.textTheme.bodySmall?.copyWith(
                fontSize: 11,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),

          const SizedBox(height: 10),

          // ---- Action button ---------------------------------------------
          SizedBox(
            width: double.infinity,
            child: _alreadyJoined
                ? OutlinedButton.icon(
                    onPressed: onJoin,
                    icon: const Icon(Icons.videocam_rounded, size: 18),
                    label: const Text('Enter'),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 10),
                      side: const BorderSide(color: AppTheme.deepPlum),
                    ),
                  )
                : _canJoin
                    ? _JoinButton(onPressed: onJoin)
                    : ElevatedButton(
                        onPressed: null,
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 10),
                        ),
                        child: Text(
                          room.isFull ? 'Full' : 'In Progress',
                        ),
                      ),
          ),
        ],
      ),
    )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: (index * 80).ms,
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          delay: (index * 80).ms,
          curve: Curves.easeOut,
        );
  }

  double _stackWidth() {
    final count = room.participantCount.clamp(0, 4);
    if (count == 0) return 0;
    return count * 16.0 + 12; // 16px offset each + trailing diameter
  }
}

// ---------------------------------------------------------------------------
// Small sub-widgets
// ---------------------------------------------------------------------------

class _StatusBadge extends StatelessWidget {
  const _StatusBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: color,
        ),
      ),
    );
  }
}

class _DurationChip extends StatelessWidget {
  const _DurationChip({required this.minutes, required this.color});

  final int minutes;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final String label;
    if (minutes >= 60) {
      final hrs = minutes ~/ 60;
      final rem = minutes % 60;
      label = rem > 0 ? '${hrs}h ${rem}m' : '${hrs}h';
    } else {
      label = '${minutes}min';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.timer_outlined, size: 12, color: color),
          const SizedBox(width: 3),
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

class _MiniAvatar extends StatelessWidget {
  const _MiniAvatar({required this.index});

  final int index;

  static const _colors = [
    AppTheme.deepPlum,
    AppTheme.warmRose,
    AppTheme.softAmber,
    AppTheme.emerald,
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 28,
      height: 28,
      decoration: BoxDecoration(
        color: _colors[index % _colors.length].withValues(alpha: 0.2),
        shape: BoxShape.circle,
        border: Border.all(
          color: Theme.of(context).colorScheme.surface,
          width: 2,
        ),
      ),
      child: Icon(
        Icons.person_rounded,
        size: 14,
        color: _colors[index % _colors.length],
      ),
    );
  }
}

class _JoinButton extends StatelessWidget {
  const _JoinButton({required this.onPressed});

  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return DecoratedBox(
      decoration: BoxDecoration(
        gradient: AppTheme.primaryGradient,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
      ),
      child: ElevatedButton(
        onPressed: onPressed,
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.transparent,
          shadowColor: Colors.transparent,
          padding: const EdgeInsets.symmetric(vertical: 10),
        ),
        child: const Text('Join'),
      ),
    );
  }
}
