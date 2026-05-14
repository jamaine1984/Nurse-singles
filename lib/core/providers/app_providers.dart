import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:nightingale_heart/core/models/user_model.dart';
import 'package:nightingale_heart/core/localization/app_language.dart';
import 'package:nightingale_heart/core/services/auth_service.dart';

// ─── Auth State Provider ───────────────────────────────────────────────────
/// Streams the Firebase Auth state (logged-in / logged-out).
final authStateProvider = StreamProvider<User?>((ref) {
  final authService = ref.watch(authServiceProvider);
  return authService.authStateChanges;
});

// ─── Current User Provider ─────────────────────────────────────────────────
/// Streams the full [UserModel] profile for the currently authenticated user.
///
/// Returns `null` when the user is not signed in or has no Firestore document.
final currentUserProvider = StreamProvider<UserModel?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.when(
    data: (user) {
      if (user == null) return Stream.value(null);
      final authService = ref.read(authServiceProvider);
      return authService.streamCurrentUser();
    },
    loading: () => Stream.value(null),
    error: (_, __) => Stream.value(null),
  );
});

// ─── Theme Provider ────────────────────────────────────────────────────────
/// Manages the app's ThemeMode (light / dark / system) with persistence.
final themeProvider = StateNotifierProvider<ThemeNotifier, ThemeMode>((ref) {
  return ThemeNotifier();
});

class ThemeNotifier extends StateNotifier<ThemeMode> {
  ThemeNotifier() : super(ThemeMode.light) {
    _loadTheme();
  }

  Future<void> _loadTheme() async {
    final prefs = await SharedPreferences.getInstance();
    final modeStr = prefs.getString('theme_mode') ?? 'light';
    switch (modeStr) {
      case 'dark':
        state = ThemeMode.dark;
        break;
      case 'system':
        state = ThemeMode.system;
        break;
      default:
        state = ThemeMode.light;
    }
  }

  Future<void> setTheme(ThemeMode mode) async {
    final prefs = await SharedPreferences.getInstance();
    String modeStr;
    switch (mode) {
      case ThemeMode.dark:
        modeStr = 'dark';
        break;
      case ThemeMode.system:
        modeStr = 'system';
        break;
      default:
        modeStr = 'light';
    }
    await prefs.setString('theme_mode', modeStr);
    state = mode;
  }

  void toggle() {
    setTheme(state == ThemeMode.light ? ThemeMode.dark : ThemeMode.light);
  }
}

// ─── Locale Provider ───────────────────────────────────────────────────────
/// Manages the app locale (language selection) with persistence.
final localeProvider = StateNotifierProvider<LocaleNotifier, Locale>((ref) {
  return LocaleNotifier();
});

class LocaleNotifier extends StateNotifier<Locale> {
  LocaleNotifier() : super(const Locale('en')) {
    _loadLocale();
  }

  Future<void> _loadLocale() async {
    final prefs = await SharedPreferences.getInstance();
    final code = prefs.getString('app_locale') ?? 'en';
    state = Locale(_normalizeLocaleCode(code));
  }

  Future<void> setLocale(String languageCode) async {
    final prefs = await SharedPreferences.getInstance();
    final code = _normalizeLocaleCode(languageCode);
    await prefs.setString('app_locale', code);
    state = Locale(code);
  }

  String _normalizeLocaleCode(String code) {
    return AppLanguages.normalizeFullySupportedCode(code);
  }
}

// ─── Connectivity Provider ─────────────────────────────────────────────────
/// Streams the device's connectivity status.
///
/// Emits `true` when any network is available and `false` when offline.
final connectivityProvider = StreamProvider<bool>((ref) {
  final connectivity = Connectivity();

  // Map the list of results to a simple boolean
  return connectivity.onConnectivityChanged.map((results) {
    return results.any((r) => r != ConnectivityResult.none);
  });
});

// ─── Convenience Providers ─────────────────────────────────────────────────

/// Quick check: is the user signed in?
final isAuthenticatedProvider = Provider<bool>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (user) => user != null) ?? false;
});

/// The current user's UID, or `null`.
final currentUserIdProvider = Provider<String?>((ref) {
  final authState = ref.watch(authStateProvider);
  return authState.whenOrNull(data: (user) => user?.uid);
});
