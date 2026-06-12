import 'package:flutter/material.dart';

import '../../tokens/app_text_styles.dart';

/// Tap-to-pick date range field for list filters (transactions, reports).
/// Uses the Material date range picker themed by the app; shows a clear
/// affordance when a range is selected.
class AppDateRangeField extends StatelessWidget {
  final String? label;
  final String? hint;
  final DateTimeRange? value;
  final ValueChanged<DateTimeRange?> onChanged;
  final DateTime? firstDate;
  final DateTime? lastDate;

  const AppDateRangeField({
    super.key,
    this.label,
    this.hint,
    this.value,
    required this.onChanged,
    this.firstDate,
    this.lastDate,
  });

  Future<void> _pick(BuildContext context) async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: firstDate ?? DateTime(now.year - 3),
      lastDate: lastDate ?? now,
      initialDateRange: value,
    );
    if (picked != null) {
      onChanged(picked);
    }
  }

  String _format(BuildContext context, DateTimeRange range) {
    final localizations = MaterialLocalizations.of(context);
    return '${localizations.formatCompactDate(range.start)} – '
        '${localizations.formatCompactDate(range.end)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final hasValue = value != null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      mainAxisSize: MainAxisSize.min,
      children: [
        if (label != null) ...[
          Text(
            label!,
            style: AppTextStyles.labelMedium(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w600,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
        ],
        Material(
          color: colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: () => _pick(context),
            child: Container(
              height: 44,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: hasValue
                      ? colorScheme.primary
                      : colorScheme.outline.withValues(alpha: 0.2),
                  width: 1,
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.date_range_outlined,
                    size: 18,
                    color: hasValue
                        ? colorScheme.primary
                        : colorScheme.onSurfaceVariant,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      hasValue ? _format(context, value!) : (hint ?? ''),
                      style: AppTextStyles.bodyMedium(
                        color: hasValue
                            ? colorScheme.onSurface
                            : colorScheme.onSurfaceVariant
                                .withValues(alpha: 0.7),
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (hasValue)
                    InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () => onChanged(null),
                      child: Icon(
                        Icons.close,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
