import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';
import 'package:nightingale_heart/features/discover/providers/discover_provider.dart';

/// Bottom sheet that allows the user to fine-tune discovery filters such as
/// gender, age range, department, shift type, language, distance, and
/// verified-only toggle.
class FilterSheet extends ConsumerStatefulWidget {
  const FilterSheet({super.key});

  @override
  ConsumerState<FilterSheet> createState() => _FilterSheetState();
}

class _FilterSheetState extends ConsumerState<FilterSheet> {
  // Local copies of filter values so we only apply on tap.
  late String? _gender;
  late RangeValues _ageRange;
  late String? _department;
  late String? _shiftType;
  late String? _language;
  late double _distance;
  late bool _verifiedOnly;

  static const _departments = [
    'All',
    'Emergency',
    'ICU',
    'Surgery',
    'Pediatrics',
    'Oncology',
    'Cardiology',
    'Mental Health',
    'General Ward',
    'Outpatient',
  ];

  static const _languages = [
    'All',
    'English',
    'Japanese',
    'Korean',
    'Spanish',
    'French',
    'German',
    'Portuguese',
    'Mandarin',
    'Arabic',
    'Hindi',
    'Filipino',
  ];

  @override
  void initState() {
    super.initState();
    final filters = ref.read(filtersProvider);
    _gender = filters.gender;
    _ageRange = RangeValues(
      filters.ageMin.toDouble(),
      filters.ageMax.toDouble(),
    );
    _department = filters.department;
    _shiftType = filters.shiftType;
    _language = filters.language;
    _distance = filters.distanceKm;
    _verifiedOnly = filters.verifiedOnly;
  }

  void _apply() {
    final notifier = ref.read(filtersProvider.notifier);
    notifier.updateGender(_gender);
    notifier.updateAge(_ageRange.start.round(), _ageRange.end.round());
    notifier.updateDepartment(_department);
    notifier.updateShiftType(_shiftType);
    notifier.updateLanguage(_language);
    notifier.updateDistance(_distance);
    notifier.updateVerifiedOnly(_verifiedOnly);
    Navigator.of(context).pop();
  }

  void _reset() {
    setState(() {
      _gender = null;
      _ageRange = const RangeValues(18, 60);
      _department = null;
      _shiftType = null;
      _language = null;
      _distance = 100;
      _verifiedOnly = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      decoration: BoxDecoration(
        color: theme.scaffoldBackgroundColor,
        borderRadius: const BorderRadius.vertical(
          top: Radius.circular(AppTheme.borderRadiusLarge),
        ),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          const SizedBox(height: 12),
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: theme.dividerColor,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 16),

          // Title row
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Discovery Filters',
                  style: GoogleFonts.playfairDisplay(
                    fontSize: 22,
                    fontWeight: FontWeight.w700,
                    color: theme.colorScheme.onSurface,
                  ),
                ),
                TextButton(
                  onPressed: _reset,
                  child: Text(
                    'Reset All',
                    style: GoogleFonts.plusJakartaSans(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.warmRose,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 8),

          // Scrollable content
          Flexible(
            child: SingleChildScrollView(
              padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // ── Gender ────────────────────────────────────────────
                  _SectionLabel(label: 'Gender'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected: _gender == null || _gender == 'all',
                        onTap: () => setState(() => _gender = null),
                      ),
                      _FilterChip(
                        label: 'Male',
                        isSelected: _gender == 'male',
                        onTap: () => setState(() => _gender = 'male'),
                      ),
                      _FilterChip(
                        label: 'Female',
                        isSelected: _gender == 'female',
                        onTap: () => setState(() => _gender = 'female'),
                      ),
                      _FilterChip(
                        label: 'Non-Binary',
                        isSelected: _gender == 'nonBinary',
                        onTap: () => setState(() => _gender = 'nonBinary'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Age range ─────────────────────────────────────────
                  _SectionLabel(
                    label:
                        'Age Range (${_ageRange.start.round()} - ${_ageRange.end.round()})',
                  ),
                  const SizedBox(height: 4),
                  RangeSlider(
                    values: _ageRange,
                    min: 18,
                    max: 80,
                    divisions: 62,
                    activeColor: AppTheme.deepPlum,
                    inactiveColor: AppTheme.softLavender,
                    labels: RangeLabels(
                      _ageRange.start.round().toString(),
                      _ageRange.end.round().toString(),
                    ),
                    onChanged: (v) => setState(() => _ageRange = v),
                  ),

                  const SizedBox(height: 16),

                  // ── Department ─────────────────────────────────────────
                  _SectionLabel(label: 'Department'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _department ?? 'All',
                    items: _departments,
                    onChanged: (v) => setState(
                      () => _department = v == 'All' ? null : v,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Shift type ─────────────────────────────────────────
                  _SectionLabel(label: 'Shift Type'),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    children: [
                      _FilterChip(
                        label: 'All',
                        isSelected:
                            _shiftType == null || _shiftType == 'all',
                        onTap: () => setState(() => _shiftType = null),
                      ),
                      _FilterChip(
                        label: 'Day',
                        icon: Icons.wb_sunny_rounded,
                        isSelected: _shiftType == 'dayShift',
                        onTap: () =>
                            setState(() => _shiftType = 'dayShift'),
                      ),
                      _FilterChip(
                        label: 'Night',
                        icon: Icons.nightlight_round,
                        isSelected: _shiftType == 'nightShift',
                        onTap: () =>
                            setState(() => _shiftType = 'nightShift'),
                      ),
                      _FilterChip(
                        label: 'Rotating',
                        icon: Icons.sync,
                        isSelected: _shiftType == 'rotatingShift',
                        onTap: () =>
                            setState(() => _shiftType = 'rotatingShift'),
                      ),
                      _FilterChip(
                        label: 'Flexible',
                        icon: Icons.schedule,
                        isSelected: _shiftType == 'flexible',
                        onTap: () =>
                            setState(() => _shiftType = 'flexible'),
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Language ────────────────────────────────────────────
                  _SectionLabel(label: 'Language'),
                  const SizedBox(height: 8),
                  _DropdownField(
                    value: _language ?? 'All',
                    items: _languages,
                    onChanged: (v) => setState(
                      () => _language = v == 'All' ? null : v,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // ── Distance ───────────────────────────────────────────
                  _SectionLabel(
                    label: 'Distance (${_distance.round()} km)',
                  ),
                  const SizedBox(height: 4),
                  Slider(
                    value: _distance,
                    min: 10,
                    max: 500,
                    divisions: 49,
                    activeColor: AppTheme.deepPlum,
                    inactiveColor: AppTheme.softLavender,
                    label: '${_distance.round()} km',
                    onChanged: (v) => setState(() => _distance = v),
                  ),

                  const SizedBox(height: 16),

                  // ── Verified only ──────────────────────────────────────
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          const Icon(
                            Icons.verified,
                            color: AppTheme.softAmber,
                            size: 20,
                          ),
                          const SizedBox(width: 8),
                          Text(
                            'Show Verified Only',
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                              color: theme.colorScheme.onSurface,
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _verifiedOnly,
                        onChanged: (v) =>
                            setState(() => _verifiedOnly = v),
                        activeColor: AppTheme.deepPlum,
                      ),
                    ],
                  ),

                  const SizedBox(height: 24),

                  // ── Apply button ───────────────────────────────────────
                  SizedBox(
                    width: double.infinity,
                    height: 54,
                    child: DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: AppTheme.primaryGradient,
                        borderRadius: BorderRadius.circular(
                          AppTheme.borderRadiusMedium,
                        ),
                      ),
                      child: ElevatedButton(
                        onPressed: _apply,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Colors.transparent,
                          shadowColor: Colors.transparent,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(
                              AppTheme.borderRadiusMedium,
                            ),
                          ),
                        ),
                        child: Text(
                          'Apply Filters',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 16,
                            fontWeight: FontWeight.w700,
                            color: Colors.white,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Helper widgets ─────────────────────────────────────────────────────────

class _SectionLabel extends StatelessWidget {
  const _SectionLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: GoogleFonts.plusJakartaSans(
        fontSize: 13,
        fontWeight: FontWeight.w700,
        color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
        letterSpacing: 0.5,
      ),
    );
  }
}

class _FilterChip extends StatelessWidget {
  const _FilterChip({
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.icon,
  });

  final String label;
  final bool isSelected;
  final VoidCallback onTap;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.deepPlum
              : AppTheme.softLavender,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(
            color: isSelected
                ? AppTheme.deepPlum
                : Colors.transparent,
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (icon != null) ...[
              Icon(
                icon,
                size: 14,
                color: isSelected ? Colors.white : AppTheme.deepPlum,
              ),
              const SizedBox(width: 4),
            ],
            Text(
              label,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : AppTheme.deepPlum,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DropdownField extends StatelessWidget {
  const _DropdownField({
    required this.value,
    required this.items,
    required this.onChanged,
  });

  final String value;
  final List<String> items;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: theme.inputDecorationTheme.fillColor ?? AppTheme.softLavender,
        borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
        border: Border.all(color: theme.dividerColor),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          icon: const Icon(Icons.keyboard_arrow_down_rounded),
          style: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            color: theme.colorScheme.onSurface,
          ),
          dropdownColor: theme.cardTheme.color ?? Colors.white,
          borderRadius: BorderRadius.circular(AppTheme.borderRadiusMedium),
          items: items
              .map((item) => DropdownMenuItem(
                    value: item,
                    child: Text(item),
                  ))
              .toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
