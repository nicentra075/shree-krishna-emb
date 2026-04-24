import 'package:flutter/material.dart';
import 'package:shimmer/shimmer.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Shimmer wrapper component for loading skeleton screens
class AppShimmer extends StatelessWidget {
  final Widget child;
  final Color? baseColor;
  final Color? highlightColor;
  final bool enabled;
  final AppThemeConfig? themeConfig;

  const AppShimmer({
    required this.child,
    this.baseColor,
    this.highlightColor,
    this.enabled = true,
    this.themeConfig,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    if (!enabled) {
      return child;
    }

    return Shimmer.fromColors(
      baseColor: baseColor ?? Colors.grey[300]!,
      highlightColor: highlightColor ?? Colors.grey[100]!,
      child: child,
    );
  }
}
