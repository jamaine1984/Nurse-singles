import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/gifts/services/gift_service.dart';

// ─── Theme Colors ───────────────────────────────────────────────────────────

const _kDeepPlum = Color(0xFF0F766E);
const _kWarmRose = Color(0xFFDC2626);
const _kSoftAmber = Color(0xFFF59E0B);

// ─── Gift Inventory Page ────────────────────────────────────────────────────

/// Displays the current user's gift inventory. Tapping a gift selects it and
/// pops back with the gift data so the caller (e.g., chat page) can use it.
class GiftInventoryPage extends ConsumerStatefulWidget {
  const GiftInventoryPage({super.key});

  @override
  ConsumerState<GiftInventoryPage> createState() => _GiftInventoryPageState();
}

class _GiftInventoryPageState extends ConsumerState<GiftInventoryPage> {
  String? _selectedGiftId;

  @override
  Widget build(BuildContext context) {
    final userId = ref.watch(currentUserIdProvider);

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(
          title: Text(
            'My Inventory',
            style: GoogleFonts.playfairDisplay(fontWeight: FontWeight.w600),
          ),
        ),
        body: const Center(child: Text('Please sign in to view your inventory.')),
      );
    }

    final inventoryAsync = ref.watch(giftInventoryProvider(userId));

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
              iconTheme: const IconThemeData(color: Colors.white),
              flexibleSpace: FlexibleSpaceBar(
                title: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.inventory_2_rounded,
                      size: 22,
                      color: Colors.white,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'My Inventory',
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
            ),

            // ── Inventory Content ────────────────────────────────────────
            inventoryAsync.when(
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(color: _kDeepPlum),
                ),
              ),
              error: (e, _) => SliverFillRemaining(
                child: Center(
                  child: Padding(
                    padding: const EdgeInsets.all(32),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: _kWarmRose.withValues(alpha: 0.7),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          'Could not load inventory',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: Colors.white70,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '$e',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 12,
                            color: Colors.white38,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              data: (items) {
                if (items.isEmpty) {
                  return SliverFillRemaining(
                    child: Center(
                      child: Padding(
                        padding: const EdgeInsets.all(32),
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.card_giftcard_rounded,
                              size: 64,
                              color: _kDeepPlum.withValues(alpha: 0.5),
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'No gifts yet',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 22,
                                fontWeight: FontWeight.w600,
                                color: Colors.white70,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              'Visit the Gift Store and watch ads to collect gifts you can send to your matches!',
                              textAlign: TextAlign.center,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 14,
                                color: Colors.white38,
                              ),
                            ),
                            const SizedBox(height: 24),
                            Container(
                              decoration: BoxDecoration(
                                gradient: const LinearGradient(
                                  colors: [_kDeepPlum, _kWarmRose],
                                ),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: ElevatedButton(
                                onPressed: () => Navigator.of(context).pop(),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 32,
                                    vertical: 14,
                                  ),
                                ),
                                child: Text(
                                  'Go to Gift Store',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontWeight: FontWeight.w600,
                                    color: Colors.white,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
                }

                // ── Stats Header ─────────────────────────────────────
                final totalGifts = items.fold<int>(
                  0,
                  (sum, item) => sum + item.quantity,
                );

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(12, 8, 12, 100),
                  sliver: SliverMainAxisGroup(
                    slivers: [
                      // Stats row
                      SliverToBoxAdapter(
                        child: Padding(
                          padding: const EdgeInsets.fromLTRB(4, 8, 4, 16),
                          child: Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: Colors.white.withValues(alpha: 0.06),
                              borderRadius: BorderRadius.circular(16),
                              border: Border.all(
                                color: _kDeepPlum.withValues(alpha: 0.2),
                              ),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceAround,
                              children: [
                                _StatItem(
                                  label: 'Unique Gifts',
                                  value: '${items.length}',
                                  color: _kDeepPlum,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white12,
                                ),
                                _StatItem(
                                  label: 'Total Items',
                                  value: '$totalGifts',
                                  color: _kSoftAmber,
                                ),
                                Container(
                                  width: 1,
                                  height: 30,
                                  color: Colors.white12,
                                ),
                                _StatItem(
                                  label: 'Tap to Select',
                                  value: _selectedGiftId != null
                                      ? 'Selected'
                                      : '--',
                                  color: _kWarmRose,
                                ),
                              ],
                            ),
                          ).animate().fadeIn(duration: 300.ms),
                        ),
                      ),

                      // Grid of owned gifts
                      SliverGrid(
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 3,
                          mainAxisSpacing: 10,
                          crossAxisSpacing: 10,
                          childAspectRatio: 0.75,
                        ),
                        delegate: SliverChildBuilderDelegate(
                          (context, index) {
                            final item = items[index];
                            final isSelected =
                                _selectedGiftId == item.giftId;
                            return _InventoryCard(
                              item: item,
                              isSelected: isSelected,
                              onTap: () => _onGiftTap(item),
                            ).animate().fadeIn(
                                  duration: 300.ms,
                                  delay: (50 * (index % 6)).ms,
                                );
                          },
                          childCount: items.length,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),

      // ── Send Button (when a gift is selected) ──────────────────────────
      bottomNavigationBar: _selectedGiftId != null
          ? _buildSendBar()
          : null,
    );
  }

  void _onGiftTap(InventoryItem item) {
    setState(() {
      if (_selectedGiftId == item.giftId) {
        // Double-tap to deselect.
        _selectedGiftId = null;
      } else {
        _selectedGiftId = item.giftId;
      }
    });
  }

  Widget _buildSendBar() {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 28),
      decoration: BoxDecoration(
        color: const Color(0xFF1A0A2E),
        border: Border(
          top: BorderSide(
            color: _kDeepPlum.withValues(alpha: 0.3),
          ),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Container(
          width: double.infinity,
          decoration: BoxDecoration(
            gradient: const LinearGradient(
              colors: [_kDeepPlum, _kWarmRose],
            ),
            borderRadius: BorderRadius.circular(16),
            boxShadow: [
              BoxShadow(
                color: _kDeepPlum.withValues(alpha: 0.3),
                blurRadius: 12,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: ElevatedButton(
            onPressed: _confirmSelection,
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.transparent,
              shadowColor: Colors.transparent,
              padding: const EdgeInsets.symmetric(vertical: 16),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.send_rounded,
                  color: Colors.white,
                  size: 20,
                ),
                const SizedBox(width: 10),
                Text(
                  'Select for Sending',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _confirmSelection() {
    if (_selectedGiftId == null) return;

    final userId = ref.read(currentUserIdProvider);
    if (userId == null) return;

    final inventoryAsync = ref.read(giftInventoryProvider(userId));
    final items = inventoryAsync.valueOrNull ?? [];

    final selected = items.where((i) => i.giftId == _selectedGiftId).toList();
    if (selected.isEmpty) return;

    final item = selected.first;

    // Pop back with the selected gift data.
    Navigator.of(context).pop(<String, dynamic>{
      'giftId': item.giftId,
      'giftName': item.giftName,
      'giftEmoji': item.giftEmoji,
      'quantity': item.quantity,
      'selected': true,
    });
  }
}

// ─── Stat Item ──────────────────────────────────────────────────────────────

class _StatItem extends StatelessWidget {
  const _StatItem({
    required this.label,
    required this.value,
    required this.color,
  });

  final String label;
  final String value;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          value,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: color,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            fontWeight: FontWeight.w500,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

// ─── Inventory Card ─────────────────────────────────────────────────────────

class _InventoryCard extends StatelessWidget {
  const _InventoryCard({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final InventoryItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: isSelected
          ? _kDeepPlum.withValues(alpha: 0.2)
          : Colors.white.withValues(alpha: 0.08),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected
                  ? _kDeepPlum.withValues(alpha: 0.7)
                  : Colors.white.withValues(alpha: 0.1),
              width: isSelected ? 2.0 : 1.5,
            ),
          ),
          child: Stack(
            children: [
              // Quantity badge (top-right)
              Positioned(
                top: 6,
                right: 6,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 7,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _kSoftAmber,
                    borderRadius: BorderRadius.circular(10),
                    boxShadow: [
                      BoxShadow(
                        color: _kSoftAmber.withValues(alpha: 0.3),
                        blurRadius: 4,
                      ),
                    ],
                  ),
                  child: Text(
                    'x${item.quantity}',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 10,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),

              // Selected checkmark (top-left)
              if (isSelected)
                Positioned(
                  top: 6,
                  left: 6,
                  child: Container(
                    width: 22,
                    height: 22,
                    decoration: const BoxDecoration(
                      color: _kDeepPlum,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      size: 14,
                      color: Colors.white,
                    ),
                  ),
                ),

              // Gift content (centered)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const SizedBox(height: 10),
                      // Emoji
                      Text(
                        item.giftEmoji,
                        style: const TextStyle(fontSize: 40),
                      ),
                      const SizedBox(height: 8),
                      // Name
                      Text(
                        item.giftName,
                        textAlign: TextAlign.center,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.white.withValues(alpha: 0.9),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
