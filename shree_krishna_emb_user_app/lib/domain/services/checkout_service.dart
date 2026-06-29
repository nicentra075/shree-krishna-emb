import 'package:shree_krishna_emb/domain/entities/order_draft.dart';

/// Outcome of a checkout attempt.
///
/// - [success] true → payment captured + records written (or finalized
///   server-side); the caller should clear the cart and refresh purchases.
/// - [cancelled] true → user dismissed the payment sheet; cart is untouched.
/// - [error] non-null → something failed; cart is untouched.
class CheckoutResult {
  final bool success;
  final bool cancelled;
  final String? orderId;
  final String? error;

  const CheckoutResult({
    this.success = false,
    this.cancelled = false,
    this.orderId,
    this.error,
  });

  factory CheckoutResult.ok({String? orderId}) =>
      CheckoutResult(success: true, orderId: orderId);

  factory CheckoutResult.cancel() => const CheckoutResult(cancelled: true);

  factory CheckoutResult.fail(String message) => CheckoutResult(error: message);
}

/// Pays for a draft order. Implementations: mock (demo), test-key Razorpay,
/// and production server-trusted Razorpay. Selected at runtime by the
/// `paymentTestMode` flag.
abstract class CheckoutService {
  Future<CheckoutResult> pay(OrderDraft draft);

  /// Releases any native resources (e.g. the Razorpay instance).
  void dispose() {}
}
