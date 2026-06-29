import 'dart:async';

import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shree_krishna_emb/core/utils/app_logger.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_order_writer.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';
import 'package:shree_krishna_emb/domain/services/checkout_service.dart';

/// Test-key Razorpay checkout. Opens the native Razorpay sheet with the TEST
/// publishable key (no server order id), and on success writes the order +
/// purchases + clears the cart client-side (same as [MockCheckout]). Used in
/// test mode when a Razorpay test key IS configured. No real money moves
/// (Razorpay test keys only accept test cards).
class RazorpayTestCheckout implements CheckoutService {
  final FirebaseOrderWriter _orderWriter;
  final String _keyId;
  final String _businessName;

  Razorpay? _razorpay;
  Completer<CheckoutResult>? _completer;

  RazorpayTestCheckout({
    required FirebaseOrderWriter orderWriter,
    required String keyId,
    required String businessName,
  }) : _orderWriter = orderWriter,
       _keyId = keyId,
       _businessName = businessName;

  @override
  Future<CheckoutResult> pay(OrderDraft draft) async {
    final completer = Completer<CheckoutResult>();
    _completer = completer;

    final razorpay = Razorpay();
    _razorpay = razorpay;
    razorpay.on(
      Razorpay.EVENT_PAYMENT_SUCCESS,
      (PaymentSuccessResponse r) => _onSuccess(draft, r),
    );
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    try {
      razorpay.open(<String, dynamic>{
        'key': _keyId,
        // razorpay amount is ALWAYS in paise.
        'amount': draft.total * 100,
        'currency': 'INR',
        'name': _businessName.isEmpty ? 'Shree Krishna' : _businessName,
        'description': 'Design purchase',
        // Prefill the buyer's contact + email so Razorpay (and UPI) skip asking
        // for them — they're already known from the signed-in account.
        if (draft.razorpayPrefill.isNotEmpty) 'prefill': draft.razorpayPrefill,
      });
    } catch (e, s) {
      AppLogger.logError('Razorpay open failed', error: e, stackTrace: s);
      _settle(CheckoutResult.fail(e.toString()));
    }

    return completer.future;
  }

  Future<void> _onSuccess(
    OrderDraft draft,
    PaymentSuccessResponse response,
  ) async {
    try {
      final orderId = await _orderWriter.writePaidOrder(
        draft,
        razorpayPaymentId: response.paymentId,
      );
      _settle(CheckoutResult.ok(orderId: orderId));
    } catch (e, s) {
      AppLogger.logError(
        'Order write failed after payment',
        error: e,
        stackTrace: s,
      );
      _settle(CheckoutResult.fail(e.toString()));
    }
  }

  void _onError(PaymentFailureResponse response) {
    if (response.code == Razorpay.PAYMENT_CANCELLED) {
      _settle(CheckoutResult.cancel());
      return;
    }
    AppLogger.logError('Razorpay payment error: ${response.message}');
    _settle(CheckoutResult.fail(response.message ?? 'Payment failed'));
  }

  void _onExternalWallet(ExternalWalletResponse response) {
    // The wallet flow continues outside the sheet; treat as cancelled so the
    // cart is preserved and the user can retry.
    _settle(CheckoutResult.cancel());
  }

  void _settle(CheckoutResult result) {
    _razorpay?.clear();
    final completer = _completer;
    if (completer != null && !completer.isCompleted) {
      completer.complete(result);
    }
  }

  @override
  void dispose() {
    _razorpay?.clear();
    _razorpay = null;
  }
}
