import 'dart:async';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/widgets/desktop_app_header.dart';
import 'package:nightingale_heart/features/video_dating/services/video_service.dart';
import 'package:nightingale_heart/l10n/app_localizations.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------

const int _totalRooms = 30;

const Color _greenDuration = Color(0xFF059669);
const Color _amberDuration = Color(0xFFF59E0B);
const Color _roseDuration = Color(0xFFDC2626);

const List<_HospitalRoomTheme> _hospitalRoomThemes = [
  _HospitalRoomTheme(
    'speed_room_er_coffee_bay',
    'ER Coffee Bay',
    'Fast hello for busy shifts',
  ),
  _HospitalRoomTheme(
    'speed_room_icu_quiet_room',
    'ICU Quiet Room',
    'Calm intros for critical care',
  ),
  _HospitalRoomTheme(
    'speed_room_night_shift_lounge',
    'Night Shift Lounge',
    'Meet after midnight rounds',
  ),
  _HospitalRoomTheme(
    'speed_room_travel_nurse_terminal',
    'Travel Nurse Terminal',
    'Assignment-friendly chat',
  ),
  _HospitalRoomTheme(
    'speed_room_pediatrics_playroom',
    'Pediatrics Playroom',
    'Warm, light conversation',
  ),
  _HospitalRoomTheme(
    'speed_room_or_scrub_in',
    'OR Scrub In',
    'Focused five-minute intro',
  ),
  _HospitalRoomTheme(
    'speed_room_telemetry_station',
    'Telemetry Station',
    'Heart-check compatibility',
  ),
  _HospitalRoomTheme(
    'speed_room_student_clinicals',
    'Student Clinicals',
    'Nursing school connections',
  ),
  _HospitalRoomTheme(
    'speed_room_charge_nurse_desk',
    'Charge Nurse Desk',
    'Leadership-minded matches',
  ),
  _HospitalRoomTheme(
    'speed_room_wellness_break',
    'Wellness Break',
    'Low-pressure reset chat',
  ),
  _HospitalRoomTheme(
    'speed_room_clinic_huddle',
    'Clinic Huddle',
    'Outpatient-friendly meet',
  ),
  _HospitalRoomTheme(
    'speed_room_labor_delivery',
    'Labor + Delivery',
    'Kind, steady introductions',
  ),
  _HospitalRoomTheme(
    'speed_room_respiratory_rounds',
    'Respiratory Rounds',
    'Allied health welcome',
  ),
  _HospitalRoomTheme(
    'speed_room_pharmacy_window',
    'Pharmacy Window',
    'Quick professional spark',
  ),
  _HospitalRoomTheme(
    'speed_room_radiology_hall',
    'Radiology Hall',
    'Clear-picture chemistry',
  ),
  _HospitalRoomTheme(
    'speed_room_code_heart_room',
    'Code Heart Room',
    'Match-confirmed energy',
  ),
  _HospitalRoomTheme(
    'speed_room_weekend_warriors',
    'Weekend Warriors',
    'Days-off dating window',
  ),
  _HospitalRoomTheme(
    'speed_room_float_pool',
    'Float Pool',
    'Flexible schedules welcome',
  ),
  _HospitalRoomTheme(
    'speed_room_agency_mixer',
    'Agency Mixer',
    'Staffing partner friendly',
  ),
  _HospitalRoomTheme(
    'speed_room_nursing_alumni',
    'Nursing Alumni',
    'College and alumni circle',
  ),
  _HospitalRoomTheme(
    'speed_room_cardiac_stepdown',
    'Cardiac Stepdown',
    'Steady pace intro',
  ),
  _HospitalRoomTheme(
    'speed_room_mental_health_reset',
    'Mental Health Reset',
    'Respectful, grounded chat',
  ),
  _HospitalRoomTheme(
    'speed_room_med_surg_station',
    'Med-Surg Station',
    'Classic care-team meet',
  ),
  _HospitalRoomTheme(
    'speed_room_home_health_route',
    'Home Health Route',
    'On-the-go connection',
  ),
  _HospitalRoomTheme(
    'speed_room_dialysis_chairside',
    'Dialysis Chairside',
    'Patient rhythm, real talk',
  ),
  _HospitalRoomTheme(
    'speed_room_case_manager_cafe',
    'Case Manager Cafe',
    'Planning-friendly intro',
  ),
  _HospitalRoomTheme(
    'speed_room_trauma_bay',
    'Trauma Bay',
    'High-energy quick match',
  ),
  _HospitalRoomTheme(
    'speed_room_informatics_lab',
    'Informatics Lab',
    'Tech and care overlap',
  ),
  _HospitalRoomTheme(
    'speed_room_wellness_partner_room',
    'Wellness Partner Room',
    'Sponsored appreciation space',
  ),
  _HospitalRoomTheme(
    'speed_room_scholarship_circle',
    'Scholarship Circle',
    'Future nurse friendly',
  ),
];

/// Maps room index (0-based) to a duration in minutes.
/// Rooms 1-10 = 5 min, 11-20 = 10 min, 21-30 = 30 min.
int _durationForIndex(int index) {
  if (index < 10) return 5;
  if (index < 20) return 10;
  return 30;
}

Color _colorForDuration(int duration) {
  switch (duration) {
    case 5:
      return _greenDuration;
    case 10:
      return _amberDuration;
    case 30:
      return _roseDuration;
    default:
      return _amberDuration;
  }
}

_HospitalRoomTheme _themeForRoomNumber(int roomNumber) {
  final index = (roomNumber - 1)
      .clamp(0, _hospitalRoomThemes.length - 1)
      .toInt();
  return _hospitalRoomThemes[index];
}

class _HospitalRoomTheme {
  const _HospitalRoomTheme(this.keyPrefix, this.name, this.description);

  final String keyPrefix;
  final String name;
  final String description;

  String localizedName(BuildContext context) =>
      _tr(context, '${keyPrefix}_name');
}

bool _isDefaultRoomName(String value) {
  final trimmed = value.trim();
  if (trimmed.isEmpty || RegExp(r'^Room \d+$').hasMatch(trimmed)) {
    return true;
  }
  return _hospitalRoomThemes.any((theme) => theme.name == trimmed);
}

String _tr(BuildContext context, String key) {
  return AppLocalizations.translate(key, Localizations.localeOf(context));
}

String _trf(BuildContext context, String key, Map<String, Object?> values) {
  return AppLocalizations.format(key, Localizations.localeOf(context), values);
}

String _labelForDuration(BuildContext context, int duration) =>
    '$duration ${_tr(context, 'min')}';

// ---------------------------------------------------------------------------
// Page
// ---------------------------------------------------------------------------

/// The speed-dating video lobby displaying 30 pre-made 1v1 rooms in a
/// scrollable two-column grid. Rooms are streamed in real-time from
/// Firestore and created automatically on first load if they do not exist.
class VideoLobbyPage extends ConsumerStatefulWidget {
  const VideoLobbyPage({super.key});

  @override
  ConsumerState<VideoLobbyPage> createState() => _VideoLobbyPageState();
}

class _VideoLobbyPageState extends ConsumerState<VideoLobbyPage>
    with TickerProviderStateMixin {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// The room id the current user has joined (at most one at a time).
  String? _joinedRoomId;

  /// Countdown state when both users are present.
  int _countdown = 0;
  Timer? _countdownTimer;
  bool _isCountdownActive = false;

  /// Whether we have already ensured the 30 rooms exist.
  bool _roomsSeeded = false;
  bool _isSeeding = false;

  // Animation controller for the countdown overlay pulse.
  late final AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 800),
    );
  }

  @override
  void dispose() {
    _countdownTimer?.cancel();
    _pulseController.dispose();
    // If the user is still in a room when leaving, remove them.
    unawaited(_leaveCurrentRoom());
    super.dispose();
  }

  // ---- Firestore helpers --------------------------------------------------

  CollectionReference<Map<String, dynamic>> get _roomsRef =>
      _firestore.collection(AppConstants.speedDatingRoomsCollection);

  /// Ensures 30 rooms exist in Firestore. Idempotent -- checks existing count
  /// first and only creates missing rooms.
  Future<void> _ensureRoomsExist() async {
    if (_roomsSeeded || _isSeeding) return;
    _isSeeding = true;

    try {
      final snapshot = await _roomsRef.get();
      final existingNumbers = <int>{};
      for (final doc in snapshot.docs) {
        final roomNum = (doc.data()['roomNumber'] as int?) ?? 0;
        if (roomNum > 0) existingNumbers.add(roomNum);
      }

      final batch = _firestore.batch();
      int created = 0;

      for (int i = 1; i <= _totalRooms; i++) {
        if (existingNumbers.contains(i)) continue;
        final docRef = _roomsRef.doc('room_$i');
        final roomTheme = _themeForRoomNumber(i);
        batch.set(docRef, {
          'roomNumber': i,
          'name': roomTheme.name,
          'description': roomTheme.description,
          'duration': _durationForIndex(i - 1),
          'maxParticipants': 2,
          'currentParticipants': <String>[],
          'status': 'waiting',
          'hostId': null,
          'hostName': null,
          'user1Id': null,
          'user1Name': null,
          'user1PhotoUrl': null,
          'user1Age': null,
          'user2Id': null,
          'user2Name': null,
          'user2PhotoUrl': null,
          'user2Age': null,
          'createdAt': FieldValue.serverTimestamp(),
          'startedAt': null,
        });
        created++;
      }

      if (created > 0) {
        await batch.commit();
      }

      _roomsSeeded = true;
    } catch (e) {
      debugPrint('[VideoLobby] Error seeding rooms: $e');
    } finally {
      _isSeeding = false;
    }
  }

  /// Joins a room by writing the current user's info to the appropriate slot.
  Future<void> _joinRoom(String roomId, String userId) async {
    // Leave any previously joined room first.
    await _leaveCurrentRoom();

    try {
      await ref.read(videoServiceProvider).joinRoom(roomId, userId);
      if (mounted) {
        setState(() {
          _joinedRoomId = roomId;
        });
      }
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(_friendlyRoomJoinError(context, e)),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _friendlyRoomJoinError(BuildContext context, Object error) {
    if (error is FirebaseFunctionsException) {
      if (error.code == 'unauthenticated') {
        return _tr(context, 'room_join_auth_failed');
      }
      if (error.code == 'resource-exhausted') {
        return _tr(context, 'this_room_full');
      }
      if (error.code == 'failed-precondition') {
        return _tr(context, 'this_room_in_call');
      }
      if (error.code == 'permission-denied' || error.code == 'unavailable') {
        return _tr(context, 'video_calling_unavailable');
      }
    }
    return _tr(context, 'failed_join_room_generic');
  }

  /// Removes the current user from whichever room they are in.
  /// If [specificRoomId] is provided, leaves that room directly (even if
  /// [_joinedRoomId] was lost on page rebuild).
  Future<void> _leaveCurrentRoom({String? specificRoomId}) async {
    final roomId = specificRoomId ?? _joinedRoomId;
    if (roomId == null) return;
    _joinedRoomId = null;

    _cancelCountdown();

    final userAsync = ref.read(currentUserProvider);
    final user = userAsync.valueOrNull;
    if (user == null) return;

    try {
      await ref.read(videoServiceProvider).leaveRoom(roomId, user.id);
    } catch (e) {
      debugPrint('[VideoLobby] Error leaving room $roomId: $e');
    }
  }

  Map<String, dynamic> _displayDataForRoom(Map<String, dynamic> data) {
    if (!_shouldDisplayAsEmptyRoom(data)) {
      return data;
    }

    return {
      ...data,
      '_clearStaleSlots': true,
      'status': 'waiting',
      'startedAt': null,
      'currentParticipants': <String>[],
      'user1Id': null,
      'user1Name': null,
      'user1PhotoUrl': null,
      'user1Age': null,
      'user2Id': null,
      'user2Name': null,
      'user2PhotoUrl': null,
      'user2Age': null,
    };
  }

  bool _shouldDisplayAsEmptyRoom(Map<String, dynamic> data) {
    final status = data['status'] as String? ?? 'waiting';
    final slotParticipants = _slotParticipantIds(data);
    if (slotParticipants.isEmpty) return false;

    final currentParticipants = _currentParticipantIds(data);
    if (currentParticipants.isEmpty) return true;

    if (status == 'active') {
      return _isExpiredActiveRoom(data);
    }

    return status == 'waiting' && _isStaleWaitingRoom(data);
  }

  List<String> _currentParticipantIds(Map<String, dynamic> data) {
    final ids = <String>[];
    final currentParticipants = data['currentParticipants'];
    if (currentParticipants is List) {
      for (final value in currentParticipants) {
        final id = value?.toString() ?? '';
        if (id.isNotEmpty) ids.add(id);
      }
    }
    return ids;
  }

  List<String> _slotParticipantIds(Map<String, dynamic> data) {
    final ids = <String>[];
    for (final key in ['user1Id', 'user2Id']) {
      final value = data[key];
      if (value is String && value.isNotEmpty) ids.add(value);
    }
    return ids;
  }

  bool _isExpiredActiveRoom(Map<String, dynamic> data) {
    final startedAt = data['startedAt'];
    final duration = (data['duration'] as num?)?.toInt() ?? 5;
    return startedAt is Timestamp &&
        DateTime.now().difference(startedAt.toDate()) >
            Duration(minutes: duration + 1);
  }

  bool _isStaleWaitingRoom(Map<String, dynamic> data) {
    final timestamp =
        data['lastJoinedAt'] ?? data['updatedAt'] ?? data['createdAt'];
    return timestamp is Timestamp &&
        DateTime.now().difference(timestamp.toDate()) >
            const Duration(minutes: 5);
  }

  /// Called when both users are present -- starts a 5-second countdown then
  /// navigates to the video call.
  void _startCountdown(String roomId) {
    if (_isCountdownActive) return;
    setState(() {
      _isCountdownActive = true;
      _countdown = 5;
    });
    _pulseController.repeat(reverse: true);

    _countdownTimer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (!mounted) {
        timer.cancel();
        return;
      }
      setState(() {
        _countdown--;
      });
      if (_countdown <= 0) {
        timer.cancel();
        _pulseController.stop();
        _navigateToVideoCall(roomId);
      }
    });
  }

  void _cancelCountdown() {
    _countdownTimer?.cancel();
    _countdownTimer = null;
    _pulseController.stop();
    _pulseController.reset();
    if (mounted) {
      setState(() {
        _isCountdownActive = false;
        _countdown = 0;
      });
    }
  }

  void _navigateToVideoCall(String roomId) async {
    // Mark room as active.
    var activated = false;
    try {
      final user = ref.read(currentUserProvider).valueOrNull;
      if (user == null) return;
      final minutes = await ref
          .read(videoServiceProvider)
          .getUserVideoMinutesOnce(user.id);
      if (minutes <= 0) {
        await _leaveCurrentRoom(specificRoomId: roomId);
        if (!mounted) return;
        await _showOutOfMinutesDialog();
        return;
      }

      final doc = await _roomsRef.doc(roomId).get();
      final data = doc.data();
      final participants = data == null
          ? <String>[]
          : VideoService.participantIdsFromRoomData(data);
      if (participants.length < 2) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(_tr(context, 'waiting_for_second_person'))),
        );
        return;
      }

      await ref.read(videoServiceProvider).activateSpeedDatingRoom(roomId);
      activated = true;
    } catch (error) {
      debugPrint('[VideoLobby] Failed to activate room $roomId: $error');
    }

    if (!mounted || !activated) return;
    _cancelCountdown();
    // Clear joined room so dispose doesn't remove user.
    _joinedRoomId = null;
    context.push('/video/call/$roomId');
  }

  /// Handles a room card tap.
  Future<void> _onRoomTap(
    Map<String, dynamic> roomData,
    String roomId,
    String userId,
  ) async {
    final user1Id = roomData['user1Id'] as String?;
    final user2Id = roomData['user2Id'] as String?;
    final status = roomData['status'] as String? ?? 'waiting';

    final isUser1 = user1Id == userId;
    final isUser2 = user2Id == userId;
    final isInRoom = isUser1 || isUser2;
    final hasUser1 = user1Id != null && user1Id.isNotEmpty;
    final hasUser2 = user2Id != null && user2Id.isNotEmpty;
    final bothPresent = hasUser1 && hasUser2;

    if (status == 'active' || status == 'completed') {
      if (isInRoom) {
        _showLeaveConfirmation(roomId);
        return;
      }

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(context, 'this_room_in_call'),
            style: GoogleFonts.plusJakartaSans(),
          ),
        ),
      );
      return;
    }

    if (isInRoom) {
      // User is in this room - show leave confirmation
      _showLeaveConfirmation(roomId);
      return;
    }

    if (bothPresent) {
      // Room is full with other users.
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _tr(context, 'this_room_full'),
            style: GoogleFonts.plusJakartaSans(),
          ),
          backgroundColor: _roseDuration,
        ),
      );
      return;
    }

    final minutes = await ref
        .read(videoServiceProvider)
        .getUserVideoMinutesOnce(userId);
    if (minutes <= 0) {
      if (!mounted) return;
      await _showOutOfMinutesDialog();
      return;
    }

    await _joinRoom(roomId, userId);
  }

  Future<void> _showOutOfMinutesDialog() async {
    await showDialog<void>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(_tr(context, 'video_minutes_exhausted')),
        content: Text(_tr(context, 'video_minutes_exhausted_body')),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(_tr(context, 'ok')),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              context.push('/video/minutes');
            },
            child: Text(_tr(context, 'get_minutes')),
          ),
        ],
      ),
    );
  }

  void _showLeaveConfirmation(String roomId) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: const Color(0xFF1A1523),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: Text(
          _tr(context, 'leave_room'),
          style: GoogleFonts.playfairDisplay(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        content: Text(
          _tr(context, 'leave_room_confirm'),
          style: GoogleFonts.plusJakartaSans(color: Colors.white70),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: Text(
              _tr(context, 'stay'),
              style: GoogleFonts.plusJakartaSans(color: Colors.white54),
            ),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              _leaveCurrentRoom(specificRoomId: roomId);
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: _roseDuration,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: Text(
              _tr(context, 'leave'),
              style: GoogleFonts.plusJakartaSans(fontWeight: FontWeight.w700),
            ),
          ),
        ],
      ),
    );
  }

  // ---- Build --------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final userAsync = ref.watch(currentUserProvider);

    return userAsync.when(
      loading: () =>
          const Scaffold(body: Center(child: CircularProgressIndicator())),
      error: (e, _) => Scaffold(
        body: Center(
          child: Text(_trf(context, 'error_loading_user', {'error': e})),
        ),
      ),
      data: (user) {
        if (user == null) {
          return Scaffold(
            body: Center(child: Text(_tr(context, 'please_sign_in_continue'))),
          );
        }

        // Ensure rooms are seeded.
        if (!_roomsSeeded && !_isSeeding) {
          _ensureRoomsExist();
        }

        final isDesktopWeb = kIsWeb && MediaQuery.sizeOf(context).width >= 1000;

        return Scaffold(
          extendBodyBehindAppBar: !isDesktopWeb,
          appBar: isDesktopWeb
              ? DesktopAppHeader(
                  activeRoute: RoutePaths.video,
                  onMenuPressed: () => showDesktopAppMenu(context),
                  extraActions: [
                    IconButton(
                      tooltip: _tr(context, 'video_minutes'),
                      icon: const Icon(
                        Icons.timer_outlined,
                        color: Colors.white,
                      ),
                      onPressed: () => context.push(RoutePaths.videoMinutes),
                    ),
                  ],
                )
              : _buildAppBar(),
          body: _AnimatedBackground(
            child: SafeArea(
              child: Stack(
                children: [
                  StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
                    stream: _roomsRef.orderBy('roomNumber').snapshots(),
                    builder: (context, snapshot) {
                      if (snapshot.connectionState == ConnectionState.waiting &&
                          !snapshot.hasData) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (snapshot.hasError) {
                        return Center(
                          child: Text(
                            _trf(context, 'error_loading_rooms', {
                              'error': snapshot.error,
                            }),
                            style: GoogleFonts.plusJakartaSans(
                              color: Colors.white70,
                            ),
                          ),
                        );
                      }

                      final docs = snapshot.data?.docs ?? [];
                      if (docs.isEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const CircularProgressIndicator(),
                              const SizedBox(height: 16),
                              Text(
                                _tr(context, 'setting_up_rooms'),
                                style: GoogleFonts.plusJakartaSans(
                                  color: Colors.white70,
                                  fontSize: 14,
                                ),
                              ),
                            ],
                          ),
                        );
                      }

                      // Compute stats.
                      int occupied = 0;
                      int active = 0;
                      final rooms = <_RoomViewData>[];
                      for (final doc in docs) {
                        final d = _displayDataForRoom(doc.data());
                        rooms.add(_RoomViewData(id: doc.id, data: d));
                        final u1 = d['user1Id'] as String?;
                        final u2 = d['user2Id'] as String?;
                        final hasU1 = u1 != null && u1.isNotEmpty;
                        final hasU2 = u2 != null && u2.isNotEmpty;
                        if (hasU1 || hasU2) occupied++;
                        if (d['status'] == 'active') active++;
                      }

                      // Check if user is in a room with both users present to
                      // trigger countdown reactively.
                      _repairBrokenRooms(docs, user.id);
                      _checkForCountdownTrigger(rooms, user.id);

                      return Column(
                        children: [
                          // Progress tracker bar.
                          _ProgressBar(
                                total: docs.length,
                                occupied: occupied,
                                active: active,
                              )
                              .animate()
                              .fadeIn(duration: 400.ms)
                              .slideY(begin: -0.2, end: 0, duration: 400.ms),

                          // Room grid.
                          Expanded(
                            child: GridView.builder(
                              padding: const EdgeInsets.fromLTRB(
                                12,
                                8,
                                12,
                                100,
                              ),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                    crossAxisCount: 2,
                                    childAspectRatio: 0.68,
                                    mainAxisSpacing: 10,
                                    crossAxisSpacing: 10,
                                  ),
                              itemCount: docs.length,
                              itemBuilder: (context, index) {
                                final room = rooms[index];
                                final data = room.data;
                                return _RoomCard(
                                  roomId: room.id,
                                  data: data,
                                  currentUserId: user.id,
                                  index: index,
                                  onTap: () =>
                                      _onRoomTap(data, room.id, user.id),
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                  if (_isCountdownActive)
                    _CountdownOverlay(
                      countdown: _countdown,
                      pulse: _pulseController,
                    ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  /// Reactively checks if the current user is in a room where both slots are
  /// filled. If so, starts the countdown. If the other user leaves, cancels.
  void _checkForCountdownTrigger(List<_RoomViewData> rooms, String userId) {
    // Run post-frame to avoid setState during build.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      String? roomWithBothUsers;

      for (final room in rooms) {
        final d = room.data;
        final u1 = d['user1Id'] as String?;
        final u2 = d['user2Id'] as String?;
        final hasU1 = u1 != null && u1.isNotEmpty;
        final hasU2 = u2 != null && u2.isNotEmpty;
        final isUserInRoom = u1 == userId || u2 == userId;
        final status = d['status'] as String? ?? 'waiting';

        if (isUserInRoom && hasU1 && hasU2 && status == 'waiting') {
          roomWithBothUsers = room.id;
          break;
        }
      }

      if (roomWithBothUsers != null && !_isCountdownActive) {
        _joinedRoomId = roomWithBothUsers;
        _startCountdown(roomWithBothUsers);
      } else if (roomWithBothUsers == null && _isCountdownActive) {
        _cancelCountdown();
      }
    });
  }

  void _repairBrokenRooms(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs,
    String userId,
  ) {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      for (final doc in docs) {
        final data = doc.data();
        final participants = VideoService.participantIdsFromRoomData(data);
        final currentUserInRoom = participants.contains(userId);
        if (!currentUserInRoom) continue;

        final shouldClear =
            _shouldDisplayAsEmptyRoom(data) ||
            (data['status'] == 'active' && participants.length < 2);

        if (shouldClear) {
          unawaited(
            ref.read(videoServiceProvider).leaveRoom(doc.id, userId).catchError(
              (error) {
                debugPrint(
                  '[VideoLobby] Failed to repair room ${doc.id}: $error',
                );
              },
            ),
          );
        }
      }
    });
  }

  PreferredSizeWidget _buildAppBar() {
    return AppBar(
      backgroundColor: Colors.transparent,
      elevation: 0,
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.videocam_rounded, size: 22, color: Colors.white),
          const SizedBox(width: 8),
          Text(
            _tr(context, 'speed_dating'),
            style: GoogleFonts.playfairDisplay(
              fontWeight: FontWeight.w600,
              color: Colors.white,
              fontSize: 20,
            ),
          ),
        ],
      ),
      centerTitle: true,
      iconTheme: const IconThemeData(color: Colors.white),
      actions: [
        IconButton(
          tooltip: _tr(context, 'video_minutes'),
          icon: const Icon(Icons.timer_rounded, color: Colors.white),
          onPressed: () => context.push('/video/minutes'),
        ),
      ],
    );
  }
}

class _CountdownOverlay extends StatelessWidget {
  const _CountdownOverlay({required this.countdown, required this.pulse});

  final int countdown;
  final Animation<double> pulse;

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: IgnorePointer(
        child: Container(
          color: Colors.black.withValues(alpha: 0.45),
          child: Center(
            child: AnimatedBuilder(
              animation: pulse,
              builder: (context, child) {
                final scale = 0.92 + (pulse.value * 0.1);
                return Transform.scale(scale: scale, child: child);
              },
              child: Container(
                width: 210,
                padding: const EdgeInsets.symmetric(
                  horizontal: 24,
                  vertical: 26,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF111827).withValues(alpha: 0.94),
                  borderRadius: BorderRadius.circular(24),
                  border: Border.all(
                    color: _greenDuration.withValues(alpha: 0.45),
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: _greenDuration.withValues(alpha: 0.2),
                      blurRadius: 24,
                      spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.monitor_heart_rounded,
                      color: _greenDuration,
                      size: 42,
                    ),
                    const SizedBox(height: 14),
                    Text(
                      countdown.clamp(0, 5).toString(),
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 64,
                        height: 0.95,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _tr(context, 'starting_video_intro'),
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Animated dark purple gradient background
// ---------------------------------------------------------------------------

class _AnimatedBackground extends StatefulWidget {
  const _AnimatedBackground({required this.child});
  final Widget child;

  @override
  State<_AnimatedBackground> createState() => _AnimatedBackgroundState();
}

class _AnimatedBackgroundState extends State<_AnimatedBackground>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 10),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, child) {
        return Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                const Color(0xFF0F0B15),
                Color.lerp(
                  const Color(0xFF1A0B2E),
                  const Color(0xFF2D1B4E),
                  _controller.value,
                )!,
                Color.lerp(
                  const Color(0xFF1B0A2E),
                  const Color(0xFF3B1470),
                  _controller.value,
                )!,
                const Color(0xFF0F0B15),
              ],
              stops: [
                0.0,
                0.3 + (_controller.value * 0.1),
                0.7 - (_controller.value * 0.1),
                1.0,
              ],
            ),
          ),
          child: child,
        );
      },
      child: widget.child,
    );
  }
}

// ---------------------------------------------------------------------------
// Progress bar showing room occupancy stats
// ---------------------------------------------------------------------------

class _RoomViewData {
  const _RoomViewData({required this.id, required this.data});

  final String id;
  final Map<String, dynamic> data;
}

class _ProgressBar extends StatelessWidget {
  const _ProgressBar({
    required this.total,
    required this.occupied,
    required this.active,
  });

  final int total;
  final int occupied;
  final int active;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 4, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          _StatChip(
            icon: Icons.meeting_room_rounded,
            label: '$total ${_tr(context, 'rooms')}',
            color: Colors.white70,
          ),
          const SizedBox(width: 16),
          _StatChip(
            icon: Icons.person_rounded,
            label: '$occupied ${_tr(context, 'occupied')}',
            color: _amberDuration,
          ),
          const SizedBox(width: 16),
          _StatChip(
            icon: Icons.videocam_rounded,
            label: '$active ${_tr(context, 'active')}',
            color: _greenDuration,
          ),
        ],
      ),
    );
  }
}

class _StatChip extends StatelessWidget {
  const _StatChip({
    required this.icon,
    required this.label,
    required this.color,
  });

  final IconData icon;
  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 11,
            fontWeight: FontWeight.w600,
            color: color,
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Room Card
// ---------------------------------------------------------------------------

class _RoomCard extends StatelessWidget {
  const _RoomCard({
    required this.roomId,
    required this.data,
    required this.currentUserId,
    required this.index,
    required this.onTap,
  });

  final String roomId;
  final Map<String, dynamic> data;
  final String currentUserId;
  final int index;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final roomNumber = (data['roomNumber'] as num?)?.toInt() ?? (index + 1);
    final roomTheme = _themeForRoomNumber(roomNumber);
    final storedName = (data['name'] as String?)?.trim() ?? '';
    final roomName = _isDefaultRoomName(storedName)
        ? roomTheme.localizedName(context)
        : storedName;
    final duration = (data['duration'] as num?)?.toInt() ?? 5;
    final status = data['status'] as String? ?? 'waiting';

    final user1Id = data['user1Id'] as String?;
    final user1Name = data['user1Name'] as String?;
    final user1Photo = data['user1PhotoUrl'] as String?;
    final user1Age = (data['user1Age'] as num?)?.toInt();

    final user2Id = data['user2Id'] as String?;
    final user2Name = data['user2Name'] as String?;
    final user2Photo = data['user2PhotoUrl'] as String?;
    final user2Age = (data['user2Age'] as num?)?.toInt();

    final hasUser1 = user1Id != null && user1Id.isNotEmpty;
    final hasUser2 = user2Id != null && user2Id.isNotEmpty;
    final isUserInRoom = user1Id == currentUserId || user2Id == currentUserId;
    final bothPresent = hasUser1 && hasUser2;
    final isEmpty = !hasUser1 && !hasUser2;
    final isActive = status == 'active';

    final durationColor = _colorForDuration(duration);

    return GestureDetector(
          onTap: onTap,
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isUserInRoom
                    ? durationColor.withValues(alpha: 0.5)
                    : Colors.white.withValues(alpha: 0.06),
                width: isUserInRoom ? 1.5 : 1,
              ),
              boxShadow: isUserInRoom
                  ? [
                      BoxShadow(
                        color: durationColor.withValues(alpha: 0.15),
                        blurRadius: 12,
                        spreadRadius: 0,
                      ),
                    ]
                  : null,
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Stack(
                children: [
                  // Main content.
                  Padding(
                    padding: const EdgeInsets.all(14),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                roomName,
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis,
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 14,
                                  height: 1.15,
                                  fontWeight: FontWeight.w800,
                                  color: Colors.white,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            _DurationBadge(
                              duration: duration,
                              color: durationColor,
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          height: 2,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(99),
                            color: durationColor.withValues(alpha: 0.45),
                          ),
                        ),

                        const SizedBox(height: 10),

                        // User slots.
                        Expanded(
                          child: Column(
                            children: [
                              // User 1 slot.
                              _UserSlot(
                                name: user1Name,
                                photoUrl: user1Photo,
                                age: user1Age,
                                isPresent: hasUser1,
                                isCurrentUser: user1Id == currentUserId,
                                durationColor: durationColor,
                              ),

                              const SizedBox(height: 8),

                              // VS divider.
                              Row(
                                children: [
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                  Padding(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 8,
                                    ),
                                    child: Text(
                                      'VS',
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white.withValues(
                                          alpha: 0.3,
                                        ),
                                        letterSpacing: 2,
                                      ),
                                    ),
                                  ),
                                  Expanded(
                                    child: Container(
                                      height: 1,
                                      color: Colors.white.withValues(
                                        alpha: 0.1,
                                      ),
                                    ),
                                  ),
                                ],
                              ),

                              const SizedBox(height: 8),

                              // User 2 slot.
                              _UserSlot(
                                name: user2Name,
                                photoUrl: user2Photo,
                                age: user2Age,
                                isPresent: hasUser2,
                                isCurrentUser: user2Id == currentUserId,
                                durationColor: durationColor,
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 10),

                        // Action button.
                        SizedBox(
                          width: double.infinity,
                          child: _buildActionButton(
                            context,
                            isEmpty: isEmpty,
                            isUserInRoom: isUserInRoom,
                            bothPresent: bothPresent,
                            isActive: isActive,
                            durationColor: durationColor,
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Active call indicator overlay.
                  if (isActive)
                    Positioned(
                      top: 8,
                      right: 8,
                      child:
                          Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 8,
                                  vertical: 4,
                                ),
                                decoration: BoxDecoration(
                                  color: _roseDuration,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: [
                                    Container(
                                      width: 6,
                                      height: 6,
                                      decoration: const BoxDecoration(
                                        color: Colors.white,
                                        shape: BoxShape.circle,
                                      ),
                                    ),
                                    const SizedBox(width: 4),
                                    Text(
                                      _tr(context, 'live'),
                                      style: GoogleFonts.plusJakartaSans(
                                        fontSize: 9,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.white,
                                        letterSpacing: 1,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                              .animate(onPlay: (c) => c.repeat(reverse: true))
                              .fade(begin: 0.7, end: 1.0, duration: 800.ms),
                    ),
                ],
              ),
            ),
          ),
        )
        .animate()
        .fadeIn(
          duration: 400.ms,
          delay: Duration(milliseconds: 50 * (index % 6)),
        )
        .slideY(
          begin: 0.1,
          end: 0,
          duration: 400.ms,
          delay: Duration(milliseconds: 50 * (index % 6)),
          curve: Curves.easeOutCubic,
        );
  }

  Widget _buildActionButton(
    BuildContext context, {
    required bool isEmpty,
    required bool isUserInRoom,
    required bool bothPresent,
    required bool isActive,
    required Color durationColor,
  }) {
    if (isActive) {
      return _ActionButton(
        label: _tr(context, 'in_call'),
        color: _roseDuration.withValues(alpha: 0.3),
        textColor: _roseDuration,
        icon: Icons.videocam_rounded,
      );
    }

    if (bothPresent && isUserInRoom) {
      return _ActionButton(
            label: _tr(context, 'starting'),
            color: durationColor,
            textColor: Colors.white,
            icon: Icons.play_arrow_rounded,
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.7, end: 1.0, duration: 600.ms);
    }

    if (isUserInRoom) {
      return _ActionButton(
            label: _tr(context, 'waiting'),
            color: Colors.white.withValues(alpha: 0.12),
            textColor: durationColor,
            icon: Icons.hourglass_top_rounded,
          )
          .animate(onPlay: (c) => c.repeat(reverse: true))
          .fade(begin: 0.6, end: 1.0, duration: 1200.ms);
    }

    if (isEmpty) {
      return _ActionButton(
        label: _tr(context, 'join'),
        color: durationColor.withValues(alpha: 0.15),
        textColor: durationColor,
        icon: Icons.login_rounded,
      );
    }

    // One person waiting -- show "Join & Start".
    return _ActionButton(
      label: _tr(context, 'join_and_start'),
      color: durationColor,
      textColor: Colors.white,
      icon: Icons.play_arrow_rounded,
    );
  }
}

// ---------------------------------------------------------------------------
// Duration badge chip
// ---------------------------------------------------------------------------

class _DurationBadge extends StatelessWidget {
  const _DurationBadge({required this.duration, required this.color});

  final int duration;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Text(
        _labelForDuration(context, duration),
        style: GoogleFonts.plusJakartaSans(
          fontSize: 11,
          fontWeight: FontWeight.w700,
          color: color,
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// User slot (shows avatar + name or empty state)
// ---------------------------------------------------------------------------

class _UserSlot extends StatelessWidget {
  const _UserSlot({
    required this.name,
    required this.photoUrl,
    required this.age,
    required this.isPresent,
    required this.isCurrentUser,
    required this.durationColor,
  });

  final String? name;
  final String? photoUrl;
  final int? age;
  final bool isPresent;
  final bool isCurrentUser;
  final Color durationColor;

  @override
  Widget build(BuildContext context) {
    if (!isPresent) {
      return Row(
        children: [
          // Empty avatar placeholder.
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.white.withValues(alpha: 0.06),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
                width: 1.5,
                strokeAlign: BorderSide.strokeAlignOutside,
              ),
            ),
            child: Icon(
              Icons.person_add_rounded,
              size: 20,
              color: Colors.white.withValues(alpha: 0.25),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              _tr(context, 'empty'),
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: Colors.white.withValues(alpha: 0.35),
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      );
    }

    // Present user.
    final displayName = name ?? 'User';
    final shortName = displayName.length > 10
        ? '${displayName.substring(0, 10)}...'
        : displayName;

    return Row(
      children: [
        // Profile photo circle with glow.
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            boxShadow: [
              BoxShadow(
                color: durationColor.withValues(alpha: 0.35),
                blurRadius: 10,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: isCurrentUser
                    ? durationColor
                    : Colors.white.withValues(alpha: 0.4),
                width: 2,
              ),
            ),
            child: ClipOval(
              child: photoUrl != null && photoUrl!.isNotEmpty
                  ? CachedNetworkImage(
                      imageUrl: photoUrl!,
                      width: 40,
                      height: 40,
                      fit: BoxFit.cover,
                      placeholder: (_, __) => Container(
                        color: durationColor.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: durationColor,
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: durationColor.withValues(alpha: 0.2),
                        child: Icon(
                          Icons.person,
                          size: 20,
                          color: durationColor,
                        ),
                      ),
                    )
                  : Container(
                      width: 40,
                      height: 40,
                      color: durationColor.withValues(alpha: 0.2),
                      child: Center(
                        child: Text(
                          displayName.isNotEmpty
                              ? displayName[0].toUpperCase()
                              : '?',
                          style: GoogleFonts.playfairDisplay(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                            color: durationColor,
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ),

        const SizedBox(width: 10),

        // Name and age.
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                isCurrentUser ? _tr(context, 'you') : shortName,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              if (age != null)
                Text(
                  _trf(context, 'age_label', {'age': age}),
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    color: Colors.white.withValues(alpha: 0.5),
                    fontWeight: FontWeight.w500,
                  ),
                ),
            ],
          ),
        ),

        // Online indicator.
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _greenDuration,
            boxShadow: [
              BoxShadow(
                color: _greenDuration.withValues(alpha: 0.5),
                blurRadius: 4,
              ),
            ],
          ),
        ),
      ],
    );
  }
}

// ---------------------------------------------------------------------------
// Action button used inside room cards
// ---------------------------------------------------------------------------

class _ActionButton extends StatelessWidget {
  const _ActionButton({
    required this.label,
    required this.color,
    required this.textColor,
    required this.icon,
  });

  final String label;
  final Color color;
  final Color textColor;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 14, color: textColor),
          const SizedBox(width: 4),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w700,
              color: textColor,
            ),
          ),
        ],
      ),
    );
  }
}
