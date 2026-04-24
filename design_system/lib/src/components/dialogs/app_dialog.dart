import 'package:flutter/material.dart';
import '../../theme/design_system_theme.dart';
import '../buttons/app_button.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Dialog helper with predefined patterns for common dialogs
class AppDialog {
  AppDialog._();

  static Future<bool?> showConfirm(
    BuildContext context, {
    required String title,
    required String message,
    String confirmLabel = 'Confirm',
    String cancelLabel = 'Cancel',
    bool isDestructive = false,
    AppThemeConfig? themeConfig,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: Text(cancelLabel),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: isDestructive
                  ? DesignSystemTheme.errorColor(themeConfig)
                  : DesignSystemTheme.primaryDark(themeConfig),
            ),
            child: Text(confirmLabel),
          ),
        ],
      ),
    );
  }

  static Future<bool?> showDeleteConfirm(
    BuildContext context, {
    required String itemName,
    AppThemeConfig? themeConfig,
  }) {
    return showConfirm(
      context,
      title: 'Delete $itemName?',
      message: 'This action cannot be undone.',
      confirmLabel: 'Delete',
      cancelLabel: 'Cancel',
      isDestructive: true,
      themeConfig: themeConfig,
    );
  }

  static Future<void> showInfo(
    BuildContext context, {
    required String title,
    required String message,
    String dismissLabel = 'OK',
    AppThemeConfig? themeConfig,
  }) {
    return showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(title),
        content: Text(message),
        actions: [
          FilledButton(
            onPressed: () => Navigator.pop(context),
            style: FilledButton.styleFrom(
              backgroundColor: DesignSystemTheme.primaryDark(themeConfig),
            ),
            child: Text(dismissLabel),
          ),
        ],
      ),
    );
  }
}
