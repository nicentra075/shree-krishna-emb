import 'package:flutter/material.dart';
import '../../theme/design_system_theme.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Pull-to-refresh wrapper component with consistent theming
class AppPullToRefresh extends StatelessWidget {
  final Widget child;
  final Future<void> Function() onRefresh;
  final AppThemeConfig? themeConfig;

  const AppPullToRefresh({
    required this.child,
    required this.onRefresh,
    this.themeConfig,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return RefreshIndicator(
      onRefresh: onRefresh,
      color: Colors.white,
      backgroundColor: DesignSystemTheme.primaryDark(themeConfig),
      child: child,
    );
  }
}
