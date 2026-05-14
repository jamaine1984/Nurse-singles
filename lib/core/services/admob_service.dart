import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_mobile_ads/google_mobile_ads.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';

/// Provides the singleton [AdMobService] instance.
final adMobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService.instance;
});

/// Also expose under the original provider name for backward compat.
final admobServiceProvider = Provider<AdMobService>((ref) {
  return AdMobService.instance;
});

/// Google AdMob service that handles rewarded video ads.
///
/// Singleton pattern ensures the same initialized instance is used everywhere.
class AdMobService {
  AdMobService._();

  static final AdMobService instance = AdMobService._();

  bool _initialized = false;
  RewardedAd? _rewardedAd;
  bool _isAdLoading = false;

  /// Whether the Mobile Ads SDK has been initialized.
  bool get isInitialized => _initialized;

  /// Whether a rewarded ad is loaded and ready to show.
  bool get isRewardedAdReady => _rewardedAd != null;

  // ─── Initialization ──────────────────────────────────────────────────

  /// Initializes the Google Mobile Ads SDK.
  ///
  /// Call once during app startup **after** `WidgetsFlutterBinding.ensureInitialized()`.
  Future<void> initAdMob() async {
    if (_initialized) return;
    if (kIsWeb) {
      debugPrint('[AdMobService] Skipped on web; use AdSense web ads.');
      return;
    }
    try {
      await MobileAds.instance.initialize();
      _initialized = true;
      debugPrint('[AdMobService] Mobile Ads SDK initialized');

      // Pre-load the first rewarded ad
      loadRewardedAd();
    } catch (e) {
      debugPrint('[AdMobService] init error: $e');
    }
  }

  /// Alias for backward compatibility with older callers.
  Future<void> initialize() => initAdMob();

  // ─── Load Rewarded Ad ────────────────────────────────────────────────

  /// Loads a rewarded ad using the ad unit ID from [AppConstants].
  ///
  /// Does nothing if an ad is already loaded or currently loading.
  void loadRewardedAd() {
    if (kIsWeb) return;
    if (!_initialized) return;
    if (_rewardedAd != null || _isAdLoading) return;

    _isAdLoading = true;

    RewardedAd.load(
      adUnitId: AppConstants.admobRewardedId,
      request: const AdRequest(),
      rewardedAdLoadCallback: RewardedAdLoadCallback(
        onAdLoaded: (ad) {
          _rewardedAd = ad;
          _isAdLoading = false;
          debugPrint('[AdMobService] Rewarded ad loaded');

          // Set up full-screen callbacks on load (like nurse singles app)
          _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
            onAdDismissedFullScreenContent: (ad) {
              debugPrint('[AdMobService] Rewarded ad dismissed');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd(); // Pre-load next ad
            },
            onAdFailedToShowFullScreenContent: (ad, error) {
              debugPrint('[AdMobService] Failed to show ad: ${error.message}');
              ad.dispose();
              _rewardedAd = null;
              loadRewardedAd();
            },
          );
        },
        onAdFailedToLoad: (error) {
          _rewardedAd = null;
          _isAdLoading = false;
          debugPrint(
              '[AdMobService] Rewarded ad failed to load: ${error.message}');
          // Retry after 30 seconds (like nurse singles app)
          Future.delayed(const Duration(seconds: 30), loadRewardedAd);
        },
      ),
    );
  }

  // ─── Show Rewarded Ad (callback style) ───────────────────────────────

  /// Shows a rewarded ad and invokes [onReward] when the user earns the
  /// reward (i.e., watches the ad to completion).
  ///
  /// * [onReward] receives the reward type (String) and amount (int).
  /// * Returns `true` when the ad was shown **and dismissed**, `false` if
  ///   no ad was ready or an error occurred.
  ///
  /// This method waits until the ad is fully dismissed before returning,
  /// ensuring that the reward callback has already fired by the time the
  /// caller continues.
  Future<bool> showRewardedAdWithCallback({
    required void Function(String rewardType, int amount) onReward,
  }) async {
    if (kIsWeb) {
      debugPrint('[AdMobService] Rewarded ads are unavailable on web.');
      return false;
    }
    if (_rewardedAd == null) {
      debugPrint('[AdMobService] No rewarded ad available');
      loadRewardedAd();
      return false;
    }

    final completer = Completer<bool>();

    // Override callbacks so we can wait for dismissal.
    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMobService] Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(true);
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMobService] Failed to show ad: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete(false);
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          debugPrint(
            '[AdMobService] User earned reward: ${reward.type} x ${reward.amount}',
          );
          onReward(reward.type, reward.amount.toInt());
        },
      );
      // Wait until the ad is fully dismissed (not just presented).
      return await completer.future;
    } catch (e) {
      debugPrint('[AdMobService] Error showing ad: $e');
      if (!completer.isCompleted) completer.complete(false);
      return false;
    }
  }

  // ─── Show Rewarded Ad (simple style) ─────────────────────────────────

  /// Shows a rewarded ad and returns the reward amount on success.
  ///
  /// Returns `null` if no ad is available or the user dismisses early.
  /// Waits for the ad to be fully dismissed before returning.
  Future<int?> showRewardedAd() async {
    if (kIsWeb) {
      debugPrint('[AdMobService] Rewarded ads are unavailable on web.');
      return null;
    }
    if (_rewardedAd == null) {
      debugPrint('[AdMobService] No rewarded ad available');
      loadRewardedAd();
      return null;
    }

    int? rewardAmount;
    final completer = Completer<void>();

    _rewardedAd!.fullScreenContentCallback = FullScreenContentCallback(
      onAdDismissedFullScreenContent: (ad) {
        debugPrint('[AdMobService] Rewarded ad dismissed');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete();
      },
      onAdFailedToShowFullScreenContent: (ad, error) {
        debugPrint('[AdMobService] Failed to show ad: ${error.message}');
        ad.dispose();
        _rewardedAd = null;
        loadRewardedAd();
        if (!completer.isCompleted) completer.complete();
      },
    );

    try {
      await _rewardedAd!.show(
        onUserEarnedReward: (ad, reward) {
          rewardAmount = reward.amount.toInt();
          debugPrint(
              '[AdMobService] User earned reward: ${reward.amount} ${reward.type}');
        },
      );
      // Wait for the ad to be fully dismissed.
      await completer.future;
    } catch (e) {
      debugPrint('[AdMobService] Error showing ad: $e');
      return null;
    }

    return rewardAmount;
  }

  // ─── Dispose ─────────────────────────────────────────────────────────

  /// Disposes any loaded ad. Call when the service is no longer needed.
  void dispose() {
    _rewardedAd?.dispose();
    _rewardedAd = null;
  }
}
