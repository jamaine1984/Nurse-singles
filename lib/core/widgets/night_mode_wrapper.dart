import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nightingale_heart/core/config/app_theme.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Night Mode State
// ═══════════════════════════════════════════════════════════════════════════

/// Describes why night mode is currently active or inactive.
enum NightModeSource {
  /// User explicitly toggled night mode on or off.
  manual,

  /// The system clock determined the mode automatically (7 PM - 7 AM).
  auto,
}

/// Immutable state for the night-mode feature.
class NightModeState {
  const NightModeState({
    required this.isNightMode,
    required this.source,
    required this.isAutoEnabled,
  });

  /// Whether the UI should currently use the dark theme.
  final bool isNightMode;

  /// Why the current value was chosen.
  final NightModeSource source;

  /// Whether the automatic time-based switching is enabled.
  final bool isAutoEnabled;

  NightModeState copyWith({
    bool? isNightMode,
    NightModeSource? source,
    bool? isAutoEnabled,
  }) {
    return NightModeState(
      isNightMode: isNightMode ?? this.isNightMode,
      source: source ?? this.source,
      isAutoEnabled: isAutoEnabled ?? this.isAutoEnabled,
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Night Mode Notifier
// ═══════════════════════════════════════════════════════════════════════════

/// SharedPreferences keys.
const _kNightModeManual = 'night_mode_manual';
const _kNightModeAuto = 'night_mode_auto';
const _kNightModeOn = 'night_mode_on';

/// A [StateNotifier] that manages night/dark mode state.
///
/// - On first launch, auto-mode is enabled by default.
/// - In auto-mode the theme switches to dark between 19:00 and 07:00.
/// - The user can override with a manual toggle; that disables auto-mode.
/// - All preferences are persisted via [SharedPreferences].
class NightModeNotifier extends StateNotifier<NightModeState> {
  NightModeNotifier()
      : super(const NightModeState(
          isNightMode: false,
          source: NightModeSource.auto,
          isAutoEnabled: true,
        )) {
    _init();
  }

  Future<void> _init() async {
    final prefs = await SharedPreferences.getInstance();
    final isManual = prefs.getBool(_kNightModeManual) ?? false;
    final isAutoEnabled = prefs.getBool(_kNightModeAuto) ?? true;

    if (isManual) {
      final manualOn = prefs.getBool(_kNightModeOn) ?? false;
      state = NightModeState(
        isNightMode: manualOn,
        source: NightModeSource.manual,
        isAutoEnabled: isAutoEnabled,
      );
    } else {
      state = NightModeState(
        isNightMode: _isNightHours(),
        source: NightModeSource.auto,
        isAutoEnabled: isAutoEnabled,
      );
    }
  }

  /// Returns true if the current local time is between 19:00 and 07:00.
  static bool _isNightHours() {
    final hour = DateTime.now().hour;
    return hour >= 19 || hour < 7;
  }

  /// Manually toggle night mode on/off.
  Future<void> toggle() async {
    final newValue = !state.isNightMode;
    state = NightModeState(
      isNightMode: newValue,
      source: NightModeSource.manual,
      isAutoEnabled: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNightModeManual, true);
    await prefs.setBool(_kNightModeOn, newValue);
    await prefs.setBool(_kNightModeAuto, false);
  }

  /// Explicitly set night mode on or off (manual).
  Future<void> setNightMode(bool value) async {
    state = NightModeState(
      isNightMode: value,
      source: NightModeSource.manual,
      isAutoEnabled: false,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNightModeManual, true);
    await prefs.setBool(_kNightModeOn, value);
    await prefs.setBool(_kNightModeAuto, false);
  }

  /// Re-enable automatic time-based switching.
  Future<void> enableAutoMode() async {
    state = NightModeState(
      isNightMode: _isNightHours(),
      source: NightModeSource.auto,
      isAutoEnabled: true,
    );
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_kNightModeManual, false);
    await prefs.setBool(_kNightModeAuto, true);
    await prefs.remove(_kNightModeOn);
  }

  /// Call periodically (e.g. from a timer) to re-evaluate auto mode.
  void refresh() {
    if (state.isAutoEnabled && state.source == NightModeSource.auto) {
      final shouldBeDark = _isNightHours();
      if (shouldBeDark != state.isNightMode) {
        state = state.copyWith(isNightMode: shouldBeDark);
      }
    }
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Riverpod Provider
// ═══════════════════════════════════════════════════════════════════════════

/// Global provider for night-mode state. Widgets can watch this to rebuild
/// when the theme changes.
///
/// ```dart
/// final nightState = ref.watch(nightModeProvider);
/// final theme = nightState.isNightMode ? AppTheme.darkTheme : AppTheme.lightTheme;
/// ```
final nightModeProvider =
    StateNotifierProvider<NightModeNotifier, NightModeState>(
  (ref) => NightModeNotifier(),
);

// ═══════════════════════════════════════════════════════════════════════════
// NightModeWrapper Widget
// ═══════════════════════════════════════════════════════════════════════════

/// Wraps its [child] in an [AnimatedTheme] that smoothly transitions between
/// the light and dark Nurse Singles themes based on [nightModeProvider].
///
/// Place this high in the widget tree (typically around [MaterialApp] or just
/// inside it) so that the entire app responds to night-mode changes.
///
/// The widget also sets up a periodic timer that re-evaluates auto-mode
/// every 60 seconds so the theme flips at 7 PM / 7 AM without user action.
class NightModeWrapper extends ConsumerStatefulWidget {
  const NightModeWrapper({super.key, required this.child});

  final Widget child;

  @override
  ConsumerState<NightModeWrapper> createState() => _NightModeWrapperState();
}

class _NightModeWrapperState extends ConsumerState<NightModeWrapper> {
  late final Stream<void> _ticker;

  @override
  void initState() {
    super.initState();
    // Periodic refresh every 60 s for auto-mode clock checks.
    _ticker = Stream.periodic(const Duration(seconds: 60));
    _ticker.listen((_) {
      if (mounted) {
        ref.read(nightModeProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final nightState = ref.watch(nightModeProvider);
    final theme =
        nightState.isNightMode ? AppTheme.darkTheme : AppTheme.lightTheme;

    return AnimatedTheme(
      data: theme,
      duration: const Duration(milliseconds: 500),
      curve: Curves.easeInOut,
      child: widget.child,
    );
  }
}
