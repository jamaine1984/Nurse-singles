import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';

// ─── CompatibilityResult ────────────────────────────────────────────────────

/// The output of a full compatibility calculation between two users.
///
/// Contains both the overall score and the breakdown by category, plus
/// a list of human-readable top reasons for the compatibility.
class CompatibilityResult {
  const CompatibilityResult({
    required this.totalScore,
    required this.shiftScore,
    required this.locationScore,
    required this.interestScore,
    required this.languageScore,
    required this.departmentScore,
    required this.workplaceScore,
    required this.verificationScore,
    required this.ageScore,
    required this.topReasons,
    required this.careSignals,
    required this.cautionSignals,
  });

  final int totalScore;
  final int shiftScore;
  final int locationScore;
  final int interestScore;
  final int languageScore;
  final int departmentScore;
  final int workplaceScore;
  final int verificationScore;
  final int ageScore;
  final List<String> topReasons;
  final List<String> careSignals;
  final List<String> cautionSignals;

  String get matchTier {
    if (totalScore >= 85) return 'Elite care fit';
    if (totalScore >= 72) return 'Strong care fit';
    if (totalScore >= 55) return 'Promising care fit';
    return 'Light care fit';
  }

  /// Empty result used as a default.
  static const CompatibilityResult empty = CompatibilityResult(
    totalScore: 0,
    shiftScore: 0,
    locationScore: 0,
    interestScore: 0,
    languageScore: 0,
    departmentScore: 0,
    workplaceScore: 0,
    verificationScore: 0,
    ageScore: 0,
    topReasons: [],
    careSignals: [],
    cautionSignals: [],
  );

  @override
  String toString() =>
      'CompatibilityResult(total: $totalScore, shift: $shiftScore, '
      'location: $locationScore, interest: $interestScore, '
      'language: $languageScore, dept: $departmentScore, '
      'workplace: $workplaceScore, verification: $verificationScore, '
      'age: $ageScore)';
}

// ─── Related Departments Map ────────────────────────────────────────────────

/// Groups of departments that are considered "related" for scoring purposes.
const List<Set<String>> _relatedDepartmentGroups = [
  {'Emergency', 'ICU', 'Critical Care', 'Trauma'},
  {'Cardiology', 'Internal Medicine', 'Pulmonology'},
  {'Pediatrics', 'Neonatal', 'NICU'},
  {'Surgery', 'Orthopedics', 'Neurosurgery', 'Anesthesiology'},
  {'Oncology', 'Radiology', 'Pathology'},
  {'Obstetrics', 'Gynecology', 'Maternity'},
  {'Psychiatry', 'Psychology', 'Mental Health'},
  {'General Practice', 'Family Medicine', 'Internal Medicine'},
  {'Dermatology', 'Allergy', 'Immunology'},
  {'Nursing', 'Home Health', 'Rehabilitation'},
];

// ─── CompatibilityService ───────────────────────────────────────────────────

/// Calculates comprehensive compatibility scores between users based on
/// multiple factors relevant to healthcare workers' dating lives.
class CompatibilityService {
  CompatibilityService({FirebaseFirestore? firestore})
    : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  CollectionReference<Map<String, dynamic>> get _usersRef =>
      _firestore.collection(AppConstants.usersCollection);

  // ─── Calculate Full Compatibility ───────────────────────────────────

  CompatibilityResult calculateCompatibility(
    UserModel user1,
    UserModel user2,
  ) => score(user1, user2);

  /// Calculates a comprehensive compatibility score between two users.
  ///
  /// Scoring breakdown (total: 100 points):
  ///   - Shift compatibility:    25 points max
  ///   - Location proximity:     15 points max
  ///   - Interest overlap:       15 points max
  ///   - Language overlap:       10 points max
  ///   - Department affinity:    15 points max
  ///   - Workplace privacy:      10 points max
  ///   - Healthcare verification: 5 points max
  ///   - Age proximity:           5 points max
  static CompatibilityResult score(UserModel user1, UserModel user2) {
    final List<String> reasons = [];
    final List<String> careSignals = [];
    final List<String> cautionSignals = [];

    // 1. Shift compatibility (max 25).
    int shiftScore = 0;
    if (user1.shiftType != null && user2.shiftType != null) {
      if (user1.shiftType == user2.shiftType) {
        shiftScore = 25;
        reasons.add('Same ${user1.shiftType!.displayName} schedule');
        careSignals.add('Same shift rhythm');
      } else if (_shiftsOverlap(user1.shiftType!, user2.shiftType!)) {
        shiftScore = 18;
        reasons.add('Overlapping shift schedules');
        careSignals.add('Shift-aware timing');
      } else {
        shiftScore = 5;
        cautionSignals.add('Different shift rhythms');
      }
    }

    if (user1.preferredDatingWindow != null &&
        user1.preferredDatingWindow == user2.preferredDatingWindow) {
      shiftScore = (shiftScore + 5).clamp(0, 25);
      reasons.add(
        'Same dating window: ${user1.preferredDatingWindow!.displayName}',
      );
      careSignals.add('Matching off-shift window');
    }

    if (user1.availableAfterShift && user2.availableAfterShift) {
      careSignals.add('Both available after shift');
    }

    if (user1.quietHoursStart != null ||
        user2.quietHoursStart != null ||
        user1.quietHoursEnd != null ||
        user2.quietHoursEnd != null) {
      careSignals.add('Quiet hours visible');
    }

    // 2. Location proximity (max 15).
    int locationScore = 0;
    if (user1.location != null &&
        user2.location != null &&
        user1.location!.isNotEmpty &&
        user2.location!.isNotEmpty) {
      if (_sameText(user1.location!, user2.location!)) {
        locationScore = 15;
        reasons.add('Same city: ${user1.location}');
        careSignals.add('Local connection');
      } else if (_sameCountry(user1.location!, user2.location!)) {
        locationScore = 8;
        reasons.add('Same country');
      } else {
        locationScore = 3;
      }
    }

    // 3. Interest overlap (max 15, 3 pts per shared interest).
    int interestScore = 0;
    if (user1.interests.isNotEmpty && user2.interests.isNotEmpty) {
      final sharedInterests = _sharedValues(user1.interests, user2.interests);
      interestScore = (sharedInterests.length * 3).clamp(0, 15);
      if (sharedInterests.isNotEmpty) {
        if (sharedInterests.length == 1) {
          reasons.add('Shared interest: ${sharedInterests.first}');
        } else {
          reasons.add(
            '${sharedInterests.length} shared interests including ${sharedInterests.first}',
          );
        }
        careSignals.add('Shared off-shift interests');
      }
    }

    // 4. Language overlap (max 10, 5 pts per shared language).
    int languageScore = 0;
    if (user1.languages.isNotEmpty && user2.languages.isNotEmpty) {
      final sharedLanguages = _sharedValues(user1.languages, user2.languages);
      languageScore = (sharedLanguages.length * 5).clamp(0, 10);
      if (sharedLanguages.isNotEmpty) {
        reasons.add('Both speak ${sharedLanguages.join(", ")}');
        careSignals.add('Shared language comfort');
      }
    }

    // 5. Department affinity (max 15).
    int departmentScore = 0;
    final hasDepartment1 =
        user1.department != null && user1.department!.trim().isNotEmpty;
    final hasDepartment2 =
        user2.department != null && user2.department!.trim().isNotEmpty;
    final sameDepartment =
        hasDepartment1 &&
        hasDepartment2 &&
        _sameText(user1.department!, user2.department!);
    final avoidsSameDepartment =
        user1.avoidSameDepartment || user2.avoidSameDepartment;

    if (hasDepartment1 && hasDepartment2) {
      if (sameDepartment && !avoidsSameDepartment) {
        departmentScore = 15;
        reasons.add('Same department: ${user1.department}');
        careSignals.add('Same unit understanding');
      } else if (sameDepartment && avoidsSameDepartment) {
        departmentScore = 3;
        cautionSignals.add('Same department preference conflict');
      } else if (_departmentsRelated(user1.department!, user2.department!)) {
        departmentScore = 10;
        reasons.add('Related departments');
        careSignals.add('Related clinical background');
      } else {
        departmentScore = 5;
      }
    }

    // 6. Workplace privacy and hospital-safe fit (max 10).
    int workplaceScore = 8;
    final hasWorkplace1 =
        user1.hospital != null && user1.hospital!.trim().isNotEmpty;
    final hasWorkplace2 =
        user2.hospital != null && user2.hospital!.trim().isNotEmpty;
    final sameWorkplace =
        hasWorkplace1 &&
        hasWorkplace2 &&
        _sameText(user1.hospital!, user2.hospital!);
    final avoidsSameWorkplace =
        user1.avoidSameWorkplace || user2.avoidSameWorkplace;

    if (sameWorkplace && avoidsSameWorkplace) {
      workplaceScore = 0;
      cautionSignals.add('Same workplace preference conflict');
    } else if (sameWorkplace) {
      workplaceScore = 6;
      reasons.add('Same healthcare system');
    } else if (hasWorkplace1 && hasWorkplace2) {
      workplaceScore = 10;
      reasons.add('Separate workplaces');
      careSignals.add('Workplace privacy respected');
    }

    if (user1.hideWorkplace || user2.hideWorkplace) {
      careSignals.add('Workplace privacy protected');
    }

    // 7. Healthcare verification (max 5).
    int verificationScore = 0;
    if (user1.isVerified && user2.isVerified) {
      verificationScore = 5;
      reasons.add('Both healthcare verified');
      careSignals.add('Verified healthcare profiles');
    } else if (user1.isVerified || user2.isVerified) {
      verificationScore = 3;
      careSignals.add('One verified profile');
    }

    // 8. Age proximity (max 5).
    int ageScore = 0;
    if (user1.age != null && user2.age != null) {
      final diff = (user1.age! - user2.age!).abs();
      if (diff <= 3) {
        ageScore = 5;
        reasons.add('Close in age');
      } else if (diff <= 5) {
        ageScore = 3;
      } else if (diff <= 10) {
        ageScore = 1;
      }
    }

    final total =
        (shiftScore +
                locationScore +
                interestScore +
                languageScore +
                departmentScore +
                workplaceScore +
                verificationScore +
                ageScore)
            .clamp(0, 100);

    if (careSignals.isEmpty) {
      careSignals.add('Healthcare community match');
    }

    return CompatibilityResult(
      totalScore: total,
      shiftScore: shiftScore,
      locationScore: locationScore,
      interestScore: interestScore,
      languageScore: languageScore,
      departmentScore: departmentScore,
      workplaceScore: workplaceScore,
      verificationScore: verificationScore,
      ageScore: ageScore,
      topReasons: reasons.toSet().toList(),
      careSignals: careSignals.toSet().toList(),
      cautionSignals: cautionSignals.toSet().take(3).toList(),
    );
  }

  // ─── Top Compatible Users ───────────────────────────────────────────

  /// Fetches a pool of users from Firestore and returns the top 20
  /// most compatible with the given user, sorted descending by score.
  Future<List<MapEntry<UserModel, CompatibilityResult>>> getTopCompatibleUsers(
    UserModel user,
  ) async {
    // Fetch a broad pool of users (excluding the current user and blocked).
    final snap = await _usersRef
        .where('isVerified', isEqualTo: true)
        .limit(200)
        .get();

    final candidates = snap.docs
        .map((d) => UserModel.fromFirestore(d))
        .where((u) => u.id != user.id && !user.blocked.contains(u.id))
        .toList();

    // Calculate compatibility for each candidate.
    final scored = candidates.map((candidate) {
      final result = calculateCompatibility(user, candidate);
      return MapEntry(candidate, result);
    }).toList();

    // Sort by total score descending.
    scored.sort((a, b) => b.value.totalScore.compareTo(a.value.totalScore));

    return scored.take(20).toList();
  }

  // ─── Helper Methods ─────────────────────────────────────────────────

  /// Determines whether two shift types have overlapping work hours.
  static bool _shiftsOverlap(ShiftType s1, ShiftType s2) {
    if (s1 == ShiftType.rotatingShift ||
        s1 == ShiftType.flexible ||
        s2 == ShiftType.rotatingShift ||
        s2 == ShiftType.flexible) {
      return true;
    }
    return false;
  }

  /// Simple heuristic: two locations are in the same country if they
  /// share the last word (e.g. "Tokyo, Japan" and "Osaka, Japan").
  static bool _sameCountry(String loc1, String loc2) {
    final parts1 = loc1.split(',').map((s) => s.trim().toLowerCase()).toList();
    final parts2 = loc2.split(',').map((s) => s.trim().toLowerCase()).toList();
    if (parts1.length >= 2 && parts2.length >= 2) {
      return parts1.last == parts2.last;
    }
    return false;
  }

  /// Checks whether two departments are considered related based on
  /// the pre-defined groups.
  static bool _departmentsRelated(String dept1, String dept2) {
    final d1 = dept1.toLowerCase();
    final d2 = dept2.toLowerCase();
    for (final group in _relatedDepartmentGroups) {
      final loweredGroup = group.map((d) => d.toLowerCase()).toSet();
      if (loweredGroup.contains(d1) && loweredGroup.contains(d2)) {
        return true;
      }
    }
    return false;
  }

  static bool _sameText(String first, String second) =>
      first.trim().toLowerCase() == second.trim().toLowerCase();

  static List<String> _sharedValues(List<String> first, List<String> second) {
    final secondLower = second.map((item) => item.trim().toLowerCase()).toSet();
    return first
        .where((item) => secondLower.contains(item.trim().toLowerCase()))
        .toList();
  }
}

// ─── Riverpod Providers ─────────────────────────────────────────────────────

final compatibilityServiceProvider = Provider<CompatibilityService>((ref) {
  return CompatibilityService();
});

/// Calculates and provides the compatibility result between two users.
final compatibilityResultProvider =
    Provider.family<CompatibilityResult, ({UserModel user1, UserModel user2})>((
      ref,
      params,
    ) {
      final service = ref.watch(compatibilityServiceProvider);
      return service.calculateCompatibility(params.user1, params.user2);
    });

/// Fetches the top compatible users for the given user.
final topCompatibleUsersProvider =
    FutureProvider.family<
      List<MapEntry<UserModel, CompatibilityResult>>,
      UserModel
    >((ref, user) async {
      final service = ref.watch(compatibilityServiceProvider);
      return service.getTopCompatibleUsers(user);
    });
