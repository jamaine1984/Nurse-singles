import 'dart:async';
import 'dart:math';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';

/// Provides a singleton [DiscoverService] via Riverpod.
final discoverServiceProvider = Provider<DiscoverService>((ref) {
  return DiscoverService(FirebaseFirestore.instance);
});

class SwipeUsageLimitException implements Exception {
  SwipeUsageLimitException({
    required this.usageType,
    this.plan,
    this.limit,
    this.used,
  });

  final String usageType;
  final String? plan;
  final int? limit;
  final int? used;

  factory SwipeUsageLimitException.fromFunctionsException(
    FirebaseFunctionsException error,
  ) {
    final details = error.details;
    if (details is Map) {
      return SwipeUsageLimitException(
        usageType: details['usageType']?.toString() ?? 'likes',
        plan: details['plan']?.toString(),
        limit: (details['limit'] as num?)?.toInt(),
        used: (details['used'] as num?)?.toInt(),
      );
    }
    return SwipeUsageLimitException(usageType: 'likes');
  }

  @override
  String toString() => 'SwipeUsageLimitException($usageType)';
}

/// Service responsible for fetching discovery profiles, recording swipes,
/// detecting mutual matches, and boosting profiles.
class DiscoverService {
  DiscoverService(this._firestore);

  final FirebaseFirestore _firestore;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;
  static const Duration _profileCacheTtl = Duration(minutes: 2);
  static const int _maxCachedDecks = 12;
  static final Map<String, _CachedProfiles> _profileCache = {};

  /// Returns up to 20 user profiles that [currentUserId] can discover.
  Future<List<UserModel>> fetchProfiles(
    String currentUserId, {
    String? gender,
    int? ageMin,
    int? ageMax,
    String? department,
    String? shiftType,
    String? language,
    double? maxDistance,
    bool verifiedOnly = false,
  }) async {
    final cacheKey = _profileCacheKey(
      currentUserId: currentUserId,
      gender: gender,
      ageMin: ageMin,
      ageMax: ageMax,
      department: department,
      shiftType: shiftType,
      language: language,
      maxDistance: maxDistance,
      verifiedOnly: verifiedOnly,
    );
    final cached = _profileCache[cacheKey];
    if (cached != null && !cached.isExpired) {
      unawaited(
        _recordCostTelemetry(
          feature: 'discovery_deck_open',
          amount: cached.profiles.length,
          unit: 'cached_cards',
        ),
      );
      return List<UserModel>.from(cached.profiles);
    }

    final currentUserDoc = await _firestore
        .collection(AppConstants.usersCollection)
        .doc(currentUserId)
        .get();

    UserModel? currentUser;
    final blockedIds = <String>{};
    if (currentUserDoc.exists && currentUserDoc.data() != null) {
      currentUser = UserModel.fromFirestore(currentUserDoc);
      final data = currentUserDoc.data();
      if (data != null && data['blocked'] != null) {
        blockedIds.addAll(List<String>.from(data['blocked']));
      }
    }

    final actedOnIds = await _fetchActedOnProfileIds(currentUserId);

    Query<Map<String, dynamic>> query = _firestore.collection(
      AppConstants.usersCollection,
    );

    if (gender != null && gender.isNotEmpty && gender != 'all') {
      query = query.where('gender', isEqualTo: gender);
    }

    if (department != null && department.isNotEmpty && department != 'All') {
      query = query.where('department', isEqualTo: department);
    }

    if (shiftType != null && shiftType.isNotEmpty && shiftType != 'all') {
      query = query.where('shiftType', isEqualTo: shiftType);
    }

    query = query.limit(60);
    final currentUserLocation = _pointFromData(currentUserDoc.data());
    final snapshot = await query.get();
    unawaited(
      _recordCostTelemetry(
        feature: 'profile_card_cache_miss',
        amount: snapshot.docs.length,
        unit: 'profile_docs',
        metadata: {'queryLimit': 60},
      ),
    );

    var profiles = _eligibleProfilesFromSnapshot(
      snapshot.docs,
      currentUserId: currentUserId,
      currentUser: currentUser,
      currentUserLocation: currentUserLocation,
      blockedIds: blockedIds,
      actedOnIds: actedOnIds,
      ageMin: ageMin,
      ageMax: ageMax,
      language: language,
      maxDistance: maxDistance,
      verifiedOnly: verifiedOnly,
      recycleActedOnProfiles: false,
    );

    if (profiles.isEmpty && actedOnIds.isNotEmpty) {
      profiles = _eligibleProfilesFromSnapshot(
        snapshot.docs,
        currentUserId: currentUserId,
        currentUser: currentUser,
        currentUserLocation: currentUserLocation,
        blockedIds: blockedIds,
        actedOnIds: actedOnIds,
        ageMin: ageMin,
        ageMax: ageMax,
        language: language,
        maxDistance: maxDistance,
        verifiedOnly: verifiedOnly,
        recycleActedOnProfiles: true,
      );
    }

    final rankedProfiles = _rankAndShuffleProfiles(profiles);
    _cacheProfiles(cacheKey, rankedProfiles);
    return rankedProfiles;
  }

  void _cacheProfiles(String cacheKey, List<UserModel> profiles) {
    if (_profileCache.length >= _maxCachedDecks) {
      final oldestKey = _profileCache.entries.reduce((oldest, entry) {
        return entry.value.cachedAt.isBefore(oldest.value.cachedAt)
            ? entry
            : oldest;
      }).key;
      _profileCache.remove(oldestKey);
    }
    _profileCache[cacheKey] = _CachedProfiles(List<UserModel>.from(profiles));
  }

  void _clearUserProfileCache(String currentUserId) {
    _profileCache.removeWhere((key, _) => key.startsWith('$currentUserId|'));
  }

  String _profileCacheKey({
    required String currentUserId,
    required String? gender,
    required int? ageMin,
    required int? ageMax,
    required String? department,
    required String? shiftType,
    required String? language,
    required double? maxDistance,
    required bool verifiedOnly,
  }) {
    return [
      currentUserId,
      gender ?? '',
      ageMin ?? '',
      ageMax ?? '',
      department ?? '',
      shiftType ?? '',
      language ?? '',
      maxDistance?.round() ?? '',
      verifiedOnly,
    ].join('|');
  }

  List<UserModel> _eligibleProfilesFromSnapshot(
    List<QueryDocumentSnapshot<Map<String, dynamic>>> docs, {
    required String currentUserId,
    required UserModel? currentUser,
    required _GeoPoint? currentUserLocation,
    required Set<String> blockedIds,
    required Set<String> actedOnIds,
    required int? ageMin,
    required int? ageMax,
    required String? language,
    required double? maxDistance,
    required bool verifiedOnly,
    required bool recycleActedOnProfiles,
  }) {
    final profiles = <UserModel>[];
    final excludeIds = {
      ...blockedIds,
      if (!recycleActedOnProfiles) ...actedOnIds,
      currentUserId,
    };

    for (final doc in docs) {
      if (excludeIds.contains(doc.id)) continue;

      final user = UserModel.fromFirestore(doc);
      if (user.blocked.contains(currentUserId)) continue;
      if (_hasWorkplaceConflict(currentUser, user)) continue;
      if (verifiedOnly && !user.isVerified) continue;

      if (ageMin != null && user.age != null && user.age! < ageMin) continue;
      if (ageMax != null && user.age != null && user.age! > ageMax) continue;

      if (language != null &&
          language.isNotEmpty &&
          language != 'All' &&
          !user.languages.contains(language)) {
        continue;
      }

      if (!_isWithinDistance(
        currentUserLocation,
        _pointFromData(doc.data()),
        maxDistance,
      )) {
        continue;
      }

      profiles.add(user);
    }

    return profiles;
  }

  List<UserModel> _rankAndShuffleProfiles(List<UserModel> profiles) {
    final random = Random(DateTime.now().microsecondsSinceEpoch);
    final boosted = <UserModel>[];
    final standard = <UserModel>[];

    for (final profile in profiles) {
      if (profile.isBoostActive) {
        boosted.add(profile);
      } else {
        standard.add(profile);
      }
    }

    boosted.shuffle(random);
    standard.shuffle(random);
    return [
      ...boosted,
      ...standard,
    ].take(AppConstants.paginationLimit).toList();
  }

  bool _hasWorkplaceConflict(UserModel? currentUser, UserModel targetUser) {
    if (currentUser == null) return false;

    final currentHospital = _normalized(currentUser.hospital);
    final targetHospital = _normalized(targetUser.hospital);
    final sameWorkplace =
        currentHospital.isNotEmpty && currentHospital == targetHospital;
    if (sameWorkplace &&
        (currentUser.avoidSameWorkplace || targetUser.avoidSameWorkplace)) {
      return true;
    }

    final currentDepartment = _normalized(currentUser.department);
    final targetDepartment = _normalized(targetUser.department);
    final sameDepartment =
        currentDepartment.isNotEmpty && currentDepartment == targetDepartment;
    if (sameDepartment &&
        (currentUser.avoidSameDepartment || targetUser.avoidSameDepartment)) {
      return true;
    }

    return false;
  }

  String _normalized(String? value) => value?.trim().toLowerCase() ?? '';

  Future<Set<String>> _fetchActedOnProfileIds(String currentUserId) async {
    final snapshots = await Future.wait([
      _firestore
          .collection(AppConstants.swipesCollection)
          .where('swiperId', isEqualTo: currentUserId)
          .limit(500)
          .get(),
      _firestore
          .collection(AppConstants.likesCollection)
          .where('likerId', isEqualTo: currentUserId)
          .limit(500)
          .get(),
    ]);

    final actedOn = <String>{};
    for (final doc in snapshots[0].docs) {
      final id = doc.data()['swipedUserId'] as String?;
      if (id != null && id.isNotEmpty) actedOn.add(id);
    }
    for (final doc in snapshots[1].docs) {
      final id = doc.data()['likedUserId'] as String?;
      if (id != null && id.isNotEmpty) actedOn.add(id);
    }
    return actedOn;
  }

  _GeoPoint? _pointFromData(Map<String, dynamic>? data) {
    if (data == null) return null;
    final directLatitude = (data['latitude'] as num?)?.toDouble();
    final directLongitude = (data['longitude'] as num?)?.toDouble();
    if (directLatitude != null && directLongitude != null) {
      return _GeoPoint(directLatitude, directLongitude);
    }

    final location = data['location'];
    if (location is Map) {
      final latitude =
          (location['latitude'] as num?)?.toDouble() ??
          (location['lat'] as num?)?.toDouble();
      final longitude =
          (location['longitude'] as num?)?.toDouble() ??
          (location['lng'] as num?)?.toDouble();
      if (latitude != null && longitude != null) {
        return _GeoPoint(latitude, longitude);
      }
    }

    final geo = data['geo'];
    if (geo is Map) {
      final latitude =
          (geo['latitude'] as num?)?.toDouble() ??
          (geo['lat'] as num?)?.toDouble();
      final longitude =
          (geo['longitude'] as num?)?.toDouble() ??
          (geo['lng'] as num?)?.toDouble();
      if (latitude != null && longitude != null) {
        return _GeoPoint(latitude, longitude);
      }
    }

    return null;
  }

  bool _isWithinDistance(
    _GeoPoint? current,
    _GeoPoint? target,
    double? maxDistanceKm,
  ) {
    if (maxDistanceKm == null || maxDistanceKm >= 500) return true;
    if (current == null || target == null) return true;
    return _distanceKm(current, target) <= maxDistanceKm;
  }

  double _distanceKm(_GeoPoint a, _GeoPoint b) {
    const earthRadiusKm = 6371.0;
    final dLat = _radians(b.latitude - a.latitude);
    final dLon = _radians(b.longitude - a.longitude);
    final lat1 = _radians(a.latitude);
    final lat2 = _radians(b.latitude);
    final h =
        sin(dLat / 2) * sin(dLat / 2) +
        cos(lat1) * cos(lat2) * sin(dLon / 2) * sin(dLon / 2);
    return earthRadiusKm * 2 * atan2(sqrt(h), sqrt(1 - h));
  }

  double _radians(double degrees) => degrees * pi / 180.0;

  /// Records a swipe on the backend. Returns true when it creates a match.
  Future<bool> recordSwipe(
    String currentUserId,
    String targetUserId, {
    required bool isLike,
    required bool isSuperLike,
  }) async {
    try {
      final callable = _functions.httpsCallable('recordSwipeWithLimit');
      final response = await callable.call<Map<String, dynamic>>({
        'targetUserId': targetUserId,
        'isLike': isLike,
        'isSuperLike': isSuperLike,
      });
      _clearUserProfileCache(currentUserId);
      return response.data['isMatch'] == true;
    } on FirebaseFunctionsException catch (error) {
      if (error.code == 'resource-exhausted') {
        throw SwipeUsageLimitException.fromFunctionsException(error);
      }
      rethrow;
    }
  }

  /// Activates a 30-minute profile boost for [userId].
  Future<void> boostProfile(String userId) async {
    final callable = _functions.httpsCallable('activateProfileBoost');
    await callable.call<Map<String, dynamic>>({'userId': userId});
  }

  Future<void> _recordCostTelemetry({
    required String feature,
    required int amount,
    required String unit,
    Map<String, Object?> metadata = const {},
  }) async {
    try {
      final callable = _functions.httpsCallable('recordCostTelemetry');
      await callable.call<Map<String, dynamic>>({
        'feature': feature,
        'amount': amount,
        'unit': unit,
        'metadata': metadata,
      });
    } catch (_) {
      // Telemetry must never block discovery.
    }
  }
}

class _CachedProfiles {
  _CachedProfiles(this.profiles) : cachedAt = DateTime.now();

  final List<UserModel> profiles;
  final DateTime cachedAt;

  bool get isExpired =>
      DateTime.now().difference(cachedAt) > DiscoverService._profileCacheTtl;
}

class _GeoPoint {
  const _GeoPoint(this.latitude, this.longitude);

  final double latitude;
  final double longitude;
}
