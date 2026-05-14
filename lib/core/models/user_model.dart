import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

/// Nested stats object that lives under each user document.
class UserStats {
  const UserStats({
    this.likesReceived = 0,
    this.likesSent = 0,
    this.matches = 0,
    this.messagesSent = 0,
    this.giftsReceived = 0,
    this.giftsSent = 0,
    this.videoMinutesUsed = 0,
  });

  final int likesReceived;
  final int likesSent;
  final int matches;
  final int messagesSent;
  final int giftsReceived;
  final int giftsSent;
  final int videoMinutesUsed;

  factory UserStats.fromMap(Map<String, dynamic>? map) {
    if (map == null) return const UserStats();
    return UserStats(
      likesReceived: (map['likesReceived'] as num?)?.toInt() ?? 0,
      likesSent: (map['likesSent'] as num?)?.toInt() ?? 0,
      matches: (map['matches'] as num?)?.toInt() ?? 0,
      messagesSent: (map['messagesSent'] as num?)?.toInt() ?? 0,
      giftsReceived: (map['giftsReceived'] as num?)?.toInt() ?? 0,
      giftsSent: (map['giftsSent'] as num?)?.toInt() ?? 0,
      videoMinutesUsed: (map['videoMinutesUsed'] as num?)?.toInt() ?? 0,
    );
  }

  Map<String, dynamic> toMap() => {
    'likesReceived': likesReceived,
    'likesSent': likesSent,
    'matches': matches,
    'messagesSent': messagesSent,
    'giftsReceived': giftsReceived,
    'giftsSent': giftsSent,
    'videoMinutesUsed': videoMinutesUsed,
  };

  UserStats copyWith({
    int? likesReceived,
    int? likesSent,
    int? matches,
    int? messagesSent,
    int? giftsReceived,
    int? giftsSent,
    int? videoMinutesUsed,
  }) {
    return UserStats(
      likesReceived: likesReceived ?? this.likesReceived,
      likesSent: likesSent ?? this.likesSent,
      matches: matches ?? this.matches,
      messagesSent: messagesSent ?? this.messagesSent,
      giftsReceived: giftsReceived ?? this.giftsReceived,
      giftsSent: giftsSent ?? this.giftsSent,
      videoMinutesUsed: videoMinutesUsed ?? this.videoMinutesUsed,
    );
  }
}

/// Full user profile model that maps 1-to-1 to Firestore `users` documents.
class UserModel {
  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    this.photoUrl,
    this.gallery = const [],
    this.jobTitle,
    this.hospital,
    this.department,
    this.showProfessionBadge = true,
    this.hideWorkplace = false,
    this.avoidSameWorkplace = false,
    this.avoidSameDepartment = false,
    this.location,
    this.bio,
    this.interests = const [],
    this.age,
    this.gender,
    this.lookingFor,
    this.shiftType,
    this.preferredDatingWindow,
    this.availableAfterShift = false,
    this.quietHoursStart,
    this.quietHoursEnd,
    this.yearsExperience,
    this.languages = const [],
    this.timezone,
    this.partnerCode,
    this.healthcareCredentialType,
    this.isVerified = false,
    this.isOnline = false,
    this.lastSeen,
    this.plan = SubscriptionPlan.free,
    this.videoMinutes = AppConstants.defaultVideoMinutes,
    this.messagesLeft = AppConstants.defaultMessagesPerDay,
    this.giftPoints = AppConstants.defaultGiftPoints,
    this.superlikesLeft = AppConstants.defaultSuperlikesPerDay,
    this.isBoosted = false,
    this.boostExpiresAt,
    this.boostAdCredits = 0,
    this.following = const [],
    this.blocked = const [],
    this.inventory = const [],
    this.stats = const UserStats(),
    this.fcmToken,
    this.createdAt,
    this.updatedAt,
  });

  final String id;
  final String name;
  final String email;
  final String? photoUrl;
  final List<String> gallery;
  final String? jobTitle;
  final String? hospital;
  final String? department;
  final bool showProfessionBadge;
  final bool hideWorkplace;
  final bool avoidSameWorkplace;
  final bool avoidSameDepartment;
  final String? location;
  final String? bio;
  final List<String> interests;
  final int? age;
  final Gender? gender;
  final LookingFor? lookingFor;
  final ShiftType? shiftType;
  final DatingWindow? preferredDatingWindow;
  final bool availableAfterShift;
  final String? quietHoursStart;
  final String? quietHoursEnd;
  final int? yearsExperience;
  final List<String> languages;
  final String? timezone;
  final String? partnerCode;
  final HealthcareCredentialType? healthcareCredentialType;
  final bool isVerified;
  final bool isOnline;
  final DateTime? lastSeen;
  final SubscriptionPlan plan;
  final int videoMinutes;
  final int messagesLeft;
  final int giftPoints;
  final int superlikesLeft;
  final bool isBoosted;
  final DateTime? boostExpiresAt;
  final int boostAdCredits;
  final List<String> following;
  final List<String> blocked;
  final List<String> inventory;
  final UserStats stats;
  final String? fcmToken;
  final DateTime? createdAt;
  final DateTime? updatedAt;

  // ─── Firestore Factories ─────────────────────────────────────────────

  factory UserModel.fromFirestore(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return UserModel(
      id: doc.id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      gallery: _toStringList(data['gallery']),
      jobTitle: data['jobTitle'] as String?,
      hospital: data['hospital'] as String?,
      department: data['department'] as String?,
      showProfessionBadge: data['showProfessionBadge'] as bool? ?? true,
      hideWorkplace: data['hideWorkplace'] as bool? ?? false,
      avoidSameWorkplace: data['avoidSameWorkplace'] as bool? ?? false,
      avoidSameDepartment: data['avoidSameDepartment'] as bool? ?? false,
      location: data['location'] as String?,
      bio: data['bio'] as String?,
      interests: _toStringList(data['interests']),
      age: (data['age'] as num?)?.toInt(),
      gender: data['gender'] != null
          ? Gender.fromString(data['gender'] as String?)
          : null,
      lookingFor: data['lookingFor'] != null
          ? LookingFor.fromString(data['lookingFor'] as String?)
          : null,
      shiftType: data['shiftType'] != null
          ? ShiftType.fromString(data['shiftType'] as String?)
          : null,
      preferredDatingWindow: data['preferredDatingWindow'] != null
          ? DatingWindow.fromString(data['preferredDatingWindow'] as String?)
          : null,
      availableAfterShift: data['availableAfterShift'] as bool? ?? false,
      quietHoursStart: data['quietHoursStart'] as String?,
      quietHoursEnd: data['quietHoursEnd'] as String?,
      yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
      languages: _toStringList(data['languages']),
      timezone: data['timezone'] as String?,
      partnerCode: data['partnerCode'] as String?,
      healthcareCredentialType: _toCredentialType(data),
      isVerified: data['isVerified'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: _toDateTime(data['lastSeen']),
      plan: SubscriptionPlan.fromString(data['plan'] as String?),
      videoMinutes:
          (data['videoMinutes'] as num?)?.toInt() ??
          AppConstants.defaultVideoMinutes,
      messagesLeft:
          (data['messagesLeft'] as num?)?.toInt() ??
          AppConstants.defaultMessagesPerDay,
      giftPoints:
          (data['giftPoints'] as num?)?.toInt() ??
          AppConstants.defaultGiftPoints,
      superlikesLeft:
          (data['superlikesLeft'] as num?)?.toInt() ??
          AppConstants.defaultSuperlikesPerDay,
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: _toDateTime(data['boostExpiresAt']),
      boostAdCredits: (data['boostAdCredits'] as num?)?.toInt() ?? 0,
      following: _toStringList(data['following']),
      blocked: _toStringList(data['blocked']),
      inventory: _toStringList(data['inventory']),
      stats: UserStats.fromMap(data['stats'] as Map<String, dynamic>?),
      fcmToken: data['fcmToken'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  factory UserModel.fromMap(Map<String, dynamic> data, String id) {
    return UserModel(
      id: id,
      name: data['name'] as String? ?? '',
      email: data['email'] as String? ?? '',
      photoUrl: data['photoUrl'] as String?,
      gallery: _toStringList(data['gallery']),
      jobTitle: data['jobTitle'] as String?,
      hospital: data['hospital'] as String?,
      department: data['department'] as String?,
      showProfessionBadge: data['showProfessionBadge'] as bool? ?? true,
      hideWorkplace: data['hideWorkplace'] as bool? ?? false,
      avoidSameWorkplace: data['avoidSameWorkplace'] as bool? ?? false,
      avoidSameDepartment: data['avoidSameDepartment'] as bool? ?? false,
      location: data['location'] as String?,
      bio: data['bio'] as String?,
      interests: _toStringList(data['interests']),
      age: (data['age'] as num?)?.toInt(),
      gender: data['gender'] != null
          ? Gender.fromString(data['gender'] as String?)
          : null,
      lookingFor: data['lookingFor'] != null
          ? LookingFor.fromString(data['lookingFor'] as String?)
          : null,
      shiftType: data['shiftType'] != null
          ? ShiftType.fromString(data['shiftType'] as String?)
          : null,
      preferredDatingWindow: data['preferredDatingWindow'] != null
          ? DatingWindow.fromString(data['preferredDatingWindow'] as String?)
          : null,
      availableAfterShift: data['availableAfterShift'] as bool? ?? false,
      quietHoursStart: data['quietHoursStart'] as String?,
      quietHoursEnd: data['quietHoursEnd'] as String?,
      yearsExperience: (data['yearsExperience'] as num?)?.toInt(),
      languages: _toStringList(data['languages']),
      timezone: data['timezone'] as String?,
      partnerCode: data['partnerCode'] as String?,
      healthcareCredentialType: _toCredentialType(data),
      isVerified: data['isVerified'] as bool? ?? false,
      isOnline: data['isOnline'] as bool? ?? false,
      lastSeen: _toDateTime(data['lastSeen']),
      plan: SubscriptionPlan.fromString(data['plan'] as String?),
      videoMinutes:
          (data['videoMinutes'] as num?)?.toInt() ??
          AppConstants.defaultVideoMinutes,
      messagesLeft:
          (data['messagesLeft'] as num?)?.toInt() ??
          AppConstants.defaultMessagesPerDay,
      giftPoints:
          (data['giftPoints'] as num?)?.toInt() ??
          AppConstants.defaultGiftPoints,
      superlikesLeft:
          (data['superlikesLeft'] as num?)?.toInt() ??
          AppConstants.defaultSuperlikesPerDay,
      isBoosted: data['isBoosted'] as bool? ?? false,
      boostExpiresAt: _toDateTime(data['boostExpiresAt']),
      boostAdCredits: (data['boostAdCredits'] as num?)?.toInt() ?? 0,
      following: _toStringList(data['following']),
      blocked: _toStringList(data['blocked']),
      inventory: _toStringList(data['inventory']),
      stats: UserStats.fromMap(data['stats'] as Map<String, dynamic>?),
      fcmToken: data['fcmToken'] as String?,
      createdAt: _toDateTime(data['createdAt']),
      updatedAt: _toDateTime(data['updatedAt']),
    );
  }

  Map<String, dynamic> toFirestore() => {
    'name': name,
    'email': email,
    'photoUrl': photoUrl,
    'gallery': gallery,
    'jobTitle': jobTitle,
    'hospital': hospital,
    'department': department,
    'showProfessionBadge': showProfessionBadge,
    'hideWorkplace': hideWorkplace,
    'avoidSameWorkplace': avoidSameWorkplace,
    'avoidSameDepartment': avoidSameDepartment,
    'location': location,
    'bio': bio,
    'interests': interests,
    'age': age,
    'gender': gender?.value,
    'lookingFor': lookingFor?.value,
    'shiftType': shiftType?.value,
    'preferredDatingWindow': preferredDatingWindow?.value,
    'availableAfterShift': availableAfterShift,
    'quietHoursStart': quietHoursStart,
    'quietHoursEnd': quietHoursEnd,
    'yearsExperience': yearsExperience,
    'languages': languages,
    'timezone': timezone,
    'partnerCode': partnerCode,
    'healthcareCredentialType': healthcareCredentialType?.value,
    'healthcareCredentialLabel': healthcareCredentialType?.displayName,
    'isVerified': isVerified,
    'isOnline': isOnline,
    'lastSeen': lastSeen != null ? Timestamp.fromDate(lastSeen!) : null,
    'plan': plan.value,
    'videoMinutes': videoMinutes,
    'messagesLeft': messagesLeft,
    'giftPoints': giftPoints,
    'superlikesLeft': superlikesLeft,
    'isBoosted': isBoosted,
    'boostExpiresAt': boostExpiresAt != null
        ? Timestamp.fromDate(boostExpiresAt!)
        : null,
    'boostAdCredits': boostAdCredits,
    'following': following,
    'blocked': blocked,
    'inventory': inventory,
    'stats': stats.toMap(),
    'fcmToken': fcmToken,
    'createdAt': createdAt != null
        ? Timestamp.fromDate(createdAt!)
        : FieldValue.serverTimestamp(),
    'updatedAt': FieldValue.serverTimestamp(),
  };

  // ─── copyWith ────────────────────────────────────────────────────────

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? photoUrl,
    List<String>? gallery,
    String? jobTitle,
    String? hospital,
    String? department,
    bool? showProfessionBadge,
    bool? hideWorkplace,
    bool? avoidSameWorkplace,
    bool? avoidSameDepartment,
    String? location,
    String? bio,
    List<String>? interests,
    int? age,
    Gender? gender,
    LookingFor? lookingFor,
    ShiftType? shiftType,
    DatingWindow? preferredDatingWindow,
    bool? availableAfterShift,
    String? quietHoursStart,
    String? quietHoursEnd,
    int? yearsExperience,
    List<String>? languages,
    String? timezone,
    String? partnerCode,
    HealthcareCredentialType? healthcareCredentialType,
    bool? isVerified,
    bool? isOnline,
    DateTime? lastSeen,
    SubscriptionPlan? plan,
    int? videoMinutes,
    int? messagesLeft,
    int? giftPoints,
    int? superlikesLeft,
    bool? isBoosted,
    DateTime? boostExpiresAt,
    int? boostAdCredits,
    List<String>? following,
    List<String>? blocked,
    List<String>? inventory,
    UserStats? stats,
    String? fcmToken,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      photoUrl: photoUrl ?? this.photoUrl,
      gallery: gallery ?? this.gallery,
      jobTitle: jobTitle ?? this.jobTitle,
      hospital: hospital ?? this.hospital,
      department: department ?? this.department,
      showProfessionBadge: showProfessionBadge ?? this.showProfessionBadge,
      hideWorkplace: hideWorkplace ?? this.hideWorkplace,
      avoidSameWorkplace: avoidSameWorkplace ?? this.avoidSameWorkplace,
      avoidSameDepartment: avoidSameDepartment ?? this.avoidSameDepartment,
      location: location ?? this.location,
      bio: bio ?? this.bio,
      interests: interests ?? this.interests,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      lookingFor: lookingFor ?? this.lookingFor,
      shiftType: shiftType ?? this.shiftType,
      preferredDatingWindow:
          preferredDatingWindow ?? this.preferredDatingWindow,
      availableAfterShift: availableAfterShift ?? this.availableAfterShift,
      quietHoursStart: quietHoursStart ?? this.quietHoursStart,
      quietHoursEnd: quietHoursEnd ?? this.quietHoursEnd,
      yearsExperience: yearsExperience ?? this.yearsExperience,
      languages: languages ?? this.languages,
      timezone: timezone ?? this.timezone,
      partnerCode: partnerCode ?? this.partnerCode,
      healthcareCredentialType:
          healthcareCredentialType ?? this.healthcareCredentialType,
      isVerified: isVerified ?? this.isVerified,
      isOnline: isOnline ?? this.isOnline,
      lastSeen: lastSeen ?? this.lastSeen,
      plan: plan ?? this.plan,
      videoMinutes: videoMinutes ?? this.videoMinutes,
      messagesLeft: messagesLeft ?? this.messagesLeft,
      giftPoints: giftPoints ?? this.giftPoints,
      superlikesLeft: superlikesLeft ?? this.superlikesLeft,
      isBoosted: isBoosted ?? this.isBoosted,
      boostExpiresAt: boostExpiresAt ?? this.boostExpiresAt,
      boostAdCredits: boostAdCredits ?? this.boostAdCredits,
      following: following ?? this.following,
      blocked: blocked ?? this.blocked,
      inventory: inventory ?? this.inventory,
      stats: stats ?? this.stats,
      fcmToken: fcmToken ?? this.fcmToken,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }

  // ─── Helpers ─────────────────────────────────────────────────────────

  /// Whether the user has completed onboarding (has at minimum a name and age).
  bool get isProfileComplete =>
      name.isNotEmpty &&
      age != null &&
      jobTitle != null &&
      jobTitle!.isNotEmpty;

  /// Main display image: photoUrl, first gallery item, or null.
  String? get displayPhoto =>
      photoUrl ?? (gallery.isNotEmpty ? gallery.first : null);

  bool get hasWorkplace => hospital != null && hospital!.trim().isNotEmpty;

  String? get workplaceDisplayLabel {
    if (!hasWorkplace) return null;
    if (hideWorkplace) return 'Workplace private';
    return hospital!.trim();
  }

  bool get hasWorkplacePrivacy =>
      hideWorkplace || avoidSameWorkplace || avoidSameDepartment;

  String? get healthcareVerificationBadge {
    if (!isVerified) return null;
    return healthcareCredentialType?.displayName ??
        'Healthcare Worker Verified';
  }

  String? get publicProfessionBadge {
    if (!showProfessionBadge) return null;
    final job = jobTitle?.trim();
    if (job != null && job.isNotEmpty) return job;
    return healthcareCredentialType?.displayName ?? 'Healthcare Worker';
  }

  String get careRoleBadge =>
      publicProfessionBadge ??
      healthcareCredentialType?.displayName ??
      'Healthcare Professional';

  bool get hasPartnerCode =>
      partnerCode != null && partnerCode!.trim().isNotEmpty;

  /// Whether the boost is currently active.
  bool get isBoostActive =>
      isBoosted &&
      boostExpiresAt != null &&
      boostExpiresAt!.isAfter(DateTime.now());

  static List<String> _toStringList(dynamic value) {
    if (value == null) return [];
    if (value is List) return value.map((e) => e.toString()).toList();
    return [];
  }

  static HealthcareCredentialType? _toCredentialType(
    Map<String, dynamic> data,
  ) {
    final value =
        data['healthcareCredentialType'] as String? ??
        data['credentialType'] as String?;
    if (value == null || value.isEmpty) return null;
    return HealthcareCredentialType.fromString(value);
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value == null) return null;
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }

  @override
  String toString() => 'UserModel(id: $id, name: $name, email: $email)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserModel && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;
}
