# Nurse Singles International

Flutter + Firebase mobile app for Nurse Singles, a healthcare-focused dating and video-chat experience.

## Stack

- Flutter
- Firebase Auth, Firestore, Storage, Messaging, Analytics, Crashlytics, App Check
- Firebase Cloud Functions
- Zego Cloud video calls with server-issued Token04 authentication
- RevenueCat subscriptions
- Google Mobile Ads rewarded ads

## Local Setup

1. Install Flutter and Android Studio.
2. Add Firebase mobile config locally:
   - `lib/firebase_options.dart`
   - `android/app/google-services.json`
3. Install Flutter packages:

```bash
flutter pub get
```

4. Install Functions packages:

```bash
npm --prefix functions install
```

5. Configure Zego Cloud for Functions:

```bash
firebase functions:secrets:set ZEGO_SERVER_SECRET
```

Set `ZEGO_APP_ID` as the Functions parameter when the Firebase CLI prompts during deploy, or in the project-specific Functions environment file used by your deployment flow.

6. Configure the RevenueCat server API key used by the purchase sync callable:

```bash
firebase functions:secrets:set REVENUECAT_API_KEY
```

Use a RevenueCat secret API key here. Keep the public SDK key in the Flutter app only for client SDK configuration.

## Validation

```bash
flutter analyze --no-pub
npm --prefix functions run lint
flutter build apk --debug --target-platform android-arm64 --no-pub
flutter build appbundle --release --no-pub --no-shrink
```

## Google Play Release Notes

- Create `android/key.properties` and a release upload keystore before uploading to Play.
- Keep Zego server secret, RevenueCat webhooks, service accounts, and any production secrets out of the Flutter app.
- Complete Google Play Data Safety, account deletion URL, privacy policy, terms, content reporting, blocking, and moderation review before production launch.
