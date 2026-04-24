import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import '../../theme/design_system_theme.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Loading spinner component using discreteCircular animation
class AppLoader extends StatelessWidget {
  final Color? color;
  final double size;
  final AppThemeConfig? themeConfig;

  const AppLoader({
    this.color,
    this.size = 40.0,
    this.themeConfig,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    final loaderColor = color ?? DesignSystemTheme.primaryDark(themeConfig);

    return LoadingAnimationWidget.discreteCircle(
      size: size,
      color: loaderColor,
    );
  }
}
