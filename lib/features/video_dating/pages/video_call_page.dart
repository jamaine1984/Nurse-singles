import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:zego_uikit/zego_uikit.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/message_model.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/call_notification_service.dart';
import 'package:nightingale_heart/core/services/video_call_service.dart';
import 'package:nightingale_heart/features/messages/providers/message_providers.dart';
import 'package:nightingale_heart/features/video_dating/services/video_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

/// ZegoCloud-powered video call page with real-time video minutes tracking.
///
/// Receives a [roomId] from the route which serves as the ZegoCloud callID.
/// Uses the same ZegoCloud keys as velvet_connect_flutter.
class VideoCallPage extends ConsumerStatefulWidget {
  const VideoCallPage({
    super.key,
    required this.roomId,
    this.sessionType = 'speedDate',
    this.targetUserId,
    this.targetUserName,
    this.chatId,
    this.callNotificationId,
  });

  final String roomId;
  final String sessionType;
  final String? targetUserId;
  final String? targetUserName;
  final String? chatId;
  final String? callNotificationId;

  @override
  ConsumerState<VideoCallPage> createState() => _VideoCallPageState();
}

class _VideoCallPageState extends ConsumerState<VideoCallPage> {
  // ---- State -------------------------------------------------------------
  int _elapsedSeconds = 0;
  Timer? _timer;
  String? _sessionId;
  String? _currentUserId;
  String? _otherUserId;
  String? _otherUserName;
  String? _speedDateSessionId;

  // Video minutes tracking
  int _userVideoMinutes = 0;
  StreamSubscription<int>? _minutesSub;
  StreamSubscription<DocumentSnapshot<Map<String, dynamic>>>? _roomSub;
  StreamSubscription<CallNotification?>? _callNotificationSub;

  int? _zegoAppID;
  String _zegoAppSign = '';
  String _zegoToken = '';
  bool _zegoReady = false;
  bool _zegoLoading = true;
  String? _zegoError;
  bool _ending = false;
  bool _roomCleaned = false;
  bool _roomCleaning = false;
  bool _speedDateFollowUpShown = false;
  bool _postCallNavigated = false;

  late final VideoService _videoService;
  late final VideoCallService _videoCallService;

  bool get _isSpeedDate => widget.sessionType == 'speedDate';

  @override
  void initState() {
    super.initState();
    _videoService = ref.read(videoServiceProvider);
    _videoCallService = ref.read(videoCallServiceProvider);
    _initCall();
  }

  String _t(String key) {
    return AppLocalizations.translate(key, ref.read(localeProvider));
  }

  String _tf(String key, Map<String, Object?> values) {
    return AppLocalizations.format(key, ref.read(localeProvider), values);
  }

  Future<void> _initCall() async {
    final user = ref.read(currentUserProvider).valueOrNull;
    if (user == null) return;
    _currentUserId = user.id;

    try {
      if (_isSpeedDate) {
        final roomSnapshot = await _videoService.getSpeedDatingRoom(
          widget.roomId,
        );
        final roomData = roomSnapshot.data();
        if (roomData == null) {
          throw StateError(_t('this_room_in_call'));
        }

        final participants = VideoService.participantIdsFromRoomData(roomData);
        if (!participants.contains(user.id) || participants.length < 2) {
          if (_isSpeedDate) {
            await _cleanupRoomPresence();
          }
          if (!mounted) return;
          setState(() {
            _zegoReady = false;
            _zegoLoading = false;
            _zegoError = _t('waiting_for_second_person');
          });
          return;
        }

        _setOtherParticipant(roomData, user.id);
        _speedDateSessionId = roomData['activeSessionId'] as String?;
        _watchRoom(user.id);
      } else {
        final targetUserId = widget.targetUserId ?? '';
        if (targetUserId.isEmpty || targetUserId == user.id) {
          throw StateError(_t('video_calling_unavailable'));
        }
        _otherUserId = targetUserId;
        _otherUserName = widget.targetUserName;
        _watchCallNotification(user.id);
      }

      final credentials = await _videoCallService.createCallCredentials(
        roomId: widget.roomId,
        userId: user.id,
        targetUserId: _otherUserId,
        sessionType: widget.sessionType,
        allowPublish: true,
      );
      if (!mounted) return;
      setState(() {
        _zegoAppID = credentials.appID;
        _zegoAppSign = credentials.appSign;
        _zegoToken = credentials.token;
        _sessionId = credentials.sessionId;
        _zegoReady = true;
        _zegoLoading = false;
        _zegoError = null;
      });
    } catch (e) {
      debugPrint('[VideoCall] Failed to initialize ${widget.roomId}: $e');
      if (_isSpeedDate) {
        await _cleanupRoomPresence();
      }
      if (!mounted) return;
      setState(() {
        _zegoReady = false;
        _zegoLoading = false;
        _zegoError = _videoErrorMessage(e);
      });
      return;
    }

    // Listen to remaining video minutes.
    _minutesSub = _videoService.getUserVideoMinutes(user.id).listen((minutes) {
      if (!mounted) return;
      setState(() => _userVideoMinutes = minutes);
      // Auto-end when minutes run out.
      if (minutes <= 0) {
        unawaited(_endCall(autoEnd: true));
      }
    });

    _startTimer();
  }

  void _setOtherParticipant(Map<String, dynamic> roomData, String userId) {
    final user1Id = roomData['user1Id'] as String?;
    final user2Id = roomData['user2Id'] as String?;
    if (user1Id == userId) {
      _otherUserId = user2Id;
      _otherUserName = roomData['user2Name'] as String?;
    } else {
      _otherUserId = user1Id;
      _otherUserName = roomData['user1Name'] as String?;
    }
  }

  String _videoErrorMessage(Object error) {
    if (error is StateError) {
      final message = error.message.toString();
      if (message.isNotEmpty) return message;
    }
    if (error is FirebaseFunctionsException) {
      if (error.code == 'not-found' ||
          error.code == 'failed-precondition' ||
          error.code == 'permission-denied' ||
          error.code == 'unauthenticated' ||
          error.code == 'unavailable') {
        return _t('video_calling_unavailable');
      }
    }
    return _t('video_calling_unavailable');
  }

  void _watchRoom(String userId) {
    _roomSub?.cancel();
    _roomSub = _videoService.watchSpeedDatingRoom(widget.roomId).listen((
      snapshot,
    ) {
      if (_ending || !snapshot.exists) return;
      final data = snapshot.data();
      if (data == null) return;
      final status = data['status'] as String? ?? 'waiting';
      final participants = VideoService.participantIdsFromRoomData(data);
      final userStillPresent = participants.contains(userId);
      final bothPresent = participants.length >= 2;

      if (status != 'active' || !userStillPresent || !bothPresent) {
        unawaited(_endCall(remoteEnded: true));
      }
    });
  }

  void _watchCallNotification(String userId) {
    final notificationId = widget.callNotificationId;
    if (notificationId == null || notificationId.isEmpty) return;

    _callNotificationSub?.cancel();
    _callNotificationSub = ref
        .read(callNotificationServiceProvider)
        .watchCall(notificationId)
        .listen((call) {
          if (_ending || call == null || !mounted) return;
          final isCurrentUserInCall =
              call.callerId == userId || call.receiverId == userId;
          if (!isCurrentUserInCall) return;

          final receiverDeclinedOrMissed =
              call.callerId == userId &&
              (call.status == 'declined' || call.status == 'missed');
          final remoteEnded = call.status == 'ended';
          if (receiverDeclinedOrMissed || remoteEnded) {
            unawaited(_endCall(remoteEnded: true));
          }
        });
  }

  void _startTimer() {
    _timer?.cancel();
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      if (!mounted) return;
      setState(() => _elapsedSeconds++);

      if (_elapsedSeconds > 0 &&
          _elapsedSeconds % 60 == 0 &&
          _remainingVideoMinutes <= 0) {
        unawaited(_endCall(autoEnd: true));
      }
    });
  }

  int get _remainingVideoMinutes {
    final elapsedMinutes = _elapsedSeconds ~/ 60;
    return (_userVideoMinutes - elapsedMinutes).clamp(0, 999999);
  }

  Future<void> _endCall({
    bool autoEnd = false,
    bool remoteEnded = false,
    bool popWhenDone = true,
  }) async {
    if (_ending) return;
    _ending = true;

    _timer?.cancel();
    await _minutesSub?.cancel();
    await _roomSub?.cancel();
    await _callNotificationSub?.cancel();
    await _cleanupRoomPresence();
    if (!remoteEnded) {
      await _markCallNotificationEnded();
    }

    if (_sessionId != null) {
      try {
        await _videoCallService.completeCallSession(
          sessionId: _sessionId!,
          durationSeconds: _elapsedSeconds,
        );
      } catch (_) {}
    }

    if (!mounted) return;

    if (autoEnd) {
      await showDialog(
        context: context,
        barrierDismissible: false,
        builder: (ctx) => AlertDialog(
          title: Text(_t('video_minutes_exhausted')),
          content: Text(_t('video_minutes_exhausted_body')),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.of(ctx).pop();
                _postCallNavigated = true;
                context.push('/video/minutes');
              },
              child: Text(_t('get_minutes')),
            ),
            ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: Text(_t('ok')),
            ),
          ],
        ),
      );
    } else if (remoteEnded) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('other_person_left'))));
    } else {
      await _showFeedbackDialog();
    }

    await _showSpeedDateFollowUpDialog();

    if (!mounted) return;
    if (popWhenDone && !_postCallNavigated && context.canPop()) {
      context.pop();
    }
  }

  Future<void> _cleanupRoomPresence() async {
    if (!_isSpeedDate || _roomCleaned || _roomCleaning) return;
    final userId = _currentUserId;
    if (userId == null) return;
    _roomCleaning = true;
    try {
      for (var attempt = 1; attempt <= 3; attempt++) {
        try {
          await _videoService.endSpeedDatingRoom(
            roomId: widget.roomId,
            endedByUserId: userId,
          );
          _roomCleaned = true;
          return;
        } catch (error) {
          debugPrint(
            '[VideoCall] Failed to cleanup room ${widget.roomId} '
            '(attempt $attempt): $error',
          );
          if (attempt < 3) {
            await Future.delayed(Duration(milliseconds: 350 * attempt));
          }
        }
      }
    } finally {
      _roomCleaning = false;
    }
  }

  Future<void> _markCallNotificationEnded() async {
    final notificationId = widget.callNotificationId;
    if (notificationId == null || notificationId.isEmpty) return;
    try {
      await ref.read(callNotificationServiceProvider).markEnded(notificationId);
    } catch (error) {
      debugPrint('[VideoCall] Failed to mark call notification ended: $error');
    }
  }

  Future<void> _closeUnavailableCall() async {
    await _roomSub?.cancel();
    _roomSub = null;
    await _cleanupRoomPresence();
    if (!mounted) return;
    if (context.canPop()) {
      context.pop();
    }
  }

  Future<void> _showFeedbackDialog() async {
    double rating = 3;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              title: Text(
                _t('how_was_call'),
                style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    _tf('call_duration', {
                      'duration': _formatDuration(_elapsedSeconds),
                    }),
                    style: Theme.of(ctx).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: List.generate(5, (i) {
                      final starValue = i + 1;
                      return IconButton(
                        onPressed: () {
                          setDialogState(() => rating = starValue.toDouble());
                        },
                        icon: Icon(
                          starValue <= rating
                              ? Icons.star_rounded
                              : Icons.star_border_rounded,
                          color: AppTheme.softAmber,
                          size: 36,
                        ),
                      );
                    }),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _ratingLabel(rating),
                    style: Theme.of(ctx).textTheme.bodySmall,
                  ),
                ],
              ),
              actions: [
                ElevatedButton(
                  onPressed: () => Navigator.of(ctx).pop(),
                  child: Text(_t('done')),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _showSpeedDateFollowUpDialog() async {
    if (!_isSpeedDate || _speedDateFollowUpShown || !mounted) return;
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    final otherUserId = _otherUserId;
    final sessionId = _speedDateSessionId;
    if (currentUser == null ||
        otherUserId == null ||
        otherUserId.isEmpty ||
        sessionId == null ||
        sessionId.isEmpty) {
      return;
    }

    _speedDateFollowUpShown = true;
    final wantsToConnect = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: Text(
          _t('speed_date_followup_title'),
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(
          _t('speed_date_followup_body'),
          style: GoogleFonts.plusJakartaSans(height: 1.35),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: Text(_t('speed_date_no')),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: Text(_t('speed_date_yes')),
          ),
        ],
      ),
    );
    if (wantsToConnect == null || !mounted) return;

    try {
      final result = await _videoService.submitSpeedDateFollowUp(
        sessionId: sessionId,
        roomId: widget.roomId,
        otherUserId: otherUserId,
        wantsToConnect: wantsToConnect,
      );
      if (!mounted) return;
      await _showSpeedDateFollowUpResult(
        result,
        currentUser,
        sessionId: sessionId,
      );
    } catch (error) {
      debugPrint('[VideoCall] Speed-date follow-up failed: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(_t('speed_date_followup_failed'))));
    }
  }

  Future<void> _showSpeedDateFollowUpResult(
    SpeedDateFollowUpResult result,
    UserModel currentUser, {
    required String sessionId,
  }) async {
    if (result.status == 'pending') {
      await _showLiveSpeedDateFollowUpResult(sessionId, currentUser);
      return;
    }

    await _showResolvedSpeedDateFollowUpResult(result, currentUser);
  }

  Future<void> _showLiveSpeedDateFollowUpResult(
    String sessionId,
    UserModel currentUser,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StreamBuilder<SpeedDateFollowUpResult>(
        stream: _videoService.watchSpeedDateFollowUp(sessionId),
        initialData: const SpeedDateFollowUpResult(status: 'pending'),
        builder: (ctx, snapshot) {
          final latest =
              snapshot.data ?? const SpeedDateFollowUpResult(status: 'pending');
          return _buildSpeedDateResultDialog(ctx, latest, currentUser);
        },
      ),
    );
  }

  Future<void> _showResolvedSpeedDateFollowUpResult(
    SpeedDateFollowUpResult result,
    UserModel currentUser,
  ) async {
    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => _buildSpeedDateResultDialog(ctx, result, currentUser),
    );
  }

  Widget _buildSpeedDateResultDialog(
    BuildContext ctx,
    SpeedDateFollowUpResult result,
    UserModel currentUser,
  ) {
    if (result.status == 'connected' && result.chatId != null) {
      return AlertDialog(
        title: Text(_t('speed_date_connected_title')),
        content: Text(_t('speed_date_connected_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_t('later')),
          ),
          TextButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _postCallNavigated = true;
              context.push('/messages/${result.chatId}');
            },
            child: Text(_t('start_chat')),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.of(ctx).pop();
              await _sendSpeedDateShiftReport(
                chatId: result.chatId!,
                currentUser: currentUser,
              );
            },
            child: Text(_t('send_shift_report')),
          ),
        ],
      );
    }

    final connected = result.status == 'connected';
    final declined = result.status == 'declined';
    return AlertDialog(
      title: Text(
        declined
            ? _t('speed_date_declined_title')
            : connected
            ? _t('speed_date_connected_title')
            : _t('speed_date_pending_title'),
      ),
      content: Text(
        declined
            ? _t('speed_date_declined_body')
            : _t('speed_date_pending_body'),
      ),
      actions: [
        ElevatedButton(
          onPressed: () => Navigator.of(ctx).pop(),
          child: Text(_t('ok')),
        ),
      ],
    );
  }

  Future<void> _sendSpeedDateShiftReport({
    required String chatId,
    required UserModel currentUser,
  }) async {
    final message = MessageModel(
      id: '',
      chatId: chatId,
      senderId: currentUser.id,
      senderName: currentUser.name,
      senderPhotoUrl: currentUser.photoUrl,
      content:
          'Shift Report: Great speed date. Want to compare schedules and keep talking?',
      type: MessageType.text,
      isRead: false,
      createdAt: DateTime.now(),
    );
    try {
      await ref.read(messageServiceProvider).sendMessage(chatId, message);
      if (mounted) {
        _postCallNavigated = true;
        context.push('/messages/$chatId');
      }
    } catch (error) {
      debugPrint('[VideoCall] Failed to send speed-date shift report: $error');
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(_t('could_not_send_shift_report'))),
      );
    }
  }

  String _ratingLabel(double rating) {
    if (rating <= 1) return _t('terrible');
    if (rating <= 2) return _t('not_great');
    if (rating <= 3) return _t('okay');
    if (rating <= 4) return _t('great');
    return _t('amazing');
  }

  String _formatDuration(int totalSeconds) {
    final h = totalSeconds ~/ 3600;
    final m = (totalSeconds % 3600) ~/ 60;
    final s = totalSeconds % 60;
    if (h > 0) {
      return '${h.toString().padLeft(2, '0')}:'
          '${m.toString().padLeft(2, '0')}:'
          '${s.toString().padLeft(2, '0')}';
    }
    return '${m.toString().padLeft(2, '0')}:${s.toString().padLeft(2, '0')}';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _minutesSub?.cancel();
    _roomSub?.cancel();
    _callNotificationSub?.cancel();
    if (!_ending && !_roomCleaned) {
      unawaited(_cleanupRoomPresence());
    }
    if (!_ending) {
      unawaited(_markCallNotificationEnded());
    }
    super.dispose();
  }

  // ---- Build -------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(child: Text(_t('please_sign_in_video'))),
          );
        }

        if (_zegoLoading) {
          return const Scaffold(
            backgroundColor: Color(0xFF0A0A0F),
            body: Center(
              child: CircularProgressIndicator(color: AppTheme.deepPlum),
            ),
          );
        }

        if (!_zegoReady ||
            _zegoAppID == null ||
            (_zegoAppSign.isEmpty && _zegoToken.isEmpty)) {
          return Scaffold(
            backgroundColor: const Color(0xFF0A0A0F),
            body: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.videocam_off_rounded,
                    size: 64,
                    color: Colors.white38,
                  ),
                  const SizedBox(height: 16),
                  Text(
                    _zegoError ?? _t('video_calling_unavailable'),
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      color: Colors.white70,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: _closeUnavailableCall,
                    child: Text(_t('go_back')),
                  ),
                ],
              ),
            ),
          );
        }

        return PopScope(
          canPop: false,
          onPopInvokedWithResult: (didPop, result) {
            if (!didPop) unawaited(_endCall());
          },
          child: Scaffold(
            body: SafeArea(
              child: Stack(
                children: [
                  // ── ZegoCloud Prebuilt Video Call UI ──
                  ZegoUIKitPrebuiltCall(
                    appID: _zegoAppID!,
                    appSign: _zegoAppSign,
                    token: _zegoToken,
                    userID: user.id,
                    userName: user.name,
                    callID: widget.roomId,
                    config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
                      ..turnOnCameraWhenJoining = true
                      ..turnOnMicrophoneWhenJoining = true
                      ..useSpeakerWhenJoining = true
                      ..duration = ZegoCallDurationConfig(isVisible: true)
                      ..audioVideoView = ZegoCallAudioVideoViewConfig(
                        showMicrophoneStateOnView: true,
                        showCameraStateOnView: true,
                        showUserNameOnView: true,
                        showSoundWavesInAudioMode: true,
                        useVideoViewAspectFill: true,
                      )
                      ..user = ZegoCallUserConfig(
                        requiredUsers: ZegoCallRequiredUserConfig(
                          enabled: _otherUserId != null,
                          detectSeconds: _isSpeedDate ? 20 : 90,
                          detectInDebugMode: true,
                          users: _otherUserId == null
                              ? const []
                              : [
                                  ZegoUIKitUser(
                                    id: _otherUserId!,
                                    name: _otherUserName?.isNotEmpty == true
                                        ? _otherUserName!
                                        : 'Nurse',
                                  ),
                                ],
                        ),
                      )
                      ..translationText = ZegoUIKitPrebuiltCallInnerText(
                        audioEffectTitle: _t('audio_effects'),
                        audioEffectReverbTitle: _t('reverb'),
                        audioEffectVoiceChangingTitle: _t('voice_changing'),
                        voiceChangerNoneTitle: _t('none'),
                        reverbTypeNoneTitle: _t('none'),
                        stopScreenSharingButtonText: _t('stop_sharing'),
                        screenBlockedTitle: _t('call_in_progress'),
                        screenBlockedSubtitle: _t('restore_operation'),
                      )
                      ..audioEffect = ZegoCallAudioEffectConfig.none()
                      ..pip = ZegoCallPIPConfig(
                        enableWhenBackground: false,
                        iOS: ZegoCallPIPIOSConfig(support: false),
                      )
                      ..topMenuBar = ZegoCallTopMenuBarConfig(
                        isVisible: true,
                        buttons: [
                          ZegoCallMenuBarButtonName.showMemberListButton,
                        ],
                      )
                      ..bottomMenuBar = ZegoCallBottomMenuBarConfig(
                        buttons: [
                          ZegoCallMenuBarButtonName.toggleCameraButton,
                          ZegoCallMenuBarButtonName.toggleMicrophoneButton,
                          ZegoCallMenuBarButtonName.hangUpButton,
                          ZegoCallMenuBarButtonName.switchCameraButton,
                        ],
                      ),
                    events: ZegoUIKitPrebuiltCallEvents(
                      onHangUpConfirmation: (event, defaultAction) async {
                        await _endCall(popWhenDone: false);
                        return defaultAction.call();
                      },
                      onCallEnd: (event, defaultAction) {
                        unawaited(
                          _endCall(
                            popWhenDone: false,
                          ).whenComplete(defaultAction.call),
                        );
                      },
                    ),
                  ),

                  // ── Remaining minutes overlay (top-right) ──
                  Positioned(
                    top: 16,
                    right: 16,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 8,
                      ),
                      decoration: BoxDecoration(
                        color: _remainingVideoMinutes <= 2
                            ? AppTheme.warmRose.withValues(alpha: 0.8)
                            : Colors.black54,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.schedule_rounded,
                            color: Colors.white,
                            size: 14,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            _tf('minutes_left', {
                              'minutes': _remainingVideoMinutes,
                            }),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
      loading: () => const Scaffold(
        backgroundColor: Color(0xFF0A0A0F),
        body: Center(
          child: CircularProgressIndicator(color: AppTheme.deepPlum),
        ),
      ),
      error: (e, _) => Scaffold(body: Center(child: Text('Error: $e'))),
    );
  }
}
