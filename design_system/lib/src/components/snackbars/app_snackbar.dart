import 'package:flutter/material.dart';
import '../../theme/design_system_theme.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Snackbar helper for consistent notification toasts
class AppSnackbar {
  AppSnackbar._();

  static void showSuccess(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    AppThemeConfig? themeConfig,
  }) {
    _show(
      context,
      message,
      icon: Icons.check_circle,
      backgroundColor: DesignSystemTheme.successColor(themeConfig),
      duration: duration,
    );
  }

  static void showError(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 4),
    AppThemeConfig? themeConfig,
  }) {
    _show(
      context,
      message,
      icon: Icons.error,
      backgroundColor: DesignSystemTheme.errorColor(themeConfig),
      duration: duration,
    );
  }

  static void showInfo(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    AppThemeConfig? themeConfig,
  }) {
    _show(
      context,
      message,
      icon: Icons.info,
      backgroundColor: DesignSystemTheme.infoColor(themeConfig),
      duration: duration,
    );
  }

  static void showWarning(
    BuildContext context,
    String message, {
    Duration duration = const Duration(seconds: 3),
    AppThemeConfig? themeConfig,
  }) {
    _show(
      context,
      message,
      icon: Icons.warning,
      backgroundColor: DesignSystemTheme.warningColor(themeConfig),
      duration: duration,
    );
  }

  static void _show(
    BuildContext context,
    String message, {
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
  }) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            Icon(icon, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(child: Text(message, style: const TextStyle(color: Colors.white))),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        action: SnackBarAction(
          label: 'Dismiss',
          textColor: Colors.white,
          onPressed: () => ScaffoldMessenger.of(context).hideCurrentSnackBar(),
        ),
      ),
    );
  }
}
