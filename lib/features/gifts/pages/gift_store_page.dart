import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/gift_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/core/services/admob_service.dart';
import 'package:nightingale_heart/features/gifts/services/gift_service.dart';

// ─── Theme Colors ───────────────────────────────────────────────────────────

const _kDeepPlum = Color(0xFF0F766E);
const _kWarmRose = Color(0xFFDC2626);
const _kSoftAmber = Color(0xFFF59E0B);

// ─── Category Tab Data ──────────────────────────────────────────────────────

class _CategoryTab {
  const _CategoryTab({
    required this.label,
    this.category,
    required this.icon,
    required this.color,
  });

  final String label;
  final GiftCategory? category; // null = "All"
  final IconData icon;
  final Color color;
}

const List<_CategoryTab> _tabs = [
  _CategoryTab(
    label: 'All',
    category: null,
    icon: Icons.grid_view_rounded,
    color: _kDeepPlum,
  ),
  _CategoryTab(
    label: 'Medical',
    category: GiftCategory.medical,
    icon: Icons.local_hospital_rounded,
    color: Color(0xFF059669),
  ),
  _CategoryTab(
    label: 'Romantic',
    category: GiftCategory.romantic,
    icon: Icons.favorite_rounded,
    color: _kWarmRose,
  ),
  _CategoryTab(
    label: 'Luxury',
    category: GiftCategory.luxury,
    icon: Icons.diamond_rounded,
    color: _kSoftAmber,
  ),
  _CategoryTab(
    label: 'Food & Drink',
    category: GiftCategory.foodDrink,
    icon: Icons.restaurant_rounded,
    color: Color(0xFFEA580C),
  ),
  _CategoryTab(
    label: 'Tech',
    category: GiftCategory.tech,
    icon: Icons.devices_rounded,
    color: Color(0xFF2563EB),
  ),
  _CategoryTab(
    label: 'Nature',
    category: GiftCategory.nature,
    icon: Icons.eco_rounded,
    color: Color(0xFF16A34A),
  ),
  _CategoryTab(
    label: 'Fun',
    category: GiftCategory.fun,
    icon: Icons.celebration_rounded,
    color: Color(0xFFDB2777),
  ),
  _CategoryTab(
    label: 'Special',
    category: GiftCategory.special,
    icon: Icons.auto_awesome_rounded,
    color: Color(0xFF7C3AED),
  ),
];

// ─── Gift Store Page ────────────────────────────────────────────────────────

class GiftStorePage extends ConsumerStatefulWidget {
  const GiftStorePage({super.key});

  @override
  ConsumerState<GiftStorePage> createState() => _GiftStorePageState();
}

class _GiftStorePageState extends ConsumerState<GiftStorePage> {
  int _selectedCategoryIndex = 0;
  bool _isClaimingGift = false;

  List<GiftModel> get _filteredGifts {
    final tab = _tabs[_selectedCategoryIndex];
    if (tab.category == null) return GiftModel.allGifts;
    return GiftModel.allGifts
        .where((g) => g.category == tab.category)
        .toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final inventoryMapAsync = userId != null
        ? ref.watch(giftInventoryMapProvider(userId))
        : const AsyncValue<Map<String, int>>.data({});
    final inventoryMap = inventoryMapAsync.valueOrNull ?? {};
    final totalInventoryCount =
        inventoryMap.values.fold<int>(0, (sum, qty) => sum + qty);

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0xFF1A0A2E),
              Color(0xFF16082A),
              Color(0xFF0F0620),
            ],
          ),
        ),
        child: CustomScrollView(
          slivers: [
            // ── App Bar ──────────────────────────────────────────────────
            SliverAppBar(
              expandedHeight: 100,
              floating: true,
              pinned: true,
              backgroundColor: const Color(0xFF1A0A2E),
              leading: IconButton(
                icon: const Icon(Icons.arrow_back, color: Colors.white),
                onPressed: () => Navigator.of(context).pop(),
              ),
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.card_giftcard_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Gift Store',
                      style: GoogleFonts.playfairDisplay(
                        fontSize: 20,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
                centerTitle: true,
              ),
              actions: [
                // Inventory badge
                Padding(
                  padding: const EdgeInsets.only(right: 16),
                  child: GestureDetector(
                    onTap: () => context.push('/gifts/inventory'),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: _kSoftAmber,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: [
                          BoxShadow(
                            color: _kSoftAmber.withValues(alpha: 0.3),
                            blurRadius: 8,
                            offset: const Offset(0, 2),
                          ),
                        ],
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.inventory_2_rounded,
                            size: 16,
                            color: Colors.white,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            '$totalInventoryCount',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // ── Info Banner ─────────────────────────────────────────────
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _InfoBanner(),
              ),
            ),

            // ── Category Chips ──────────────────────────────────────────
            SliverToBoxAdapter(
              child: SizedBox(
                height: 52,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  itemCount: _tabs.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, index) {
                    final tab = _tabs[index];
                    final isSelected = index == _selectedCategoryIndex;
                    return ChoiceChip(
                      label: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(
                            tab.icon,
                            size: 15,
                            color: isSelected ? Colors.white : tab.color,
                          ),
                          const SizedBox(width: 5),
                          Text(
                            tab.label,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? Colors.white : tab.color,
                            ),
                          ),
                        ],
                      ),
                      selected: isSelected,
                      selectedColor: tab.color,
                      backgroundColor: tab.color.withValues(alpha: 0.12),
                      showCheckmark: false,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      onSelected: (_) {
                        setState(() => _selectedCategoryIndex = index);
                      },
                    );
                  },
                ),
              ),
            ),

            // ── Gift Grid ───────────────────────────────────────────────
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
              sliver: SliverGrid(
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 3,
                  mainAxisSpacing: 10,
                  crossAxisSpacing: 10,
                  childAspectRatio: 0.65,
                ),
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final gifts = _filteredGifts;
                    if (index >= gifts.length) return null;
                    final gift = gifts[index];
                    final ownedQty = inventoryMap[gift.id] ?? 0;
                    final categoryTab = _tabs[_selectedCategoryIndex];
                    return _GiftGridCard(
                      gift: gift,
                      accentColor: categoryTab.color,
                      ownedQuantity: ownedQty,
                      isClaiming: _isClaimingGift,
                      onClaim: () => _claimGift(gift),
                    ).animate().fadeIn(
                          duration: 300.ms,
                          delay: (50 * (index % 6)).ms,
                        );
                  },
                  childCount: _filteredGifts.length,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _claimGift(GiftModel gift) async {
    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;
    if (_isClaimingGift) return;

    setState(() => _isClaimingGift = true);

    try {
      final adMobService = AdMobService.instance;

      // Ensure an ad is loaded before attempting to show.
      if (!adMobService.isRewardedAdReady) {
        adMobService.loadRewardedAd();
        // Wait for the ad to finish loading (up to 5 seconds).
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (adMobService.isRewardedAdReady) break;
        }
      }

      if (!mounted) return;

      if (!adMobService.isRewardedAdReady) {
        _showErrorSnackBar('Ad is loading. Please try again in a moment.');
        return;
      }

      // Show the rewarded ad using callback style for reliable reward detection.
      bool rewarded = false;
      final shown = await adMobService.showRewardedAdWithCallback(
        onReward: (type, amount) {
          rewarded = true;
        },
      );

      if (!mounted) return;

      if (shown && rewarded) {
        // Ad was watched successfully -- claim the gift.
        final giftService = ref.read(giftServiceProvider);
        final success = await giftService.claimGift(
          userId: userId,
          giftId: gift.id,
          giftName: gift.name,
          giftEmoji: gift.emoji,
        );

        if (!mounted) return;

        if (success) {
          // Invalidate so the inventory map refreshes.
          ref.invalidate(giftInventoryMapProvider(userId));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${gift.emoji} ${gift.name} added to your inventory!',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: const Color(0xFF059669),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );
        } else {
          _showErrorSnackBar('Failed to claim gift. Please try again.');
        }
      } else if (!shown) {
        _showErrorSnackBar('Could not show ad. Please try again.');
      } else {
        _showErrorSnackBar('Watch the full ad to claim this gift.');
      }
    } catch (e) {
      if (mounted) {
        _showErrorSnackBar('Ad not available right now. Try again later.');
      }
    } finally {
      if (mounted) {
        setState(() => _isClaimingGift = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kWarmRose,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

// ─── Info Banner ────────────────────────────────────────────────────────────

class _InfoBanner extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [_kDeepPlum, _kWarmRose],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: _kDeepPlum.withValues(alpha: 0.25),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.play_circle_filled_rounded,
              color: Colors.white,
              size: 28,
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Watch Ads, Collect Gifts',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  'Watch a short ad to add any gift to your inventory. Send them to your matches!',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 12,
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.1, end: 0);
  }
}

// ─── Gift Grid Card ─────────────────────────────────────────────────────────

class _GiftGridCard extends StatelessWidget {
  const _GiftGridCard({
    required this.gift,
    required this.accentColor,
    required this.ownedQuantity,
    required this.isClaiming,
    required this.onClaim,
  });

  final GiftModel gift;
  final Color accentColor;
  final int ownedQuantity;
  final bool isClaiming;
  final VoidCallback onClaim;

  bool get _isOwned => ownedQuantity > 0;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: isClaiming ? null : onClaim,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: _isOwned
                  ? const Color(0xFF059669).withValues(alpha: 0.4)
                  : accentColor.withValues(alpha: 0.15),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),

              // Owned badge
              if (_isOwned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_rounded,
                        size: 12,
                        color: Color(0xFF059669),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        'x$ownedQuantity',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: const Color(0xFF059669),
                        ),
                      ),
                    ],
                  ),
                )
              else
                const SizedBox(height: 16),

              // Emoji
              Text(
                gift.emoji,
                style: const TextStyle(fontSize: 40),
              ),
              const SizedBox(height: 6),

              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  gift.name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: Colors.white.withValues(alpha: 0.9),
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Claim button or "In Inventory" label
              if (_isOwned)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669).withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'In Inventory',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFF059669),
                    ),
                  ),
                )
              else
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [_kDeepPlum, _kWarmRose],
                    ),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.play_arrow_rounded,
                        size: 12,
                        color: Colors.white,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        'Watch Ad',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 9,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 6),
            ],
          ),
        ),
      ),
    );
  }
}
