import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/core/utils/global_navigator.dart';

/// Responsive snackbar wrapper that positions AppSnackbar based on screen size.
/// On web/desktop (width >= 600), shows in bottom-right corner with max-width.
/// On mobile (width < 600), shows full-width at bottom.
class ResponsiveSnackbar {
  static const _mobileThreshold = 600.0;

  /// Show success message with responsive positioning
  static void showSuccess(String message) {
    _showSnackbar(message, type: _SnackbarType.success);
  }

  /// Show error message with responsive positioning
  static void showError(String message) {
    _showSnackbar(message, type: _SnackbarType.error);
  }

  /// Show info message with responsive positioning
  static void showInfo(String message) {
    _showSnackbar(message, type: _SnackbarType.info);
  }

  /// Show warning message with responsive positioning
  static void showWarning(String message) {
    _showSnackbar(message, type: _SnackbarType.warning);
  }

  static void _showSnackbar(
    String message, {
    required _SnackbarType type,
  }) {
    final context = _getContext();
    if (context == null) {
      _callAppSnackbar(message, type);
      return;
    }

    final screenWidth = MediaQuery.of(context).size.width;
    final isWideScreen = screenWidth >= _mobileThreshold && kIsWeb;

    if (isWideScreen) {
      _showResponsiveSnackbar(context, message, type);
    } else {
      _callAppSnackbar(message, type);
    }
  }

  /// Show snackbar at bottom-right for web/desktop
  static void _showResponsiveSnackbar(
    BuildContext context,
    String message,
    _SnackbarType type,
  ) {
    final scaffoldMessenger = ScaffoldMessenger.of(context);

    final color = _getColorForType(type);
    final textColor = _getTextColorForType(type);

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(_getIconForType(type), color: textColor, size: 20),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                message,
                style: TextStyle(color: textColor, fontSize: 14),
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: const EdgeInsets.only(bottom: 24, right: 24),
        width: 400,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
      ),
    );
  }

  /// Delegate to AppSnackbar for default behavior
  static void _callAppSnackbar(String message, _SnackbarType type) {
    switch (type) {
      case _SnackbarType.success:
        AppSnackbar.showSuccess(message);
      case _SnackbarType.error:
        AppSnackbar.showError(message);
      case _SnackbarType.info:
        AppSnackbar.showInfo(message);
      case _SnackbarType.warning:
        AppSnackbar.showWarning(message);
    }
  }

  /// Get BuildContext from global navigator
  static BuildContext? _getContext() {
    try {
      return GlobalNavigator.navigatorKey.currentContext;
    } catch (_) {
      return null;
    }
  }

  /// Get background color based on snackbar type
  static Color _getColorForType(_SnackbarType type) {
    return switch (type) {
      _SnackbarType.success => const Color(0xFF4CAF50),
      _SnackbarType.error => const Color(0xFFFF6B6B),
      _SnackbarType.info => const Color(0xFF2196F3),
      _SnackbarType.warning => const Color(0xFFFFC107),
    };
  }

  /// Get text color based on snackbar type
  static Color _getTextColorForType(_SnackbarType type) {
    return switch (type) {
      _SnackbarType.success => Colors.white,
      _SnackbarType.error => Colors.white,
      _SnackbarType.info => Colors.white,
      _SnackbarType.warning => Colors.black87,
    };
  }

  /// Get icon based on snackbar type
  static IconData _getIconForType(_SnackbarType type) {
    return switch (type) {
      _SnackbarType.success => Icons.check_circle,
      _SnackbarType.error => Icons.error,
      _SnackbarType.info => Icons.info,
      _SnackbarType.warning => Icons.warning,
    };
  }
}

enum _SnackbarType { success, error, info, warning }
