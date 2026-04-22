import 'package:flutter/material.dart';

/// App Theme Configuration
/// Based on "The Modern Heirloom" Design System
///
/// This theme implements the design system MD with:
/// - Royal Saffron (#8f4e00, #ff9933) as primary
/// - Deep Blue (#4059aa, #8fa7fe) as secondary
/// - Plus Jakarta Sans for headlines
/// - Manrope for body text
/// - Dark mode support with inverted colors

class AppTheme {
  // Royal Saffron Palette
  static const Color primaryDark = Color(0xFF8f4e00);
  static const Color primaryLight = Color(0xFFff9933);

  // Deep Blue Palette
  static const Color secondaryDark = Color(0xFF4059aa);
  static const Color secondaryLight = Color(0xFF8fa7fe);

  // Neutral & Surface Colors
  static const Color surfaceLight = Color(0xFFFFFBFE);
  static const Color surfaceDark = Color(0xFF1a1c19);

  static const Color surfaceContainerLowestLight = Color(0xFFFFFFFF);
  static const Color surfaceContainerLowestDark = Color(0xFF2e2e2d);

  static const Color surfaceContainerLowLight = Color(0xFFFAF7FA);
  static const Color surfaceContainerLowDark = Color(0xFF3a3a39);

  static const Color onSurfaceLight = Color(0xFF1a1c19);
  static const Color onSurfaceDark = Color(0xFFf5f5f1);

  static const Color outlineVariant = Color(0xFFdbc2b0);

  /// Light Theme Configuration
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.light(
        primary: primaryDark,
        onPrimary: Colors.white,
        primaryContainer: primaryLight,
        onPrimaryContainer: Colors.white,
        secondary: secondaryDark,
        onSecondary: Colors.white,
        secondaryContainer: secondaryLight,
        onSecondaryContainer: Colors.white,
        surface: surfaceLight,
        onSurface: onSurfaceLight,
        surfaceContainerLowest: surfaceContainerLowestLight,
        surfaceContainerLow: surfaceContainerLowLight,
        outline: outlineVariant,
        outlineVariant: outlineVariant,
        error: const Color(0xFFB3261E),
        onError: Colors.white,
      ),

      // Typography
      fontFamily: 'Manrope',
      textTheme: _buildTextTheme('Manrope', 'Plus Jakarta Sans'),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceLight,
        foregroundColor: onSurfaceLight,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textStyle(
          'Plus Jakarta Sans',
          28,
          FontWeight.w600,
          onSurfaceLight,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryDark,
          foregroundColor: Colors.white,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
          textStyle: _textStyle('Manrope', 16, FontWeight.w600, Colors.white),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryDark,
          side: const BorderSide(color: outlineVariant, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _textStyle('Manrope', 14, FontWeight.w600, secondaryDark),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: surfaceContainerLowestLight,
        hintStyle: _textStyle('Manrope', 14, FontWeight.w400, Colors.grey),
        labelStyle: _textStyle('Manrope', 12, FontWeight.w500, onSurfaceLight),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryDark, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceContainerLowestLight,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLowLight,
        selectedColor: secondaryDark,
        labelStyle: _textStyle('Manrope', 12, FontWeight.w500, onSurfaceLight),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceLight,
        selectedItemColor: primaryDark,
        unselectedItemColor: onSurfaceLight.withValues(alpha: 0.6),
        selectedLabelStyle: _textStyle('Manrope', 12, FontWeight.w600, primaryDark),
        unselectedLabelStyle: _textStyle('Manrope', 12, FontWeight.w500, onSurfaceLight),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: surfaceLight,
    );
  }

  /// Dark Theme Configuration
  static ThemeData get darkTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.dark(
        primary: primaryLight,
        onPrimary: Colors.black,
        primaryContainer: primaryDark,
        onPrimaryContainer: primaryLight,
        secondary: secondaryLight,
        onSecondary: Colors.black,
        secondaryContainer: secondaryDark,
        onSecondaryContainer: secondaryLight,
        surface: surfaceDark,
        onSurface: onSurfaceDark,
        surfaceContainerLowest: surfaceContainerLowestDark,
        surfaceContainerLow: surfaceContainerLowDark,
        outline: outlineVariant,
        outlineVariant: outlineVariant,
        error: const Color(0xFFF2B8B5),
        onError: Color(0xFF601410),
      ),

      // Typography
      fontFamily: 'Manrope',
      textTheme: _buildTextTheme('Manrope', 'Plus Jakarta Sans', isDark: true),

      // AppBar Theme
      appBarTheme: AppBarTheme(
        backgroundColor: surfaceDark,
        foregroundColor: onSurfaceDark,
        elevation: 0,
        centerTitle: true,
        titleTextStyle: _textStyle(
          'Plus Jakarta Sans',
          28,
          FontWeight.w600,
          onSurfaceDark,
        ),
      ),

      // Elevated Button Theme
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primaryLight,
          foregroundColor: Colors.black,
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(9999),
          ),
          elevation: 0,
          textStyle: _textStyle('Manrope', 16, FontWeight.w600, Colors.black),
        ),
      ),

      // Outlined Button Theme
      outlinedButtonTheme: OutlinedButtonThemeData(
        style: OutlinedButton.styleFrom(
          foregroundColor: secondaryLight,
          side: const BorderSide(color: outlineVariant, width: 1),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: _textStyle('Manrope', 14, FontWeight.w600, secondaryLight),
        ),
      ),

      // Input Decoration Theme
      inputDecorationTheme: InputDecorationTheme(
        filled: false,
        fillColor: surfaceContainerLowestDark,
        hintStyle: _textStyle('Manrope', 14, FontWeight.w400, Colors.grey),
        labelStyle: _textStyle('Manrope', 12, FontWeight.w500, onSurfaceDark),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: outlineVariant, width: 1),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(
            color: outlineVariant.withValues(alpha: 0.15),
            width: 1,
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: primaryLight, width: 2),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      ),

      // Card Theme
      cardTheme: CardThemeData(
        color: surfaceContainerLowestDark,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
      ),

      // Chip Theme
      chipTheme: ChipThemeData(
        backgroundColor: surfaceContainerLowDark,
        selectedColor: secondaryLight,
        labelStyle: _textStyle('Manrope', 12, FontWeight.w500, onSurfaceDark),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(4),
        ),
      ),

      // Bottom Navigation Theme
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surfaceDark,
        selectedItemColor: primaryLight,
        unselectedItemColor: onSurfaceDark.withValues(alpha: 0.6),
        selectedLabelStyle: _textStyle('Manrope', 12, FontWeight.w600, primaryLight),
        unselectedLabelStyle: _textStyle('Manrope', 12, FontWeight.w500, onSurfaceDark),
        elevation: 8,
        type: BottomNavigationBarType.fixed,
      ),

      // Scaffold Background
      scaffoldBackgroundColor: surfaceDark,
    );
  }

  /// Helper method to build TextTheme
  static TextTheme _buildTextTheme(
    String bodyFont,
    String headlineFont, {
    bool isDark = false,
  }) {
    final textColor = isDark ? onSurfaceDark : onSurfaceLight;
    return TextTheme(
      // Display Styles (Plus Jakarta Sans)
      displayLarge: _textStyle(headlineFont, 57, FontWeight.w600, textColor),
      displayMedium: _textStyle(headlineFont, 45, FontWeight.w600, textColor),
      displaySmall: _textStyle(headlineFont, 36, FontWeight.w600, textColor),

      // Headline Styles (Plus Jakarta Sans)
      headlineLarge: _textStyle(headlineFont, 32, FontWeight.w600, textColor),
      headlineMedium: _textStyle(headlineFont, 28, FontWeight.w600, textColor),
      headlineSmall: _textStyle(headlineFont, 24, FontWeight.w600, textColor),

      // Title Styles (Manrope)
      titleLarge: _textStyle(bodyFont, 22, FontWeight.w600, textColor),
      titleMedium: _textStyle(bodyFont, 16, FontWeight.w600, textColor),
      titleSmall: _textStyle(bodyFont, 14, FontWeight.w600, textColor),

      // Body Styles (Manrope)
      bodyLarge: _textStyle(bodyFont, 16, FontWeight.w400, textColor),
      bodyMedium: _textStyle(bodyFont, 14, FontWeight.w400, textColor),
      bodySmall: _textStyle(bodyFont, 12, FontWeight.w400, textColor),

      // Label Styles (Manrope)
      labelLarge: _textStyle(bodyFont, 14, FontWeight.w500, textColor),
      labelMedium: _textStyle(bodyFont, 12, FontWeight.w500, textColor),
      labelSmall: _textStyle(bodyFont, 11, FontWeight.w500, textColor),
    );
  }

  /// Helper method to create TextStyle
  static TextStyle _textStyle(
    String fontFamily,
    double fontSize,
    FontWeight weight,
    Color color,
  ) {
    return TextStyle(
      fontFamily: fontFamily,
      fontSize: fontSize,
      fontWeight: weight,
      color: color,
    );
  }

  /// Ambient Shadow for elevated elements
  /// Follows the design system rule: Blur 32px, Y: 8px, Spread: 0, at 6% opacity
  static List<BoxShadow> get ambientShadow {
    return [
      BoxShadow(
        color: Colors.black.withValues(alpha: 0.06),
        blurRadius: 32,
        offset: const Offset(0, 8),
        spreadRadius: 0,
      ),
    ];
  }

  /// Glass Morphism Effect for floating headers
  /// Surface container lowest at 80% opacity with 20px backdrop blur
  static BoxDecoration get glassMorphism {
    return BoxDecoration(
      color: surfaceContainerLowestLight.withValues(alpha: 0.8),
      borderRadius: BorderRadius.circular(12),
      border: Border.all(
        color: Colors.white.withValues(alpha: 0.2),
        width: 1,
      ),
    );
  }
}
