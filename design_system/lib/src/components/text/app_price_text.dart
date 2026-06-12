import 'package:flutter/material.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

import '../../tokens/app_text_styles.dart';

/// Size presets for [AppPriceText].
enum AppPriceTextSize { small, medium, large }

/// Renders an int-paise amount as Indian Rupees (₹1,490.00) using the shared
/// `Money` formatter from core — the ONLY way prices are displayed.
/// Pass [comparePaise] to show a strikethrough original price beside it.
class AppPriceText extends StatelessWidget {
  final int pricePaise;
  final AppPriceTextSize size;
  final Color? color;
  final int? comparePaise;

  const AppPriceText({
    super.key,
    required this.pricePaise,
    this.size = AppPriceTextSize.medium,
    this.color,
    this.comparePaise,
  });

  TextStyle _style(BuildContext context) {
    final effectiveColor =
        color ?? Theme.of(context).colorScheme.onSurface;
    switch (size) {
      case AppPriceTextSize.small:
        return AppTextStyles.labelSmall(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
        );
      case AppPriceTextSize.medium:
        return AppTextStyles.labelMedium(
          color: effectiveColor,
          fontWeight: FontWeight.w700,
        );
      case AppPriceTextSize.large:
        return AppTextStyles.headlineMedium(
          color: effectiveColor,
          fontWeight: FontWeight.w800,
        );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.baseline,
      textBaseline: TextBaseline.alphabetic,
      children: [
        Flexible(
          child: Text(
            Money.formatPaise(pricePaise),
            style: _style(context),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (comparePaise != null && comparePaise! > pricePaise) ...[
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              Money.formatPaise(comparePaise!),
              style: AppTextStyles.labelSmall(
                color: colorScheme.onSurfaceVariant,
              ).copyWith(decoration: TextDecoration.lineThrough),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ],
    );
  }
}
