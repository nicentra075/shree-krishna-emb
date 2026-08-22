import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart'
    show OrderModel, OrderStatus, OrderItemEntity;
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/core/auth/access_policy.dart';
import 'package:shree_krishna_emb_admin/bloc/transactions/orders_cubit.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/transactions/widgets/order_status_chip.dart';

/// Detail dialog for a single order: items, fee/GST breakdown, payment id,
/// invoice, status timeline, and a Refund action (paid orders only).
class OrderDetailDialog extends StatelessWidget {
  final OrderModel order;

  const OrderDetailDialog({super.key, required this.order});

  String _fmt(DateTime? d) =>
      d == null ? '—' : DateFormat('dd MMM yyyy, hh:mm a').format(d);

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final screenWidth = MediaQuery.of(context).size.width;
    final dialogWidth = screenWidth < 600 ? screenWidth - 32 : 560.0;

    return Dialog(
      backgroundColor: colorScheme.surface,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: dialogWidth,
          maxHeight: MediaQuery.of(context).size.height * 0.85,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            _header(context, strings, colorScheme),
            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _section(colorScheme, strings.items),
                    ...order.items.map((i) => _itemRow(context, i)),
                    const SizedBox(height: 16),
                    _section(colorScheme, strings.total),
                    _amountRow(context, strings.subtotal, order.itemsSubtotal),
                    _amountRow(context, strings.platformFee, order.platformFee),
                    _amountRow(context, strings.gst, order.gstAmount),
                    const Divider(height: 20),
                    _amountRow(
                      context,
                      strings.total,
                      order.totalAmount,
                      emphasize: true,
                    ),
                    const SizedBox(height: 16),
                    _section(colorScheme, strings.paymentId),
                    _kv(
                      context,
                      strings.paymentId,
                      order.razorpayPaymentId ?? '—',
                    ),
                    _kv(context, strings.invoice, order.invoiceNumber ?? '—'),
                    const SizedBox(height: 16),
                    _section(colorScheme, strings.timeline),
                    _kv(context, strings.orderPlaced, _fmt(order.createdAt)),
                    _kv(context, strings.paidOn, _fmt(order.paidAt)),
                    if (order.refundedAt != null)
                      _kv(context, strings.refundedOn, _fmt(order.refundedAt)),
                  ],
                ),
              ),
            ),
            _footer(context, strings, colorScheme),
          ],
        ),
      ),
    );
  }

  Widget _header(
    BuildContext context,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 20, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  strings.orderDetails,
                  style: AppTextStyles.headlineMedium(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.w800,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        order.id,
                        style: AppTextStyles.bodySmall(
                          color: colorScheme.onSurfaceVariant,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 8),
                    OrderStatusChip(status: order.status),
                  ],
                ),
              ],
            ),
          ),
          IconButton(
            icon: const Icon(Icons.close),
            color: colorScheme.onSurfaceVariant,
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }

  Widget _section(ColorScheme colorScheme, String title) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Text(
      title,
      style: AppTextStyles.labelMedium(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _itemRow(BuildContext context, OrderItemEntity item) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: SizedBox(
              width: 40,
              height: 40,
              child: (item.thumbUrl != null && item.thumbUrl!.isNotEmpty)
                  ? AppNetworkImage(imageUrl: item.thumbUrl!, fit: BoxFit.cover)
                  : Container(
                      color: colorScheme.surfaceContainerHighest,
                      child: Icon(
                        Icons.image_outlined,
                        size: 18,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  item.categoryName.isNotEmpty
                      ? item.categoryName
                      : item.fileFormat,
                  style: AppTextStyles.labelSmall(
                    color: colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          Text(
            '₹${item.price}',
            style: AppTextStyles.labelMedium(
              color: colorScheme.onSurface,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    int amount, {
    bool emphasize = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final style = emphasize
        ? AppTextStyles.labelLarge(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w800,
          )
        : AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              style: style,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Text(
            '₹$amount',
            style: style,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _kv(BuildContext context, String key, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              key,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: AppTextStyles.bodySmall(color: colorScheme.onSurface),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  Widget _footer(
    BuildContext context,
    dynamic strings,
    ColorScheme colorScheme,
  ) {
    // Refunds move money — admin only (D2); designers see their sales
    // read-only.
    final canRefund =
        order.status == OrderStatus.paid &&
        currentAccessPolicy().canInitiateRefunds;
    return BlocBuilder<OrdersCubit, OrdersState>(
      builder: (context, state) {
        return Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(
                color: colorScheme.outline.withValues(alpha: 0.2),
              ),
            ),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.end,
            children: [
              AppButton(
                label: strings.cancel,
                variant: AppButtonVariant.secondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
              const SizedBox(width: 12),
              AppButton(
                label: strings.refund,
                variant: AppButtonVariant.destructive,
                isLoading: state.refunding,
                onPressed: canRefund && !state.refunding
                    ? () => _confirmRefund(context, strings)
                    : () {},
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _confirmRefund(BuildContext context, dynamic strings) async {
    final reasonController = TextEditingController();
    final cubit = context.read<OrdersCubit>();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final colorScheme = Theme.of(ctx).colorScheme;
        return AlertDialog(
          backgroundColor: colorScheme.surface,
          title: Text(
            strings.refundConfirmTitle,
            style: AppTextStyles.headlineMedium(color: colorScheme.onSurface),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                strings.refundConfirmMessage,
                style: AppTextStyles.bodyMedium(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 4,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              AppTextField(
                controller: reasonController,
                label: strings.refundReason,
                hint: strings.refundReasonHint,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx, false),
              child: Text(
                strings.cancel,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            TextButton(
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(
                strings.refundOrder,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      reasonController.dispose();
      return;
    }
    if (!context.mounted) return;

    final reason = reasonController.text.trim();
    reasonController.dispose();

    final success = await cubit.refundOrder(
      orderId: order.id,
      reason: reason.isEmpty ? 'Refund initiated by admin' : reason,
    );
    if (!context.mounted) return;

    if (success) {
      ResponsiveSnackbar.showSuccess(strings.refundSuccess, context);
      Navigator.of(context).pop();
    } else {
      ResponsiveSnackbar.showError(
        cubit.state.error ?? strings.refundFailed,
        context,
      );
    }
  }
}
