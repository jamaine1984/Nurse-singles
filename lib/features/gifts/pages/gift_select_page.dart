import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
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
const _kEmerald = Color(0xFF059669);

// ─── Category Filter Item ───────────────────────────────────────────────────

class _CategoryFilter {
  const _CategoryFilter({
    required this.label,
    this.category,
    required this.icon,
    required this.color,
  });

  final String label;
  final GiftCategory? category;
  final IconData icon;
  final Color color;
}

const List<_CategoryFilter> _categories = [
  _CategoryFilter(label: 'All', category: null, icon: Icons.grid_view_rounded, color: _kDeepPlum),
  _CategoryFilter(label: 'Medical', category: GiftCategory.medical, icon: Icons.local_hospital_rounded, color: _kEmerald),
  _CategoryFilter(label: 'Romantic', category: GiftCategory.romantic, icon: Icons.favorite_rounded, color: _kWarmRose),
  _CategoryFilter(label: 'Luxury', category: GiftCategory.luxury, icon: Icons.diamond_rounded, color: _kSoftAmber),
  _CategoryFilter(label: 'Food & Drink', category: GiftCategory.foodDrink, icon: Icons.restaurant_rounded, color: Color(0xFFEA580C)),
  _CategoryFilter(label: 'Tech', category: GiftCategory.tech, icon: Icons.devices_rounded, color: Color(0xFF2563EB)),
  _CategoryFilter(label: 'Nature', category: GiftCategory.nature, icon: Icons.eco_rounded, color: Color(0xFF16A34A)),
  _CategoryFilter(label: 'Fun', category: GiftCategory.fun, icon: Icons.celebration_rounded, color: Color(0xFFDB2777)),
  _CategoryFilter(label: 'Special', category: GiftCategory.special, icon: Icons.auto_awesome_rounded, color: Color(0xFF7C3AED)),
];

// ─── Gift Select Page ───────────────────────────────────────────────────────

/// A gift selection page opened from within a chat.
///
/// Shows user's inventory first, with option to watch an ad to claim any gift.
/// Sending uses inventory (ad-based), not points.
class GiftSelectPage extends ConsumerStatefulWidget {
  const GiftSelectPage({
    super.key,
    required this.receiverId,
    required this.receiverName,
    this.chatId = '',
  });

  final String receiverId;
  final String receiverName;
  final String chatId;

  @override
  ConsumerState<GiftSelectPage> createState() => _GiftSelectPageState();
}

class _GiftSelectPageState extends ConsumerState<GiftSelectPage>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  int _selectedCategoryIndex = 0;
  bool _isBusy = false;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  List<GiftModel> get _filteredGifts {
    final cat = _categories[_selectedCategoryIndex].category;
    if (cat == null) return GiftModel.allGifts;
    return GiftModel.allGifts.where((g) => g.category == cat).toList();
  }

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);
    final inventoryMapAsync = userId != null
        ? ref.watch(giftInventoryMapProvider(userId))
        : const AsyncValue<Map<String, int>>.data({});
    final inventoryMap = inventoryMapAsync.valueOrNull ?? {};
    final totalInventory =
        inventoryMap.values.fold<int>(0, (sum, qty) => sum + qty);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Send Gift to ${widget.receiverName}',
          style: GoogleFonts.playfairDisplay(
            fontSize: 18,
            fontWeight: FontWeight.w600,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: _kDeepPlum,
          labelColor: _kDeepPlum,
          unselectedLabelColor: Colors.grey,
          labelStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w700,
          ),
          tabs: [
            Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.inventory_2_rounded, size: 18),
                  const SizedBox(width: 6),
                  Text('My Inventory ($totalInventory)'),
                ],
              ),
            ),
            const Tab(
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.add_circle_outline_rounded, size: 18),
                  SizedBox(width: 6),
                  Text('Claim New Gift'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // ── Tab 1: Inventory ──────────────────────────────────────────
          _buildInventoryTab(userId, inventoryMap),

          // ── Tab 2: Claim New Gift (Watch Ad) ─────────────────────────
          _buildClaimTab(userId, inventoryMap),
        ],
      ),
    );
  }

  // ─── Inventory Tab ──────────────────────────────────────────────────────

  Widget _buildInventoryTab(String? userId, Map<String, int> inventoryMap) {
    if (userId == null) {
      return const Center(child: Text('Please sign in.'));
    }

    final inventoryAsync = ref.watch(giftInventoryProvider(userId));

    return inventoryAsync.when(
      loading: () => const Center(
        child: CircularProgressIndicator(color: _kDeepPlum),
      ),
      error: (e, _) => Center(child: Text('Error: $e')),
      data: (items) {
        if (items.isEmpty) {
          return Center(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.card_giftcard_rounded,
                    size: 64,
                    color: _kDeepPlum.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'No gifts in inventory',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Switch to "Claim New Gift" tab to watch an ad and get a free gift to send!',
                    textAlign: TextAlign.center,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 14,
                      color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    onPressed: () => _tabController.animateTo(1),
                    icon: const Icon(Icons.play_circle_filled_rounded, size: 20),
                    label: Text(
                      'Claim a Gift',
                      style: GoogleFonts.plusJakartaSans(
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _kDeepPlum,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 28,
                        vertical: 14,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        return GridView.builder(
          padding: const EdgeInsets.fromLTRB(12, 12, 12, 100),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 3,
            mainAxisSpacing: 10,
            crossAxisSpacing: 10,
            childAspectRatio: 0.78,
          ),
          itemCount: items.length,
          itemBuilder: (context, index) {
            final item = items[index];
            return _InventoryGiftCard(
              item: item,
              onTap: _isBusy
                  ? null
                  : () => _sendFromInventory(userId, item),
            ).animate().fadeIn(
                  duration: 250.ms,
                  delay: (40 * (index % 6)).ms,
                );
          },
        );
      },
    );
  }

  // ─── Claim Tab ──────────────────────────────────────────────────────────

  Widget _buildClaimTab(String? userId, Map<String, int> inventoryMap) {
    return Column(
      children: [
        // Info banner
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kDeepPlum, _kWarmRose],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.play_circle_filled_rounded,
                    color: Colors.white, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Watch 1 Ad = 1 Free Gift',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: Colors.white,
                        ),
                      ),
                      Text(
                        'Claim any gift, then send it from your inventory!',
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
          ).animate().fadeIn(duration: 300.ms),
        ),

        // Category chips
        SizedBox(
          height: 52,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            itemCount: _categories.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final cat = _categories[index];
              final isSelected = index == _selectedCategoryIndex;
              return ChoiceChip(
                label: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(cat.icon, size: 15,
                        color: isSelected ? Colors.white : cat.color),
                    const SizedBox(width: 5),
                    Text(
                      cat.label,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: isSelected ? Colors.white : cat.color,
                      ),
                    ),
                  ],
                ),
                selected: isSelected,
                selectedColor: cat.color,
                backgroundColor: cat.color.withValues(alpha: 0.1),
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

        // Gift grid
        Expanded(
          child: GridView.builder(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 100),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 3,
              mainAxisSpacing: 10,
              crossAxisSpacing: 10,
              childAspectRatio: 0.78,
            ),
            itemCount: _filteredGifts.length,
            itemBuilder: (context, index) {
              final gift = _filteredGifts[index];
              final ownedQty = inventoryMap[gift.id] ?? 0;
              return _ClaimGiftCard(
                gift: gift,
                ownedQty: ownedQty,
                accentColor: _categories[_selectedCategoryIndex].color,
                isBusy: _isBusy,
                onClaim: () => _claimGift(userId!, gift),
              ).animate().fadeIn(
                    duration: 250.ms,
                    delay: (40 * (index % 6)).ms,
                  );
            },
          ),
        ),
      ],
    );
  }

  // ─── Send from Inventory ────────────────────────────────────────────────

  Future<void> _sendFromInventory(
    String userId,
    InventoryItem item,
  ) async {
    final currentUser = ref.read(currentUserProvider).valueOrNull;
    if (currentUser == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Send Gift',
          style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(item.giftEmoji, style: const TextStyle(fontSize: 52))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.12, 1.12),
                  duration: 800.ms,
                ),
            const SizedBox(height: 12),
            Text(
              'Send ${item.giftName} to ${widget.receiverName}?',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(fontSize: 15),
            ),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: _kEmerald.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                'x${item.quantity} in inventory',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: _kEmerald,
                ),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel'),
          ),
          Container(
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kDeepPlum, _kWarmRose],
              ),
              borderRadius: BorderRadius.circular(12),
            ),
            child: ElevatedButton(
              onPressed: () => Navigator.of(ctx).pop(true),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding:
                    const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              ),
              child: Text(
                'Send Gift',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w600,
                  color: Colors.white,
                ),
              ),
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isBusy = true);

    final giftService = ref.read(giftServiceProvider);
    final success = await giftService.sendGiftFromInventory(
      fromUserId: currentUser.id,
      fromUserName: currentUser.name,
      toUserId: widget.receiverId,
      toUserName: widget.receiverName,
      chatId: widget.chatId,
      giftId: item.giftId,
      giftName: item.giftName,
      giftEmoji: item.giftEmoji,
    );

    if (!mounted) return;
    setState(() => _isBusy = false);

    if (success) {
      ref.invalidate(giftInventoryProvider(userId));
      ref.invalidate(giftInventoryMapProvider(userId));

      Navigator.of(context).pop(<String, dynamic>{
        'giftId': item.giftId,
        'giftName': item.giftName,
        'giftEmoji': item.giftEmoji,
        'sent': true,
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${item.giftEmoji} ${item.giftName} sent to ${widget.receiverName}!',
          ),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kEmerald,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Failed to send gift. Please try again.'),
          behavior: SnackBarBehavior.floating,
          backgroundColor: _kWarmRose,
        ),
      );
    }
  }

  // ─── Claim Gift (Watch Ad) ──────────────────────────────────────────────

  Future<void> _claimGift(String userId, GiftModel gift) async {
    if (_isBusy) return;

    setState(() => _isBusy = true);

    try {
      final adMob = AdMobService.instance;

      if (!adMob.isRewardedAdReady) {
        adMob.loadRewardedAd();
        for (int i = 0; i < 10; i++) {
          await Future.delayed(const Duration(milliseconds: 500));
          if (adMob.isRewardedAdReady) break;
        }
      }

      if (!mounted) return;

      if (!adMob.isRewardedAdReady) {
        _showError('Ad is loading. Please try again in a moment.');
        return;
      }

      bool rewarded = false;
      final shown = await adMob.showRewardedAdWithCallback(
        onReward: (type, amount) {
          rewarded = true;
        },
      );

      if (!mounted) return;

      if (shown && rewarded) {
        final giftService = ref.read(giftServiceProvider);
        final success = await giftService.claimGift(
          userId: userId,
          giftId: gift.id,
          giftName: gift.name,
          giftEmoji: gift.emoji,
        );

        if (!mounted) return;

        if (success) {
          ref.invalidate(giftInventoryProvider(userId));
          ref.invalidate(giftInventoryMapProvider(userId));

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                '${gift.emoji} ${gift.name} added to your inventory!',
              ),
              behavior: SnackBarBehavior.floating,
              backgroundColor: _kEmerald,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
          );

          // Switch to inventory tab to show the new gift
          _tabController.animateTo(0);
        } else {
          _showError('Failed to claim gift.');
        }
      } else if (!shown) {
        _showError('Could not show ad. Please try again.');
      } else {
        _showError('Watch the full ad to claim this gift.');
      }
    } catch (e) {
      if (mounted) {
        _showError('Ad not available right now. Try again later.');
      }
    } finally {
      if (mounted) setState(() => _isBusy = false);
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
        backgroundColor: _kWarmRose,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }
}

// ─── Inventory Gift Card ─────────────────────────────────────────────────────

class _InventoryGiftCard extends StatelessWidget {
  const _InventoryGiftCard({
    required this.item,
    this.onTap,
  });

  final InventoryItem item;
  final VoidCallback? onTap;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: _kEmerald.withValues(alpha: 0.3),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Quantity badge
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                  color: _kEmerald.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'x${item.quantity}',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: _kEmerald,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Emoji
              Text(item.giftEmoji, style: const TextStyle(fontSize: 38)),
              const SizedBox(height: 6),
              // Name
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 6),
                child: Text(
                  item.giftName,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Send button
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    colors: [_kDeepPlum, _kWarmRose],
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.send_rounded,
                        size: 10, color: Colors.white),
                    const SizedBox(width: 3),
                    Text(
                      'Send',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Claim Gift Card ────────────────────────────────────────────────────────

class _ClaimGiftCard extends StatelessWidget {
  const _ClaimGiftCard({
    required this.gift,
    required this.ownedQty,
    required this.accentColor,
    required this.isBusy,
    required this.onClaim,
  });

  final GiftModel gift;
  final int ownedQty;
  final Color accentColor;
  final bool isBusy;
  final VoidCallback onClaim;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Material(
      color: theme.cardTheme.color ?? theme.colorScheme.surface,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: isBusy ? null : onClaim,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(
              color: ownedQty > 0
                  ? _kEmerald.withValues(alpha: 0.3)
                  : accentColor.withValues(alpha: 0.2),
              width: 1.5,
            ),
          ),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const SizedBox(height: 6),
              if (ownedQty > 0)
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: _kEmerald.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    'x$ownedQty owned',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 9,
                      fontWeight: FontWeight.w700,
                      color: _kEmerald,
                    ),
                  ),
                )
              else
                const SizedBox(height: 16),
              // Emoji
              Text(gift.emoji, style: const TextStyle(fontSize: 38)),
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
                    color: theme.colorScheme.onSurface,
                  ),
                ),
              ),
              const SizedBox(height: 4),
              // Watch Ad button
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
                    const Icon(Icons.play_arrow_rounded,
                        size: 12, color: Colors.white),
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
              const SizedBox(height: 4),
            ],
          ),
        ),
      ),
    );
  }
}
