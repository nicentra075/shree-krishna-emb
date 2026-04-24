import 'package:flutter/material.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Theme color helpers that bridge app_theme_config (int-stored colors) to Flutter Color
class DesignSystemTheme {
  DesignSystemTheme._();

  static Color primaryDark(AppThemeConfig? config) {
    return Color(config?.primaryDarkColor ?? 0xFF8f4e00);
  }

  static Color primaryLight(AppThemeConfig? config) {
    return Color(config?.primaryLightColor ?? 0xFFff9933);
  }

  static Color secondaryDark(AppThemeConfig? config) {
    return Color(config?.secondaryDarkColor ?? 0xFF4059aa);
  }

  static Color secondaryLight(AppThemeConfig? config) {
    return Color(config?.secondaryLightColor ?? 0xFF8fa7fe);
  }

  static Color surfaceDark(AppThemeConfig? config) {
    return const Color(0xFF121212);
  }

  static Color surfaceLight(AppThemeConfig? config) {
    return const Color(0xFFFFFFFF);
  }

  static Color backgroundDark(AppThemeConfig? config) {
    return const Color(0xFF1F1F1F);
  }

  static Color backgroundLight(AppThemeConfig? config) {
    return const Color(0xFFFAFAFA);
  }

  static Color errorColor(AppThemeConfig? config) {
    return const Color(0xFFD32F2F);
  }

  static Color successColor(AppThemeConfig? config) {
    return const Color(0xFF388E3C);
  }

  static Color warningColor(AppThemeConfig? config) {
    return const Color(0xFFFFA726);
  }

  static Color infoColor(AppThemeConfig? config) {
    return const Color(0xFF1976D2);
  }
}
