import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/cart/cart_cubit.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/cart/cart_screen.dart';

/// Full-width CTA that adds the design to the cart, or — when it is already in
/// the cart — switches to "Go to Cart" and opens the cart screen. Reads the
/// app-wide [CartCubit] so its state stays in sync everywhere.
class AddToCartButton extends StatelessWidget {
  final String designId;
  final String title;
  final String? thumbUrl;

  /// Display price in integer rupees.
  final int price;
  final String categoryName;

  const AddToCartButton({
    super.key,
    required this.designId,
    required this.title,
    this.thumbUrl,
    this.price = 0,
    this.categoryName = '',
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    return BlocBuilder<CartCubit, CartState>(
      buildWhen: (prev, curr) =>
          prev.contains(designId) != curr.contains(designId),
      builder: (context, state) {
        final inCart = state.contains(designId);
        if (inCart) {
          return AppButton(
            label: strings.goToCart,
            leadingIcon: Icons.shopping_cart,
            variant: AppButtonVariant.outlined,
            isFullWidth: true,
            onPressed: () => Navigator.of(
              context,
            ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
          );
        }
        return AppButton(
          label: strings.addToCart,
          leadingIcon: Icons.add_shopping_cart_outlined,
          isFullWidth: true,
          onPressed: () async {
            final added = await context.read<CartCubit>().add(
              designId: designId,
              title: title,
              thumbUrl: thumbUrl,
              price: price,
              categoryName: categoryName,
            );
            if (added) {
              AppSnackbar.showSuccess(strings.addedToCart);
            } else {
              AppSnackbar.showError(strings.cartLimitReached);
            }
          },
        );
      },
    );
  }
}
