import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

final usageLimitsServiceProvider = Provider<UsageLimitsService>((ref) {
  return UsageLimitsService();
});

class UsageLimitsService {
  final _firestore = FirebaseFirestore.instance;
  final _functions = FirebaseFunctions.instance;

  String _dailyDocId() {
    final now = DateTime.now().toUtc();
    return 'daily_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _monthlyDocId() {
    final now = DateTime.now().toUtc();
    return 'monthly_${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  DocumentReference _dailyDoc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('usage')
      .doc(_dailyDocId());

  DocumentReference _monthlyDoc(String userId) => _firestore
      .collection('users')
      .doc(userId)
      .collection('usage')
      .doc(_monthlyDocId());

  Future<Map<String, dynamic>> _getDailyUsage(String userId) async {
    final doc = await _dailyDoc(userId).get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return {
      'messagesSent': 0,
      'likesSent': 0,
      'messagesRefilled': 0,
      'likesRefilled': 0,
      'rewindsUsed': 0,
      'rewindsRefilled': 0,
      'superLikesSent': 0,
    };
  }

  Future<Map<String, dynamic>> _getMonthlyUsage(String userId) async {
    final doc = await _monthlyDoc(userId).get();
    if (doc.exists) return doc.data() as Map<String, dynamic>;
    return {'superLikesSent': 0, 'videoMinutesUsed': 0, 'videoPurchased': 0};
  }

  // ── Messages ──
  Future<int> getRemainingMessages(String userId, SubscriptionPlan plan) async {
    final limits = AppConstants.planFeatures[plan]!;
    final dailyLimit = limits['dailyMessages'] as int;
    if (dailyLimit == -1) return 999;
    final usage = await _getDailyUsage(userId);
    final sent = (usage['messagesSent'] ?? 0) as int;
    final refilled = (usage['messagesRefilled'] ?? 0) as int;
    return (dailyLimit + refilled) - sent;
  }

  Future<bool> canSendMessage(String userId, SubscriptionPlan plan) async {
    return (await getRemainingMessages(userId, plan)) > 0;
  }

  Future<void> recordMessageSent(String userId) async {
    await _recordUsageEvent(userId: userId, eventType: 'message');
  }

  Future<void> refillMessages(String userId, int amount) async {
    await _claimUsageRefill(
      userId: userId,
      usageType: 'messages',
      amount: amount,
    );
  }

  // ── Likes ──
  Future<int> getRemainingLikes(String userId, SubscriptionPlan plan) async {
    final limits = AppConstants.planFeatures[plan]!;
    final dailyLimit = limits['dailyLikes'] as int;
    if (dailyLimit == -1) return 999;
    final usage = await _getDailyUsage(userId);
    final sent = (usage['likesSent'] ?? 0) as int;
    final refilled = (usage['likesRefilled'] ?? 0) as int;
    return (dailyLimit + refilled) - sent;
  }

  Future<bool> canLike(String userId, SubscriptionPlan plan) async {
    return (await getRemainingLikes(userId, plan)) > 0;
  }

  Future<void> recordLike(String userId, {String? targetUserId}) async {
    await _recordUsageEvent(
      userId: userId,
      eventType: 'like',
      targetUserId: targetUserId,
    );
  }

  Future<void> refillLikes(String userId, int amount) async {
    await _claimUsageRefill(userId: userId, usageType: 'likes', amount: amount);
  }

  // ── SuperLikes ──
  Future<int> getRemainingSuperLikes(
    String userId,
    SubscriptionPlan plan,
  ) async {
    final limits = AppConstants.planFeatures[plan]!;
    final dailyLimit = limits['dailySuperLikes'] as int?;
    if (dailyLimit != null) {
      if (dailyLimit == -1) return 999;
      final usage = await _getDailyUsage(userId);
      final sent = (usage['superLikesSent'] ?? 0) as int;
      return dailyLimit - sent;
    }

    final monthlyLimit = limits['monthlySuperLikes'] as int;
    if (monthlyLimit == -1) return 999;
    final usage = await _getMonthlyUsage(userId);
    final sent = (usage['superLikesSent'] ?? 0) as int;
    return monthlyLimit - sent;
  }

  Future<void> recordSuperLike(String userId, {String? targetUserId}) async {
    await _recordUsageEvent(
      userId: userId,
      eventType: 'superlike',
      targetUserId: targetUserId,
    );
  }

  // ── Video Minutes ──
  // Rewinds
  Future<int> getRemainingRewinds(String userId, SubscriptionPlan plan) async {
    final limits = AppConstants.planFeatures[plan]!;
    final dailyLimit = limits['dailyRewinds'] as int? ?? 0;
    if (dailyLimit == -1) return 999;
    final usage = await _getDailyUsage(userId);
    final used = (usage['rewindsUsed'] ?? 0) as int;
    final refilled = (usage['rewindsRefilled'] ?? 0) as int;
    return (dailyLimit + refilled) - used;
  }

  Future<bool> canRewind(String userId, SubscriptionPlan plan) async {
    return (await getRemainingRewinds(userId, plan)) > 0;
  }

  Future<void> recordRewind(String userId) async {
    await _recordUsageEvent(userId: userId, eventType: 'rewind');
  }

  Future<void> refillRewinds(String userId, int amount) async {
    await _claimUsageRefill(
      userId: userId,
      usageType: 'rewinds',
      amount: amount,
    );
  }

  Future<int> getRemainingVideoMinutes(
    String userId,
    SubscriptionPlan plan,
  ) async {
    final limits = AppConstants.planFeatures[plan]!;
    final monthlyLimit = limits['monthlyVideoMinutes'] as int;
    final usage = await _getMonthlyUsage(userId);
    final used = (usage['videoMinutesUsed'] ?? 0) as int;
    final purchased = (usage['videoPurchased'] ?? 0) as int;
    return (monthlyLimit + purchased) - used;
  }

  Future<void> deductVideoMinutes(String userId, int minutes) async {
    throw UnsupportedError(
      'Video minutes are deducted by completeZegoCallSession.',
    );
  }

  Future<void> addPurchasedVideoMinutes(String userId, int minutes) async {
    throw UnsupportedError(
      'Purchased video minutes are synced by syncRevenueCatCustomer.',
    );
  }

  // ── Boost ──
  Future<void> recordBoost(String userId) async {
    final callable = _functions.httpsCallable('activateProfileBoost');
    await callable.call<Map<String, dynamic>>({'userId': userId});
  }

  Future<void> _recordUsageEvent({
    required String userId,
    required String eventType,
    String? targetUserId,
  }) async {
    final callable = _functions.httpsCallable('recordUsageEvent');
    await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'eventType': eventType,
      if (targetUserId != null) 'targetUserId': targetUserId,
    });
  }

  Future<void> _claimUsageRefill({
    required String userId,
    required String usageType,
    required int amount,
  }) async {
    final callable = _functions.httpsCallable('claimUsageRefill');
    await callable.call<Map<String, dynamic>>({
      'userId': userId,
      'usageType': usageType,
      'amount': amount,
    });
  }
}
