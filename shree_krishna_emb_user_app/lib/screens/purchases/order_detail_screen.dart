import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/services/invoice_pdf_service.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/purchases/orders_tab.dart';

/// Full breakdown of one order: items, fee/GST totals, payment reference and
/// the invoice download action (WS-B3).
class OrderDetailScreen extends StatefulWidget {
  final OrderModel order;

  const OrderDetailScreen({required this.order, super.key});

  @override
  State<OrderDetailScreen> createState() => _OrderDetailScreenState();
}

class _OrderDetailScreenState extends State<OrderDetailScreen> {
  bool _generatingInvoice = false;

  Future<void> _downloadInvoice() async {
    final strings = AppLocalization.strings;
    setState(() => _generatingInvoice = true);
    try {
      await getIt<InvoicePdfService>().shareInvoice(
        widget.order,
        appName: strings.appName,
      );
    } catch (_) {
      if (mounted) AppSnackbar.showError(strings.invoiceFailed);
    } finally {
      if (mounted) setState(() => _generatingInvoice = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final order = widget.order;
    final (statusLabel, statusColor) = orderStatusPresentation(
      context,
      order.status,
    );
    final date = DateFormat('dd MMM yyyy, hh:mm a').format(order.createdAt);

    return Scaffold(
      backgroundColor: colorScheme.surface,
      appBar: AppAppBar(
        title: strings.orderDetails,
        onBack: () => Navigator.pop(context),
      ),
      bottomNavigationBar: order.isPaid
          ? SafeArea(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                child: AppButton(
                  label: strings.downloadInvoice,
                  leadingIcon: Icons.picture_as_pdf_outlined,
                  onPressed: _generatingInvoice ? null : _downloadInvoice,
                  isLoading: _generatingInvoice,
                  isFullWidth: true,
                  variant: AppButtonVariant.primary,
                ),
              ),
            )
          : null,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header card: reference, date, status
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          order.invoiceNumber ?? order.id,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 3,
                        ),
                        decoration: BoxDecoration(
                          color: statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Text(
                          statusLabel,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall(
                            color: statusColor,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${strings.orderDate}: $date',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                  if ((order.razorpayPaymentId ?? '').isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      '${strings.paymentId}: ${order.razorpayPaymentId}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              strings.orderItems,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodyLarge(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 10),
            for (final item in order.items)
              Container(
                margin: const EdgeInsets.only(bottom: 10),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: colorScheme.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: colorScheme.outlineVariant),
                ),
                child: Row(
                  children: [
                    AppNetworkImage(
                      imageUrl: item.thumbUrl,
                      width: 52,
                      height: 52,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            item.title,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: AppTextStyles.labelMedium(
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          if (item.fileFormat.isNotEmpty)
                            Text(
                              item.fileFormat,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.bodySmall(
                                color: colorScheme.onSurfaceVariant,
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      orderAmountInr(order, item.price),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelMedium(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 12),
            // Totals card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerLowest,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: colorScheme.outlineVariant),
              ),
              child: Column(
                children: [
                  _totalRow(
                    strings.subtotal,
                    orderAmountInr(order, order.itemsSubtotal),
                    colorScheme,
                  ),
                  _totalRow(
                    '${strings.platformFee} (${order.platformFeePercent}%)',
                    orderAmountInr(order, order.platformFee),
                    colorScheme,
                  ),
                  _totalRow(
                    '${strings.gst} (${order.gstPercent}%)',
                    orderAmountInr(order, order.gstAmount),
                    colorScheme,
                  ),
                  Divider(color: colorScheme.outlineVariant),
                  _totalRow(
                    strings.total,
                    orderAmountInr(order, order.totalAmount),
                    colorScheme,
                    bold: true,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _totalRow(
    String label,
    String value,
    ColorScheme colorScheme, {
    bool bold = false,
  }) {
    final style = bold
        ? AppTextStyles.labelMedium(fontWeight: FontWeight.w700)
        : AppTextStyles.bodySmall(color: colorScheme.onSurfaceVariant);
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            child: Text(
              label,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: style,
            ),
          ),
          Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: style,
          ),
        ],
      ),
    );
  }
}
