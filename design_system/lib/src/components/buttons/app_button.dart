import 'package:flutter/material.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';
import '../../theme/design_system_theme.dart';
import '../../tokens/app_border_radius.dart';

enum AppButtonVariant { primary, secondary, outlined, ghost, destructive }
enum AppButtonSize { small, medium, large }

/// Reusable button component with multiple variants and sizes
class AppButton extends StatelessWidget {
  final String label;
  final VoidCallback? onPressed;
  final AppButtonVariant variant;
  final AppButtonSize size;
  final IconData? leadingIcon;
  final bool isLoading;
  final bool isFullWidth;
  final AppThemeConfig? themeConfig;

  const AppButton({
    required this.label,
    required this.onPressed,
    this.variant = AppButtonVariant.primary,
    this.size = AppButtonSize.medium,
    this.leadingIcon,
    this.isLoading = false,
    this.isFullWidth = false,
    this.themeConfig,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final enabled = onPressed != null && !isLoading;

    return SizedBox(
      width: isFullWidth ? double.infinity : null,
      child: _buildButton(context, enabled),
    );
  }

  Widget _buildButton(BuildContext context, bool enabled) {
    switch (variant) {
      case AppButtonVariant.primary:
        return _buildPrimaryButton(context, enabled);
      case AppButtonVariant.secondary:
        return _buildSecondaryButton(context, enabled);
      case AppButtonVariant.outlined:
        return _buildOutlinedButton(context, enabled);
      case AppButtonVariant.ghost:
        return _buildGhostButton(context, enabled);
      case AppButtonVariant.destructive:
        return _buildDestructiveButton(context, enabled);
    }
  }

  Widget _buildPrimaryButton(BuildContext context, bool enabled) {
    final primaryColor = DesignSystemTheme.primaryDark(themeConfig);
    final padding = _getPadding();

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: primaryColor,
        disabledBackgroundColor: Colors.grey[300],
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.pill),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildSecondaryButton(BuildContext context, bool enabled) {
    final secondaryColor = DesignSystemTheme.secondaryDark(themeConfig);
    final padding = _getPadding();

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: secondaryColor,
        disabledBackgroundColor: Colors.grey[300],
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildOutlinedButton(BuildContext context, bool enabled) {
    final secondaryColor = DesignSystemTheme.secondaryDark(themeConfig);
    final padding = _getPadding();

    return OutlinedButton(
      onPressed: enabled ? onPressed : null,
      style: OutlinedButton.styleFrom(
        foregroundColor: secondaryColor,
        disabledForegroundColor: Colors.grey[400],
        side: BorderSide(color: secondaryColor),
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
      child: _buildButtonContent(context, textColor: secondaryColor),
    );
  }

  Widget _buildGhostButton(BuildContext context, bool enabled) {
    final secondaryColor = DesignSystemTheme.secondaryDark(themeConfig);
    final padding = _getPadding();

    return TextButton(
      onPressed: enabled ? onPressed : null,
      style: TextButton.styleFrom(
        foregroundColor: secondaryColor,
        disabledForegroundColor: Colors.grey[400],
        padding: padding,
      ),
      child: _buildButtonContent(context, textColor: secondaryColor),
    );
  }

  Widget _buildDestructiveButton(BuildContext context, bool enabled) {
    final errorColor = DesignSystemTheme.errorColor(themeConfig);
    final padding = _getPadding();

    return FilledButton(
      onPressed: enabled ? onPressed : null,
      style: FilledButton.styleFrom(
        backgroundColor: errorColor,
        disabledBackgroundColor: Colors.grey[300],
        padding: padding,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(AppBorderRadius.sm),
        ),
      ),
      child: _buildButtonContent(context),
    );
  }

  Widget _buildButtonContent(BuildContext context, {Color? textColor}) {
    if (isLoading) {
      return SizedBox(
        height: 20,
        width: 20,
        child: CircularProgressIndicator(
          strokeWidth: 2,
          valueColor: AlwaysStoppedAnimation(textColor ?? Colors.white),
        ),
      );
    }

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        if (leadingIcon != null) ...[
          Icon(leadingIcon, size: 20),
          const SizedBox(width: 8),
        ],
        Text(
          label,
          style: TextStyle(
            fontSize: _getFontSize(),
            fontWeight: FontWeight.w600,
            color: textColor,
          ),
        ),
      ],
    );
  }

  EdgeInsetsGeometry _getPadding() {
    switch (size) {
      case AppButtonSize.small:
        return const EdgeInsets.symmetric(horizontal: 16, vertical: 8);
      case AppButtonSize.medium:
        return const EdgeInsets.symmetric(horizontal: 24, vertical: 12);
      case AppButtonSize.large:
        return const EdgeInsets.symmetric(horizontal: 32, vertical: 16);
    }
  }

  double _getFontSize() {
    switch (size) {
      case AppButtonSize.small:
        return 14;
      case AppButtonSize.medium:
        return 16;
      case AppButtonSize.large:
        return 18;
    }
  }
}
