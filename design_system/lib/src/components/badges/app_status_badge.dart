import 'package:flutter/material.dart';

import '../../tokens/app_text_styles.dart';

/// Semantic color category for [AppStatusBadge]. Apps map their domain
/// statuses (OrderStatus, DesignStatus, …) to one of these.
enum AppStatusType { success, warning, error, info, neutral }

/// Colored pill for order/design/user statuses. [label] must already be
/// localized by the caller.
class AppStatusBadge extends StatelessWidget {
  final String label;
  final AppStatusType type;

  const AppStatusBadge({
    super.key,
    required this.label,
    this.type = AppStatusType.neutral,
  });

  Color _baseColor(ColorScheme colorScheme) {
    switch (type) {
      case AppStatusType.success:
        return const Color(0xFF2E7D32);
      case AppStatusType.warning:
        return const Color(0xFFF57C00);
      case AppStatusType.error:
        return colorScheme.error;
      case AppStatusType.info:
        return const Color(0xFF1976D2);
      case AppStatusType.neutral:
        return colorScheme.onSurfaceVariant;
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final base = _baseColor(colorScheme);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final foreground = isDark
        ? Color.alphaBlend(Colors.white.withValues(alpha: 0.4), base)
        : base;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: base.withValues(alpha: isDark ? 0.22 : 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall(
          color: foreground,
          fontWeight: FontWeight.w600,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
