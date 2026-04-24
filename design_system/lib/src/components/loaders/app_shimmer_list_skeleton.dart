import 'package:flutter/material.dart';
import 'app_shimmer.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Ready-made list skeleton for loading states
class AppShimmerListSkeleton extends StatelessWidget {
  final int itemCount;
  final double itemHeight;
  final EdgeInsets? padding;
  final AppThemeConfig? themeConfig;

  const AppShimmerListSkeleton({
    this.itemCount = 6,
    this.itemHeight = 72.0,
    this.padding,
    this.themeConfig,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return AppShimmer(
      themeConfig: themeConfig,
      child: ListView.builder(
        padding: padding ?? const EdgeInsets.all(16),
        itemCount: itemCount,
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemBuilder: (context, index) {
          return Padding(
            padding: const EdgeInsets.only(bottom: 16),
            child: Container(
              height: itemHeight,
              decoration: BoxDecoration(
                color: Colors.grey[300],
                borderRadius: BorderRadius.circular(8),
              ),
            ),
          );
        },
      ),
    );
  }
}
