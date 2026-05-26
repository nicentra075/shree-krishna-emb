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
  /// Pass context for reliable snackbar positioning
  static void showSuccess(String message, [BuildContext? context]) {
    _showSnackbar(message, type: _SnackbarType.success, context: context);
  }

  /// Show error message with responsive positioning
  /// Pass context for reliable snackbar positioning
  static void showError(String message, [BuildContext? context]) {
    _showSnackbar(message, type: _SnackbarType.error, context: context);
  }

  /// Show info message with responsive positioning
  /// Pass context for reliable snackbar positioning
  static void showInfo(String message, [BuildContext? context]) {
    _showSnackbar(message, type: _SnackbarType.info, context: context);
  }

  /// Show warning message with responsive positioning
  /// Pass context for reliable snackbar positioning
  static void showWarning(String message, [BuildContext? context]) {
    _showSnackbar(message, type: _SnackbarType.warning, context: context);
  }

  static void _showSnackbar(
    String message, {
    required _SnackbarType type,
    BuildContext? context,
  }) {
    final ctx = context ?? _getContext();
    if (ctx == null) {
      _callAppSnackbar(message, type);
      return;
    }

    try {
      final screenWidth = MediaQuery.of(ctx).size.width;
      final isWideScreen = screenWidth >= _mobileThreshold && kIsWeb;

      if (isWideScreen) {
        _showResponsiveSnackbar(ctx, message, type);
      } else {
        _callAppSnackbar(message, type);
      }
    } catch (_) {
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
    final screenWidth = MediaQuery.of(context).size.width;
    
    final color = _getColorForType(type);
    final textColor = _getTextColorForType(type);

    // Calculate left margin dynamically to push snackbar to right side
    // Content width (380) + right margin (24) + padding (24) = 428.   

    final leftMargin = screenWidth - 428;

    scaffoldMessenger.showSnackBar(
      SnackBar(
        content: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 380),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(_getIconForType(type), color: textColor, size: 20),
              const SizedBox(width: 12),
              Flexible(
                child: Text(
                  message,
                  style: TextStyle(color: textColor, fontSize: 14),
                  maxLines: 3,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ),
        backgroundColor: color,
        behavior: SnackBarBehavior.floating,
        margin: EdgeInsets.only(bottom: 24, right: 24, left: leftMargin),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
        duration: const Duration(seconds: 3),
        elevation: 6.0,
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
