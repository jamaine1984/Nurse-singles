import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';

import 'package:nightingale_heart/core/config/app_constants.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/compatibility/services/compatibility_service.dart';

// ─── Compatibility Page ─────────────────────────────────────────────────────

class CompatibilityPage extends ConsumerStatefulWidget {
  const CompatibilityPage({super.key});

  @override
  ConsumerState<CompatibilityPage> createState() => _CompatibilityPageState();
}

class _CompatibilityPageState extends ConsumerState<CompatibilityPage> {
  ShiftType? _filterShiftType;
  int _minCompatibility = 0;
  bool _howItWorksExpanded = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final userAsync = ref.watch(currentUserProvider);
    final currentUser = userAsync.valueOrNull;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          // ── App Bar ──────────────────────────────────────────────────
          SliverAppBar(
            expandedHeight: 120,
            floating: true,
            pinned: true,
            flexibleSpace: FlexibleSpaceBar(
              title: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.favorite_rounded,
                    size: 18,
                    color: Color(0xFFDC2626),
                  ),
                  const SizedBox(width: 4),
                  const Icon(
                    Icons.medical_services_rounded,
                    size: 16,
                    color: Color(0xFF0F766E),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Compatibility',
                    style: GoogleFonts.playfairDisplay(
                      fontSize: 20,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
              centerTitle: true,
            ),
          ),

          // ── Your Schedule Card ───────────────────────────────────────
          if (currentUser != null)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
                child: _YourScheduleCard(user: currentUser),
              ),
            ),

          // ── Filters ──────────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: _FiltersRow(
                selectedShiftType: _filterShiftType,
                minCompatibility: _minCompatibility,
                onShiftChanged: (v) => setState(() => _filterShiftType = v),
                onMinChanged: (v) => setState(() => _minCompatibility = v),
              ),
            ),
          ),

          // ── Best Matches Section Title ───────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 4),
              child: Text(
                'Best Matches by Schedule',
                style: GoogleFonts.playfairDisplay(
                  fontSize: 20,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
            ),
          ),

          // ── Compatible Users List ────────────────────────────────────
          if (currentUser != null)
            _CompatibleUsersList(
              currentUser: currentUser,
              filterShiftType: _filterShiftType,
              minCompatibility: _minCompatibility,
            )
          else
            const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),

          // ── How It Works ─────────────────────────────────────────────
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              child: _HowItWorksCard(
                isExpanded: _howItWorksExpanded,
                onToggle: () {
                  setState(() => _howItWorksExpanded = !_howItWorksExpanded);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Your Schedule Card ─────────────────────────────────────────────────────

class _YourScheduleCard extends StatelessWidget {
  const _YourScheduleCard({required this.user});

  final UserModel user;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFF0F766E), Color(0xFFDC2626)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF0F766E).withValues(alpha: 0.25),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                color: Colors.white70,
                size: 20,
              ),
              const SizedBox(width: 8),
              Text(
                'Your Schedule',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 14,
                  fontWeight: FontWeight.w600,
                  color: Colors.white70,
                  letterSpacing: 0.5,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              // Shift type badge
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Text(
                  user.shiftType?.displayName ?? 'Not Set',
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 14,
                    fontWeight: FontWeight.w600,
                    color: Colors.white,
                  ),
                ),
              ),
              const Spacer(),
              if (user.department != null)
                Text(
                  user.department!,
                  style: GoogleFonts.plusJakartaSans(
                    fontSize: 13,
                    color: Colors.white60,
                  ),
                ),
            ],
          ),
          const SizedBox(height: 16),

          // 24-hour clock visualization
          _ScheduleClockVisualization(shiftType: user.shiftType),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms).slideY(begin: -0.05, end: 0);
  }
}

// ─── 24-Hour Clock Visualization ────────────────────────────────────────────

class _ScheduleClockVisualization extends StatelessWidget {
  const _ScheduleClockVisualization({this.shiftType});

  final ShiftType? shiftType;

  @override
  Widget build(BuildContext context) {
    // Define time blocks based on shift type.
    // Each block: (start hour, end hour, label, color).
    List<_TimeBlock> blocks;

    switch (shiftType) {
      case ShiftType.dayShift:
        blocks = [
          _TimeBlock(0, 6, 'Sleep', const Color(0xFF1E1B4B)),
          _TimeBlock(6, 7, 'Commute', const Color(0xFF4338CA)),
          _TimeBlock(7, 19, 'Work', const Color(0xFF059669)),
          _TimeBlock(19, 21, 'Free', const Color(0xFFF59E0B)),
          _TimeBlock(21, 24, 'Sleep', const Color(0xFF1E1B4B)),
        ];
      case ShiftType.nightShift:
        blocks = [
          _TimeBlock(0, 7, 'Work', const Color(0xFF059669)),
          _TimeBlock(7, 8, 'Commute', const Color(0xFF4338CA)),
          _TimeBlock(8, 16, 'Sleep', const Color(0xFF1E1B4B)),
          _TimeBlock(16, 19, 'Free', const Color(0xFFF59E0B)),
          _TimeBlock(19, 24, 'Work', const Color(0xFF059669)),
        ];
      case ShiftType.rotatingShift:
        blocks = [
          _TimeBlock(0, 6, 'Varies', const Color(0xFF7C3AED)),
          _TimeBlock(6, 18, 'Work/Rest', const Color(0xFF059669)),
          _TimeBlock(18, 24, 'Varies', const Color(0xFF7C3AED)),
        ];
      case ShiftType.flexible:
      case null:
        blocks = [
          _TimeBlock(0, 8, 'Sleep', const Color(0xFF1E1B4B)),
          _TimeBlock(8, 17, 'Work', const Color(0xFF059669)),
          _TimeBlock(17, 22, 'Free', const Color(0xFFF59E0B)),
          _TimeBlock(22, 24, 'Sleep', const Color(0xFF1E1B4B)),
        ];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Hour markers
        Row(
          children: [
            _hourLabel('12AM'),
            const Spacer(),
            _hourLabel('6AM'),
            const Spacer(),
            _hourLabel('12PM'),
            const Spacer(),
            _hourLabel('6PM'),
            const Spacer(),
            _hourLabel('12AM'),
          ],
        ),
        const SizedBox(height: 4),
        // Color bar
        ClipRRect(
          borderRadius: BorderRadius.circular(6),
          child: SizedBox(
            height: 18,
            child: Row(
              children: blocks.map((block) {
                final widthFraction = (block.endHour - block.startHour) / 24;
                return Expanded(
                  flex: (widthFraction * 100).round(),
                  child: Container(
                    color: block.color,
                    child: Center(
                      child: Text(
                        block.label,
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 7,
                          fontWeight: FontWeight.w600,
                          color: Colors.white,
                        ),
                        overflow: TextOverflow.clip,
                        maxLines: 1,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ),
        ),
        const SizedBox(height: 8),
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            _legendDot(const Color(0xFF059669), 'Work'),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFF1E1B4B), 'Sleep'),
            const SizedBox(width: 12),
            _legendDot(const Color(0xFFF59E0B), 'Free'),
          ],
        ),
      ],
    );
  }

  Widget _hourLabel(String text) {
    return Text(
      text,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 9,
        color: Colors.white38,
        fontWeight: FontWeight.w500,
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 8,
          height: 8,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 4),
        Text(
          label,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 10,
            color: Colors.white54,
          ),
        ),
      ],
    );
  }
}

class _TimeBlock {
  const _TimeBlock(this.startHour, this.endHour, this.label, this.color);
  final int startHour;
  final int endHour;
  final String label;
  final Color color;
}

// ─── Filters Row ────────────────────────────────────────────────────────────

class _FiltersRow extends StatelessWidget {
  const _FiltersRow({
    required this.selectedShiftType,
    required this.minCompatibility,
    required this.onShiftChanged,
    required this.onMinChanged,
  });

  final ShiftType? selectedShiftType;
  final int minCompatibility;
  final ValueChanged<ShiftType?> onShiftChanged;
  final ValueChanged<int> onMinChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Row(
      children: [
        // Shift type filter
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<ShiftType?>(
                value: selectedShiftType,
                isExpanded: true,
                hint: Text(
                  'All Shifts',
                  style: GoogleFonts.plusJakartaSans(fontSize: 13),
                ),
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: [
                  DropdownMenuItem<ShiftType?>(
                    value: null,
                    child: Text(
                      'All Shifts',
                      style: GoogleFonts.plusJakartaSans(fontSize: 13),
                    ),
                  ),
                  ...ShiftType.values.map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.displayName,
                        style: GoogleFonts.plusJakartaSans(fontSize: 13),
                      ),
                    ),
                  ),
                ],
                onChanged: onShiftChanged,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        // Min compatibility filter
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: theme.dividerColor),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<int>(
                value: minCompatibility,
                isExpanded: true,
                icon: const Icon(Icons.keyboard_arrow_down_rounded, size: 20),
                items: [0, 20, 40, 60, 80]
                    .map(
                      (v) => DropdownMenuItem(
                        value: v,
                        child: Text(
                          v == 0 ? 'Min: Any' : 'Min: $v%',
                          style: GoogleFonts.plusJakartaSans(fontSize: 13),
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => onMinChanged(v ?? 0),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Compatible Users List ──────────────────────────────────────────────────

class _CompatibleUsersList extends ConsumerWidget {
  const _CompatibleUsersList({
    required this.currentUser,
    required this.filterShiftType,
    required this.minCompatibility,
  });

  final UserModel currentUser;
  final ShiftType? filterShiftType;
  final int minCompatibility;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final topAsync = ref.watch(topCompatibleUsersProvider(currentUser));

    return topAsync.when(
      loading: () => const SliverToBoxAdapter(
        child: Padding(
          padding: EdgeInsets.all(40),
          child: Center(child: CircularProgressIndicator()),
        ),
      ),
      error: (e, _) => SliverToBoxAdapter(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Text(
            'Could not load compatible users.\n$e',
            textAlign: TextAlign.center,
            style: GoogleFonts.plusJakartaSans(
              color: Theme.of(context).colorScheme.error,
            ),
          ),
        ),
      ),
      data: (entries) {
        // Apply filters.
        var filtered = entries.where((e) {
          if (e.value.totalScore < minCompatibility) return false;
          if (filterShiftType != null && e.key.shiftType != filterShiftType) {
            return false;
          }
          return true;
        }).toList();

        if (filtered.isEmpty) {
          return SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(32),
              child: Center(
                child: Column(
                  children: [
                    const Icon(
                      Icons.search_off_rounded,
                      size: 48,
                      color: Color(0xFF78716C),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'No matches found with these filters.',
                      style: GoogleFonts.plusJakartaSans(
                        color: const Color(0xFF78716C),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Try lowering the minimum compatibility.',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 12,
                        color: const Color(0xFF78716C),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        }

        return SliverPadding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          sliver: SliverList(
            delegate: SliverChildBuilderDelegate((context, index) {
              final entry = filtered[index];
              return _CompatibleUserCard(
                user: entry.key,
                result: entry.value,
                index: index,
              );
            }, childCount: filtered.length),
          ),
        );
      },
    );
  }
}

// ─── Compatible User Card ───────────────────────────────────────────────────

class _CompatibleUserCard extends StatefulWidget {
  const _CompatibleUserCard({
    required this.user,
    required this.result,
    required this.index,
  });

  final UserModel user;
  final CompatibilityResult result;
  final int index;

  @override
  State<_CompatibleUserCard> createState() => _CompatibleUserCardState();
}

class _CompatibleUserCardState extends State<_CompatibleUserCard>
    with SingleTickerProviderStateMixin {
  bool _showBreakdown = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final score = widget.result.totalScore;
    final scoreColor = _scoreColor(score);

    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: scoreColor.withValues(alpha: 0.1),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
        border: Border.all(
          color: scoreColor.withValues(alpha: 0.15),
          width: 1.5,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () => setState(() => _showBreakdown = !_showBreakdown),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              children: [
                Row(
                  children: [
                    // User avatar
                    Container(
                      width: 60,
                      height: 60,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: scoreColor.withValues(alpha: 0.3),
                          width: 2,
                        ),
                      ),
                      child: ClipOval(
                        child:
                            widget.user.photoUrl != null &&
                                widget.user.photoUrl!.isNotEmpty
                            ? CachedNetworkImage(
                                imageUrl: widget.user.photoUrl!,
                                fit: BoxFit.cover,
                                placeholder: (_, __) => Container(
                                  color: const Color(0xFFF3E8FF),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                                errorWidget: (_, __, ___) => Container(
                                  color: const Color(0xFFF3E8FF),
                                  child: const Icon(
                                    Icons.person_rounded,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                              )
                            : Container(
                                color: const Color(0xFFF3E8FF),
                                child: const Icon(
                                  Icons.person_rounded,
                                  size: 30,
                                  color: Color(0xFF0F766E),
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(width: 12),

                    // User info
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  widget.user.name,
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: theme.colorScheme.onSurface,
                                  ),
                                ),
                              ),
                              if (widget.user.isVerified)
                                const Padding(
                                  padding: EdgeInsets.only(left: 4),
                                  child: Icon(
                                    Icons.verified_rounded,
                                    size: 16,
                                    color: Color(0xFF0F766E),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 2),
                          Text(
                            [
                              if (widget.user.jobTitle != null)
                                widget.user.jobTitle!,
                              if (widget.user.hospital != null)
                                widget.user.hospital!,
                            ].join(' at '),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 12,
                              color: theme.colorScheme.onSurfaceVariant,
                            ),
                          ),
                          const SizedBox(height: 4),
                          // Top reasons
                          if (widget.result.topReasons.isNotEmpty)
                            Text(
                              widget.result.topReasons.first,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: GoogleFonts.plusJakartaSans(
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                                color: scoreColor,
                              ),
                            ),
                          if (widget.result.careSignals.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Wrap(
                              spacing: 6,
                              runSpacing: 6,
                              children: widget.result.careSignals
                                  .take(2)
                                  .map(
                                    (signal) => _CareSignalPill(
                                      label: signal,
                                      color: scoreColor,
                                    ),
                                  )
                                  .toList(),
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(width: 10),

                    // Circular score indicator
                    _CircularScoreIndicator(score: score, color: scoreColor),
                  ],
                ),

                // Expandable breakdown
                if (_showBreakdown) ...[
                  const SizedBox(height: 14),
                  Divider(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                    height: 1,
                  ),
                  const SizedBox(height: 14),
                  _BreakdownBars(result: widget.result),
                  if (widget.result.cautionSignals.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    _CautionPanel(signals: widget.result.cautionSignals),
                  ],
                  const SizedBox(height: 12),
                  // Action buttons
                  Row(
                    children: [
                      Expanded(
                        child: OutlinedButton.icon(
                          onPressed: () {
                            // Navigate to profile view.
                          },
                          icon: const Icon(Icons.person_rounded, size: 18),
                          label: const Text('View Profile'),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            side: BorderSide(color: scoreColor),
                            foregroundColor: scoreColor,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [Color(0xFF0F766E), Color(0xFFDC2626)],
                            ),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: ElevatedButton.icon(
                            onPressed: () {
                              // Send like.
                            },
                            icon: const Icon(
                              Icons.favorite_rounded,
                              size: 18,
                              color: Colors.white,
                            ),
                            label: Text(
                              'Like',
                              style: GoogleFonts.plusJakartaSans(
                                fontWeight: FontWeight.w600,
                                color: Colors.white,
                              ),
                            ),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Colors.transparent,
                              shadowColor: Colors.transparent,
                              padding: const EdgeInsets.symmetric(vertical: 10),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    ).animate().fadeIn(duration: 350.ms, delay: (70 * widget.index).ms);
  }

  Color _scoreColor(int score) {
    if (score >= 80) return const Color(0xFF059669);
    if (score >= 60) return const Color(0xFFF59E0B);
    if (score >= 40) return const Color(0xFFDC2626);
    return const Color(0xFF78716C);
  }
}

// ─── Circular Score Indicator ───────────────────────────────────────────────

class _CareSignalPill extends StatelessWidget {
  const _CareSignalPill({required this.label, required this.color});

  final String label;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.monitor_heart_rounded, size: 12, color: color),
          const SizedBox(width: 4),
          Flexible(
            child: Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 10,
                fontWeight: FontWeight.w700,
                color: color,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }
}

class _CautionPanel extends StatelessWidget {
  const _CautionPanel({required this.signals});

  final List<String> signals;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: const Color(0xFFF59E0B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFF59E0B).withValues(alpha: 0.25),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(
                Icons.privacy_tip_outlined,
                size: 14,
                color: Color(0xFFF59E0B),
              ),
              const SizedBox(width: 6),
              Text(
                'Hospital-safe note',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: const Color(0xFFF59E0B),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ...signals.map(
            (signal) => Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                signal,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  height: 1.25,
                  color: Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CircularScoreIndicator extends StatelessWidget {
  const _CircularScoreIndicator({required this.score, required this.color});

  final int score;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 58,
      height: 58,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Background circle
          SizedBox(
            width: 58,
            height: 58,
            child: CircularProgressIndicator(
              value: score / 100,
              strokeWidth: 5,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation(color),
              strokeCap: StrokeCap.round,
            ),
          ),
          // Score text
          Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                '$score',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                  color: color,
                ),
              ),
              Text(
                '%',
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 10,
                  fontWeight: FontWeight.w600,
                  color: color.withValues(alpha: 0.7),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().scale(
      begin: const Offset(0, 0),
      end: const Offset(1, 1),
      duration: 600.ms,
      curve: Curves.elasticOut,
    );
  }
}

// ─── Breakdown Bars ─────────────────────────────────────────────────────────

class _BreakdownBars extends StatelessWidget {
  const _BreakdownBars({required this.result});

  final CompatibilityResult result;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _BreakdownBar(
          label: 'Shift',
          score: result.shiftScore,
          maxScore: 25,
          color: const Color(0xFF059669),
          icon: Icons.schedule_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Location',
          score: result.locationScore,
          maxScore: 15,
          color: const Color(0xFF2563EB),
          icon: Icons.location_on_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Interests',
          score: result.interestScore,
          maxScore: 15,
          color: const Color(0xFFDC2626),
          icon: Icons.interests_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Languages',
          score: result.languageScore,
          maxScore: 10,
          color: const Color(0xFF7C3AED),
          icon: Icons.translate_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Department',
          score: result.departmentScore,
          maxScore: 15,
          color: const Color(0xFFF59E0B),
          icon: Icons.local_hospital_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Workplace',
          score: result.workplaceScore,
          maxScore: 10,
          color: const Color(0xFF0E7490),
          icon: Icons.privacy_tip_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Verified',
          score: result.verificationScore,
          maxScore: 5,
          color: const Color(0xFF0F766E),
          icon: Icons.verified_rounded,
        ),
        const SizedBox(height: 8),
        _BreakdownBar(
          label: 'Age',
          score: result.ageScore,
          maxScore: 5,
          color: const Color(0xFF06B6D4),
          icon: Icons.cake_rounded,
        ),
      ],
    ).animate().fadeIn(duration: 300.ms);
  }
}

class _BreakdownBar extends StatelessWidget {
  const _BreakdownBar({
    required this.label,
    required this.score,
    required this.maxScore,
    required this.color,
    required this.icon,
  });

  final String label;
  final int score;
  final int maxScore;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final fraction = maxScore > 0 ? (score / maxScore).clamp(0.0, 1.0) : 0.0;

    return Row(
      children: [
        Icon(icon, size: 14, color: color),
        const SizedBox(width: 6),
        SizedBox(
          width: 72,
          child: Text(
            label,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
        ),
        Expanded(
          child: Stack(
            children: [
              Container(
                height: 8,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(4),
                ),
              ),
              FractionallySizedBox(
                widthFactor: fraction,
                child: Container(
                  height: 8,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        SizedBox(
          width: 32,
          child: Text(
            '$score/$maxScore',
            textAlign: TextAlign.right,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}

// ─── How It Works Card ──────────────────────────────────────────────────────

class _HowItWorksCard extends StatelessWidget {
  const _HowItWorksCard({required this.isExpanded, required this.onToggle});

  final bool isExpanded;
  final VoidCallback onToggle;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      decoration: BoxDecoration(
        color: theme.cardTheme.color ?? theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: theme.dividerColor),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: onToggle,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: const Color(0xFF0F766E).withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: const Icon(
                        Icons.help_outline_rounded,
                        size: 20,
                        color: Color(0xFF0F766E),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        'How Compatibility Works',
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    Icon(
                      isExpanded
                          ? Icons.keyboard_arrow_up_rounded
                          : Icons.keyboard_arrow_down_rounded,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
                if (isExpanded) ...[
                  const SizedBox(height: 14),
                  Divider(
                    color: theme.dividerColor.withValues(alpha: 0.5),
                    height: 1,
                  ),
                  const SizedBox(height: 14),
                  _algorithmRow(
                    Icons.schedule_rounded,
                    'Shift Compatibility',
                    'Same shift = 25pts, overlapping = 18pts, opposite = 5pts',
                    const Color(0xFF059669),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.location_on_rounded,
                    'Location Proximity',
                    'Same city = 15pts, same country = 8pts, different = 3pts',
                    const Color(0xFF2563EB),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.interests_rounded,
                    'Shared Interests',
                    '3 points per shared interest, up to 15 points',
                    const Color(0xFFDC2626),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.translate_rounded,
                    'Language Match',
                    '5 points per shared language, up to 10 points',
                    const Color(0xFF7C3AED),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.local_hospital_rounded,
                    'Department Affinity',
                    'Same department = 15pts, related departments = 10pts',
                    const Color(0xFFF59E0B),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.privacy_tip_rounded,
                    'Hospital Privacy Fit',
                    'Respects workplace and same-department preferences',
                    const Color(0xFF0E7490),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.verified_rounded,
                    'Healthcare Verification',
                    'Both verified profiles earn the strongest trust signal',
                    const Color(0xFF0F766E),
                    theme,
                  ),
                  const SizedBox(height: 10),
                  _algorithmRow(
                    Icons.cake_rounded,
                    'Age Proximity',
                    'Within 3 years = 5pts, 5 years = 3pts, 10 years = 1pt',
                    const Color(0xFF06B6D4),
                    theme,
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _algorithmRow(
    IconData icon,
    String title,
    String description,
    Color color,
    ThemeData theme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: theme.colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                description,
                style: GoogleFonts.plusJakartaSans(
                  fontSize: 11,
                  color: theme.colorScheme.onSurfaceVariant,
                  height: 1.4,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
