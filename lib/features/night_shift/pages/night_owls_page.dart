import 'dart:math';

import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/night_shift/services/night_shift_service.dart';

// ─── Night Shift Tips ───────────────────────────────────────────────────────

const List<Map<String, String>> _nightShiftTips = [
  {
    'title': 'Stay Hydrated',
    'tip':
        'Drink plenty of water throughout your shift. Dehydration can make fatigue worse.',
    'icon': '\u{1F4A7}',
  },
  {
    'title': 'Strategic Napping',
    'tip':
        'A 20-minute power nap before your shift can boost alertness significantly.',
    'icon': '\u{1F634}',
  },
  {
    'title': 'Light Exposure',
    'tip':
        'Get bright light during your shift, and wear sunglasses on the way home to help your body clock adjust.',
    'icon': '\u{2600}\u{FE0F}',
  },
  {
    'title': 'Meal Timing',
    'tip':
        'Eat lighter meals during your shift. Heavy meals can make you drowsy.',
    'icon': '\u{1F957}',
  },
  {
    'title': 'Exercise Helps',
    'tip': 'Brief walks or stretches during breaks can keep your energy up.',
    'icon': '\u{1F3C3}',
  },
  {
    'title': 'Sleep Schedule',
    'tip':
        'Keep a consistent sleep schedule, even on days off, to help your circadian rhythm.',
    'icon': '\u{1F319}',
  },
  {
    'title': 'Caffeine Strategy',
    'tip':
        'Use caffeine early in your shift, but avoid it 4-6 hours before bedtime.',
    'icon': '\u{2615}',
  },
  {
    'title': 'Dark Bedroom',
    'tip':
        'Use blackout curtains and eye masks to create darkness for daytime sleeping.',
    'icon': '\u{1F303}',
  },
];

// ─── Filter Type ────────────────────────────────────────────────────────────

enum _NightFilter { all, myTimezone, nearby, sameDepartment }

// ─── Night Owls Page ────────────────────────────────────────────────────────

class NightOwlsPage extends ConsumerStatefulWidget {
  const NightOwlsPage({super.key});

  @override
  ConsumerState<NightOwlsPage> createState() => _NightOwlsPageState();
}

class _NightOwlsPageState extends ConsumerState<NightOwlsPage> {
  _NightFilter _activeFilter = _NightFilter.all;
  late int _tipIndex;

  @override
  void initState() {
    super.initState();
    _tipIndex = Random().nextInt(_nightShiftTips.length);
  }

  @override
  Widget build(BuildContext context) {
    final nightOwlsAsync = ref.watch(nightOwlsProvider);
    final awakeNowAsync = ref.watch(awakeNowProvider);
    final currentUserAsync = ref.watch(currentUserProvider);
    final currentUser = currentUserAsync.valueOrNull;

    // This page always uses a dark theme for the night-shift atmosphere.
    return Theme(
      data: _nightTheme(context),
      child: Builder(
        builder: (context) {
          return Scaffold(
            backgroundColor: const Color(0xFF0F0B15),
            body: Stack(
              children: [
                // ── Background stars ───────────────────────────────────
                const _StarField(),

                // ── Main content ───────────────────────────────────────
                CustomScrollView(
                  slivers: [
                    // ── App Bar ───────────────────────────────────────
                    SliverAppBar(
                      expandedHeight: 140,
                      floating: true,
                      pinned: true,
                      backgroundColor: const Color(
                        0xFF0F0B15,
                      ).withValues(alpha: 0.9),
                      flexibleSpace: FlexibleSpaceBar(
                        title: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Text(
                              '\u{1F319}',
                              style: TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              'Night Owls',
                              style: GoogleFonts.playfairDisplay(
                                fontSize: 20,
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                          ],
                        ),
                        centerTitle: true,
                        background: Container(
                          alignment: Alignment.bottomCenter,
                          padding: const EdgeInsets.only(bottom: 58),
                          child: Text(
                            "Who's awake right now?",
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              color: Colors.white60,
                            ),
                          ),
                        ),
                      ),
                    ),

                    // ── Online count badge ───────────────────────────
                    SliverToBoxAdapter(
                      child: awakeNowAsync.when(
                        data: (users) => _OnlineCountBadge(count: users.length),
                        loading: () => _OnlineCountBadge(count: 0),
                        error: (_, __) => _OnlineCountBadge(count: 0),
                      ),
                    ),

                    // ── Horizontal online avatars ────────────────────
                    SliverToBoxAdapter(
                      child: nightOwlsAsync.when(
                        data: (owls) => owls.isEmpty
                            ? const SizedBox.shrink()
                            : _OnlineAvatarStrip(users: owls),
                        loading: () => const SizedBox(
                          height: 100,
                          child: Center(
                            child: CircularProgressIndicator(
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        ),
                        error: (_, __) => const SizedBox.shrink(),
                      ),
                    ),

                    // ── Filter chips ─────────────────────────────────
                    SliverToBoxAdapter(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16,
                          vertical: 8,
                        ),
                        child: SingleChildScrollView(
                          scrollDirection: Axis.horizontal,
                          child: Row(
                            children: _NightFilter.values.map((filter) {
                              final isSelected = filter == _activeFilter;
                              return Padding(
                                padding: const EdgeInsets.only(right: 8),
                                child: ChoiceChip(
                                  label: Text(
                                    _filterLabel(filter),
                                    style: GoogleFonts.plusJakartaSans(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: isSelected
                                          ? Colors.white
                                          : Colors.white70,
                                    ),
                                  ),
                                  selected: isSelected,
                                  selectedColor: const Color(0xFF0284C7),
                                  backgroundColor: Colors.white.withValues(
                                    alpha: 0.08,
                                  ),
                                  showCheckmark: false,
                                  side: BorderSide(
                                    color: isSelected
                                        ? const Color(0xFF0284C7)
                                        : Colors.white24,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(14),
                                  ),
                                  onSelected: (_) {
                                    setState(() => _activeFilter = filter);
                                  },
                                ),
                              );
                            }).toList(),
                          ),
                        ),
                      ),
                    ),

                    // ── Night owl list / empty state ─────────────────
                    awakeNowAsync.when(
                      data: (users) {
                        final filtered = _applyFilter(users, currentUser);
                        if (filtered.isEmpty) {
                          return SliverFillRemaining(
                            hasScrollBody: false,
                            child: _EmptyNightState(),
                          );
                        }
                        return SliverPadding(
                          padding: const EdgeInsets.fromLTRB(16, 4, 16, 16),
                          sliver: SliverList(
                            delegate: SliverChildBuilderDelegate((
                              context,
                              index,
                            ) {
                              final user = filtered[index];
                              return _NightOwlCard(
                                user: user,
                                currentUser: currentUser,
                                service: ref.read(nightShiftServiceProvider),
                              ).animate().fadeIn(
                                duration: 350.ms,
                                delay: (60 * index).ms,
                              );
                            }, childCount: filtered.length),
                          ),
                        );
                      },
                      loading: () => const SliverFillRemaining(
                        child: Center(
                          child: CircularProgressIndicator(
                            color: Color(0xFF0284C7),
                          ),
                        ),
                      ),
                      error: (e, _) => SliverFillRemaining(
                        child: Center(
                          child: Text(
                            'Could not load night owls.\n$e',
                            textAlign: TextAlign.center,
                            style: const TextStyle(color: Colors.white54),
                          ),
                        ),
                      ),
                    ),

                    // ── Night Shift Tips Card ────────────────────────
                    SliverToBoxAdapter(
                      child: _NightShiftTipCard(
                        tip: _nightShiftTips[_tipIndex],
                        onNext: () {
                          setState(() {
                            _tipIndex =
                                (_tipIndex + 1) % _nightShiftTips.length;
                          });
                        },
                      ),
                    ),

                    // Bottom padding
                    const SliverToBoxAdapter(child: SizedBox(height: 100)),
                  ],
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  List<UserModel> _applyFilter(List<UserModel> users, UserModel? currentUser) {
    if (currentUser == null) return users;

    // Exclude the current user from the list.
    var filtered = users.where((u) => u.id != currentUser.id).toList();

    switch (_activeFilter) {
      case _NightFilter.all:
        return filtered;
      case _NightFilter.myTimezone:
        if (currentUser.timezone == null) return filtered;
        return filtered
            .where((u) => u.timezone == currentUser.timezone)
            .toList();
      case _NightFilter.nearby:
        if (currentUser.location == null) return filtered;
        return filtered
            .where((u) => u.location == currentUser.location)
            .toList();
      case _NightFilter.sameDepartment:
        if (currentUser.department == null) return filtered;
        return filtered
            .where((u) => u.department == currentUser.department)
            .toList();
    }
  }

  String _filterLabel(_NightFilter f) {
    switch (f) {
      case _NightFilter.all:
        return 'All Night Owls';
      case _NightFilter.myTimezone:
        return 'My Timezone';
      case _NightFilter.nearby:
        return 'Nearby';
      case _NightFilter.sameDepartment:
        return 'Same Department';
    }
  }

  ThemeData _nightTheme(BuildContext context) {
    return ThemeData.dark().copyWith(
      scaffoldBackgroundColor: const Color(0xFF0F0B15),
      colorScheme: const ColorScheme.dark(
        primary: Color(0xFF0284C7),
        secondary: Color(0xFFFB7185),
        tertiary: Color(0xFFFBBF24),
        surface: Color(0xFF1A1523),
        onSurface: Colors.white,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: const Color(0xFF0F0B15),
        foregroundColor: Colors.white,
        elevation: 0,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: Colors.white,
        ),
      ),
    );
  }
}

// ─── Star Field Background ──────────────────────────────────────────────────

class _StarField extends StatelessWidget {
  const _StarField();

  @override
  Widget build(BuildContext context) {
    final random = Random(42); // Fixed seed for consistent stars.
    final size = MediaQuery.of(context).size;

    return Stack(
      children: List.generate(35, (i) {
        final left = random.nextDouble() * size.width;
        final top = random.nextDouble() * size.height;
        final starSize = 1.0 + random.nextDouble() * 2.5;
        final delay = (random.nextDouble() * 3000).toInt();

        return Positioned(
          left: left,
          top: top,
          child:
              Container(
                    width: starSize,
                    height: starSize,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(
                        alpha: 0.4 + random.nextDouble() * 0.5,
                      ),
                      shape: BoxShape.circle,
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .fadeIn(duration: 600.ms, delay: delay.ms)
                  .then()
                  .fadeOut(duration: 1200.ms)
                  .then()
                  .fadeIn(duration: 800.ms),
        );
      }),
    );
  }
}

// ─── Online Count Badge ─────────────────────────────────────────────────────

class _OnlineCountBadge extends StatelessWidget {
  const _OnlineCountBadge({required this.count});

  final int count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 7),
            decoration: BoxDecoration(
              color: const Color(0xFF059669).withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: const Color(0xFF059669).withValues(alpha: 0.4),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                      width: 8,
                      height: 8,
                      decoration: const BoxDecoration(
                        color: Color(0xFF059669),
                        shape: BoxShape.circle,
                      ),
                    )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1, 1),
                      end: const Offset(1.3, 1.3),
                      duration: 1000.ms,
                    ),
                const SizedBox(width: 8),
                Text(
                  '$count Currently Online',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: const Color(0xFF059669),
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

// ─── Online Avatar Strip ────────────────────────────────────────────────────

class _OnlineAvatarStrip extends StatelessWidget {
  const _OnlineAvatarStrip({required this.users});

  final List<UserModel> users;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        itemCount: users.length,
        separatorBuilder: (_, __) => const SizedBox(width: 14),
        itemBuilder: (context, index) {
          final user = users[index];
          return Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Pulsing avatar with green ring.
              Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: const Color(0xFF059669),
                        width: 2.5,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFF059669).withValues(alpha: 0.3),
                          blurRadius: 12,
                          spreadRadius: 1,
                        ),
                      ],
                    ),
                    child: ClipOval(
                      child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                          ? CachedNetworkImage(
                              imageUrl: user.photoUrl!,
                              fit: BoxFit.cover,
                              placeholder: (_, __) => Container(
                                color: const Color(0xFF231E2E),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                              errorWidget: (_, __, ___) => Container(
                                color: const Color(0xFF231E2E),
                                child: const Icon(
                                  Icons.person,
                                  color: Color(0xFF0284C7),
                                ),
                              ),
                            )
                          : Container(
                              color: const Color(0xFF231E2E),
                              child: const Icon(
                                Icons.person,
                                color: Color(0xFF0284C7),
                                size: 28,
                              ),
                            ),
                    ),
                  )
                  .animate(onPlay: (c) => c.repeat(reverse: true))
                  .scale(
                    begin: const Offset(1, 1),
                    end: const Offset(1.05, 1.05),
                    duration: 1500.ms,
                  ),
              const SizedBox(height: 4),
              Text(
                user.name.split(' ').first,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: Colors.white70,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

// ─── Night Owl Card ─────────────────────────────────────────────────────────

class _NightOwlCard extends StatelessWidget {
  const _NightOwlCard({
    required this.user,
    required this.currentUser,
    required this.service,
  });

  final UserModel user;
  final UserModel? currentUser;
  final NightShiftService service;

  @override
  Widget build(BuildContext context) {
    final localTime = NightShiftService.localTimeString(user.timezone);
    final cityName = NightShiftService.friendlyTimezone(user.timezone);
    final compatibility = currentUser != null
        ? service.getShiftCompatibility(currentUser!, user)
        : 0;

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF1A1523),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0284C7).withValues(alpha: 0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        children: [
          // Avatar with green online ring.
          Stack(
            children: [
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: const Color(0xFF059669),
                    width: 2.5,
                  ),
                ),
                child: ClipOval(
                  child: user.photoUrl != null && user.photoUrl!.isNotEmpty
                      ? CachedNetworkImage(
                          imageUrl: user.photoUrl!,
                          fit: BoxFit.cover,
                          placeholder: (_, __) => Container(
                            color: const Color(0xFF231E2E),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                          errorWidget: (_, __, ___) => Container(
                            color: const Color(0xFF231E2E),
                            child: const Icon(
                              Icons.person,
                              color: Color(0xFF0284C7),
                            ),
                          ),
                        )
                      : Container(
                          color: const Color(0xFF231E2E),
                          child: const Icon(
                            Icons.person,
                            size: 28,
                            color: Color(0xFF0284C7),
                          ),
                        ),
                ),
              ),
              // Online indicator dot
              Positioned(
                bottom: 2,
                right: 2,
                child: Container(
                  width: 14,
                  height: 14,
                  decoration: BoxDecoration(
                    color: const Color(0xFF059669),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: const Color(0xFF1A1523),
                      width: 2,
                    ),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(width: 12),

          // User info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      user.name,
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 15,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    if (user.age != null) ...[
                      const SizedBox(width: 6),
                      Text(
                        '${user.age}',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 13,
                          color: Colors.white54,
                        ),
                      ),
                    ],
                  ],
                ),
                const SizedBox(height: 2),
                if (user.jobTitle != null)
                  Text(
                    user.jobTitle!,
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      color: Colors.white60,
                    ),
                  ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    // Local time
                    if (localTime.isNotEmpty) ...[
                      const Icon(
                        Icons.access_time_rounded,
                        size: 13,
                        color: Color(0xFFFBBF24),
                      ),
                      const SizedBox(width: 3),
                      Text(
                        '$localTime in $cityName',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 11,
                          color: const Color(0xFFFBBF24),
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                    const Spacer(),
                    // Shift badge
                    if (user.shiftType != null)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: const Color(0xFF0284C7).withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          user.shiftType!.displayName,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: const Color(0xFF0284C7),
                          ),
                        ),
                      ),
                  ],
                ),
              ],
            ),
          ),

          const SizedBox(width: 8),

          // Right side: compatibility + actions
          Column(
            children: [
              // Compatibility score
              if (currentUser != null)
                Container(
                  width: 40,
                  height: 40,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    gradient: LinearGradient(
                      colors: [
                        _compatColor(compatibility),
                        _compatColor(compatibility).withValues(alpha: 0.6),
                      ],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                  ),
                  child: Center(
                    child: Text(
                      '$compatibility%',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
              const SizedBox(height: 6),
              // Wave + Message buttons
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  _SmallIconButton(
                    icon: Icons.waving_hand_rounded,
                    color: const Color(0xFFFBBF24),
                    tooltip: 'Wave',
                    onTap: () {
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Waved at ${user.name}!',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF0284C7),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                  const SizedBox(width: 6),
                  _SmallIconButton(
                    icon: Icons.chat_bubble_rounded,
                    color: const Color(0xFFFB7185),
                    tooltip: 'Message',
                    onTap: () {
                      // Navigate to chat with this user.
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text(
                            'Opening chat with ${user.name}...',
                            style: const TextStyle(color: Colors.white),
                          ),
                          backgroundColor: const Color(0xFF0284C7),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Color _compatColor(int score) {
    if (score >= 80) return const Color(0xFF059669);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFDC2626);
    return const Color(0xFF78716C);
  }
}

// ─── Small Icon Button ──────────────────────────────────────────────────────

class _SmallIconButton extends StatelessWidget {
  const _SmallIconButton({
    required this.icon,
    required this.color,
    required this.tooltip,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final String tooltip;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(10),
        child: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(icon, size: 16, color: color),
        ),
      ),
    );
  }
}

// ─── Empty Night State ──────────────────────────────────────────────────────

class _EmptyNightState extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('\u{1F319}', style: TextStyle(fontSize: 64))
                .animate(onPlay: (c) => c.repeat(reverse: true))
                .scale(
                  begin: const Offset(1, 1),
                  end: const Offset(1.1, 1.1),
                  duration: 2000.ms,
                ),
            const SizedBox(height: 20),
            Text(
              'The night owls are sleeping!',
              textAlign: TextAlign.center,
              style: GoogleFonts.playfairDisplay(
                fontSize: 22,
                fontWeight: FontWeight.w600,
                color: Colors.white70,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Come back when the moon is out.\nNight owls are most active between 7 PM and 7 AM.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 14,
                color: Colors.white38,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Night Shift Tip Card ───────────────────────────────────────────────────

class _NightShiftTipCard extends StatelessWidget {
  const _NightShiftTipCard({required this.tip, required this.onNext});

  final Map<String, String> tip;
  final VoidCallback onNext;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              const Color(0xFF0284C7).withValues(alpha: 0.15),
              const Color(0xFFFB7185).withValues(alpha: 0.1),
            ],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
            color: const Color(0xFF0284C7).withValues(alpha: 0.2),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(tip['icon'] ?? '', style: const TextStyle(fontSize: 22)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Night Shift Tip',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: const Color(0xFFFBBF24),
                      letterSpacing: 1,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: onNext,
                  child: Container(
                    padding: const EdgeInsets.all(6),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Icon(
                      Icons.refresh_rounded,
                      size: 16,
                      color: Colors.white54,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              tip['title'] ?? '',
              style: GoogleFonts.playfairDisplay(
                fontSize: 18,
                fontWeight: FontWeight.w600,
                color: Colors.white,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              tip['tip'] ?? '',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                color: Colors.white60,
                height: 1.5,
              ),
            ),
          ],
        ),
      ),
    ).animate().fadeIn(duration: 400.ms);
  }
}
