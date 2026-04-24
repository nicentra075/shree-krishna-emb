import 'package:flutter/material.dart';

/// Text style tokens for consistent typography across the app
///
/// These are base styles that can be customized using copyWith()
/// Example: AppTextStyles.displayLarge(color: Colors.red, fontWeight: FontWeight.w900)
class AppTextStyles {
  AppTextStyles._();

  // ============================================================================
  // DISPLAY STYLES (Headlines - Large/Medium)
  // ============================================================================

  /// Large display text: 32px, bold
  /// Use for: Major page titles, splash screen titles
  static TextStyle displayLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 32,
      fontWeight: fontWeight ?? FontWeight.bold,
      fontFamily: 'Plus Jakarta Sans',
      color: color ?? const Color(0xFF1A1C19),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  /// Medium display text: 28px, bold
  /// Use for: Section headers, screen titles
  static TextStyle displayMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 28,
      fontWeight: fontWeight ?? FontWeight.bold,
      fontFamily: 'Plus Jakarta Sans',
      color: color ?? const Color(0xFF1A1C19),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  // ============================================================================
  // HEADLINE STYLES
  // ============================================================================

  /// Large headline: 32px, w700
  /// Use for: Auth screen titles, card headlines
  static TextStyle headlineLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 32,
      fontWeight: fontWeight ?? FontWeight.w700,
      fontFamily: 'Plus Jakarta Sans',
      color: color ?? const Color(0xFF1A1C19),
      letterSpacing: letterSpacing,
      height: height ?? 1.2,
      shadows: shadows,
    );
  }

  /// Medium headline: 24px, bold
  /// Use for: Walkthrough page titles, section headers
  static TextStyle headlineMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 24,
      fontWeight: fontWeight ?? FontWeight.bold,
      fontFamily: 'Plus Jakarta Sans',
      color: color ?? const Color(0xFF1A1C19),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  // ============================================================================
  // BODY STYLES (Regular text)
  // ============================================================================

  /// Large body text: 16px, normal weight
  /// Use for: Page descriptions, long-form text
  static TextStyle bodyLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.w400,
      fontFamily: 'Manrope',
      color: color ?? const Color(0xFF554336),
      letterSpacing: letterSpacing,
      height: height ?? 1.5,
      shadows: shadows,
    );
  }

  /// Medium body text: 14px, normal weight
  /// Use for: Regular text, descriptions
  static TextStyle bodyMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w400,
      fontFamily: 'Manrope',
      color: color ?? const Color(0xFF554336),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  /// Small body text: 12px, normal weight
  /// Use for: Helper text, small descriptions
  static TextStyle bodySmall({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.w400,
      fontFamily: 'Manrope',
      color: color ?? const Color(0xFF554336),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  // ============================================================================
  // LABEL STYLES (Small, medium-weight text)
  // ============================================================================

  /// Large label: 14px, w500
  /// Use for: Button labels, emphasis text
  static TextStyle labelLarge({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: fontWeight ?? FontWeight.w500,
      fontFamily: 'Manrope',
      color: color ?? const Color(0xFF554336),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  /// Medium label: 12px, w500
  /// Use for: Form labels, badges, tags
  static TextStyle labelMedium({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 12,
      fontWeight: fontWeight ?? FontWeight.w500,
      fontFamily: 'Manrope',
      color: color ?? const Color(0xFF554336),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  /// Small label: 11px, w500
  /// Use for: Caption text, footnotes
  static TextStyle labelSmall({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 11,
      fontWeight: fontWeight ?? FontWeight.w500,
      fontFamily: 'Manrope',
      color: color ?? const Color(0xFF554336),
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }

  // ============================================================================
  // BUTTON STYLE (Interactive elements)
  // ============================================================================

  /// Button text: 16px, w700
  /// Use for: Button labels, CTA text
  static TextStyle button({
    Color? color,
    FontWeight? fontWeight,
    double? letterSpacing,
    double? height,
    List<Shadow>? shadows,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: fontWeight ?? FontWeight.w700,
      fontFamily: 'Manrope',
      color: color ?? Colors.white,
      letterSpacing: letterSpacing,
      height: height,
      shadows: shadows,
    );
  }
}
