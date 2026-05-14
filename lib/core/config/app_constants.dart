/// App-wide constants for Nurse Singles.
///
/// All string literals, collection names, IDs, and configuration values live
/// here so they can be changed in one place.
library;

import 'package:nightingale_heart/core/config/runtime_config.dart';

// ─── App Identity ────────────────────────────────────────────────────────────
class AppConstants {
  AppConstants._();

  static const String appName = 'Nurse Singles';
  static const String appTagline = 'Where Night Shifts Meet Heart Shifts';
  static const String appVersion = '1.0.0';
  static const String supportEmail = 'support@nursesingles.com';
  static const String privacyPolicyUrl = 'https://nurse-singles.com/privacy';
  static const String termsUrl = 'https://nurse-singles.com/terms';

  // ─── Firebase Collection Names ───────────────────────────────────────
  static const String usersCollection = 'users';
  static const String likesCollection = 'likes';
  static const String matchesCollection = 'matches';
  static const String chatsCollection = 'chats';
  static const String messagesCollection = 'messages';
  static const String swipesCollection = 'swipes';
  static const String giftsCollection = 'gifts';
  static const String giftTransactionsCollection = 'gift_transactions';
  static const String subscriptionsCollection = 'subscriptions';
  static const String speedDatingRoomsCollection = 'speed_dating_rooms';
  static const String speedDatingSessionsCollection = 'speed_dating_sessions';
  static const String speedDateFollowUpsCollection = 'speed_date_followups';
  static const String videoSessionsCollection = 'video_sessions';
  static const String callNotificationsCollection = 'call_notifications';
  static const String postsCollection = 'posts';
  static const String reportsCollection = 'reports';
  static const String boostLogsCollection = 'boostLogs';
  static const String configCollection = 'config';
  static const String partnerLeadsCollection = 'partner_leads';
  static const String partnerOrganizationsCollection = 'partner_organizations';
  static const String partnerGivebackLedgerCollection =
      'partner_giveback_ledger';
  static const String verificationRequestsCollection = 'verification_requests';

  // ─── AdMob IDs ───────────────────────────────────────────────────────
  static const String admobAppId = 'ca-app-pub-7587025688858323~3404981432';
  static const String admobRewardedId =
      'ca-app-pub-7587025688858323/4885584060';

  // ─── RevenueCat Product IDs ──────────────────────────────────────────
  static String get revenueCatApiKey => RuntimeConfig.revenueCatPublicApiKey;
  static const String nurseSinglesProEntitlement = 'nurse_singles_pro';
  static const Set<String> nurseSinglesProEntitlementAliases = {
    nurseSinglesProEntitlement,
    'Nurse Singles Pro',
    'pro',
    'nurse_singles_pro_entitlement',
  };
  static const String monthlyProductId = 'monthly';
  static const String monthlyBasePlanProductId = 'monthly:monthly';
  static const String techMonthly = 'tech_monthly';
  static const String techMonthlyBasePlan = 'tech_monthly:monthly';
  static const String collegeMonthly = 'college_monthly';
  static const String collegeMonthlyBasePlan = 'college_monthly:monthly';
  static const String nurseMonthly = 'nurse_monthly';
  static const String nurseMonthlyBasePlan = 'nurse_monthly:monthly';
  static const String doctorMonthly = 'doctor_monthly';
  static const String doctorMonthlyBasePlan = 'doctor_monthly:monthly';
  static const String revenueCatMonthlyPackage = '\$rc_monthly';
  static const String revenueCatWebOffering = 'web_default';
  static const String techPackage = 'tech';
  static const String collegePackage = 'college';
  static const String nursePackage = 'nurse';
  static const String doctorPackage = 'doctor';
  static const String videoMinutes400 = 'video_minutes_400';
  static const String videoMinutes800 = 'video_minutes_800';
  static const String videoMinutes2500 = 'video_minutes_2500';

  static const List<String> videoMinuteProductIds = [
    videoMinutes400,
    videoMinutes800,
    videoMinutes2500,
  ];

  static const List<String> allProductIds = [
    monthlyProductId,
    monthlyBasePlanProductId,
    techMonthly,
    techMonthlyBasePlan,
    collegeMonthly,
    collegeMonthlyBasePlan,
    nurseMonthly,
    nurseMonthlyBasePlan,
    doctorMonthly,
    doctorMonthlyBasePlan,
    videoMinutes400,
    videoMinutes800,
    videoMinutes2500,
  ];

  // ─── Pagination & Limits ─────────────────────────────────────────────
  static const int paginationLimit = 20;
  static const int maxUserPhotos = 8;
  static const int maxGalleryImages = maxUserPhotos - 1;
  static const int defaultVideoMinutes = 5;
  static const int defaultMessagesPerDay = 10;
  static const int defaultSuperlikesPerDay = 1;
  static const int defaultRewindsPerDay = 3;
  static const int defaultGiftPoints = 50;
  static const int boostDurationMinutes = 30;
  static const int maxVoiceMessageSeconds = 15;
  static const int maxBioLength = 500;
  static const int maxInterests = 10;
  static const int maxRecentSearches = 20;
  static const int chatPageSize = 30;

  // ─── Speed Dating Durations (in minutes) ─────────────────────────────
  static const List<int> speedDatingDurations = [5, 10, 30];

  // ─── Gift Categories ─────────────────────────────────────────────────
  static const List<String> giftCategories = [
    'medical',
    'romantic',
    'luxury',
    'foodDrink',
    'tech',
    'nature',
    'fun',
    'special',
  ];

  // ─── Subscription Features ───────────────────────────────────────────
  static const Map<SubscriptionPlan, Map<String, dynamic>> planFeatures = {
    SubscriptionPlan.free: {
      'dailyMessages': 3,
      'dailyLikes': 3,
      'monthlySuperLikes': 1,
      'monthlyVideoMinutes': 0,
      'dailyRewinds': 3,
      'price': 0.0,
      'canSeeWhoLikedYou': false,
      'freeBoost': false,
      'adRefillMessages': 3,
      'adRefillLikes': 3,
      'adRefillRewinds': 3,
    },
    SubscriptionPlan.tech: {
      'dailyMessages': 10,
      'dailyLikes': 10,
      'dailySuperLikes': 3,
      'monthlySuperLikes': 0,
      'monthlyVideoMinutes': 30,
      'dailyRewinds': 10,
      'price': 1.99,
      'canSeeWhoLikedYou': false,
      'freeBoost': false,
      'adRefillMessages': 3,
      'adRefillLikes': 3,
      'adRefillRewinds': 0,
    },
    SubscriptionPlan.college: {
      'dailyMessages': -1,
      'dailyLikes': 25,
      'monthlySuperLikes': 5,
      'monthlyVideoMinutes': 300,
      'dailyRewinds': -1,
      'price': 4.99,
      'canSeeWhoLikedYou': false,
      'freeBoost': false,
      'adRefillMessages': 3,
      'adRefillLikes': 3,
      'adRefillRewinds': 0,
    },
    SubscriptionPlan.nurse: {
      'dailyMessages': -1,
      'dailyLikes': -1,
      'monthlySuperLikes': -1,
      'monthlyVideoMinutes': 1000,
      'dailyRewinds': -1,
      'price': 14.99,
      'canSeeWhoLikedYou': true,
      'freeBoost': true,
      'adRefillMessages': 0,
      'adRefillLikes': 0,
      'adRefillRewinds': 0,
    },
    SubscriptionPlan.doctor: {
      'dailyMessages': -1,
      'dailyLikes': -1,
      'monthlySuperLikes': -1,
      'monthlyVideoMinutes': 3500,
      'dailyRewinds': -1,
      'price': 39.99,
      'canSeeWhoLikedYou': true,
      'freeBoost': true,
      'unlimitedBoost': true,
      'adRefillMessages': 0,
      'adRefillLikes': 0,
      'adRefillRewinds': 0,
    },
  };
}

// ─── Subscription Plans ──────────────────────────────────────────────────────
enum SubscriptionPlan {
  free('free', 'Free'),
  tech('tech', 'Tech'),
  college('college', 'College'),
  nurse('nurse', 'Nurse'),
  doctor('doctor', 'Doctor');

  const SubscriptionPlan(this.value, this.displayName);
  final String value;
  final String displayName;

  static SubscriptionPlan fromString(String? value) {
    return SubscriptionPlan.values.firstWhere(
      (plan) => plan.value == value,
      orElse: () => SubscriptionPlan.free,
    );
  }
}

// ─── Shift Types ─────────────────────────────────────────────────────────────
enum ShiftType {
  dayShift('dayShift', 'Day Shift'),
  nightShift('nightShift', 'Night Shift'),
  rotatingShift('rotatingShift', 'Rotating Shift'),
  flexible('flexible', 'Flexible');

  const ShiftType(this.value, this.displayName);
  final String value;
  final String displayName;

  static ShiftType fromString(String? value) {
    return ShiftType.values.firstWhere(
      (s) => s.value == value,
      orElse: () => ShiftType.dayShift,
    );
  }
}

// ─── Gender Options ──────────────────────────────────────────────────────────
enum DatingWindow {
  afterShift('afterShift', 'After Shift'),
  daysOff('daysOff', 'Days Off'),
  morningCoffee('morningCoffee', 'Morning Coffee'),
  eveningDinner('eveningDinner', 'Evening Dinner'),
  flexible('flexible', 'Flexible');

  const DatingWindow(this.value, this.displayName);
  final String value;
  final String displayName;

  static DatingWindow fromString(String? value) {
    return DatingWindow.values.firstWhere(
      (window) => window.value == value,
      orElse: () => DatingWindow.flexible,
    );
  }
}

enum Gender {
  male('male', 'Male'),
  female('female', 'Female'),
  nonBinary('nonBinary', 'Non-Binary'),
  other('other', 'Other'),
  preferNotToSay('preferNotToSay', 'Prefer Not to Say');

  const Gender(this.value, this.displayName);
  final String value;
  final String displayName;

  static Gender fromString(String? value) {
    return Gender.values.firstWhere(
      (g) => g.value == value,
      orElse: () => Gender.preferNotToSay,
    );
  }
}

// ─── Looking For ─────────────────────────────────────────────────────────────
enum LookingFor {
  relationship('relationship', 'Relationship'),
  friendship('friendship', 'Friendship'),
  dating('dating', 'Casual Dating'),
  networking('networking', 'Professional Networking'),
  notSure('notSure', 'Not Sure Yet');

  const LookingFor(this.value, this.displayName);
  final String value;
  final String displayName;

  static LookingFor fromString(String? value) {
    return LookingFor.values.firstWhere(
      (l) => l.value == value,
      orElse: () => LookingFor.notSure,
    );
  }
}

// ─── Message Types ───────────────────────────────────────────────────────────
enum HealthcareCredentialType {
  healthcareWorker('healthcareWorker', 'Healthcare Worker Verified'),
  nursingStudent('nursingStudent', 'Nursing Student Verified'),
  travelNurse('travelNurse', 'Travel Nurse Verified'),
  agencyPartner('agencyPartner', 'Agency Partner Verified'),
  collegePartner('collegePartner', 'College Partner Verified');

  const HealthcareCredentialType(this.value, this.displayName);
  final String value;
  final String displayName;

  static HealthcareCredentialType fromString(String? value) {
    return HealthcareCredentialType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => HealthcareCredentialType.healthcareWorker,
    );
  }
}

enum MessageType {
  text('text'),
  image('image'),
  gift('gift'),
  videoCall('videoCall'),
  system('system'),
  voiceNote('voiceNote');

  const MessageType(this.value);
  final String value;

  static MessageType fromString(String? value) {
    return MessageType.values.firstWhere(
      (m) => m.value == value,
      orElse: () => MessageType.text,
    );
  }
}

// ─── Gift Category Enum ──────────────────────────────────────────────────────
enum GiftCategory {
  medical('medical', 'Medical'),
  romantic('romantic', 'Romantic'),
  luxury('luxury', 'Luxury'),
  foodDrink('foodDrink', 'Food & Drink'),
  tech('tech', 'Tech'),
  nature('nature', 'Nature'),
  fun('fun', 'Fun'),
  special('special', 'Special');

  const GiftCategory(this.value, this.displayName);
  final String value;
  final String displayName;

  static GiftCategory fromString(String? value) {
    return GiftCategory.values.firstWhere(
      (c) => c.value == value,
      orElse: () => GiftCategory.fun,
    );
  }
}

// ─── Like Types ──────────────────────────────────────────────────────────────
enum LikeType {
  like('like'),
  superlike('superlike');

  const LikeType(this.value);
  final String value;

  static LikeType fromString(String? value) {
    return LikeType.values.firstWhere(
      (l) => l.value == value,
      orElse: () => LikeType.like,
    );
  }
}

// ─── Speed Dating Room Status ────────────────────────────────────────────────
enum RoomStatus {
  waiting('waiting'),
  active('active'),
  completed('completed'),
  cancelled('cancelled');

  const RoomStatus(this.value);
  final String value;

  static RoomStatus fromString(String? value) {
    return RoomStatus.values.firstWhere(
      (r) => r.value == value,
      orElse: () => RoomStatus.waiting,
    );
  }
}

// ─── Report Reasons ──────────────────────────────────────────────────────────
enum ReportReason {
  inappropriate('inappropriate', 'Inappropriate Content'),
  spam('spam', 'Spam'),
  harassment('harassment', 'Harassment'),
  fakeProfile('fakeProfile', 'Fake Profile'),
  scam('scam', 'Scam'),
  underage('underage', 'Underage User'),
  other('other', 'Other');

  const ReportReason(this.value, this.displayName);
  final String value;
  final String displayName;
}
