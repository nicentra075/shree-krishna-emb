import 'package:flutter/material.dart';
import '../../theme/design_system_theme.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Snackbar helper for consistent notification toasts
///
/// Uses a global navigator key from the app to display snackbars
/// without requiring context to be passed as a parameter.
///
/// Setup (in main.dart before runApp):
/// ```dart
/// AppSnackbar.setNavigatorKey(GlobalNavigator.navigatorKey);
/// ```
class AppSnackbar {
  AppSnackbar._();

  /// Global navigator key - set by the app during initialization
  static GlobalKey<NavigatorState>? _globalNavigatorKey;

  /// Initialize AppSnackbar with the app's global navigator key
  /// Call this in main.dart before running the app
  static void setNavigatorKey(GlobalKey<NavigatorState> key) {
    _globalNavigatorKey = key;
  }

  /// Get the current ScaffoldMessengerState from the app
  static ScaffoldMessengerState? _getMessenger() {
    try {
      final context = _globalNavigatorKey?.currentContext;
      if (context == null) {
        debugPrint('AppSnackbar: Global navigator key is not initialized. '
            'Call AppSnackbar.setNavigatorKey() in main.dart before running the app.');
        return null;
      }
      return ScaffoldMessenger.of(context);
    } catch (e) {
      debugPrint('AppSnackbar: Error accessing ScaffoldMessenger: $e');
      return null;
    }
  }

  static void showSuccess(
    String message, {
    Duration duration = const Duration(seconds: 3),
    AppThemeConfig? themeConfig,
    bool showIcon = true,
    IconData? customIcon,
    bool showAction = false,
    String actionLabel = 'Dismiss',
    TextStyle? messageStyle,
  }) {
    _show(
      message,
      icon: customIcon ?? Icons.check_circle,
      backgroundColor: DesignSystemTheme.successColor(themeConfig),
      duration: duration,
      showIcon: showIcon,
      showAction: showAction,
      actionLabel: actionLabel,
      messageStyle: messageStyle,
    );
  }

  static void showError(
    String message, {
    Duration duration = const Duration(seconds: 4),
    AppThemeConfig? themeConfig,
    bool showIcon = true,
    IconData? customIcon,
    bool showAction = false,
    String actionLabel = 'Dismiss',
    TextStyle? messageStyle,
  }) {
    _show(
      message,
      icon: customIcon ?? Icons.error,
      backgroundColor: DesignSystemTheme.errorColor(themeConfig),
      duration: duration,
      showIcon: showIcon,
      showAction: showAction,
      actionLabel: actionLabel,
      messageStyle: messageStyle,
    );
  }

  static void showInfo(
    String message, {
    Duration duration = const Duration(seconds: 3),
    AppThemeConfig? themeConfig,
    bool showIcon = true,
    IconData? customIcon,
    bool showAction = false,
    String actionLabel = 'Dismiss',
    TextStyle? messageStyle,
  }) {
    _show(
      message,
      icon: customIcon ?? Icons.info,
      backgroundColor: DesignSystemTheme.infoColor(themeConfig),
      duration: duration,
      showIcon: showIcon,
      showAction: showAction,
      actionLabel: actionLabel,
      messageStyle: messageStyle,
    );
  }

  static void showWarning(
    String message, {
    Duration duration = const Duration(seconds: 3),
    AppThemeConfig? themeConfig,
    bool showIcon = true,
    IconData? customIcon,
    bool showAction = false,
    String actionLabel = 'Dismiss',
    TextStyle? messageStyle,
  }) {
    _show(
      message,
      icon: customIcon ?? Icons.warning,
      backgroundColor: DesignSystemTheme.warningColor(themeConfig),
      duration: duration,
      showIcon: showIcon,
      showAction: showAction,
      actionLabel: actionLabel,
      messageStyle: messageStyle,
    );
  }

  static void _show(
    String message, {
    required IconData icon,
    required Color backgroundColor,
    required Duration duration,
    required bool showIcon,
    required bool showAction,
    required String actionLabel,
    TextStyle? messageStyle,
  }) {
    final defaultTextStyle = TextStyle(
      color: Colors.white,
      fontSize: 14,
      fontWeight: FontWeight.w500,
    );

    final messenger = _getMessenger();
    if (messenger == null) return;

    messenger.hideCurrentSnackBar();

    messenger.showSnackBar(
      SnackBar(
        content: Row(
          children: [
            if (showIcon) ...[
              Icon(icon, color: Colors.white, size: 20),
              const SizedBox(width: 12),
            ],
            Expanded(
              child: Text(
                message,
                style: messageStyle ?? defaultTextStyle,
              ),
            ),
          ],
        ),
        backgroundColor: backgroundColor,
        duration: duration,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.all(16),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        elevation: 6,
        action: showAction
            ? SnackBarAction(
                label: actionLabel,
                textColor: Colors.white,
                onPressed: () {
                  messenger.hideCurrentSnackBar();
                },
              )
            : null,
      ),
    );
  }
}
