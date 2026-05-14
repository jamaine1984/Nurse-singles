import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:purchases_flutter/purchases_flutter.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/runtime_config.dart';

/// Provides the singleton [PaymentService] instance.
final paymentServiceProvider = Provider<PaymentService>((ref) {
  return PaymentService.instance;
});

/// RevenueCat-backed in-app purchase / subscription service.
class PaymentService {
  PaymentService._();

  factory PaymentService() => instance;

  static final PaymentService instance = PaymentService._();

  bool _initialized = false;
  String? _identifiedUserId;
  Future<void>? _initializing;
  final FirebaseFunctions _functions = FirebaseFunctions.instance;

  /// Whether RevenueCat has been initialized.
  bool get isInitialized => _initialized;

  // ─── Initialization ──────────────────────────────────────────────────

  /// Call once during app startup.
  ///
  /// Uses the public SDK key from build-time configuration. Pass an optional
  /// [userId] to link the RevenueCat customer with your Firebase UID.
  Future<void> initRevenueCat({String? userId}) =>
      ensureInitialized(userId: userId);

  /// Ensures the SDK is configured before purchase, restore, or offerings work.
  ///
  /// RevenueCat purchases must be tied to the Firebase UID so the backend can
  /// verify entitlements and update Firestore limits for the same account.
  Future<void> ensureInitialized({String? userId}) async {
    final resolvedUserId = userId ?? FirebaseAuth.instance.currentUser?.uid;

    if (_initialized) {
      if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
        await _logInRevenueCat(resolvedUserId);
      }
      return;
    }

    final pending = _initializing;
    if (pending != null) {
      await pending;
      if (resolvedUserId != null && resolvedUserId.isNotEmpty) {
        await _logInRevenueCat(resolvedUserId);
      }
      return;
    }

    _initializing = _configureRevenueCat(resolvedUserId);
    try {
      await _initializing;
    } finally {
      _initializing = null;
    }
  }

  Future<void> _configureRevenueCat(String? userId) async {
    try {
      final apiKey = AppConstants.revenueCatApiKey;
      if (apiKey.isEmpty) {
        debugPrint('[PaymentService] RevenueCat public SDK key is missing');
        return;
      }
      if (kIsWeb && RuntimeConfig.revenueCatWebPublicApiKey.isEmpty) {
        debugPrint(
          '[PaymentService] REVENUECAT_WEB_PUBLIC_API_KEY is missing; '
          'web billing may not return Web Billing products.',
        );
      }

      await Purchases.setLogLevel(kDebugMode ? LogLevel.debug : LogLevel.warn);

      final configuration = PurchasesConfiguration(apiKey);

      if (userId != null) {
        configuration.appUserID = userId;
      }

      await Purchases.configure(configuration);
      _initialized = true;
      debugPrint('[PaymentService] RevenueCat initialized');
    } catch (e) {
      debugPrint('[PaymentService] RevenueCat init failed: $e');
    }
  }

  Future<void> _logInRevenueCat(String userId) async {
    if (_identifiedUserId == userId) return;
    try {
      await Purchases.logIn(userId);
      _identifiedUserId = userId;
    } catch (e) {
      debugPrint('[PaymentService] identify error: $e');
    }
  }

  // ─── Offerings ───────────────────────────────────────────────────────

  /// Returns the current RevenueCat offerings, which contain the available
  /// subscription packages.
  Future<Offerings?> getOfferings() async {
    await ensureInitialized();
    if (!_initialized) return null;
    try {
      return await Purchases.getOfferings();
    } catch (e) {
      debugPrint('[PaymentService] getOfferings error: $e');
      return null;
    }
  }

  // ─── Purchase ────────────────────────────────────────────────────────

  /// Initiates a purchase flow for the given [package].
  ///
  /// Returns the [CustomerInfo] after a successful purchase, or `null`
  /// when the user cancels or an error occurs.
  Future<CustomerInfo?> purchasePackage(Package package) async {
    await ensureInitialized();
    if (!_initialized) return null;
    try {
      final result = await Purchases.purchase(PurchaseParams.package(package));
      debugPrint('[PaymentService] Purchase successful');
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[PaymentService] Purchase cancelled by user');
      } else {
        debugPrint('[PaymentService] Purchase error: $code ${e.message}');
      }
      return null;
    } catch (e) {
      debugPrint('[PaymentService] Unexpected purchase error: $e');
      return null;
    }
  }

  // ─── Restore ─────────────────────────────────────────────────────────

  Future<List<StoreProduct>> getVideoMinuteProducts() async {
    await ensureInitialized();
    if (!_initialized) return const [];
    if (kIsWeb) {
      debugPrint(
        '[PaymentService] Flutter Web uses RevenueCat offerings/packages; '
        'direct getProducts for video minutes is not available.',
      );
      return const [];
    }

    try {
      final products = await Purchases.getProducts(
        AppConstants.videoMinuteProductIds,
        productCategory: ProductCategory.nonSubscription,
      );
      products.sort(
        (a, b) => AppConstants.videoMinuteProductIds
            .indexOf(a.identifier)
            .compareTo(
              AppConstants.videoMinuteProductIds.indexOf(b.identifier),
            ),
      );
      return products;
    } catch (e) {
      debugPrint('[PaymentService] getVideoMinuteProducts error: $e');
      return const [];
    }
  }

  Future<List<StoreProduct>> getSubscriptionProducts() async {
    await ensureInitialized();
    if (!_initialized) return const [];
    if (kIsWeb) {
      debugPrint(
        '[PaymentService] Flutter Web uses RevenueCat offerings/packages; '
        'direct getProducts for subscriptions is not available.',
      );
      return const [];
    }

    const productIds = [
      AppConstants.monthlyProductId,
      AppConstants.monthlyBasePlanProductId,
      AppConstants.techMonthly,
      AppConstants.techMonthlyBasePlan,
      AppConstants.collegeMonthly,
      AppConstants.collegeMonthlyBasePlan,
      AppConstants.nurseMonthly,
      AppConstants.nurseMonthlyBasePlan,
      AppConstants.doctorMonthly,
      AppConstants.doctorMonthlyBasePlan,
    ];

    try {
      final products = await Purchases.getProducts(
        productIds,
        productCategory: ProductCategory.subscription,
      );
      products.sort(
        (a, b) => productIds
            .indexOf(a.identifier)
            .compareTo(productIds.indexOf(b.identifier)),
      );
      return products;
    } catch (e) {
      debugPrint('[PaymentService] getSubscriptionProducts error: $e');
      return const [];
    }
  }

  Future<RevenueCatSyncResult?> purchaseVideoMinuteProduct(
    StoreProduct product,
  ) async {
    await ensureInitialized();
    if (!_initialized) return null;

    try {
      await Purchases.purchase(PurchaseParams.storeProduct(product));
      return await syncRevenueCatCustomer();
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[PaymentService] Video minutes purchase cancelled');
      } else {
        debugPrint(
          '[PaymentService] Video minutes purchase error: $code ${e.message}',
        );
      }
      return null;
    } catch (e) {
      debugPrint(
        '[PaymentService] Unexpected video minutes purchase error: $e',
      );
      return null;
    }
  }

  Future<CustomerInfo?> purchaseSubscriptionProduct(
    StoreProduct product,
  ) async {
    await ensureInitialized();
    if (!_initialized) return null;

    try {
      final result = await Purchases.purchase(
        PurchaseParams.storeProduct(product),
      );
      debugPrint('[PaymentService] Subscription product purchase successful');
      return result.customerInfo;
    } on PlatformException catch (e) {
      final code = PurchasesErrorHelper.getErrorCode(e);
      if (code == PurchasesErrorCode.purchaseCancelledError) {
        debugPrint('[PaymentService] Subscription purchase cancelled');
      } else {
        debugPrint(
          '[PaymentService] Subscription purchase error: $code ${e.message}',
        );
      }
      return null;
    } catch (e) {
      debugPrint('[PaymentService] Unexpected subscription purchase error: $e');
      return null;
    }
  }

  /// Restores any previous purchases for the current user.
  Future<CustomerInfo?> restorePurchases() async {
    await ensureInitialized();
    if (!_initialized) return null;
    if (kIsWeb) {
      debugPrint(
        '[PaymentService] restorePurchases is not available on Flutter Web.',
      );
      return null;
    }
    try {
      final customerInfo = await Purchases.restorePurchases();
      debugPrint('[PaymentService] Restore successful');
      return customerInfo;
    } catch (e) {
      debugPrint('[PaymentService] Restore error: $e');
      return null;
    }
  }

  // ─── Customer Info ───────────────────────────────────────────────────

  /// Returns the latest [CustomerInfo] from RevenueCat.
  Future<CustomerInfo?> getCustomerInfo() async {
    await ensureInitialized();
    if (!_initialized) return null;
    try {
      return await Purchases.getCustomerInfo();
    } catch (e) {
      debugPrint('[PaymentService] getCustomerInfo error: $e');
      return null;
    }
  }

  // ─── Subscription Check ──────────────────────────────────────────────

  /// Maps the user's active RevenueCat entitlements to a [SubscriptionPlan].
  ///
  /// Entitlement identifiers must match the entitlement names configured in
  /// the RevenueCat dashboard:
  ///   - `nurse_singles_pro` / `Nurse Singles Pro`
  ///   - `doctor_tier`
  ///   - `nurse_tier`
  ///   - `college_tier`
  ///   - `tech_tier`
  Future<SubscriptionPlan> checkSubscription() async {
    await ensureInitialized();
    if (!_initialized) return SubscriptionPlan.free;

    try {
      final customerInfo = await Purchases.getCustomerInfo();
      final entitlements = customerInfo.entitlements.active;

      if (entitlements.containsKey('doctor_tier')) {
        return SubscriptionPlan.doctor;
      }
      if (entitlements.containsKey('nurse_tier')) return SubscriptionPlan.nurse;
      if (entitlements.containsKey('college_tier')) {
        return SubscriptionPlan.college;
      }
      if (entitlements.containsKey('tech_tier')) return SubscriptionPlan.tech;
      if (AppConstants.nurseSinglesProEntitlementAliases.any(
        entitlements.containsKey,
      )) {
        return SubscriptionPlan.nurse;
      }

      return SubscriptionPlan.free;
    } catch (e) {
      debugPrint('[PaymentService] checkSubscription error: $e');
      return SubscriptionPlan.free;
    }
  }

  /// Asks the backend to sync trusted RevenueCat entitlements and purchases.
  ///
  /// The callable uses the current Firebase Auth UID as the RevenueCat
  /// `app_user_id`, verifies the customer on the server, credits unprocessed
  /// video-minute consumables once, and updates the user's stored plan.
  Future<RevenueCatSyncResult> syncRevenueCatCustomer() async {
    await ensureInitialized();
    final callable = _functions.httpsCallable('syncRevenueCatCustomer');
    final response = await callable.call<Map<String, dynamic>>();
    return RevenueCatSyncResult.fromMap(response.data);
  }

  // ─── Identify / Logout ──────────────────────────────────────────────

  /// Associates a Firebase UID with the RevenueCat customer.
  Future<void> identify(String userId) async {
    await ensureInitialized(userId: userId);
    if (!_initialized) return;
  }

  /// Resets the RevenueCat user (call on sign-out).
  Future<void> logout() async {
    if (!_initialized) return;
    try {
      await Purchases.logOut();
      _identifiedUserId = null;
    } catch (e) {
      debugPrint('[PaymentService] logout error: $e');
    }
  }
}

class RevenueCatSyncResult {
  const RevenueCatSyncResult({
    required this.plan,
    required this.creditedVideoMinutes,
    required this.newVideoMinutes,
  });

  final SubscriptionPlan plan;
  final int creditedVideoMinutes;
  final int newVideoMinutes;

  factory RevenueCatSyncResult.fromMap(Map<String, dynamic> data) {
    return RevenueCatSyncResult(
      plan: SubscriptionPlan.fromString(data['plan'] as String?),
      creditedVideoMinutes:
          (data['creditedVideoMinutes'] as num?)?.toInt() ?? 0,
      newVideoMinutes: (data['newVideoMinutes'] as num?)?.toInt() ?? 0,
    );
  }
}
