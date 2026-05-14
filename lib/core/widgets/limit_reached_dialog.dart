import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/services/admob_service.dart';
import 'package:nightingale_heart/core/services/usage_limits_service.dart';

/// Shows a dialog when a user hits a refilled daily usage limit.
/// Offers rewarded ads to refill.
///
/// Returns `true` if the user successfully watched the required ads and was
/// refilled.
Future<bool> showLimitReachedDialog({
  required BuildContext context,
  required String userId,
  required String limitType, // 'likes' or 'messages'
  required int refillAmount,
  int adsRequired = 3,
}) async {
  final result = await showDialog<bool>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _LimitReachedDialog(
      userId: userId,
      limitType: limitType,
      refillAmount: refillAmount,
      adsRequired: adsRequired,
    ),
  );
  return result ?? false;
}

class _LimitReachedDialog extends StatefulWidget {
  const _LimitReachedDialog({
    required this.userId,
    required this.limitType,
    required this.refillAmount,
    required this.adsRequired,
  });

  final String userId;
  final String limitType;
  final int refillAmount;
  final int adsRequired;

  @override
  State<_LimitReachedDialog> createState() => _LimitReachedDialogState();
}

class _LimitReachedDialogState extends State<_LimitReachedDialog> {
  int _adsWatched = 0;
  bool _isWatchingAd = false;
  int get _adsRequired => widget.adsRequired;

  String get _title {
    switch (widget.limitType) {
      case 'likes':
        return 'Daily Likes Limit Reached';
      case 'messages':
        return 'Daily Messages Limit Reached';
      case 'rewinds':
        return 'Daily Rewinds Limit Reached';
      default:
        return 'Limit Reached';
    }
  }

  String get _description {
    switch (widget.limitType) {
      case 'likes':
        return 'You\'ve used all your daily likes. Watch $_adsRequired short ads to get ${widget.refillAmount} more likes!';
      case 'messages':
        return 'You\'ve used all your daily messages. Watch $_adsRequired short ads to get ${widget.refillAmount} more messages!';
      case 'rewinds':
        return 'You\'ve used all your daily rewinds. Watch $_adsRequired short ads to get ${widget.refillAmount} more rewinds!';
      default:
        return 'Watch $_adsRequired ads to continue.';
    }
  }

  IconData get _icon {
    switch (widget.limitType) {
      case 'likes':
        return Icons.favorite_rounded;
      case 'messages':
        return Icons.message_rounded;
      case 'rewinds':
        return Icons.undo_rounded;
      default:
        return Icons.lock_rounded;
    }
  }

  Future<void> _watchAd() async {
    if (_isWatchingAd) return;

    final adMob = AdMobService.instance;

    if (!adMob.isRewardedAdReady) {
      setState(() => _isWatchingAd = true);
      // Wait a moment for the ad to load
      await Future.delayed(const Duration(seconds: 2));
      adMob.loadRewardedAd();
      await Future.delayed(const Duration(seconds: 2));

      if (!adMob.isRewardedAdReady) {
        if (mounted) {
          setState(() => _isWatchingAd = false);
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                'Ad not ready yet. Please try again in a moment.',
                style: GoogleFonts.plusJakartaSans(),
              ),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
        return;
      }
    }

    setState(() => _isWatchingAd = true);

    final shown = await adMob.showRewardedAdWithCallback(
      onReward: (type, amount) {
        if (mounted) {
          setState(() {
            _adsWatched++;
          });
        }
      },
    );

    if (!shown && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Could not show ad. Please try again.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }

    if (mounted) {
      setState(() => _isWatchingAd = false);
    }

    // Check if all ads are watched
    if (_adsWatched >= _adsRequired) {
      await _refill();
    }
  }

  Future<void> _refill() async {
    final usageLimitsService = UsageLimitsService();

    if (widget.limitType == 'likes') {
      await usageLimitsService.refillLikes(widget.userId, widget.refillAmount);
    } else if (widget.limitType == 'messages') {
      await usageLimitsService.refillMessages(
        widget.userId,
        widget.refillAmount,
      );
    } else if (widget.limitType == 'rewinds') {
      await usageLimitsService.refillRewinds(
        widget.userId,
        widget.refillAmount,
      );
    }

    if (mounted) {
      Navigator.of(context).pop(true);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'You earned ${widget.refillAmount} more ${widget.limitType}!',
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: AppTheme.emerald,
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return AlertDialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      contentPadding: const EdgeInsets.fromLTRB(24, 20, 24, 0),
      actionsPadding: const EdgeInsets.fromLTRB(24, 8, 24, 20),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: AppTheme.warmRose.withValues(alpha: 0.12),
              shape: BoxShape.circle,
            ),
            child: Icon(_icon, color: AppTheme.warmRose, size: 32),
          ),
          const SizedBox(height: 16),
          Text(
            _title,
            textAlign: TextAlign.center,
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          Text(
            _description,
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 14,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
          const SizedBox(height: 20),
          // Progress dots
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(_adsRequired, (index) {
              final isCompleted = index < _adsWatched;
              return Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    color: isCompleted
                        ? AppTheme.emerald
                        : AppTheme.deepPlum.withValues(alpha: 0.12),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: isCompleted
                          ? AppTheme.emerald
                          : AppTheme.deepPlum.withValues(alpha: 0.3),
                      width: 2,
                    ),
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(
                            Icons.check_rounded,
                            color: Colors.white,
                            size: 20,
                          )
                        : Text(
                            '${index + 1}',
                            style: GoogleFonts.plusJakartaSans(
                              fontWeight: FontWeight.w700,
                              color: AppTheme.deepPlum,
                            ),
                          ),
                  ),
                ),
              );
            }),
          ),
          const SizedBox(height: 8),
          Text(
            '$_adsWatched / $_adsRequired ads watched',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
      actions: [
        Row(
          children: [
            Expanded(
              child: TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: Text(
                  'Cancel',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              flex: 2,
              child: ElevatedButton.icon(
                onPressed: _isWatchingAd ? null : _watchAd,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.deepPlum,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                ),
                icon: _isWatchingAd
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.play_circle_fill_rounded, size: 20),
                label: Text(
                  _isWatchingAd
                      ? 'Loading...'
                      : 'Watch Ad (${_adsRequired - _adsWatched} left)',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        SizedBox(
          width: double.infinity,
          child: TextButton(
            onPressed: () {
              Navigator.of(context).pop(false);
              context.push(RoutePaths.subscription);
            },
            child: Text(
              'Upgrade for Unlimited',
              style: GoogleFonts.plusJakartaSans(
                fontWeight: FontWeight.w600,
                color: AppTheme.softAmber,
              ),
            ),
          ),
        ),
      ],
    );
  }
}
