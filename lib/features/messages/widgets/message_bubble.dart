import 'dart:io';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:intl/intl.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/message_model.dart';

// ─── Color Constants ─────────────────────────────────────────────────────────
const Color _deepPlum = Color(0xFF0F766E);
const Color _softAmber = Color(0xFFF59E0B);
const Color _softLavender = Color(0xFFF3E8FF);

/// A single message bubble in the chat.
///
/// Handles all [MessageType]s with specialized rendering:
/// - **text**: standard bubble with content
/// - **image**: rounded image thumbnail (tap to view full)
/// - **gift**: decorated bubble with large emoji + gift name
/// - **videoCall**: icon + duration text
/// - **system**: centered, no bubble, plain gray text
/// - **voiceNote**: waveform placeholder with duration
///
/// Sent messages (right-aligned) use a plum gradient background.
/// Received messages (left-aligned) use soft lavender.
class MessageBubble extends StatelessWidget {
  const MessageBubble({
    super.key,
    required this.message,
    required this.isMe,
    this.onVideoCallTap,
    this.videoCallLabel = 'Video Call',
    this.tapToJoinLabel = 'Tap to join',
  });

  final MessageModel message;
  final bool isMe;
  final VoidCallback? onVideoCallTap;
  final String videoCallLabel;
  final String tapToJoinLabel;

  @override
  Widget build(BuildContext context) {
    // System messages are centered with no bubble.
    if (message.type == MessageType.system) {
      return _buildSystemMessage(context);
    }

    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    // Bubble corner radius.
    final borderRadius = BorderRadius.only(
      topLeft: const Radius.circular(18),
      topRight: const Radius.circular(18),
      bottomLeft: isMe ? const Radius.circular(18) : const Radius.circular(4),
      bottomRight: isMe ? const Radius.circular(4) : const Radius.circular(18),
    );

    // Bubble background.
    final BoxDecoration decoration;
    if (isMe) {
      decoration = BoxDecoration(
        gradient: const LinearGradient(
          colors: [_deepPlum, Color(0xFF7C3AED)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: _deepPlum.withValues(alpha: 0.15),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      );
    } else {
      decoration = BoxDecoration(
        color: isDark ? const Color(0xFF231E2E) : _softLavender,
        borderRadius: borderRadius,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 2),
          ),
        ],
      );
    }

    final textColor = isMe ? Colors.white : theme.colorScheme.onSurface;
    final subtextColor = isMe
        ? Colors.white.withValues(alpha: 0.7)
        : theme.colorScheme.onSurfaceVariant;

    return Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Align(
            alignment: isMe ? Alignment.centerRight : Alignment.centerLeft,
            child: ConstrainedBox(
              constraints: BoxConstraints(
                maxWidth: MediaQuery.of(context).size.width * 0.75,
              ),
              child: _buildBubbleContent(
                context,
                decoration: decoration,
                borderRadius: borderRadius,
                textColor: textColor,
                subtextColor: subtextColor,
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .slideY(begin: 0.1, end: 0, duration: 200.ms);
  }

  Widget _buildBubbleContent(
    BuildContext context, {
    required BoxDecoration decoration,
    required BorderRadius borderRadius,
    required Color textColor,
    required Color subtextColor,
  }) {
    switch (message.type) {
      case MessageType.gift:
        return _buildGiftBubble(
          context,
          decoration,
          borderRadius,
          textColor,
          subtextColor,
        );
      case MessageType.image:
        return _buildImageBubble(
          context,
          decoration,
          borderRadius,
          textColor,
          subtextColor,
        );
      case MessageType.videoCall:
        return _buildVideoCallBubble(
          context,
          decoration,
          borderRadius,
          textColor,
          subtextColor,
        );
      case MessageType.voiceNote:
        return _buildVoiceNoteBubble(
          context,
          decoration,
          borderRadius,
          textColor,
          subtextColor,
        );
      case MessageType.text:
      default:
        return _buildTextBubble(context, decoration, textColor, subtextColor);
    }
  }

  // ─── Text Bubble ────────────────────────────────────────────────────────
  Widget _buildTextBubble(
    BuildContext context,
    BoxDecoration decoration,
    Color textColor,
    Color subtextColor,
  ) {
    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text(
            message.content,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              color: textColor,
              height: 1.35,
            ),
          ),
          const SizedBox(height: 4),
          _buildTimestampRow(subtextColor),
        ],
      ),
    );
  }

  // ─── Gift Bubble ────────────────────────────────────────────────────────
  Widget _buildGiftBubble(
    BuildContext context,
    BoxDecoration baseDecoration,
    BorderRadius borderRadius,
    Color textColor,
    Color subtextColor,
  ) {
    final giftEmoji = message.giftEmoji ?? '🎁';
    final giftName = message.giftName ?? 'Gift';

    return Container(
      decoration: baseDecoration.copyWith(
        border: Border.all(
          color: _softAmber.withValues(alpha: 0.5),
          width: 1.5,
        ),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(giftEmoji, style: const TextStyle(fontSize: 48)),
          const SizedBox(height: 8),
          Text(
            'Sent $giftName!',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: textColor,
            ),
          ),
          const SizedBox(height: 6),
          _buildTimestampRow(subtextColor),
        ],
      ),
    );
  }

  // ─── Image Bubble ───────────────────────────────────────────────────────
  Widget _buildImageBubble(
    BuildContext context,
    BoxDecoration decoration,
    BorderRadius borderRadius,
    Color textColor,
    Color subtextColor,
  ) {
    Widget imageWidget;
    final content = message.content;

    if (content.startsWith('http')) {
      imageWidget = CachedNetworkImage(
        imageUrl: content,
        fit: BoxFit.cover,
        placeholder: (_, __) => Container(
          height: 200,
          color: _softLavender,
          child: const Center(
            child: CircularProgressIndicator(strokeWidth: 2, color: _deepPlum),
          ),
        ),
        errorWidget: (_, __, ___) => Container(
          height: 200,
          color: _softLavender,
          child: const Icon(Icons.broken_image_rounded, size: 40),
        ),
      );
    } else {
      // Local file path.
      imageWidget = Image.file(
        File(content),
        fit: BoxFit.cover,
        errorBuilder: (_, __, ___) => Container(
          height: 200,
          color: _softLavender,
          child: const Icon(Icons.broken_image_rounded, size: 40),
        ),
      );
    }

    return GestureDetector(
      onTap: () => _showFullImage(context, content),
      child: Container(
        decoration: decoration,
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            ClipRRect(
              borderRadius: BorderRadius.only(
                topLeft:
                    decoration.borderRadius
                        ?.resolve(Directionality.of(context))
                        .topLeft ??
                    Radius.zero,
                topRight:
                    decoration.borderRadius
                        ?.resolve(Directionality.of(context))
                        .topRight ??
                    Radius.zero,
              ),
              child: ConstrainedBox(
                constraints: const BoxConstraints(
                  maxHeight: 250,
                  minHeight: 120,
                ),
                child: imageWidget,
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
              child: _buildTimestampRow(subtextColor),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Video Call Bubble ──────────────────────────────────────────────────
  Widget _buildVideoCallBubble(
    BuildContext context,
    BoxDecoration decoration,
    BorderRadius borderRadius,
    Color textColor,
    Color subtextColor,
  ) {
    final detail = message.content.startsWith('room:')
        ? tapToJoinLabel
        : message.content;
    final bubble = Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: isMe
                  ? Colors.white.withValues(alpha: 0.2)
                  : _deepPlum.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.videocam_rounded,
              color: isMe ? Colors.white : _deepPlum,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  videoCallLabel,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: textColor,
                  ),
                ),
                if (detail.isNotEmpty)
                  Text(
                    detail,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: subtextColor,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _buildTimestampRow(subtextColor),
        ],
      ),
    );

    if (onVideoCallTap == null) return bubble;

    return GestureDetector(onTap: onVideoCallTap, child: bubble);
  }

  // ─── Voice Note Bubble ──────────────────────────────────────────────────
  Widget _buildVoiceNoteBubble(
    BuildContext context,
    BoxDecoration decoration,
    BorderRadius borderRadius,
    Color textColor,
    Color subtextColor,
  ) {
    // Parse content: "MM:SS|downloadUrl" or just plain text
    String durationStr = message.content;
    String? audioUrl;
    if (message.content.contains('|')) {
      final parts = message.content.split('|');
      durationStr = parts[0];
      audioUrl = parts.sublist(1).join('|');
    }

    return Container(
      decoration: decoration,
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (audioUrl != null)
            _VoicePlayButton(audioUrl: audioUrl, isMe: isMe)
          else
            Icon(
              Icons.mic_rounded,
              color: isMe ? Colors.white : _deepPlum,
              size: 22,
            ),
          const SizedBox(width: 8),
          // Simple waveform representation.
          Flexible(
            child: Row(
              children: List.generate(
                12,
                (i) => Container(
                  width: 3,
                  height: (8 + (i % 4) * 5).toDouble(),
                  margin: const EdgeInsets.symmetric(horizontal: 1),
                  decoration: BoxDecoration(
                    color: isMe
                        ? Colors.white.withValues(alpha: 0.7)
                        : _deepPlum.withValues(alpha: 0.5),
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
            ),
          ),
          const SizedBox(width: 8),
          Text(
            durationStr,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: subtextColor,
            ),
          ),
          const SizedBox(width: 8),
          _buildTimestampRow(subtextColor),
        ],
      ),
    );
  }

  // ─── System Message ─────────────────────────────────────────────────────
  Widget _buildSystemMessage(BuildContext context) {
    final theme = Theme.of(context);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: Center(
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
          decoration: BoxDecoration(
            color: theme.colorScheme.surfaceContainerHighest.withValues(
              alpha: 0.4,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            message.content,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: theme.colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w400,
            ),
          ),
        ),
      ),
    );
  }

  // ─── Timestamp + Read Receipt ───────────────────────────────────────────
  Widget _buildTimestampRow(Color subtextColor) {
    final time = message.createdAt;
    final timeStr = DateFormat.Hm().format(time);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          timeStr,
          style: GoogleFonts.plusJakartaSans(fontSize: 10, color: subtextColor),
        ),
        if (isMe) ...[const SizedBox(width: 4), _buildReadReceipt()],
      ],
    );
  }

  Widget _buildReadReceipt() {
    if (message.isRead) {
      // Double blue check = read.
      return const Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.done_all_rounded, size: 14, color: Color(0xFF06B6D4)),
        ],
      );
    } else {
      // Single gray check = sent.
      return Icon(
        Icons.done_rounded,
        size: 14,
        color: Colors.white.withValues(alpha: 0.6),
      );
    }
  }

  // ─── Full Image Viewer ──────────────────────────────────────────────────
  void _showFullImage(BuildContext context, String imageUrl) {
    showDialog(
      context: context,
      builder: (ctx) => Dialog(
        backgroundColor: Colors.transparent,
        insetPadding: const EdgeInsets.all(16),
        child: Stack(
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(16),
                child: imageUrl.startsWith('http')
                    ? CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.contain,
                        placeholder: (_, __) => const Center(
                          child: CircularProgressIndicator(color: _deepPlum),
                        ),
                      )
                    : Image.file(File(imageUrl), fit: BoxFit.contain),
              ),
            ),
            Positioned(
              top: 0,
              right: 0,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 28),
                onPressed: () => Navigator.of(ctx).pop(),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Voice Play Button ──────────────────────────────────────────────────────

class _VoicePlayButton extends StatefulWidget {
  const _VoicePlayButton({required this.audioUrl, required this.isMe});

  final String audioUrl;
  final bool isMe;

  @override
  State<_VoicePlayButton> createState() => _VoicePlayButtonState();
}

class _VoicePlayButtonState extends State<_VoicePlayButton> {
  final AudioPlayer _player = AudioPlayer();
  bool _isPlaying = false;

  @override
  void initState() {
    super.initState();
    _player.onPlayerComplete.listen((_) {
      if (mounted) setState(() => _isPlaying = false);
    });
  }

  @override
  void dispose() {
    _player.dispose();
    super.dispose();
  }

  Future<void> _togglePlay() async {
    if (_isPlaying) {
      await _player.pause();
      if (mounted) setState(() => _isPlaying = false);
    } else {
      try {
        await _player.play(UrlSource(widget.audioUrl));
        if (mounted) setState(() => _isPlaying = true);
      } catch (e) {
        debugPrint('[VoicePlayButton] Error: $e');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: _togglePlay,
      child: Container(
        padding: const EdgeInsets.all(6),
        decoration: BoxDecoration(
          color: widget.isMe
              ? Colors.white.withValues(alpha: 0.2)
              : _deepPlum.withValues(alpha: 0.1),
          shape: BoxShape.circle,
        ),
        child: Icon(
          _isPlaying ? Icons.pause_rounded : Icons.play_arrow_rounded,
          color: widget.isMe ? Colors.white : _deepPlum,
          size: 22,
        ),
      ),
    );
  }
}
