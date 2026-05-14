import 'package:cloud_functions/cloud_functions.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/runtime_config.dart';
import 'package:zego_uikit_prebuilt_call/zego_uikit_prebuilt_call.dart';

final videoCallServiceProvider = Provider<VideoCallService>((ref) {
  return VideoCallService();
});

class ZegoCallCredentials {
  const ZegoCallCredentials({
    required this.appID,
    required this.roomId,
    required this.userId,
    required this.expiresAt,
    this.appSign = '',
    this.token = '',
    this.sessionId,
  });

  final int appID;
  final String appSign;
  final String token;
  final String roomId;
  final String userId;
  final DateTime expiresAt;
  final String? sessionId;

  factory ZegoCallCredentials.fromLocalConfig({
    required int appID,
    required String appSign,
    required String roomId,
    required String userId,
  }) {
    return ZegoCallCredentials(
      appID: appID,
      appSign: appSign,
      roomId: roomId,
      userId: userId,
      expiresAt: DateTime.now().add(const Duration(hours: 12)),
    );
  }
}

class VideoCallService {
  VideoCallService({FirebaseFunctions? functions, FirebaseFirestore? firestore})
    : _functions = functions ?? FirebaseFunctions.instance,
      _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFunctions _functions;
  final FirebaseFirestore _firestore;

  int? _appID;
  String _appSign = '';
  bool _initialized = false;

  bool get isInitialized => _initialized;

  Future<void> initZego() async {
    final appId = RuntimeConfig.zegoAppId;
    if (appId == null) {
      debugPrint('[VideoCallService] ZEGO_APP_ID missing or invalid');
      return;
    }

    _appID = appId;
    _appSign = RuntimeConfig.zegoAppSign;
    _initialized = true;
    debugPrint('[VideoCallService] ZegoCloud appID loaded');
  }

  Future<ZegoCallCredentials> createCallCredentials({
    required String roomId,
    required String userId,
    String? targetUserId,
    String sessionType = 'oneOnOne',
    bool allowPublish = true,
    int ttlSeconds = 3600,
  }) async {
    await initZego();

    if (_appID == null || _appSign.isEmpty) {
      throw StateError(
        'Zego app ID and app sign are required for video calling.',
      );
    }

    final sessionId = await _createCallSession(
      roomId: roomId,
      userId: userId,
      targetUserId: targetUserId,
      sessionType: sessionType,
    );

    final credentials = ZegoCallCredentials.fromLocalConfig(
      appID: _appID!,
      appSign: _appSign,
      roomId: roomId,
      userId: userId,
    );
    return ZegoCallCredentials(
      appID: credentials.appID,
      appSign: credentials.appSign,
      token: credentials.token,
      roomId: credentials.roomId,
      userId: credentials.userId,
      expiresAt: credentials.expiresAt,
      sessionId: sessionId,
    );
  }

  Future<String> _createCallSession({
    required String roomId,
    required String userId,
    String? targetUserId,
    required String sessionType,
  }) async {
    final participants = <String>{
      userId,
      if (targetUserId != null && targetUserId.isNotEmpty) targetUserId,
    }.toList(growable: false);

    final doc = _firestore
        .collection(AppConstants.videoSessionsCollection)
        .doc();
    await doc.set({
      'roomId': roomId,
      'participants': participants,
      'callerId': userId,
      if (targetUserId != null && targetUserId.isNotEmpty)
        'receiverId': targetUserId,
      'type': sessionType,
      'status': 'active',
      'durationSeconds': 0,
      'minutesUsed': 0,
      'startedAt': FieldValue.serverTimestamp(),
      'createdAt': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
    return doc.id;
  }

  Future<void> completeCallSession({
    required String sessionId,
    required int durationSeconds,
  }) async {
    final callable = _functions.httpsCallable('completeZegoCallSession');
    await callable.call<void>({
      'sessionId': sessionId,
      'durationSeconds': durationSeconds,
    });
  }

  Widget startOneOnOneCall({
    required String callID,
    required String userID,
    required String userName,
    String token = '',
    String appSign = '',
    int? appID,
  }) {
    final resolvedAppId = appID ?? _appID;
    final resolvedAppSign = appSign.isNotEmpty ? appSign : _appSign;
    if (resolvedAppId == null || (resolvedAppSign.isEmpty && token.isEmpty)) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Video calling is not available.\nPlease check your configuration.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ZegoUIKitPrebuiltCall(
      appID: resolvedAppId,
      appSign: resolvedAppSign,
      token: token,
      userID: userID,
      userName: userName,
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..turnOnCameraWhenJoining = true
        ..turnOnMicrophoneWhenJoining = true
        ..useSpeakerWhenJoining = true
        ..duration = ZegoCallDurationConfig(isVisible: true)
        ..topMenuBar = ZegoCallTopMenuBarConfig(
          isVisible: true,
          buttons: [
            ZegoCallMenuBarButtonName.minimizingButton,
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
    );
  }

  Widget startSpeedDateCall({
    required String callID,
    required String userID,
    required String userName,
    String token = '',
    String appSign = '',
    required int durationMinutes,
    int? appID,
  }) {
    final resolvedAppId = appID ?? _appID;
    final resolvedAppSign = appSign.isNotEmpty ? appSign : _appSign;
    if (resolvedAppId == null || (resolvedAppSign.isEmpty && token.isEmpty)) {
      return const Scaffold(
        body: Center(
          child: Text(
            'Video calling is not available.\nPlease check your configuration.',
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ZegoUIKitPrebuiltCall(
      appID: resolvedAppId,
      appSign: resolvedAppSign,
      token: token,
      userID: userID,
      userName: userName,
      callID: callID,
      config: ZegoUIKitPrebuiltCallConfig.oneOnOneVideoCall()
        ..turnOnCameraWhenJoining = true
        ..turnOnMicrophoneWhenJoining = true
        ..useSpeakerWhenJoining = true
        ..duration = ZegoCallDurationConfig(isVisible: true)
        ..topMenuBar = ZegoCallTopMenuBarConfig(isVisible: true)
        ..bottomMenuBar = ZegoCallBottomMenuBarConfig(
          buttons: [
            ZegoCallMenuBarButtonName.toggleCameraButton,
            ZegoCallMenuBarButtonName.toggleMicrophoneButton,
            ZegoCallMenuBarButtonName.hangUpButton,
            ZegoCallMenuBarButtonName.switchCameraButton,
          ],
        ),
    );
  }
}
