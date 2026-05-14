class WebRewardedAdService {
  WebRewardedAdService._();

  static final WebRewardedAdService instance = WebRewardedAdService._();

  String get unavailableReason => 'Web rewarded ads are unavailable here.';

  bool get isRewardedAdReady => false;

  Future<void> initialize() async {}

  void loadRewardedAd() {}

  Future<bool> showRewardedAdWithCallback({
    required void Function(String rewardType, int amount) onReward,
  }) async {
    return false;
  }

  Future<int?> showRewardedAd() async => null;
}
