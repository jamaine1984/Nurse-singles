import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter/foundation.dart';

/// Reads runtime configuration from dart-defines first, then optional local
/// dotenv values for developer builds.
///
/// Production builds should pass values with `--dart-define` or the release
/// build script. Do not add `.env` to Flutter assets because it would be
/// bundled into the app package.
class RuntimeConfig {
  RuntimeConfig._();

  static String get revenueCatPublicApiKey {
    if (kIsWeb) {
      final webKey = _value(
        dartDefine: const String.fromEnvironment(
          'REVENUECAT_WEB_PUBLIC_API_KEY',
        ),
        envKeys: const ['REVENUECAT_WEB_PUBLIC_API_KEY'],
      );
      if (webKey.isNotEmpty) return webKey;
    }

    return _value(
      dartDefine: const String.fromEnvironment('REVENUECAT_PUBLIC_API_KEY'),
      envKeys: const ['REVENUECAT_PUBLIC_API_KEY', 'REVENUECAT_API_KEY'],
    );
  }

  static String get revenueCatWebPublicApiKey => _value(
    dartDefine: const String.fromEnvironment('REVENUECAT_WEB_PUBLIC_API_KEY'),
    envKeys: const ['REVENUECAT_WEB_PUBLIC_API_KEY'],
  );

  static int? get zegoAppId {
    final value = _value(
      dartDefine: const String.fromEnvironment('ZEGO_APP_ID'),
      legacyDartDefine: const String.fromEnvironment('ZEGOCLOUD_APP_ID'),
      envKeys: const ['ZEGO_APP_ID', 'ZEGOCLOUD_APP_ID'],
    );
    return value.isEmpty ? null : int.tryParse(value);
  }

  static String get zegoAppSign => _value(
    dartDefine: const String.fromEnvironment('ZEGO_APP_SIGN'),
    legacyDartDefine: const String.fromEnvironment('ZEGOCLOUD_APP_SIGN'),
    envKeys: const ['ZEGO_APP_SIGN', 'ZEGOCLOUD_APP_SIGN'],
  );

  static String get appCheckAndroidProvider => _value(
    dartDefine: const String.fromEnvironment('APP_CHECK_ANDROID_PROVIDER'),
    envKeys: const ['APP_CHECK_ANDROID_PROVIDER'],
  ).toLowerCase();

  static String get appCheckWebRecaptchaSiteKey => _value(
    dartDefine: const String.fromEnvironment(
      'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
    ),
    legacyDartDefine: const String.fromEnvironment(
      'APP_CHECK_WEB_RECAPTCHA_ENTERPRISE_SITE_KEY',
    ),
    envKeys: const [
      'APP_CHECK_WEB_RECAPTCHA_ENTERPRISE_SITE_KEY',
      'APP_CHECK_WEB_RECAPTCHA_SITE_KEY',
    ],
  );

  static String get appCheckWebProvider => _value(
    dartDefine: const String.fromEnvironment('APP_CHECK_WEB_PROVIDER'),
    envKeys: const ['APP_CHECK_WEB_PROVIDER'],
  );

  static String get adsensePublisherId => _value(
    dartDefine: const String.fromEnvironment('ADSENSE_PUBLISHER_ID'),
    envKeys: const ['ADSENSE_PUBLISHER_ID'],
  );

  static String get googleAdManagerRewardedAdUnitPath => _value(
    dartDefine: const String.fromEnvironment('GAM_REWARDED_AD_UNIT_PATH'),
    legacyDartDefine: const String.fromEnvironment(
      'GOOGLE_AD_MANAGER_REWARDED_AD_UNIT_PATH',
    ),
    envKeys: const [
      'GAM_REWARDED_AD_UNIT_PATH',
      'GOOGLE_AD_MANAGER_REWARDED_AD_UNIT_PATH',
    ],
  );

  static String _value({
    required String dartDefine,
    String legacyDartDefine = '',
    required List<String> envKeys,
  }) {
    final fromDefine = _clean(dartDefine);
    if (fromDefine.isNotEmpty) return fromDefine;

    final fromLegacyDefine = _clean(legacyDartDefine);
    if (fromLegacyDefine.isNotEmpty) return fromLegacyDefine;

    if (!dotenv.isInitialized) return '';
    for (final key in envKeys) {
      final value = _clean(dotenv.maybeGet(key));
      if (value.isNotEmpty) return value;
    }
    return '';
  }

  static String _clean(String? value) => (value ?? '').trim();
}
