import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Custom color extension for colors not in the standard Material palette.
@immutable
class AppCustomColors extends ThemeExtension<AppCustomColors> {
  const AppCustomColors({
    required this.online,
    required this.accent,
    required this.surfaceVariant,
    required this.cardShadow,
    required this.shimmerBase,
    required this.shimmerHighlight,
    required this.warning,
    required this.info,
    required this.gradientStart,
    required this.gradientEnd,
  });

  final Color online;
  final Color accent;
  final Color surfaceVariant;
  final Color cardShadow;
  final Color shimmerBase;
  final Color shimmerHighlight;
  final Color warning;
  final Color info;
  final Color gradientStart;
  final Color gradientEnd;

  @override
  AppCustomColors copyWith({
    Color? online,
    Color? accent,
    Color? surfaceVariant,
    Color? cardShadow,
    Color? shimmerBase,
    Color? shimmerHighlight,
    Color? warning,
    Color? info,
    Color? gradientStart,
    Color? gradientEnd,
  }) {
    return AppCustomColors(
      online: online ?? this.online,
      accent: accent ?? this.accent,
      surfaceVariant: surfaceVariant ?? this.surfaceVariant,
      cardShadow: cardShadow ?? this.cardShadow,
      shimmerBase: shimmerBase ?? this.shimmerBase,
      shimmerHighlight: shimmerHighlight ?? this.shimmerHighlight,
      warning: warning ?? this.warning,
      info: info ?? this.info,
      gradientStart: gradientStart ?? this.gradientStart,
      gradientEnd: gradientEnd ?? this.gradientEnd,
    );
  }

  @override
  AppCustomColors lerp(ThemeExtension<AppCustomColors>? other, double t) {
    if (other is! AppCustomColors) return this;
    return AppCustomColors(
      online: Color.lerp(online, other.online, t)!,
      accent: Color.lerp(accent, other.accent, t)!,
      surfaceVariant: Color.lerp(surfaceVariant, other.surfaceVariant, t)!,
      cardShadow: Color.lerp(cardShadow, other.cardShadow, t)!,
      shimmerBase: Color.lerp(shimmerBase, other.shimmerBase, t)!,
      shimmerHighlight: Color.lerp(
        shimmerHighlight,
        other.shimmerHighlight,
        t,
      )!,
      warning: Color.lerp(warning, other.warning, t)!,
      info: Color.lerp(info, other.info, t)!,
      gradientStart: Color.lerp(gradientStart, other.gradientStart, t)!,
      gradientEnd: Color.lerp(gradientEnd, other.gradientEnd, t)!,
    );
  }
}

class AppTheme {
  AppTheme._();

  // ─── Brand Colors ───────────────────────────────────────────────────
  static const Color deepPlum = Color(0xFF0F766E);
  static const Color warmRose = Color(0xFFDC2626);
  static const Color softAmber = Color(0xFFF59E0B);
  static const Color cream = Color(0xFFF6FBFB);
  static const Color midnight = Color(0xFF061A23);
  static const Color softLavender = Color(0xFFDDF7F4);
  static const Color charcoal = Color(0xFF0B1F2A);
  static const Color warmGray = Color(0xFF64748B);
  static const Color emerald = Color(0xFF0D9488);
  static const Color cyan = Color(0xFF0891B2);

  // ─── Derived Light Palette ──────────────────────────────────────────
  static const Color _lightSurface = Color(0xFFF6FBFB);
  static const Color _lightCard = Colors.white;
  static const Color _lightDivider = Color(0xFFE7E5E4);

  // ─── Derived Dark Palette ───────────────────────────────────────────
  static const Color _darkSurface = Color(0xFF082F3A);
  static const Color _darkCard = Color(0xFF0B2530);
  static const Color _darkDivider = Color(0xFF164E63);

  // ─── Shape Constants ────────────────────────────────────────────────
  static const double borderRadiusSmall = 12.0;
  static const double borderRadiusMedium = 20.0;
  static const double borderRadiusLarge = 28.0;
  static const double borderRadiusXL = 36.0;

  // ─── Elevation / Shadow ─────────────────────────────────────────────
  static List<BoxShadow> get softShadow => [
    BoxShadow(
      color: deepPlum.withValues(alpha: 0.08),
      blurRadius: 24,
      offset: const Offset(0, 8),
      spreadRadius: 0,
    ),
  ];

  static List<BoxShadow> get cardShadow => [
    BoxShadow(
      color: deepPlum.withValues(alpha: 0.06),
      blurRadius: 16,
      offset: const Offset(0, 4),
      spreadRadius: 0,
    ),
  ];

  // ─── Text Themes ────────────────────────────────────────────────────
  static TextTheme _buildTextTheme(Color primaryText, Color secondaryText) {
    return TextTheme(
      // Headlines – Playfair Display
      displayLarge: GoogleFonts.playfairDisplay(
        fontSize: 57,
        fontWeight: FontWeight.w400,
        color: primaryText,
        letterSpacing: -0.25,
      ),
      displayMedium: GoogleFonts.playfairDisplay(
        fontSize: 45,
        fontWeight: FontWeight.w400,
        color: primaryText,
      ),
      displaySmall: GoogleFonts.playfairDisplay(
        fontSize: 36,
        fontWeight: FontWeight.w400,
        color: primaryText,
      ),
      headlineLarge: GoogleFonts.playfairDisplay(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineMedium: GoogleFonts.playfairDisplay(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      headlineSmall: GoogleFonts.playfairDisplay(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      // Titles – Plus Jakarta Sans
      titleLarge: GoogleFonts.plusJakartaSans(
        fontSize: 22,
        fontWeight: FontWeight.w600,
        color: primaryText,
      ),
      titleMedium: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: 0.15,
      ),
      titleSmall: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: 0.1,
      ),
      // Body – Plus Jakarta Sans
      bodyLarge: GoogleFonts.plusJakartaSans(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        color: primaryText,
        letterSpacing: 0.5,
      ),
      bodyMedium: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        letterSpacing: 0.25,
      ),
      bodySmall: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        color: secondaryText,
        letterSpacing: 0.4,
      ),
      // Labels – Plus Jakarta Sans
      labelLarge: GoogleFonts.plusJakartaSans(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: primaryText,
        letterSpacing: 0.1,
      ),
      labelMedium: GoogleFonts.plusJakartaSans(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: 0.5,
      ),
      labelSmall: GoogleFonts.plusJakartaSans(
        fontSize: 11,
        fontWeight: FontWeight.w600,
        color: secondaryText,
        letterSpacing: 0.5,
      ),
    );
  }

  // ─── Light Theme ────────────────────────────────────────────────────
  static ThemeData get lightTheme {
    final colorScheme = ColorScheme.light(
      primary: deepPlum,
      onPrimary: Colors.white,
      primaryContainer: softLavender,
      onPrimaryContainer: deepPlum,
      secondary: warmRose,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFFFEE2E2),
      onSecondaryContainer: warmRose,
      tertiary: softAmber,
      onTertiary: Colors.white,
      tertiaryContainer: const Color(0xFFFEF3C7),
      onTertiaryContainer: const Color(0xFF92400E),
      error: const Color(0xFFDC2626),
      onError: Colors.white,
      surface: _lightSurface,
      onSurface: charcoal,
      onSurfaceVariant: warmGray,
      outline: _lightDivider,
      outlineVariant: const Color(0xFFD6D3D1),
      shadow: deepPlum.withValues(alpha: 0.08),
    );

    final textTheme = _buildTextTheme(charcoal, warmGray);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: cream,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: cream,
        foregroundColor: charcoal,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
        iconTheme: const IconThemeData(color: charcoal),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: _lightCard,
        elevation: 0,
        shadowColor: deepPlum.withValues(alpha: 0.08),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: deepPlum,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: deepPlum,
          side: const BorderSide(color: deepPlum, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: deepPlum,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Floating Action Button
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: warmRose,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: _lightDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: deepPlum, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFDC2626)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFDC2626), width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 14, color: warmGray),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: warmGray.withValues(alpha: 0.6),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: Colors.white,
        selectedItemColor: deepPlum,
        unselectedItemColor: warmGray,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: Colors.white,
        indicatorColor: softLavender,
        elevation: 4,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: deepPlum,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: warmGray,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: deepPlum, size: 24);
          }
          return const IconThemeData(color: warmGray, size: 24);
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: softLavender,
        selectedColor: deepPlum,
        disabledColor: _lightDivider,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        side: BorderSide.none,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: charcoal,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: Colors.white,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusLarge),
          ),
        ),
        elevation: 8,
        showDragHandle: true,
        dragHandleColor: _lightDivider,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: charcoal,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: Colors.white,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: _lightDivider,
        thickness: 1,
        space: 1,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: deepPlum,
        unselectedLabelColor: warmGray,
        indicatorColor: deepPlum,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return deepPlum;
          return warmGray;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return deepPlum.withValues(alpha: 0.3);
          }
          return warmGray.withValues(alpha: 0.2);
        }),
      ),

      // Extensions
      extensions: const <ThemeExtension<dynamic>>[
        AppCustomColors(
          online: cyan,
          accent: softAmber,
          surfaceVariant: softLavender,
          cardShadow: Color(0x146B21A8),
          shimmerBase: Color(0xFFE7E5E4),
          shimmerHighlight: Color(0xFFF5F5F4),
          warning: Color(0xFFD97706),
          info: Color(0xFF0284C7),
          gradientStart: deepPlum,
          gradientEnd: warmRose,
        ),
      ],
    );
  }

  // ─── Dark Theme (AMOLED Night-Shift Optimized) ──────────────────────
  static ThemeData get darkTheme {
    const Color darkPlum = Color(0xFF2DD4BF);
    const Color darkRose = Color(0xFFF87171);
    const Color darkAmber = Color(0xFFFBBF24);
    const Color darkText = Color(0xFFF5F5F4);
    const Color darkSecondaryText = Color(0xFFA8A29E);

    final colorScheme = ColorScheme.dark(
      primary: darkPlum,
      onPrimary: Colors.white,
      primaryContainer: const Color(0xFF134E4A),
      onPrimaryContainer: const Color(0xFFCCFBF1),
      secondary: darkRose,
      onSecondary: Colors.white,
      secondaryContainer: const Color(0xFF7F1D1D),
      onSecondaryContainer: const Color(0xFFFEE2E2),
      tertiary: darkAmber,
      onTertiary: charcoal,
      tertiaryContainer: const Color(0xFF78350F),
      onTertiaryContainer: const Color(0xFFFEF3C7),
      error: const Color(0xFFF87171),
      onError: Colors.white,
      surface: midnight,
      onSurface: darkText,
      onSurfaceVariant: darkSecondaryText,
      outline: _darkDivider,
      outlineVariant: const Color(0xFF155E75),
      shadow: Colors.black.withValues(alpha: 0.4),
    );

    final textTheme = _buildTextTheme(darkText, darkSecondaryText);

    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: colorScheme,
      textTheme: textTheme,
      scaffoldBackgroundColor: midnight,

      // AppBar
      appBarTheme: AppBarTheme(
        backgroundColor: midnight,
        foregroundColor: darkText,
        elevation: 0,
        scrolledUnderElevation: 2,
        centerTitle: true,
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 20,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
        iconTheme: const IconThemeData(color: darkText),
      ),

      // Cards
      cardTheme: CardThemeData(
        color: _darkCard,
        elevation: 0,
        shadowColor: Colors.black.withValues(alpha: 0.3),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      ),

      // Elevated buttons
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: darkPlum,
          foregroundColor: Colors.white,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Outlined buttons
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: darkPlum,
          side: const BorderSide(color: darkPlum, width: 1.5),
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(borderRadiusMedium),
          ),
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 16,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // Text buttons
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: darkPlum,
          textStyle: GoogleFonts.plusJakartaSans(
            fontSize: 14,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),

      // FAB
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: darkRose,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
        ),
      ),

      // Input decoration
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: _darkCard,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: _darkDivider),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: darkPlum, width: 2),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFF87171)),
        ),
        focusedErrorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(borderRadiusMedium),
          borderSide: const BorderSide(color: Color(0xFFF87171), width: 2),
        ),
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkSecondaryText,
        ),
        hintStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkSecondaryText.withValues(alpha: 0.5),
        ),
      ),

      // Bottom Navigation
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: midnight,
        selectedItemColor: darkPlum,
        unselectedItemColor: darkSecondaryText,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 12,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Navigation Bar (Material 3)
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: _darkCard,
        indicatorColor: darkPlum.withValues(alpha: 0.2),
        elevation: 4,
        height: 72,
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.plusJakartaSans(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: darkPlum,
            );
          }
          return GoogleFonts.plusJakartaSans(
            fontSize: 12,
            fontWeight: FontWeight.w400,
            color: darkSecondaryText,
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: darkPlum, size: 24);
          }
          return const IconThemeData(color: darkSecondaryText, size: 24);
        }),
      ),

      // Chip
      chipTheme: ChipThemeData(
        backgroundColor: _darkSurface,
        selectedColor: darkPlum,
        disabledColor: _darkDivider,
        labelStyle: GoogleFonts.plusJakartaSans(fontSize: 13, color: darkText),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
        side: BorderSide.none,
      ),

      // Dialog
      dialogTheme: DialogThemeData(
        backgroundColor: _darkCard,
        elevation: 8,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusLarge),
        ),
        titleTextStyle: GoogleFonts.playfairDisplay(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: darkText,
        ),
      ),

      // Bottom Sheet
      bottomSheetTheme: BottomSheetThemeData(
        backgroundColor: _darkCard,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(borderRadiusLarge),
          ),
        ),
        elevation: 8,
        showDragHandle: true,
        dragHandleColor: _darkDivider,
      ),

      // Snackbar
      snackBarTheme: SnackBarThemeData(
        backgroundColor: _darkCard,
        contentTextStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          color: darkText,
        ),
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(borderRadiusSmall),
        ),
      ),

      // Divider
      dividerTheme: const DividerThemeData(
        color: _darkDivider,
        thickness: 1,
        space: 1,
      ),

      // Tab bar
      tabBarTheme: TabBarThemeData(
        labelColor: darkPlum,
        unselectedLabelColor: darkSecondaryText,
        indicatorColor: darkPlum,
        indicatorSize: TabBarIndicatorSize.label,
        labelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w600,
        ),
        unselectedLabelStyle: GoogleFonts.plusJakartaSans(
          fontSize: 14,
          fontWeight: FontWeight.w400,
        ),
      ),

      // Switch
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return darkPlum;
          return darkSecondaryText;
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return darkPlum.withValues(alpha: 0.3);
          }
          return darkSecondaryText.withValues(alpha: 0.2);
        }),
      ),

      // Extensions
      extensions: const <ThemeExtension<dynamic>>[
        AppCustomColors(
          online: cyan,
          accent: darkAmber,
          surfaceVariant: Color(0xFF082F3A),
          cardShadow: Color(0x40000000),
          shimmerBase: Color(0xFF123D4A),
          shimmerHighlight: Color(0xFF155E75),
          warning: Color(0xFFFBBF24),
          info: Color(0xFF38BDF8),
          gradientStart: darkPlum,
          gradientEnd: darkRose,
        ),
      ],
    );
  }

  // ─── Gradient Helpers ───────────────────────────────────────────────
  static LinearGradient get primaryGradient => const LinearGradient(
    colors: [deepPlum, cyan],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get accentGradient => const LinearGradient(
    colors: [softAmber, deepPlum],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );

  static LinearGradient get darkGradient => const LinearGradient(
    colors: [Color(0xFF0F766E), Color(0xFF0284C7)],
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
  );
}
