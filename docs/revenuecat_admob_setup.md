# RevenueCat and AdMob Setup

This app uses RevenueCat for subscription purchase state, Firebase Cloud
Functions for trusted entitlement syncing, and Google Mobile Ads rewarded ads
for usage refills.

## Flutter packages

The app includes the current RevenueCat Flutter SDK packages:

```bash
flutter pub add purchases_flutter purchases_ui_flutter
```

Android billing is enabled through:

```xml
<uses-permission android:name="com.android.vending.BILLING" />
```

RevenueCat paywalls require `FlutterFragmentActivity` on Android.

## Local configuration

Use the RevenueCat public SDK key in local or build-time config:

```text
REVENUECAT_PUBLIC_API_KEY=<RevenueCat Android public SDK key>
REVENUECAT_ENTITLEMENT_ID=nurse_singles_pro
REVENUECAT_MONTHLY_PRODUCT_ID=nurse_monthly
```

The public SDK key is safe for the app. Do not put the RevenueCat REST API key
in Flutter code.

## RevenueCat dashboard

Create the Google Play products and RevenueCat objects with these identifiers:

| Plan | Product | Entitlement |
| --- | --- |
| Tech | `tech_monthly` | `tech_tier` |
| College | `college_monthly` | `college_tier` |
| Nurse | `nurse_monthly` | `nurse_tier` or `nurse_singles_pro` |
| Doctor | `doctor_monthly` | `doctor_tier` |

Attach the products to the `current` offering. The Flutter paywall reads
RevenueCat package/product prices first, so prices shown in the app follow the
real store values once RevenueCat and Google Play are connected.

Attach a RevenueCat Paywall to the `current` offering if using hosted paywalls.

## Backend secret

The backend sync function must use the RevenueCat REST API key, not the Flutter
SDK key:

```bash
firebase functions:secrets:set REVENUECAT_API_KEY
firebase deploy --only functions
```

The callable `syncRevenueCatCustomer` verifies the authenticated Firebase UID
against RevenueCat, then maps active entitlements into the app plan. The new
`nurse_singles_pro` entitlement maps to the Nurse plan.

## Customer Center

The Manage Subscription screen opens RevenueCat Customer Center after the SDK is
initialized. Use Customer Center for restore, cancellation, refund guidance, and
subscription support instead of building a custom support flow.

## AdMob

Android is configured with the real AdMob app ID:

```text
ca-app-pub-7587025688858323~3404981432
```

Rewarded usage refills use:

```text
ca-app-pub-7587025688858323/4885584060
```

For QA, register physical devices as AdMob test devices before repeatedly
loading or watching rewarded ads. Do not click or farm live ads during testing.

## Current entitlement and limit rules

| Plan | Key limits |
| --- | --- |
| Free | 3 likes/day, 3 messages/day, 1 superlike/month, 3 rewinds/day |
| Tech | 10 likes/day, 10 messages/day, 3 superlikes/day, 30 video minutes/month, 10 rewinds/day |
| College | 25 likes/day, unlimited messages, 5 superlikes/month, 300 video minutes/month, unlimited rewinds |
| Nurse | Unlimited likes, messages, superlikes, and rewinds; 1,000 video minutes/month |
| Doctor | Unlimited likes, messages, superlikes, boosts, and rewinds; 3,500 video minutes/month |

Refill rules:

| Limit | Refill |
| --- | --- |
| Free likes | Watch 3 rewarded ads |
| College likes | Watch 3 rewarded ads |
| Free rewinds | Watch 2 rewarded ads |

Subscription and usage limits are enforced in Cloud Functions. Flutter only
renders the UI state and calls the trusted backend.
