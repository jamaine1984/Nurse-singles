import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/providers/app_providers.dart';
import 'package:nightingale_heart/features/discover/services/discover_service.dart';

// ─── Filters state ──────────────────────────────────────────────────────────

/// Immutable value object that holds all discovery filter settings.
class DiscoverFilters {
  const DiscoverFilters({
    this.gender,
    this.ageMin = 18,
    this.ageMax = 60,
    this.department,
    this.shiftType,
    this.language,
    this.distanceKm = 100,
    this.verifiedOnly = false,
  });

  final String? gender;
  final int ageMin;
  final int ageMax;
  final String? department;
  final String? shiftType;
  final String? language;
  final double distanceKm;
  final bool verifiedOnly;

  DiscoverFilters copyWith({
    String? gender,
    int? ageMin,
    int? ageMax,
    String? department,
    String? shiftType,
    String? language,
    double? distanceKm,
    bool? verifiedOnly,
  }) {
    return DiscoverFilters(
      gender: gender ?? this.gender,
      ageMin: ageMin ?? this.ageMin,
      ageMax: ageMax ?? this.ageMax,
      department: department ?? this.department,
      shiftType: shiftType ?? this.shiftType,
      language: language ?? this.language,
      distanceKm: distanceKm ?? this.distanceKm,
      verifiedOnly: verifiedOnly ?? this.verifiedOnly,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is DiscoverFilters &&
          gender == other.gender &&
          ageMin == other.ageMin &&
          ageMax == other.ageMax &&
          department == other.department &&
          shiftType == other.shiftType &&
          language == other.language &&
          distanceKm == other.distanceKm &&
          verifiedOnly == other.verifiedOnly;

  @override
  int get hashCode => Object.hash(
    gender,
    ageMin,
    ageMax,
    department,
    shiftType,
    language,
    distanceKm,
    verifiedOnly,
  );
}

// ─── Filters notifier ────────────────────────────────────────────────────────

class FiltersNotifier extends StateNotifier<DiscoverFilters> {
  FiltersNotifier() : super(const DiscoverFilters());

  void updateGender(String? gender) => state = state.copyWith(gender: gender);

  void updateAge(int min, int max) =>
      state = state.copyWith(ageMin: min, ageMax: max);

  void updateDepartment(String? department) =>
      state = state.copyWith(department: department);

  void updateShiftType(String? shiftType) =>
      state = state.copyWith(shiftType: shiftType);

  void updateLanguage(String? language) =>
      state = state.copyWith(language: language);

  void updateDistance(double km) => state = state.copyWith(distanceKm: km);

  void updateVerifiedOnly(bool value) =>
      state = state.copyWith(verifiedOnly: value);

  void reset() => state = const DiscoverFilters();
}

// ─── Providers ──────────────────────────────────────────────────────────────

/// Provides the [FiltersNotifier] and its current [DiscoverFilters] state.
final filtersProvider = StateNotifierProvider<FiltersNotifier, DiscoverFilters>(
  (ref) {
    return FiltersNotifier();
  },
);

/// Fetches a batch of discoverable profiles, reacting to filter changes and
/// the current authenticated user.
final profilesProvider = FutureProvider<List<UserModel>>((ref) async {
  final currentUser = ref.watch(currentUserProvider);
  final filters = ref.watch(filtersProvider);
  final service = ref.watch(discoverServiceProvider);

  // Wait for user to be available.
  final user = currentUser.valueOrNull;
  if (user == null) return [];

  return service.fetchProfiles(
    user.id,
    gender: filters.gender,
    ageMin: filters.ageMin,
    ageMax: filters.ageMax,
    department: filters.department,
    shiftType: filters.shiftType,
    language: filters.language,
    maxDistance: filters.distanceKm,
    verifiedOnly: filters.verifiedOnly,
  );
});
