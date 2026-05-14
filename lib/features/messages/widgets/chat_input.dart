import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:emoji_picker_flutter/emoji_picker_flutter.dart'
    as emoji_picker_flutter;
import 'dart:io' show Platform;

// ─── Color Constants ─────────────────────────────────────────────────────────
const Color _deepPlum = Color(0xFF0F766E);
const Color _warmRose = Color(0xFFDC2626);
const Color _softAmber = Color(0xFFF59E0B);

/// A rich chat input bar with:
/// - An attachment button (+) that opens a bottom sheet with Photo, Video Call
/// - Gift icon button always visible next to the text field
/// - Voice note icon button (mic) when text field is empty
/// - An expanding multi-line [TextField] (up to 3 lines)
/// - An emoji picker toggle
/// - A send button that appears only when text is not empty
///
/// Callbacks:
/// - [onSendMessage]: invoked with the trimmed text when the send button is
///   tapped.
/// - [onSendImage]: invoked when the user selects "Photo" from attachments.
/// - [onSendGift]: invoked when the user taps the gift icon.
/// - [onStartVideoCall]: invoked when the user selects "Video Call" from
///   attachments.
/// - [onSendVoiceNote]: invoked when the user taps the mic icon to record.
class ChatInput extends StatefulWidget {
  const ChatInput({
    super.key,
    required this.onSendMessage,
    required this.onSendImage,
    required this.onSendGift,
    required this.onStartVideoCall,
    this.onSendVoiceNote,
    this.photoLabel = 'Photo',
    this.giftLabel = 'Gift',
    this.videoCallLabel = 'Video Call',
    this.messageHint = 'Type a message...',
  });

  final ValueChanged<String> onSendMessage;
  final VoidCallback onSendImage;
  final VoidCallback onSendGift;
  final VoidCallback onStartVideoCall;
  final VoidCallback? onSendVoiceNote;
  final String photoLabel;
  final String giftLabel;
  final String videoCallLabel;
  final String messageHint;

  @override
  State<ChatInput> createState() => _ChatInputState();
}

class _ChatInputState extends State<ChatInput> {
  final TextEditingController _controller = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  bool _showEmojiPicker = false;
  bool _hasText = false;

  @override
  void initState() {
    super.initState();
    _controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    _controller.removeListener(_onTextChanged);
    _controller.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _onTextChanged() {
    final hasText = _controller.text.trim().isNotEmpty;
    if (hasText != _hasText) {
      setState(() => _hasText = hasText);
    }
  }

  void _toggleEmojiPicker() {
    if (_showEmojiPicker) {
      // Show keyboard, hide emoji picker.
      setState(() => _showEmojiPicker = false);
      _focusNode.requestFocus();
    } else {
      // Hide keyboard, show emoji picker.
      _focusNode.unfocus();
      setState(() => _showEmojiPicker = true);
    }
  }

  void _onEmojiSelected(
    emoji_picker_flutter.Category? category,
    emoji_picker_flutter.Emoji emoji,
  ) {
    final text = _controller.text;
    final selection = _controller.selection;
    final newText = text.replaceRange(
      selection.start,
      selection.end,
      emoji.emoji,
    );
    final newCursor = selection.start + emoji.emoji.length;
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newCursor),
    );
  }

  void _onBackspacePressed() {
    final text = _controller.text;
    if (text.isEmpty) return;
    final selection = _controller.selection;
    if (selection.start == 0) return;

    final newText = text.replaceRange(selection.start - 1, selection.start, '');
    _controller.value = TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: selection.start - 1),
    );
  }

  void _handleSend() {
    final text = _controller.text.trim();
    if (text.isEmpty) return;
    widget.onSendMessage(text);
    _controller.clear();
    setState(() => _hasText = false);
  }

  void _showAttachmentSheet(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      backgroundColor: isDark ? const Color(0xFF1A1523) : Colors.white,
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 16),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                _AttachmentOption(
                  icon: Icons.photo_library_rounded,
                  label: widget.photoLabel,
                  color: _deepPlum,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onSendImage();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.card_giftcard_rounded,
                  label: widget.giftLabel,
                  color: _softAmber,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onSendGift();
                  },
                ),
                _AttachmentOption(
                  icon: Icons.videocam_rounded,
                  label: widget.videoCallLabel,
                  color: _warmRose,
                  onTap: () {
                    Navigator.of(ctx).pop();
                    widget.onStartVideoCall();
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xFF1A1523) : Colors.white;
    final fieldColor = isDark
        ? const Color(0xFF231E2E)
        : const Color(0xFFF5F5F4);

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        // ── Input Row ──────────────────────────────────────────────────
        Container(
          padding: const EdgeInsets.fromLTRB(8, 8, 8, 8),
          decoration: BoxDecoration(
            color: bgColor,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.05),
                blurRadius: 10,
                offset: const Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            top: false,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                // Attachment button (+)
                _InputIconButton(
                  icon: Icons.add_rounded,
                  onPressed: () => _showAttachmentSheet(context),
                  color: _deepPlum,
                ),
                const SizedBox(width: 4),

                // Text field
                Expanded(
                  child: Container(
                    decoration: BoxDecoration(
                      color: fieldColor,
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Expanded(
                          child: TextField(
                            controller: _controller,
                            focusNode: _focusNode,
                            maxLines: 3,
                            minLines: 1,
                            textCapitalization: TextCapitalization.sentences,
                            style: GoogleFonts.plusJakartaSans(fontSize: 15),
                            onTap: () {
                              if (_showEmojiPicker) {
                                setState(() => _showEmojiPicker = false);
                              }
                            },
                            decoration: InputDecoration(
                              hintText: widget.messageHint,
                              hintStyle: GoogleFonts.plusJakartaSans(
                                fontSize: 15,
                                color: Colors.grey,
                              ),
                              border: InputBorder.none,
                              contentPadding: const EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 10,
                              ),
                              isDense: true,
                            ),
                          ),
                        ),
                        // Emoji toggle
                        _InputIconButton(
                          icon: _showEmojiPicker
                              ? Icons.keyboard_rounded
                              : Icons.emoji_emotions_outlined,
                          onPressed: _toggleEmojiPicker,
                          color: _deepPlum.withValues(alpha: 0.6),
                          size: 22,
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(width: 4),

                // Gift button (always visible)
                _InputIconButton(
                  icon: Icons.card_giftcard_rounded,
                  onPressed: widget.onSendGift,
                  color: _softAmber,
                  size: 22,
                ),

                const SizedBox(width: 2),

                // Send / Mic button (animated swap)
                AnimatedSwitcher(
                  duration: const Duration(milliseconds: 200),
                  transitionBuilder: (child, animation) =>
                      ScaleTransition(scale: animation, child: child),
                  child: _hasText
                      ? GestureDetector(
                          key: const ValueKey('send'),
                          onTap: _handleSend,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: const BoxDecoration(
                              gradient: LinearGradient(
                                colors: [_deepPlum, Color(0xFF7C3AED)],
                                begin: Alignment.topLeft,
                                end: Alignment.bottomRight,
                              ),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.send_rounded,
                              color: Colors.white,
                              size: 20,
                            ),
                          ),
                        )
                      : GestureDetector(
                          key: const ValueKey('mic'),
                          onTap: widget.onSendVoiceNote,
                          child: Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              color: _warmRose.withValues(alpha: 0.12),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.mic_rounded,
                              color: _warmRose,
                              size: 22,
                            ),
                          ),
                        ),
                ),
              ],
            ),
          ),
        ),

        // ── Emoji Picker ───────────────────────────────────────────────
        if (_showEmojiPicker)
          SizedBox(
            height: 260,
            child: emoji_picker_flutter.EmojiPicker(
              onEmojiSelected: _onEmojiSelected,
              onBackspacePressed: _onBackspacePressed,
              config: emoji_picker_flutter.Config(
                height: 260,
                checkPlatformCompatibility: true,
                emojiViewConfig: emoji_picker_flutter.EmojiViewConfig(
                  emojiSizeMax: 28 * (Platform.isIOS ? 1.2 : 1.0),
                  backgroundColor: isDark
                      ? const Color(0xFF1A1523)
                      : Colors.white,
                  columns: 8,
                ),
                categoryViewConfig: emoji_picker_flutter.CategoryViewConfig(
                  indicatorColor: _deepPlum,
                  iconColorSelected: _deepPlum,
                  iconColor: Colors.grey,
                  backgroundColor: isDark
                      ? const Color(0xFF1A1523)
                      : Colors.white,
                ),
                bottomActionBarConfig:
                    const emoji_picker_flutter.BottomActionBarConfig(
                      enabled: false,
                    ),
                searchViewConfig: emoji_picker_flutter.SearchViewConfig(
                  backgroundColor: isDark
                      ? const Color(0xFF1A1523)
                      : Colors.white,
                  buttonIconColor: _deepPlum,
                ),
              ),
            ),
          ),
      ],
    );
  }
}

// ─── Small Icon Button ──────────────────────────────────────────────────────

class _InputIconButton extends StatelessWidget {
  const _InputIconButton({
    required this.icon,
    required this.onPressed,
    required this.color,
    this.size = 24,
  });

  final IconData icon;
  final VoidCallback onPressed;
  final Color color;
  final double size;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 40,
      height: 40,
      child: IconButton(
        icon: Icon(icon, color: color, size: size),
        onPressed: onPressed,
        padding: EdgeInsets.zero,
        constraints: const BoxConstraints(),
        splashRadius: 20,
      ),
    );
  }
}

// ─── Attachment Option ──────────────────────────────────────────────────────

class _AttachmentOption extends StatelessWidget {
  const _AttachmentOption({
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
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 28),
              ),
              const SizedBox(height: 8),
              Text(
                label,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        )
        .animate()
        .fadeIn(duration: 200.ms)
        .scale(begin: const Offset(0.8, 0.8), end: const Offset(1, 1));
  }
}
