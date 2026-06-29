import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/cart/cart_cubit.dart';
import 'package:shree_krishna_emb/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/checkout/checkout_screen.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

/// The user's cart: a list of design line items with remove, totals computed
/// from the platform fee/gst percentages, and a Proceed-to-Checkout CTA.
class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppAppBar(
        title: strings.myCart,
        onBack: () => Navigator.pop(context),
      ),
      body: BlocBuilder<CartCubit, CartState>(
        builder: (context, state) {
          if (state.status == CartStatus.loading && state.isEmpty) {
            return const Center(child: AppLoader());
          }
          if (state.isEmpty) {
            return AppEmptyState(
              message: strings.cartEmptyMessage,
              icon: Icons.shopping_cart_outlined,
              actionLabel: strings.browseDesigns,
              onAction: () => Navigator.pop(context),
            );
          }
          return _CartBody(items: state.items, subtotal: state.subtotal);
        },
      ),
    );
  }
}

class _CartBody extends StatelessWidget {
  final List<CartItemEntity> items;
  final int subtotal;
  const _CartBody({required this.items, required this.subtotal});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    return Column(
      children: [
        Expanded(
          child: ListView.separated(
            padding: const EdgeInsets.all(16),
            itemCount: items.length,
            separatorBuilder: (_, _) => const SizedBox(height: 10),
            itemBuilder: (context, i) => _CartItemTile(item: items[i]),
          ),
        ),
        BlocBuilder<PlatformConfigCubit, PlatformConfigState>(
          builder: (context, config) {
            return _CartSummary(
              subtotal: subtotal,
              feePercent: config.feePercent,
              gstPercent: config.gstPercent,
              onCheckout: () => Navigator.of(
                context,
              ).push(MaterialPageRoute(builder: (_) => const CheckoutScreen())),
              checkoutLabel: strings.proceedToCheckout,
            );
          },
        ),
      ],
    );
  }
}

class _CartItemTile extends StatelessWidget {
  final CartItemEntity item;
  const _CartItemTile({required this.item});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: AppNetworkImage(
              imageUrl: item.thumbUrl,
              width: 64,
              height: 64,
              memCacheWidth: 128,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.title,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  item.price <= 0 ? strings.free : '₹${item.price}',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.bodyMedium(
                    color: AppTheme.primaryLight,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
          IconButton(
            tooltip: strings.removeFromCart,
            icon: Icon(Icons.delete_outline, color: colorScheme.error),
            onPressed: () async {
              await context.read<CartCubit>().remove(item.designId);
              AppSnackbar.showSuccess(strings.itemRemovedFromCart);
            },
          ),
        ],
      ),
    );
  }
}

class _CartSummary extends StatelessWidget {
  final int subtotal;
  final double feePercent;
  final double gstPercent;
  final VoidCallback onCheckout;
  final String checkoutLabel;

  const _CartSummary({
    required this.subtotal,
    required this.feePercent,
    required this.gstPercent,
    required this.onCheckout,
    required this.checkoutLabel,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;
    final fee = (subtotal * feePercent / 100).round();
    final gst = ((subtotal + fee) * gstPercent / 100).round();
    final total = subtotal + fee + gst;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 20),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerLow,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _row(context, strings.subtotal, '₹$subtotal'),
          // Fee / GST rows are shown only when the admin has them active
          // (enabled with a percent > 0); otherwise they are omitted entirely.
          if (feePercent > 0) ...[
            const SizedBox(height: 6),
            _row(
              context,
              '${strings.platformFee} (${feePercent.toStringAsFixed(0)}%)',
              '₹$fee',
            ),
          ],
          if (gstPercent > 0) ...[
            const SizedBox(height: 6),
            _row(
              context,
              '${strings.gst} (${gstPercent.toStringAsFixed(0)}%)',
              '₹$gst',
            ),
          ],
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 10),
            child: Divider(height: 1),
          ),
          _row(context, strings.grandTotal, '₹$total', emphasize: true),
          const SizedBox(height: 16),
          AppButton(
            label: checkoutLabel,
            leadingIcon: Icons.lock_outline,
            isFullWidth: true,
            onPressed: onCheckout,
          ),
        ],
      ),
    );
  }

  Widget _row(
    BuildContext context,
    String label,
    String value, {
    bool emphasize = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    final labelStyle = emphasize
        ? AppTextStyles.bodyLarge(fontWeight: FontWeight.bold)
        : AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant);
    final valueStyle = emphasize
        ? AppTextStyles.bodyLarge(
            color: AppTheme.primaryLight,
            fontWeight: FontWeight.bold,
          )
        : AppTextStyles.bodyMedium(fontWeight: FontWeight.w600);
    return Row(
      children: [
        Expanded(
          child: Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: labelStyle,
          ),
        ),
        const SizedBox(width: 12),
        Text(
          value,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
      ],
    );
  }
}
