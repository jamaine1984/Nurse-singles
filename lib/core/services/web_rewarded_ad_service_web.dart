import 'dart:js_interop';
import 'dart:js_interop_unsafe';

import 'package:flutter/foundation.dart';
import 'package:nightingale_heart/core/config/runtime_config.dart';
import 'package:web/web.dart' as web;

class WebRewardedAdService {
  WebRewardedAdService._();

  static final WebRewardedAdService instance = WebRewardedAdService._();

  String _unavailableReason = 'Web rewarded ads are not configured yet.';

  String get unavailableReason => _unavailableReason;

  bool get isRewardedAdReady {
    final unitPath = RuntimeConfig.googleAdManagerRewardedAdUnitPath;
    return unitPath.isNotEmpty && _bridge != null;
  }

  JSObject? get _bridge =>
      web.window.getProperty<JSObject?>('nurseSinglesAds'.toJS);

  Future<void> initialize() async {
    if (RuntimeConfig.adsensePublisherId.isEmpty) {
      debugPrint('[WebRewardedAdService] ADSENSE_PUBLISHER_ID missing.');
    }
    if (RuntimeConfig.googleAdManagerRewardedAdUnitPath.isEmpty) {
      _unavailableReason =
          'Google Ad Manager rewarded inventory is not configured for web yet.';
      debugPrint('[WebRewardedAdService] GAM rewarded ad unit path missing.');
      return;
    }
    if (_bridge == null) {
      _unavailableReason = 'Web rewarded ad bridge is not loaded yet.';
      debugPrint('[WebRewardedAdService] Web rewarded ad bridge missing.');
      return;
    }
    _unavailableReason = '';
  }

  void loadRewardedAd() {
    // GPT rewarded slots are requested when the user opts in, not preloaded by
    // Flutter. Keeping this as a no-op preserves the existing mobile call sites.
  }

  Future<bool> showRewardedAdWithCallback({
    required void Function(String rewardType, int amount) onReward,
  }) async {
    final unitPath = RuntimeConfig.googleAdManagerRewardedAdUnitPath;
    final bridge = _bridge;
    if (unitPath.isEmpty || bridge == null) {
      await initialize();
      return false;
    }

    try {
      final promise = bridge.callMethod<JSPromise<JSAny?>>(
        'showRewardedAd'.toJS,
        unitPath.toJS,
      );
      final jsResult = await promise.toDart;
      final result = jsResult?.dartify();
      if (result is! Map) {
        _unavailableReason = 'No rewarded ad result was returned.';
        return false;
      }

      final granted = result['granted'] == true;
      if (granted) {
        final rewardType = result['rewardType']?.toString() ?? 'reward';
        final rawAmount = result['amount'];
        final amount = rawAmount is num ? rawAmount.toInt() : 1;
        onReward(rewardType, amount);
        return true;
      }

      _unavailableReason =
          result['reason']?.toString() ??
          'Rewarded ad was closed before the reward was granted.';
      return false;
    } catch (error) {
      _unavailableReason = 'Could not show rewarded ad.';
      debugPrint('[WebRewardedAdService] showRewardedAd failed: $error');
      return false;
    }
  }

  Future<int?> showRewardedAd() async {
    var earned = false;
    final shown = await showRewardedAdWithCallback(
      onReward: (_, __) {
        earned = true;
      },
    );
    return shown && earned ? 1 : null;
  }
}
