import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';

// ─── Timezone Offset Map ────────────────────────────────────────────────────

/// Maps common timezone identifiers to their UTC offsets in hours.
/// This is used to calculate the local time for each user and determine
/// whether they are currently in "night hours" (7 PM to 7 AM local time).
const Map<String, double> _timezoneOffsets = {
  'UTC': 0,
  'GMT': 0,
  'EST': -5,
  'EDT': -4,
  'CST': -6,
  'CDT': -5,
  'MST': -7,
  'MDT': -6,
  'PST': -8,
  'PDT': -7,
  'HST': -10,
  'AKST': -9,
  'AKDT': -8,
  'AST': -4,
  'NST': -3.5,
  'BRT': -3,
  'ART': -3,
  'WET': 0,
  'CET': 1,
  'EET': 2,
  'MSK': 3,
  'GST': 4,
  'IST': 5.5,
  'NPT': 5.75,
  'BST_BD': 6,
  'ICT': 7,
  'CST_CN': 8,
  'HKT': 8,
  'SGT': 8,
  'AWST': 8,
  'JST': 9,
  'KST': 9,
  'ACST': 9.5,
  'AEST': 10,
  'NZST': 12,
  'NZDT': 13,
  // Continent/city style
  'America/New_York': -5,
  'America/Chicago': -6,
  'America/Denver': -7,
  'America/Los_Angeles': -8,
  'America/Sao_Paulo': -3,
  'America/Buenos_Aires': -3,
  'Europe/London': 0,
  'Europe/Paris': 1,
  'Europe/Berlin': 1,
  'Europe/Moscow': 3,
  'Asia/Dubai': 4,
  'Asia/Kolkata': 5.5,
  'Asia/Bangkok': 7,
  'Asia/Shanghai': 8,
  'Asia/Singapore': 8,
  'Asia/Tokyo': 9,
  'Asia/Seoul': 9,
  'Australia/Sydney': 10,
  'Australia/Perth': 8,
  'Pacific/Auckland': 12,
  'Africa/Cairo': 2,
  'Africa/Lagos': 1,
  'Africa/Johannesburg': 2,
};

// ─── NightShiftService ──────────────────────────────────────────────────────

/// Service responsible for night-shift-specific features:
/// finding night owl users, determining who is awake during night hours,
/// and calculating shift compatibility between users.
class NightShiftService {
  NightShiftService({FirebaseFirestore? firestore})
      : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  // ─── Night Owls ─────────────────────────────────────────────────────

  /// Streams users whose shiftType is 'nightShift' and who are currently
  /// online, ordered by most recently seen first.
  Stream<List<UserModel>> getNightOwls() {
    return _usersRef
        .where('shiftType', isEqualTo: ShiftType.nightShift.value)
        .where('isOnline', isEqualTo: true)
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ─── Awake Now ──────────────────────────────────────────────────────

  /// Streams all currently online users, then filters client-side
  /// to find those whose local time falls within night hours (7 PM - 7 AM).
  Stream<List<UserModel>> getAwakeNow() {
    return _usersRef
        .where('isOnline', isEqualTo: true)
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snap) {
      final allOnline =
          snap.docs.map((d) => UserModel.fromFirestore(d)).toList();
      return allOnline.where((user) => _isInNightHours(user.timezone)).toList();
    });
  }

  // ─── By Timezone ────────────────────────────────────────────────────

  /// Streams users from a specific timezone, regardless of online status.
  Stream<List<UserModel>> getNursesByTimezone(String timezone) {
    return _usersRef
        .where('timezone', isEqualTo: timezone)
        .orderBy('lastSeen', descending: true)
        .snapshots()
        .map((snap) =>
            snap.docs.map((d) => UserModel.fromFirestore(d)).toList());
  }

  // ─── Shift Compatibility ────────────────────────────────────────────

  /// Calculates a 0-100 shift compatibility score between two users.
  ///
  /// Scoring breakdown:
  /// - Same shift type:              40 points
  /// - Overlapping shifts:           25 points
  /// - Opposite shifts:               5 points
  /// - Same timezone:                 30 points
  /// - Adjacent timezone (<=3h diff): 20 points
  /// - Nearby timezone (<=6h diff):   10 points
  /// - Both currently online:         15 points
  /// - One online:                    5 points
  /// - Night hours overlap bonus:     15 points
  int getShiftCompatibility(UserModel user1, UserModel user2) {
    int score = 0;

    // Shift type comparison.
    final s1 = user1.shiftType;
    final s2 = user2.shiftType;

    if (s1 != null && s2 != null) {
      if (s1 == s2) {
        score += 40;
      } else if (_shiftsOverlap(s1, s2)) {
        score += 25;
      } else {
        score += 5;
      }
    }

    // Timezone comparison.
    final tz1 = user1.timezone;
    final tz2 = user2.timezone;
    if (tz1 != null && tz2 != null) {
      if (tz1 == tz2) {
        score += 30;
      } else {
        final diff = _timezoneHourDiff(tz1, tz2);
        if (diff <= 3) {
          score += 20;
        } else if (diff <= 6) {
          score += 10;
        }
      }
    }

    // Online status.
    if (user1.isOnline && user2.isOnline) {
      score += 15;
    } else if (user1.isOnline || user2.isOnline) {
      score += 5;
    }

    // Night-hours overlap bonus.
    if (_isInNightHours(tz1) && _isInNightHours(tz2)) {
      score += 15;
    }

    return score.clamp(0, 100);
  }

  // ─── Online Status Updates ──────────────────────────────────────────

  /// Sets the online status for a user.
  Future<void> updateOnlineStatus(String userId, bool isOnline) async {
    await _usersRef.doc(userId).update({
      'isOnline': isOnline,
      'lastSeen': FieldValue.serverTimestamp(),
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  /// Updates the shift type for a user.
  Future<void> updateShiftStatus(String userId, String shiftType) async {
    await _usersRef.doc(userId).update({
      'shiftType': shiftType,
      'updatedAt': FieldValue.serverTimestamp(),
    });
  }

  // ─── Helpers ────────────────────────────────────────────────────────

  /// Checks whether the given timezone is currently in night hours
  /// (7 PM to 7 AM local time).
  bool _isInNightHours(String? timezone) {
    if (timezone == null || timezone.isEmpty) return false;

    final offsetHours = _timezoneOffsets[timezone];
    if (offsetHours == null) return false;

    final nowUtc = DateTime.now().toUtc();
    final localHour =
        (nowUtc.hour + offsetHours).round() % 24;

    // Night hours: 19:00 (7 PM) to 06:59 (7 AM).
    return localHour >= 19 || localHour < 7;
  }

  /// Calculates the absolute hour difference between two timezones.
  double _timezoneHourDiff(String tz1, String tz2) {
    final off1 = _timezoneOffsets[tz1] ?? 0;
    final off2 = _timezoneOffsets[tz2] ?? 0;
    return (off1 - off2).abs();
  }

  /// Determines whether two shift types have overlapping work hours.
  bool _shiftsOverlap(ShiftType s1, ShiftType s2) {
    // Rotating and flexible shifts overlap with everything.
    if (s1 == ShiftType.rotatingShift ||
        s1 == ShiftType.flexible ||
        s2 == ShiftType.rotatingShift ||
        s2 == ShiftType.flexible) {
      return true;
    }
    return false;
  }

  /// Returns the current local time string for a given timezone
  /// (e.g. "2:30 AM").
  static String localTimeString(String? timezone) {
    if (timezone == null || timezone.isEmpty) return '';

    final offsetHours = _timezoneOffsets[timezone];
    if (offsetHours == null) return '';

    final nowUtc = DateTime.now().toUtc();
    final localTime = nowUtc.add(Duration(
      hours: offsetHours.truncate(),
      minutes: ((offsetHours % 1) * 60).round(),
    ));

    final hour = localTime.hour;
    final minute = localTime.minute;
    final period = hour >= 12 ? 'PM' : 'AM';
    final displayHour = hour == 0
        ? 12
        : hour > 12
            ? hour - 12
            : hour;
    final displayMinute = minute.toString().padLeft(2, '0');

    return '$displayHour:$displayMinute $period';
  }

  /// Returns a friendly city name from a timezone like "Asia/Tokyo" -> "Tokyo".
  static String friendlyTimezone(String? timezone) {
    if (timezone == null || timezone.isEmpty) return 'Unknown';
    if (timezone.contains('/')) {
      return timezone.split('/').last.replaceAll('_', ' ');
    }
    return timezone;
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────────────────

final nightShiftServiceProvider = Provider<NightShiftService>((ref) {
  return NightShiftService();
});

/// Streams currently online night-shift workers.
final nightOwlsProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(nightShiftServiceProvider).getNightOwls();
});

/// Streams users who are online and in night hours in their local timezone.
final awakeNowProvider = StreamProvider<List<UserModel>>((ref) {
  return ref.watch(nightShiftServiceProvider).getAwakeNow();
});

/// Streams nurses in a specific timezone.
final nursesByTimezoneProvider =
    StreamProvider.family<List<UserModel>, String>((ref, timezone) {
  return ref.watch(nightShiftServiceProvider).getNursesByTimezone(timezone);
});
