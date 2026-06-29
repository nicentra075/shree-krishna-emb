import 'package:flutter/material.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart' show OrderStatus;
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

/// A small coloured status pill for an [OrderStatus]. Colours are fixed
/// semantic tones (green/amber/red/blue) that read well in light + dark.
class OrderStatusChip extends StatelessWidget {
  final OrderStatus status;

  const OrderStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final (color, label) = switch (status) {
      OrderStatus.paid => (const Color(0xFF4CAF50), strings.statusPaid),
      OrderStatus.created => (const Color(0xFF42A5F5), strings.statusCreated),
      OrderStatus.failed => (const Color(0xFFFF6B6B), strings.statusFailed),
      OrderStatus.refundInitiated => (
        const Color(0xFFFFA726),
        strings.statusRefundInitiated,
      ),
      OrderStatus.refunded => (const Color(0xFF9575CD), strings.statusRefunded),
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.14),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.4)),
      ),
      child: Text(
        label,
        style: AppTextStyles.labelSmall(
          color: color,
          fontWeight: FontWeight.w700,
        ),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
