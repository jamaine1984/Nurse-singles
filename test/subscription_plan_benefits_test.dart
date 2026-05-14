import 'package:flutter_test/flutter_test.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

void main() {
  group('subscription plan benefits', () {
    test('free plan limits match product requirements', () {
      final features = AppConstants.planFeatures[SubscriptionPlan.free]!;

      expect(features['dailyMessages'], 3);
      expect(features['dailyLikes'], 3);
      expect(features['monthlySuperLikes'], 1);
      expect(features['monthlyVideoMinutes'], 0);
      expect(features['dailyRewinds'], 3);
      expect(features['adRefillRewinds'], 3);
      expect(features['canSeeWhoLikedYou'], isFalse);
      expect(features['freeBoost'], isFalse);
    });

    test('tech plan limits match product requirements', () {
      final features = AppConstants.planFeatures[SubscriptionPlan.tech]!;

      expect(features['dailyMessages'], 10);
      expect(features['dailyLikes'], 10);
      expect(features['dailySuperLikes'], 3);
      expect(features['monthlyVideoMinutes'], 30);
      expect(features['dailyRewinds'], 10);
      expect(features['canSeeWhoLikedYou'], isFalse);
      expect(features['freeBoost'], isFalse);
    });

    test('college plan limits match product requirements', () {
      final features = AppConstants.planFeatures[SubscriptionPlan.college]!;

      expect(features['dailyMessages'], -1);
      expect(features['dailyLikes'], 25);
      expect(features['monthlySuperLikes'], 5);
      expect(features['monthlyVideoMinutes'], 300);
      expect(features['dailyRewinds'], -1);
      expect(features['adRefillLikes'], 3);
    });

    test('nurse plan limits match product requirements', () {
      final features = AppConstants.planFeatures[SubscriptionPlan.nurse]!;

      expect(features['dailyMessages'], -1);
      expect(features['dailyLikes'], -1);
      expect(features['monthlySuperLikes'], -1);
      expect(features['monthlyVideoMinutes'], 1000);
      expect(features['dailyRewinds'], -1);
      expect(features['price'], 14.99);
      expect(features['canSeeWhoLikedYou'], isTrue);
      expect(features['freeBoost'], isTrue);
    });

    test('doctor plan limits match product requirements', () {
      final features = AppConstants.planFeatures[SubscriptionPlan.doctor]!;

      expect(features['dailyMessages'], -1);
      expect(features['dailyLikes'], -1);
      expect(features['monthlySuperLikes'], -1);
      expect(features['monthlyVideoMinutes'], 3500);
      expect(features['dailyRewinds'], -1);
      expect(features['canSeeWhoLikedYou'], isTrue);
      expect(features['freeBoost'], isTrue);
      expect(features['unlimitedBoost'], isTrue);
    });
  });
}
