import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/orders/user_orders_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/purchases/order_detail_screen.dart';

/// "Orders" tab of My Purchases — the user's order history (WS-B3).
class OrdersTab extends StatefulWidget {
  const OrdersTab({super.key});

  @override
  State<OrdersTab> createState() => _OrdersTabState();
}

class _OrdersTabState extends State<OrdersTab>
    with AutomaticKeepAliveClientMixin {
  late final UserOrdersCubit _cubit;

  @override
  bool get wantKeepAlive => true;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<UserOrdersCubit>();
    _cubit.load();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final strings = AppLocalization.strings;
    return BlocProvider.value(
      value: _cubit,
      child: BlocBuilder<UserOrdersCubit, UserOrdersState>(
        builder: (context, state) {
          switch (state.status) {
            case UserOrdersStatus.initial:
            case UserOrdersStatus.loading:
              return const Center(child: AppLoader());
            case UserOrdersStatus.error:
              return AppEmptyState(
                icon: Icons.error_outline,
                message: strings.somethingWentWrong,
                actionLabel: strings.retry,
                onAction: _cubit.load,
              );
            case UserOrdersStatus.loaded:
              if (state.orders.isEmpty) {
                return AppEmptyState(
                  icon: Icons.receipt_long_outlined,
                  message: strings.noOrdersFound,
                );
              }
              return RefreshIndicator(
                onRefresh: _cubit.refresh,
                child: ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  padding: const EdgeInsets.all(16),
                  itemCount: state.orders.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, i) =>
                      _OrderCard(order: state.orders[i]),
                ),
              );
          }
        },
      ),
    );
  }
}

/// Localized label + color for an order status chip.
(String, Color) orderStatusPresentation(
  BuildContext context,
  OrderStatus status,
) {
  final strings = AppLocalization.strings;
  switch (status) {
    case OrderStatus.paid:
      return (strings.orderStatusPaid, Colors.green.shade600);
    case OrderStatus.created:
      return (strings.orderStatusPending, Colors.orange.shade700);
    case OrderStatus.failed:
      return (strings.orderStatusFailed, Theme.of(context).colorScheme.error);
    case OrderStatus.refundInitiated:
      return (strings.orderStatusRefundInitiated, Colors.orange.shade700);
    case OrderStatus.refunded:
      return (strings.orderStatusRefunded, Colors.blueGrey.shade600);
  }
}

/// Demo/test orders store rupees; live orders store paise (see
/// InvoicePdfService). Normalized here for display.
String orderAmountInr(OrderModel order, int value) {
  final paise = order.id.startsWith('demo_') ? value * 100 : value;
  final rupees = paise / 100;
  // Whole-rupee amounts read cleaner without trailing ".00".
  return rupees == rupees.roundToDouble()
      ? '₹${rupees.round()}'
      : '₹${rupees.toStringAsFixed(2)}';
}

class _OrderCard extends StatelessWidget {
  final OrderModel order;

  const _OrderCard({required this.order});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final (statusLabel, statusColor) = orderStatusPresentation(
      context,
      order.status,
    );
    final date = DateFormat('dd MMM yyyy').format(order.createdAt);
    final reference = order.invoiceNumber ?? order.id;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => OrderDetailScreen(order: order)),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
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
                    reference,
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
              '$date · ${order.items.length} ${strings.orderItems.toLowerCase()}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant,
              ),
            ),
            const SizedBox(height: 6),
            Row(
              children: [
                Expanded(
                  child: Text(
                    order.items.map((i) => i.title).join(', '),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.bodySmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  orderAmountInr(order, order.totalAmount),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium(
                    fontWeight: FontWeight.w700,
                    color: colorScheme.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
