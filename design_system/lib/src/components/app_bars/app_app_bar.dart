import 'package:flutter/material.dart';
import '../../tokens/app_text_styles.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Reusable AppBar component with consistent styling across the app
///
/// Features:
/// - Automatic dark/light mode support
/// - Customizable title, subtitle, and actions
/// - Built-in back button handling
/// - Flexible leading widget support
/// - Elevation and shadow customization
class AppAppBar extends StatelessWidget implements PreferredSizeWidget {
  /// Title text displayed in the AppBar
  final String title;

  /// Optional subtitle text displayed below title
  final String? subtitle;

  /// Leading widget (usually back button)
  /// If null, automatically shows back button if onBack is provided
  final Widget? leading;

  /// Callback when back button is pressed
  /// If null, back button won't be shown
  final VoidCallback? onBack;

  /// List of action widgets (usually icons) on the right side
  final List<Widget>? actions;

  /// Center the title
  final bool centerTitle;

  /// Background color of the AppBar
  /// If null, uses theme-based color
  final Color? backgroundColor;

  /// Elevation of the AppBar
  final double elevation;

  /// Theme configuration for color theming
  final AppThemeConfig? themeConfig;

  /// Whether to show a bottom border/divider
  final bool showBottomBorder;

  /// Custom bottom border color
  final Color? bottomBorderColor;

  /// Padding for title and subtitle
  final EdgeInsets titlePadding;

  /// Custom height of the AppBar
  final double appBarHeight;

  const AppAppBar({
    required this.title,
    this.subtitle,
    this.leading,
    this.onBack,
    this.actions,
    this.centerTitle = false,
    this.backgroundColor,
    this.elevation = 1,
    this.themeConfig,
    this.showBottomBorder = true,
    this.bottomBorderColor,
    this.titlePadding = const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
    this.appBarHeight = 56,
    super.key,
  });

  @override
  Size get preferredSize => Size.fromHeight(appBarHeight);

  @override
  Widget build(BuildContext context) {
    // Theme-aware: title/icons follow the active colorScheme.primary (brand
    // brown in light, brand orange in dark) and the bar background follows the
    // surface, so the app bar adapts to dark mode instead of staying light.
    final colorScheme = Theme.of(context).colorScheme;
    final primaryColor = colorScheme.primary;
    final bgColor = backgroundColor ?? colorScheme.surface;

    return AppBar(
      title: _buildTitle(primaryColor),
      leading: _buildLeading(context, primaryColor),
      actions: actions,
      centerTitle: centerTitle,
      backgroundColor: bgColor,
      elevation: elevation,
      scrolledUnderElevation: 0,
      bottom: showBottomBorder
          ? PreferredSize(
              preferredSize: const Size.fromHeight(1),
              child: Container(
                height: 1,
                color: primaryColor.withValues(alpha: 0.1),
              ),
            )
          : null,
      iconTheme: IconThemeData(color: primaryColor),
      titleTextStyle: AppTextStyles.headlineMedium(
        color: primaryColor,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  /// Builds the title section with optional subtitle
  Widget _buildTitle(Color primaryColor) {
    if (subtitle == null) {
      return Text(title);
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: AppTextStyles.headlineMedium(
            color: primaryColor,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        Text(
          subtitle!,
          style: AppTextStyles.bodySmall(
            color: primaryColor.withValues(alpha: 0.7),
          ),
        ),
      ],
    );
  }

  /// Builds the leading widget
  Widget? _buildLeading(BuildContext context, Color primaryColor) {
    // If custom leading is provided, use it
    if (leading != null) {
      return leading;
    }

    // Show back button if onBack callback is provided
    if (onBack != null) {
      return Padding(
        padding: const EdgeInsets.only(left: 8.0),
        child: IconButton(
          icon: Icon(Icons.arrow_back, color: primaryColor),
          onPressed: onBack,
          tooltip: 'Back',
        ),
      );
    }

    // No leading widget
    return null;
  }
}
