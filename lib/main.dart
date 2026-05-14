import 'dart:async';
import 'dart:ui';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_analytics/firebase_analytics.dart';
import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/localization/app_language.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/config/runtime_config.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/router/app_router.dart';
import 'package:nightingale_heart/core/services/admob_service.dart';
import 'package:nightingale_heart/core/services/push_notification_service.dart';
import 'package:nightingale_heart/core/services/video_call_service.dart';
import 'package:nightingale_heart/features/video_dating/widgets/incoming_call_listener.dart';
import 'package:nightingale_heart/firebase_options.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.dark,
      systemNavigationBarColor: Colors.white,
      systemNavigationBarIconBrightness: Brightness.dark,
    ),
  );

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);

  try {
    await dotenv.load(fileName: '.env');
  } catch (e) {
    if (!e.toString().contains('FileNotFoundError')) {
      debugPrint('[main] .env file failed to load: $e');
    }
  }

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
    await _configureFirebaseRuntime();
  } catch (error, stackTrace) {
    debugPrint('[main] Firebase startup failed: $error');
    runApp(StartupFailureApp(error: error, stackTrace: stackTrace));
    return;
  }

  unawaited(_initializeDeferredServices());

  runApp(const ProviderScope(child: NurseSinglesApp()));
}

Future<void> _configureFirebaseRuntime() async {
  _configureErrorReporting();
  await _enableAnalyticsSafely();
  await _activateAppCheckSafely();
  _configureFirestoreCacheSafely();
}

void _configureErrorReporting() {
  if (kIsWeb) {
    FlutterError.onError = (details) {
      FlutterError.presentError(details);
      debugPrint('[main] Flutter error: ${details.exception}');
    };
    PlatformDispatcher.instance.onError = (error, stackTrace) {
      debugPrint('[main] Unhandled web error: $error');
      return false;
    };
    return;
  }

  FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
  PlatformDispatcher.instance.onError = (error, stackTrace) {
    FirebaseCrashlytics.instance.recordError(error, stackTrace, fatal: true);
    return true;
  };

  unawaited(
    FirebaseCrashlytics.instance.setCrashlyticsCollectionEnabled(!kDebugMode),
  );
}

Future<void> _enableAnalyticsSafely() async {
  try {
    await FirebaseAnalytics.instance.setAnalyticsCollectionEnabled(!kDebugMode);
  } catch (error) {
    debugPrint('[main] Firebase Analytics setup skipped: $error');
  }
}

Future<void> _activateAppCheckSafely() async {
  try {
    if (kIsWeb) {
      final siteKey = RuntimeConfig.appCheckWebRecaptchaSiteKey;
      if (siteKey.isEmpty) {
        debugPrint(
          '[main] APP_CHECK_WEB_RECAPTCHA_SITE_KEY missing; '
          'App Check not activated on web.',
        );
        return;
      }
      await FirebaseAppCheck.instance.activate(
        webProvider: ReCaptchaV3Provider(siteKey),
      );
      return;
    }

    await FirebaseAppCheck.instance.activate(
      androidProvider: _androidAppCheckProvider(),
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (error) {
    debugPrint('[main] Firebase App Check setup skipped: $error');
  }
}

void _configureFirestoreCacheSafely() {
  try {
    FirebaseFirestore.instance.settings = const Settings(
      persistenceEnabled: true,
      cacheSizeBytes: Settings.CACHE_SIZE_UNLIMITED,
    );
  } catch (error) {
    debugPrint('[main] Firestore cache setup skipped: $error');
  }
}

AndroidProvider _androidAppCheckProvider() {
  final configuredProvider = RuntimeConfig.appCheckAndroidProvider;
  if (configuredProvider == 'debug') return AndroidProvider.debug;
  if (configuredProvider == 'playintegrity' ||
      configuredProvider == 'play_integrity') {
    return AndroidProvider.playIntegrity;
  }
  return kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity;
}

Future<void> _initializeDeferredServices() async {
  final initializers = <Future<void> Function()>[
    AdMobService.instance.initAdMob,
    () => VideoCallService().initZego(),
    () => PushNotificationService().initNotifications(),
  ];

  for (final initialize in initializers) {
    try {
      await initialize();
    } catch (error, stackTrace) {
      debugPrint('[main] Deferred service failed: $error');
      await _recordNonFatal(error, stackTrace);
    }
  }
}

Future<void> _recordNonFatal(Object error, StackTrace stackTrace) async {
  if (kIsWeb) return;
  try {
    await FirebaseCrashlytics.instance.recordError(error, stackTrace);
  } catch (recordError) {
    debugPrint('[main] Crashlytics record skipped: $recordError');
  }
}

class StartupFailureApp extends StatelessWidget {
  const StartupFailureApp({
    super.key,
    required this.error,
    required this.stackTrace,
  });

  final Object error;
  final StackTrace stackTrace;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        body: SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const Icon(Icons.health_and_safety, size: 48),
                const SizedBox(height: 16),
                const Text(
                  'Nurse Singles is temporarily unavailable.',
                  textAlign: TextAlign.center,
                  style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Please check your connection and try again.',
                  textAlign: TextAlign.center,
                ),
                if (kDebugMode) ...[
                  const SizedBox(height: 16),
                  Text(
                    error.toString(),
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 12),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class NurseSinglesApp extends ConsumerWidget {
  const NurseSinglesApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeProvider);
    final locale = ref.watch(localeProvider);
    final router = ref.watch(routerProvider);

    return MaterialApp.router(
      title: AppConstants.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      locale: locale,
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
      ],
      supportedLocales: AppLanguages.fullySupportedLocales,
      localeResolutionCallback: (locale, supportedLocales) {
        if (locale == null) return const Locale('en');
        final requestedCode = AppLanguages.normalizeFullySupportedCode(
          locale.languageCode,
        );
        for (final supported in supportedLocales) {
          if (supported.languageCode == requestedCode) {
            return supported;
          }
        }
        return const Locale('en');
      },
      builder: (context, child) {
        return IncomingCallListener(child: child ?? const SizedBox.shrink());
      },
      routerConfig: router,
    );
  }
}
