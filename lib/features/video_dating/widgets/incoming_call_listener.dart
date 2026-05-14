import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/services/call_notification_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

class IncomingCallListener extends ConsumerStatefulWidget {
  const IncomingCallListener({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<IncomingCallListener> createState() =>
      _IncomingCallListenerState();
}

class _IncomingCallListenerState extends ConsumerState<IncomingCallListener> {
  String? _activeNotificationId;
  bool _dialogOpen = false;

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProvider).valueOrNull;
    if (user != null) {
      ref.listen<AsyncValue<List<CallNotification>>>(
        incomingCallNotificationsProvider(user.id),
        (_, next) {
          _markExpiredCallsMissed(next.valueOrNull);
          final call = _firstFreshCall(next.valueOrNull);
          if (call == null) return;
          _queueIncomingCall(call);
        },
      );
    }

    return widget.child;
  }

  CallNotification? _firstFreshCall(List<CallNotification>? calls) {
    if (calls == null || calls.isEmpty) return null;
    final now = DateTime.now();
    for (final call in calls) {
      if (call.isRinging && call.isFresh(now)) return call;
    }
    return null;
  }

  void _markExpiredCallsMissed(List<CallNotification>? calls) {
    if (calls == null || calls.isEmpty) return;
    final now = DateTime.now();
    final service = ref.read(callNotificationServiceProvider);
    for (final call in calls) {
      if (call.isRinging && !call.isFresh(now)) {
        unawaited(service.markMissed(call.id));
      }
    }
  }

  void _queueIncomingCall(CallNotification call) {
    if (_dialogOpen || _activeNotificationId == call.id) return;
    _activeNotificationId = call.id;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      unawaited(_showIncomingCall(call));
    });
  }

  Future<void> _showIncomingCall(CallNotification call) async {
    if (_dialogOpen) return;
    _dialogOpen = true;

    final dialogContext = rootNavigatorKey.currentContext ?? context;
    final accepted = await showDialog<bool>(
      context: dialogContext,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _t('incoming_video_call'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        content: Text(
          _tf('incoming_video_call_body', {'name': call.callerName}),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('decline_call')),
          ),
          ElevatedButton.icon(
            onPressed: () => Navigator.of(ctx).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppTheme.deepPlum,
              foregroundColor: Colors.white,
            ),
            icon: const Icon(Icons.videocam_rounded),
            label: Text(_t('accept_call')),
          ),
        ],
      ),
    );

    if (!mounted) return;
    final service = ref.read(callNotificationServiceProvider);

    try {
      if (accepted == true) {
        final answered = await service.tryMarkAnswered(call.id);
        if (answered) {
          _openCall(call);
        } else if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(_t('call_no_longer_available'))),
          );
        }
      } else {
        await service.markDeclined(call.id);
      }
    } catch (error) {
      debugPrint('[IncomingCallListener] Failed to update call: $error');
    } finally {
      _dialogOpen = false;
      _activeNotificationId = null;
    }
  }

  void _openCall(CallNotification call) {
    final navContext = rootNavigatorKey.currentContext;
    if (navContext == null || !navContext.mounted) return;

    final uri = Uri(
      path: '/video/call/${call.roomId}',
      queryParameters: {
        'type': 'oneOnOne',
        'targetUserId': call.callerId,
        'targetUserName': call.callerName,
        'chatId': call.chatId,
        'callNotificationId': call.id,
      },
    );
    navContext.push(uri.toString());
  }
}
