import 'package:flutter/material.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Text style tokens for consistent typography across the app
class AppTextStyles {
  AppTextStyles._();

  static TextStyle displayLarge(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 32,
      fontWeight: FontWeight.bold,
      fontFamily: config?.headlineFontFamily ?? 'Plus Jakarta Sans',
      color: Theme.of(context).textTheme.displayLarge?.color,
    );
  }

  static TextStyle displayMedium(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 28,
      fontWeight: FontWeight.bold,
      fontFamily: config?.headlineFontFamily ?? 'Plus Jakarta Sans',
      color: Theme.of(context).textTheme.displayMedium?.color,
    );
  }

  static TextStyle headline(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 24,
      fontWeight: FontWeight.bold,
      fontFamily: config?.headlineFontFamily ?? 'Plus Jakarta Sans',
      color: Theme.of(context).textTheme.headlineMedium?.color,
    );
  }

  static TextStyle body(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.normal,
      fontFamily: config?.bodyFontFamily ?? 'Manrope',
      color: Theme.of(context).textTheme.bodyMedium?.color,
    );
  }

  static TextStyle bodySmall(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 14,
      fontWeight: FontWeight.normal,
      fontFamily: config?.bodyFontFamily ?? 'Manrope',
      color: Theme.of(context).textTheme.bodySmall?.color,
    );
  }

  static TextStyle label(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 12,
      fontWeight: FontWeight.w500,
      fontFamily: config?.bodyFontFamily ?? 'Manrope',
      color: Theme.of(context).textTheme.labelMedium?.color,
    );
  }

  static TextStyle button(
    BuildContext context, {
    AppThemeConfig? config,
  }) {
    return TextStyle(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      fontFamily: config?.bodyFontFamily ?? 'Manrope',
      color: Colors.white,
    );
  }
}
