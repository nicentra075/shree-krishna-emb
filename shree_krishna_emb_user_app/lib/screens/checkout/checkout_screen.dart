import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/bloc/cart/cart_cubit.dart';
import 'package:shree_krishna_emb/bloc/checkout/checkout_cubit.dart';
import 'package:shree_krishna_emb/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_emb/bloc/purchases/purchases_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/purchases/my_purchases_screen.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

/// Order summary + Pay. Builds an [OrderDraft] from the cart and platform
/// settings, then runs the runtime-selected checkout service (mock / test
/// razorpay / server razorpay). On success: clears the cart, refreshes
/// ownership, and routes to My Purchases.
class CheckoutScreen extends StatelessWidget {
  const CheckoutScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<CheckoutCubit>(
      create: (_) => getIt<CheckoutCubit>(),
      child: const _CheckoutView(),
    );
  }
}

class _CheckoutView extends StatefulWidget {
  const _CheckoutView();

  @override
  State<_CheckoutView> createState() => _CheckoutViewState();
}

class _CheckoutViewState extends State<_CheckoutView> {
  final _emailController = TextEditingController();

  /// Buyer phone taken from the signed-in account; prefilled into Razorpay so
  /// it isn't asked again (and so UPI has the contact it needs).
  String _buyerPhone = '';

  @override
  void initState() {
    super.initState();
    // Seed the email field + phone from the logged-in user so the buyer doesn't
    // have to retype details Razorpay would otherwise prompt for.
    final authState = getIt<AuthBloc>().state;
    if (authState is AuthAuthenticated) {
      final user = authState.user;
      if (user.email.trim().isNotEmpty) {
        _emailController.text = user.email.trim();
      }
      _buyerPhone = user.phoneNumber?.trim() ?? '';
    }
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  OrderDraft _buildDraft(BuildContext context) {
    final cart = context.read<CartCubit>().state;
    final config = context.read<PlatformConfigCubit>().state;
    return OrderDraft.fromCart(
      items: cart.items,
      platformFeePercent: config.feePercent,
      gstPercent: config.gstPercent,
      buyerEmail: _emailController.text.trim().isEmpty
          ? config.buyerSupportEmail
          : _emailController.text.trim(),
      buyerPhone: _buyerPhone,
    );
  }

  Future<void> _onPay(BuildContext context) async {
    final config = context.read<PlatformConfigCubit>().state;
    final draft = _buildDraft(context);
    await context.read<CheckoutCubit>().pay(
      draft: draft,
      paymentTestMode: config.paymentTestMode,
      razorpayKeyId: config.razorpayKeyId,
      businessName: config.config?.settings.sellerName ?? 'Shree Krishna',
    );
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppAppBar(
        title: strings.checkoutTitle,
        onBack: () => Navigator.pop(context),
      ),
      body: BlocConsumer<CheckoutCubit, CheckoutState>(
        listener: (context, state) async {
          switch (state.status) {
            case CheckoutStatus.success:
              // Capture before awaiting so no BuildContext crosses async gaps.
              final navigator = Navigator.of(context);
              final cartCubit = context.read<CartCubit>();
              final purchasesCubit = context.read<PurchasesCubit>();
              // Clear cart (no-op in live path where the server already did)
              // and refresh ownership before showing My Purchases.
              await cartCubit.clear();
              await purchasesCubit.refresh();
              AppSnackbar.showSuccess(strings.paymentSuccessMessage);
              navigator.pushReplacement(
                MaterialPageRoute(builder: (_) => const MyPurchasesScreen()),
              );
              break;
            case CheckoutStatus.cancelled:
              AppSnackbar.showError(strings.paymentCancelled);
              context.read<CheckoutCubit>().reset();
              break;
            case CheckoutStatus.error:
              AppSnackbar.showError(state.error ?? strings.paymentFailed);
              context.read<CheckoutCubit>().reset();
              break;
            case CheckoutStatus.idle:
            case CheckoutStatus.processing:
              break;
          }
        },
        builder: (context, checkout) {
          return Stack(
            children: [
              _form(context, checkout.isProcessing),
              if (checkout.isProcessing)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: AppLoader()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _form(BuildContext context, bool processing) {
    final strings = AppLocalization.strings;
    return BlocBuilder<CartCubit, CartState>(
      builder: (context, cart) {
        if (cart.isEmpty) {
          return AppEmptyState(
            message: strings.cartEmptyMessage,
            icon: Icons.shopping_cart_outlined,
          );
        }
        return BlocBuilder<PlatformConfigCubit, PlatformConfigState>(
          builder: (context, config) {
            final draft = OrderDraft.fromCart(
              items: cart.items,
              platformFeePercent: config.feePercent,
              gstPercent: config.gstPercent,
            );
            return Column(
              children: [
                Expanded(
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      Text(
                        strings.orderSummary,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodyLarge(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ...cart.items.map(
                        (i) => Padding(
                          padding: const EdgeInsets.only(bottom: 8),
                          child: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  i.title,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyMedium(),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(
                                i.price <= 0 ? strings.free : '₹${i.price}',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.bodyMedium(
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const Divider(height: 24),
                      _amountRow(context, strings.subtotal, draft.subtotal),
                      // Fee / GST shown only when the admin has them active.
                      if (config.platformFeeActive) ...[
                        const SizedBox(height: 6),
                        _amountRow(
                          context,
                          '${strings.platformFee} '
                          '(${config.feePercent.toStringAsFixed(0)}%)',
                          draft.platformFee,
                        ),
                      ],
                      if (config.gstActive) ...[
                        const SizedBox(height: 6),
                        _amountRow(
                          context,
                          '${strings.gst} '
                          '(${config.gstPercent.toStringAsFixed(0)}%)',
                          draft.gst,
                        ),
                      ],
                      const Divider(height: 24),
                      _amountRow(
                        context,
                        strings.grandTotal,
                        draft.total,
                        emphasize: true,
                      ),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 20),
                  child: AppButton(
                    label: draft.isFree
                        ? strings.payNow
                        : '${strings.payNow}  •  ₹${draft.total}',
                    leadingIcon: Icons.lock_outline,
                    isFullWidth: true,
                    isLoading: processing,
                    onPressed: processing ? null : () => _onPay(context),
                  ),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _amountRow(
    BuildContext context,
    String label,
    int amount, {
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
          '₹$amount',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: valueStyle,
        ),
      ],
    );
  }
}
