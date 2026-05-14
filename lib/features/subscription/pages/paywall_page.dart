import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/payment_service.dart';
import 'package:purchases_flutter/purchases_flutter.dart';

class PaywallPage extends ConsumerStatefulWidget {
  const PaywallPage({super.key});

  @override
  ConsumerState<PaywallPage> createState() => _PaywallPageState();
}

class _PaywallPageState extends ConsumerState<PaywallPage> {
  late Future<_SubscriptionCatalog> _catalogFuture;
  String? _busyProductId;

  static const _plans = [
    _PlanOffer(
      plan: SubscriptionPlan.tech,
      productIds: [
        AppConstants.techMonthly,
        AppConstants.techMonthlyBasePlan,
        AppConstants.techPackage,
      ],
      title: 'Tech Plan',
      subtitle: 'Light upgrade for healthcare singles testing the app.',
      accent: Color(0xFF0EA5A3),
      features: [
        '10 likes per day',
        '10 messages per day',
        '3 superlikes per day',
        '30 video minutes monthly',
        '10 rewinds daily',
      ],
    ),
    _PlanOffer(
      plan: SubscriptionPlan.college,
      productIds: [
        AppConstants.collegeMonthly,
        AppConstants.collegeMonthlyBasePlan,
        AppConstants.collegePackage,
      ],
      title: 'College Plan',
      subtitle: 'Built for nursing students and campus communities.',
      accent: Color(0xFF2563EB),
      features: [
        'Unlimited messages',
        '25 likes per day',
        'Unlimited rewinds',
        '300 video minutes monthly',
        'Ad refill when likes run out',
      ],
    ),
    _PlanOffer(
      plan: SubscriptionPlan.nurse,
      productIds: [
        AppConstants.nurseMonthly,
        AppConstants.nurseMonthlyBasePlan,
        AppConstants.nursePackage,
        AppConstants.monthlyProductId,
        AppConstants.monthlyBasePlanProductId,
        AppConstants.revenueCatMonthlyPackage,
      ],
      title: 'Nurse Plan',
      subtitle: 'Best fit for active nurses and allied health workers.',
      accent: Color(0xFF16A34A),
      featured: true,
      features: [
        'Unlimited likes and messages',
        'Unlimited superlikes',
        '1,000 video minutes monthly',
        'See who liked you',
        'Free profile boost',
      ],
    ),
    _PlanOffer(
      plan: SubscriptionPlan.doctor,
      productIds: [
        AppConstants.doctorMonthly,
        AppConstants.doctorMonthlyBasePlan,
        AppConstants.doctorPackage,
      ],
      title: 'Doctor Plan',
      subtitle: 'Premium visibility and video time for serious users.',
      accent: Color(0xFFDC2626),
      features: [
        'Unlimited likes and messages',
        'Unlimited superlikes',
        '3,500 video minutes monthly',
        'Unlimited profile boosts',
        'Priority profile visibility',
      ],
    ),
  ];

  @override
  void initState() {
    super.initState();
    _catalogFuture = _loadCatalog();
  }

  Future<_SubscriptionCatalog> _loadCatalog() async {
    final paymentService = ref.read(paymentServiceProvider);
    await paymentService.ensureInitialized();
    final offerings = await paymentService.getOfferings();
    final products = await paymentService.getSubscriptionProducts();
    final offering = kIsWeb
        ? offerings?.getOffering(AppConstants.revenueCatWebOffering) ??
              offerings?.current
        : offerings?.current;
    return _SubscriptionCatalog(
      offeringPackages: offering?.availablePackages ?? const [],
      storeProducts: products,
    );
  }

  Future<void> _buyPlan(_PlanOffer plan, _SubscriptionCatalog catalog) async {
    if (_busyProductId != null) return;

    final package = catalog.packageFor(plan.productIds);
    final product = catalog.productFor(plan.productIds);
    final productId = package?.storeProduct.identifier ?? product?.identifier;
    if (productId == null) {
      _showSnack(
        'This plan is visible, but the Play Console/RevenueCat product is not attached yet.',
        AppTheme.softAmber,
      );
      return;
    }

    setState(() => _busyProductId = productId);
    CustomerInfo? customerInfo;
    final paymentService = ref.read(paymentServiceProvider);
    if (package != null) {
      customerInfo = await paymentService.purchasePackage(package);
    } else if (product != null) {
      customerInfo = await paymentService.purchaseSubscriptionProduct(product);
    }

    if (customerInfo == null) {
      if (mounted) {
        setState(() => _busyProductId = null);
        _showSnack('Purchase was not completed.', AppTheme.warmRose);
      }
      return;
    }

    await _handleCustomerInfo(customerInfo, 'Subscription activated.');
  }

  Future<void> _restorePurchases() async {
    if (_busyProductId != null) return;
    if (kIsWeb) {
      _showSnack(
        'Web purchases are managed through RevenueCat Web Billing checkout.',
        AppTheme.softAmber,
      );
      return;
    }
    setState(() => _busyProductId = 'restore');
    final customerInfo = await ref
        .read(paymentServiceProvider)
        .restorePurchases();
    if (customerInfo == null) {
      if (mounted) {
        setState(() => _busyProductId = null);
        _showSnack('Could not restore purchases.', AppTheme.warmRose);
      }
      return;
    }
    await _handleCustomerInfo(customerInfo, 'Purchases restored.');
  }

  Future<void> _handleCustomerInfo(
    CustomerInfo customerInfo,
    String successPrefix,
  ) async {
    try {
      final syncResult = await ref
          .read(paymentServiceProvider)
          .syncRevenueCatCustomer();
      ref.invalidate(currentUserProvider);
      _showSnack(
        '$successPrefix Plan: ${syncResult.plan.displayName}',
        AppTheme.emerald,
      );
    } catch (error) {
      debugPrint('[PaywallPage] RevenueCat backend sync failed: $error');
      final hasPro = AppConstants.nurseSinglesProEntitlementAliases.any(
        customerInfo.entitlements.active.containsKey,
      );
      _showSnack(
        hasPro
            ? 'Purchase found. Backend sync still needs RevenueCat secret setup.'
            : 'Purchase status checked. No active Pro entitlement found yet.',
        hasPro ? AppTheme.softAmber : AppTheme.warmRose,
      );
    } finally {
      if (mounted) setState(() => _busyProductId = null);
    }
  }

  void _showSnack(String message, Color color) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message, style: GoogleFonts.plusJakartaSans()),
        behavior: SnackBarBehavior.floating,
        backgroundColor: color,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF6FAFB),
      appBar: AppBar(
        title: Text(
          'Nurse Singles Pro',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w700),
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh plans',
            onPressed: () {
              setState(() => _catalogFuture = _loadCatalog());
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: FutureBuilder<_SubscriptionCatalog>(
        future: _catalogFuture,
        builder: (context, snapshot) {
          final catalog = snapshot.data ?? _SubscriptionCatalog.empty;
          return ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
            children: [
              _PaywallHero(
                loading: snapshot.connectionState != ConnectionState.done,
                hasProducts: catalog.hasProducts,
              ),
              if (snapshot.hasError) ...[
                const SizedBox(height: 12),
                _CatalogWarning(
                  onRetry: () {
                    setState(() => _catalogFuture = _loadCatalog());
                  },
                ),
              ],
              const SizedBox(height: 16),
              ..._plans.map(
                (plan) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: _PlanCard(
                    plan: plan,
                    catalog: catalog,
                    busyProductId: _busyProductId,
                    onBuy: () => _buyPlan(plan, catalog),
                  ),
                ),
              ),
              const SizedBox(height: 8),
              if (!kIsWeb)
                OutlinedButton.icon(
                  onPressed: _busyProductId == null ? _restorePurchases : null,
                  icon: _busyProductId == 'restore'
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.restore_rounded),
                  label: const Text('Restore Purchases'),
                )
              else
                const _WebBillingNotice(),
              const SizedBox(height: 12),
              Text(
                kIsWeb
                    ? 'If products are not live yet, plans still display here so the screen never goes blank. Web purchases unlock when RevenueCat Web Billing products are attached to the current offering.'
                    : 'If products are not live yet, plans still display here so the screen never goes blank. Purchases unlock when Google Play products are imported into RevenueCat and attached to the current offering.',
                textAlign: TextAlign.center,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  height: 1.45,
                  color: const Color(0xFF64748B),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class _PaywallHero extends StatelessWidget {
  const _PaywallHero({required this.loading, required this.hasProducts});

  final bool loading;
  final bool hasProducts;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF075985), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: Row(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              color: Colors.white,
              size: 30,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Upgrade around your schedule',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white,
                    fontSize: 17,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  loading
                      ? 'Loading RevenueCat products...'
                      : hasProducts
                      ? 'RevenueCat products are connected.'
                      : kIsWeb
                      ? 'Plans are visible. Connect Web Billing products to enable buying.'
                      : 'Plans are visible. Connect Play products to enable buying.',
                  style: GoogleFonts.plusJakartaSans(
                    color: Colors.white.withValues(alpha: 0.84),
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    height: 1.35,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _CatalogWarning extends StatelessWidget {
  const _CatalogWarning({required this.onRetry});

  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.softAmber.withValues(alpha: 0.12),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.info_outline_rounded, color: AppTheme.softAmber),
            const SizedBox(width: 10),
            const Expanded(
              child: Text('RevenueCat did not return products on this load.'),
            ),
            TextButton(onPressed: onRetry, child: const Text('Retry')),
          ],
        ),
      ),
    );
  }
}

class _PlanCard extends StatelessWidget {
  const _PlanCard({
    required this.plan,
    required this.catalog,
    required this.busyProductId,
    required this.onBuy,
  });

  final _PlanOffer plan;
  final _SubscriptionCatalog catalog;
  final String? busyProductId;
  final VoidCallback onBuy;

  @override
  Widget build(BuildContext context) {
    final package = catalog.packageFor(plan.productIds);
    final product = catalog.productFor(plan.productIds);
    final productId = package?.storeProduct.identifier ?? product?.identifier;
    final isBusy = busyProductId != null && busyProductId == productId;
    final price =
        package?.storeProduct.priceString ??
        product?.priceString ??
        '\$${(AppConstants.planFeatures[plan.plan]?['price'] as num).toStringAsFixed(2)}/mo';

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: plan.featured ? plan.accent : const Color(0xFFE2E8F0),
          width: plan.featured ? 2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: plan.accent.withValues(alpha: plan.featured ? 0.16 : 0.08),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: plan.accent.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Icon(
                  plan.featured
                      ? Icons.local_hospital_rounded
                      : Icons.workspace_premium_rounded,
                  color: plan.accent,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            plan.title,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: const Color(0xFF0F172A),
                            ),
                          ),
                        ),
                        if (plan.featured)
                          _MiniBadge(label: 'Best value', color: plan.accent),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      plan.subtitle,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12.5,
                        height: 1.35,
                        color: const Color(0xFF64748B),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Text(
            price,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 24,
              fontWeight: FontWeight.w900,
              color: plan.accent,
            ),
          ),
          const SizedBox(height: 12),
          ...plan.features.map(
            (feature) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Icon(
                    Icons.check_circle_rounded,
                    color: plan.accent,
                    size: 18,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      feature,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 13,
                        fontWeight: FontWeight.w700,
                        color: const Color(0xFF334155),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: plan.accent,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              onPressed: busyProductId == null ? onBuy : null,
              child: isBusy
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : Text(
                      productId == null
                          ? kIsWeb
                                ? 'Connect Web Product'
                                : 'Product Setup Needed'
                          : 'Choose Plan',
                    ),
            ),
          ),
        ],
      ),
    );
  }
}

class _WebBillingNotice extends StatelessWidget {
  const _WebBillingNotice();

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppTheme.cyan.withValues(alpha: 0.10),
      borderRadius: BorderRadius.circular(16),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          children: [
            const Icon(Icons.public_rounded, color: AppTheme.cyan),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                'Web billing uses RevenueCat offerings. Restore and Customer Center are handled through the web checkout and portal.',
                style: GoogleFonts.plusJakartaSans(fontSize: 12.5),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MiniBadge extends StatelessWidget {
  const _MiniBadge({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Text(
        label,
        style: GoogleFonts.plusJakartaSans(
          color: color,
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
        ),
      ),
    );
  }
}

class _SubscriptionCatalog {
  const _SubscriptionCatalog({
    required this.offeringPackages,
    required this.storeProducts,
  });

  static const empty = _SubscriptionCatalog(
    offeringPackages: [],
    storeProducts: [],
  );

  final List<Package> offeringPackages;
  final List<StoreProduct> storeProducts;

  bool get hasProducts =>
      offeringPackages.isNotEmpty || storeProducts.isNotEmpty;

  Package? packageFor(List<String> productIds) {
    for (final productId in productIds) {
      for (final package in offeringPackages) {
        if (package.storeProduct.identifier == productId ||
            package.identifier == productId) {
          return package;
        }
      }
    }
    return null;
  }

  StoreProduct? productFor(List<String> productIds) {
    for (final productId in productIds) {
      for (final product in storeProducts) {
        if (product.identifier == productId) return product;
      }
    }
    return null;
  }
}

class _PlanOffer {
  const _PlanOffer({
    required this.plan,
    required this.productIds,
    required this.title,
    required this.subtitle,
    required this.accent,
    required this.features,
    this.featured = false,
  });

  final SubscriptionPlan plan;
  final List<String> productIds;
  final String title;
  final String subtitle;
  final Color accent;
  final List<String> features;
  final bool featured;
}
