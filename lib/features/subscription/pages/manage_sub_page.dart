import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';
import 'package:purchases_ui_flutter/purchases_ui_flutter.dart';
import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/payment_service.dart';
import 'package:nightingale_heart/core/widgets/glass_card.dart';
import 'package:nightingale_heart/features/subscription/pages/paywall_page.dart';

class ManageSubPage extends ConsumerWidget {
  const ManageSubPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final userAsync = ref.watch(currentUserProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Manage Subscription',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
      ),
      body: userAsync.when(
        data: (user) {
          if (user == null) {
            return const Center(child: Text('Please sign in to continue.'));
          }
          return _ManageSubContent(user: user);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, _) => Center(child: Text('Error: $err')),
      ),
    );
  }
}

class _ManageSubContent extends ConsumerWidget {
  const _ManageSubContent({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final plan = user.plan;
    final planFeatures =
        AppConstants.planFeatures[plan] ??
        AppConstants.planFeatures[SubscriptionPlan.free]!;

    final videoMinutesTotal = planFeatures['monthlyVideoMinutes'] as int;
    final messagesTotal = planFeatures['dailyMessages'] as int;
    final dailySuperlikesTotal = planFeatures['dailySuperLikes'] as int?;
    final superlikesTotal =
        dailySuperlikesTotal ?? (planFeatures['monthlySuperLikes'] as int);
    final likesTotal = planFeatures['dailyLikes'] as int;
    final rewindsTotal = planFeatures['dailyRewinds'] as int? ?? 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildCurrentPlanCard(
            context,
            plan,
            theme,
          ).animate().fadeIn(duration: 400.ms).slideY(begin: 0.05, end: 0),
          const SizedBox(height: 24),
          Text(
            'Usage This Period',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildUsagePeriodSection(
            context,
            user: user,
            theme: theme,
            videoMinutesTotal: videoMinutesTotal,
            messagesTotal: messagesTotal,
            likesTotal: likesTotal,
            superlikesTotal: superlikesTotal,
            superlikesAreDaily: dailySuperlikesTotal != null,
            rewindsTotal: rewindsTotal,
          ).animate().fadeIn(duration: 400.ms, delay: 100.ms),
          const SizedBox(height: 24),
          Text(
            'Billing History',
            style: GoogleFonts.playfairDisplay(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 12),
          _buildBillingHistory(theme),
          const SizedBox(height: 24),
          if (!kIsWeb) ...[
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () async {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(
                        'Restoring purchases...',
                        style: GoogleFonts.plusJakartaSans(),
                      ),
                      behavior: SnackBarBehavior.floating,
                      duration: const Duration(seconds: 2),
                    ),
                  );
                  try {
                    final paymentService = ref.read(paymentServiceProvider);
                    final info = await paymentService.restorePurchases();
                    if (info != null && context.mounted) {
                      final syncResult = await paymentService
                          .syncRevenueCatCustomer();
                      if (!context.mounted) return;
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Purchases restored. Plan: ${syncResult.plan.displayName}',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: AppTheme.emerald,
                        ),
                      );
                    }
                  } catch (e) {
                    if (context.mounted) {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Could not restore purchases. Please try again.',
                            style: GoogleFonts.plusJakartaSans(),
                          ),
                          behavior: SnackBarBehavior.floating,
                          backgroundColor: Colors.red,
                        ),
                      );
                    }
                  }
                },
                icon: const Icon(Icons.refresh),
                label: const Text('Restore Purchases'),
              ),
            ),
            const SizedBox(height: 12),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: () => _openCustomerCenter(context, ref),
                icon: const Icon(Icons.manage_accounts_rounded),
                label: const Text('Open Customer Center'),
              ),
            ),
          ] else
            GlassCard(
              borderRadius: AppTheme.borderRadiusMedium,
              child: Text(
                'Web purchases are managed through RevenueCat Web Billing checkout and the web customer portal. Mobile restore and Customer Center controls are hidden on web.',
                style: GoogleFonts.plusJakartaSans(fontSize: 13),
              ),
            ),
          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildUsagePeriodSection(
    BuildContext context, {
    required UserModel user,
    required ThemeData theme,
    required int videoMinutesTotal,
    required int messagesTotal,
    required int likesTotal,
    required int superlikesTotal,
    required bool superlikesAreDaily,
    required int rewindsTotal,
  }) {
    final dailyRef = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .collection('usage')
        .doc(_dailyUsageDocId());
    final monthlyRef = FirebaseFirestore.instance
        .collection(AppConstants.usersCollection)
        .doc(user.id)
        .collection('usage')
        .doc(_monthlyUsageDocId());

    return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
      stream: dailyRef.snapshots(),
      builder: (context, dailySnapshot) {
        final daily = dailySnapshot.data?.data();
        return StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
          stream: monthlyRef.snapshots(),
          builder: (context, monthlySnapshot) {
            final monthly = monthlySnapshot.data?.data();
            final messagesUsed = _usageValue(daily, 'messagesSent');
            final likesUsed = _usageValue(daily, 'likesSent');
            final messagesRefilled = _usageValue(daily, 'messagesRefilled');
            final likesRefilled = _usageValue(daily, 'likesRefilled');
            final rewindsUsed = _usageValue(daily, 'rewindsUsed');
            final rewindsRefilled = _usageValue(daily, 'rewindsRefilled');
            final effectiveMessagesTotal = messagesTotal == -1
                ? -1
                : messagesTotal + messagesRefilled;
            final effectiveLikesTotal = likesTotal == -1
                ? -1
                : likesTotal + likesRefilled;
            final effectiveRewindsTotal = rewindsTotal == -1
                ? -1
                : rewindsTotal + rewindsRefilled;
            final superlikesUsed = superlikesAreDaily
                ? _usageValue(daily, 'superLikesSent')
                : _usageValue(monthly, 'superLikesSent');
            final videoUsed = _usageValue(monthly, 'videoMinutesUsed');
            final videoPurchased = _usageValue(monthly, 'videoPurchased');
            var videoTotal = videoMinutesTotal == -1
                ? -1
                : videoMinutesTotal + videoPurchased;
            final balanceAwareVideoTotal = videoUsed + user.videoMinutes;
            if (videoTotal != -1 && balanceAwareVideoTotal > videoTotal) {
              videoTotal = balanceAwareVideoTotal;
            }

            return Column(
              children: [
                _buildUsageStat(
                  context,
                  icon: Icons.favorite_rounded,
                  label: 'Likes Sent Today',
                  used: likesUsed,
                  total: effectiveLikesTotal,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildUsageStat(
                  context,
                  icon: Icons.message_rounded,
                  label: 'Messages Sent Today',
                  used: messagesUsed,
                  total: effectiveMessagesTotal,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildUsageStat(
                  context,
                  icon: Icons.star_rounded,
                  label: superlikesAreDaily
                      ? 'Superlikes Used Today'
                      : 'Superlikes Used This Month',
                  used: superlikesUsed,
                  total: superlikesTotal,
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildUsageStat(
                  context,
                  icon: Icons.undo_rounded,
                  label: 'Rewinds Used Today',
                  used: rewindsUsed,
                  total: effectiveRewindsTotal,
                  subtitle: rewindsTotal == -1
                      ? 'Unlimited plan rewinds are still tracked here.'
                      : 'Daily limit $rewindsTotal + $rewindsRefilled ad refills',
                  theme: theme,
                ),
                const SizedBox(height: 12),
                _buildUsageStat(
                  context,
                  icon: Icons.videocam_rounded,
                  label: 'Video Minutes Used This Month',
                  used: videoUsed,
                  total: videoTotal,
                  theme: theme,
                ),
                const SizedBox(height: 8),
                Align(
                  alignment: Alignment.centerLeft,
                  child: Text(
                    'Current video balance: ${user.videoMinutes} min',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Future<void> _openCustomerCenter(BuildContext context, WidgetRef ref) async {
    final paymentService = ref.read(paymentServiceProvider);
    try {
      await paymentService.ensureInitialized();
      await RevenueCatUI.presentCustomerCenter(
        onRestoreCompleted: (_) async {
          try {
            await paymentService.syncRevenueCatCustomer();
            ref.invalidate(currentUserProvider);
          } catch (error) {
            debugPrint('[ManageSubPage] Customer Center sync failed: $error');
          }
        },
      );
    } catch (error) {
      debugPrint('[ManageSubPage] Customer Center error: $error');
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Customer Center is not available yet. Please try again.',
            style: GoogleFonts.plusJakartaSans(),
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  String _dailyUsageDocId() {
    final now = DateTime.now().toUtc();
    return 'daily_${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}';
  }

  String _monthlyUsageDocId() {
    final now = DateTime.now().toUtc();
    return 'monthly_${now.year}-${now.month.toString().padLeft(2, '0')}';
  }

  int _usageValue(Map<String, dynamic>? data, String key, {int fallback = 0}) {
    return (data?[key] as num?)?.toInt() ?? fallback;
  }

  Widget _buildCurrentPlanCard(
    BuildContext context,
    SubscriptionPlan plan,
    ThemeData theme,
  ) {
    Color planColor;
    IconData planIcon;
    switch (plan) {
      case SubscriptionPlan.tech:
        planColor = const Color(0xFF3B82F6);
        planIcon = Icons.computer;
        break;
      case SubscriptionPlan.college:
        planColor = AppTheme.warmRose;
        planIcon = Icons.school;
        break;
      case SubscriptionPlan.nurse:
        planColor = AppTheme.softAmber;
        planIcon = Icons.workspace_premium;
        break;
      case SubscriptionPlan.doctor:
        planColor = AppTheme.deepPlum;
        planIcon = Icons.diamond;
        break;
      default:
        planColor = AppTheme.warmGray;
        planIcon = Icons.person;
    }

    final renewalDate = DateTime.now().add(const Duration(days: 30));
    final formattedDate = DateFormat('MMMM d, yyyy').format(renewalDate);

    return Container(
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        gradient: LinearGradient(
          colors: [planColor, planColor.withValues(alpha: 0.7)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        boxShadow: [
          BoxShadow(
            color: planColor.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.2),
                ),
                child: Icon(planIcon, color: Colors.white, size: 24),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      plan.displayName,
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                        color: Colors.white,
                      ),
                    ),
                    if (plan != SubscriptionPlan.free)
                      Text(
                        'Renews $formattedDate',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white.withValues(alpha: 0.85),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => const _PaywallNavigator(),
                      ),
                    );
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: planColor,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: Text(
                    plan == SubscriptionPlan.free
                        ? 'Upgrade Now'
                        : 'Change Plan',
                    style: GoogleFonts.plusJakartaSans(
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              ),
              if (plan != SubscriptionPlan.free) ...[
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => _showCancelDialog(context, planColor),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.white,
                      side: BorderSide(
                        color: Colors.white.withValues(alpha: 0.6),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: Text(
                      'Cancel',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildUsageStat(
    BuildContext context, {
    required IconData icon,
    required String label,
    required int used,
    required int total,
    String? subtitle,
    required ThemeData theme,
  }) {
    final isUnlimited = total == -1;
    final progress = isUnlimited
        ? 0.0
        : (total > 0 ? (used / total).clamp(0.0, 1.0) : 0.0);
    final usageText = isUnlimited ? '$used used (Unlimited)' : '$used / $total';

    return GlassCard(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: AppTheme.deepPlum, size: 22),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  label,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              Text(
                usageText,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: LinearProgressIndicator(
              value: isUnlimited ? 0 : progress,
              minHeight: 8,
              backgroundColor: AppTheme.deepPlum.withValues(alpha: 0.12),
              valueColor: AlwaysStoppedAnimation<Color>(
                progress > 0.8 ? AppTheme.warmRose : AppTheme.deepPlum,
              ),
            ),
          ),
          if (subtitle != null) ...[
            const SizedBox(height: 8),
            Text(
              subtitle,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildBillingHistory(ThemeData theme) {
    return GlassCard(
      padding: const EdgeInsets.all(20),
      child: Column(
        children: [
          Icon(
            Icons.receipt_long_rounded,
            size: 40,
            color: AppTheme.deepPlum.withValues(alpha: 0.5),
          ),
          const SizedBox(height: 12),
          Text(
            'Billing is managed by your app store',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w600,
              color: theme.colorScheme.onSurface,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'To view your billing history, manage payments, or request refunds, please visit your Google Play Store or Apple App Store subscription settings.',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: theme.colorScheme.onSurfaceVariant,
              height: 1.5,
            ),
          ),
        ],
      ),
    );
  }

  void _showCancelDialog(BuildContext context, Color planColor) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(
          'Cancel Subscription?',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Text(
          'Are you sure you want to cancel your subscription? You will lose access to premium features at the end of your current billing period.',
          style: GoogleFonts.plusJakartaSans(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Keep Plan'),
          ),
          ElevatedButton(
            onPressed: () {
              Navigator.of(ctx).pop();
              debugPrint('[ManageSubPage] Cancel subscription confirmed');
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Cancellation will be processed via RevenueCat when configured.',
                    style: GoogleFonts.plusJakartaSans(),
                  ),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.red,
              foregroundColor: Colors.white,
            ),
            child: const Text('Cancel Subscription'),
          ),
        ],
      ),
    );
  }
}

class _PaywallNavigator extends StatelessWidget {
  const _PaywallNavigator();

  @override
  Widget build(BuildContext context) {
    return const PaywallPage();
  }
}
