import 'dart:async';

import 'package:cloud_functions/cloud_functions.dart';
import 'package:razorpay_flutter/razorpay_flutter.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/core/utils/app_logger.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';
import 'package:shree_krishna_emb/domain/services/checkout_service.dart';

/// PRODUCTION server-trusted Razorpay checkout.
///
/// Flow:
///  1. `createRazorpayOrder` → server re-reads the cart, computes authoritative
///     amounts, creates the Razorpay order, writes `orders/{razorpayOrderId}`
///     (status created), and returns the order id + key + amount (paise).
///  2. Open the Razorpay sheet with that server `order_id`.
///  3. On success → `verifyRazorpayPayment` → server verifies the signature,
///     finalizes the order (status paid), writes purchases, clears the cart.
///
/// The client never writes orders/purchases here — the functions do, gated by
/// Firestore rules. Amounts shown in [draft] are display-only.
class ServerRazorpayCheckout implements CheckoutService {
  final String _businessName;
  Razorpay? _razorpay;
  Completer<CheckoutResult>? _completer;
  String? _orderDocId;

  ServerRazorpayCheckout({required String businessName})
    : _businessName = businessName;

  FirebaseFunctions get _functions =>
      FirebaseFunctions.instanceFor(region: CloudFunctionNames.region);

  @override
  Future<CheckoutResult> pay(OrderDraft draft) async {
    // 1. Ask the server to create the Razorpay order.
    final Map<String, dynamic> created;
    try {
      final callable = _functions.httpsCallable(
        CloudFunctionNames.createRazorpayOrder,
      );
      final result = await callable.call<Map<String, dynamic>>(
        <String, dynamic>{},
      );
      created = Map<String, dynamic>.from(result.data as Map);
    } on FirebaseFunctionsException catch (e) {
      AppLogger.logError('createRazorpayOrder failed: ${e.code} ${e.message}');
      return CheckoutResult.fail(e.message ?? 'Could not start checkout');
    } catch (e, s) {
      AppLogger.logError('createRazorpayOrder error', error: e, stackTrace: s);
      return CheckoutResult.fail(e.toString());
    }

    final razorpayOrderId = created['razorpayOrderId'] as String?;
    final keyId = created['keyId'] as String?;
    final amountPaise = (created['amount'] as num?)?.toInt();
    final currency = created['currency'] as String? ?? 'INR';
    _orderDocId = created['orderDocId'] as String?;

    if (razorpayOrderId == null ||
        razorpayOrderId.isEmpty ||
        keyId == null ||
        keyId.isEmpty ||
        amountPaise == null) {
      return CheckoutResult.fail('Invalid checkout response');
    }

    // 2. Open the native Razorpay sheet bound to the server order.
    final completer = Completer<CheckoutResult>();
    _completer = completer;

    final razorpay = Razorpay();
    _razorpay = razorpay;
    razorpay.on(Razorpay.EVENT_PAYMENT_SUCCESS, _onSuccess);
    razorpay.on(Razorpay.EVENT_PAYMENT_ERROR, _onError);
    razorpay.on(Razorpay.EVENT_EXTERNAL_WALLET, _onExternalWallet);

    try {
      razorpay.open(<String, dynamic>{
        'key': keyId,
        'amount': amountPaise,
        'currency': currency,
        'order_id': razorpayOrderId,
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

  Future<void> _onSuccess(PaymentSuccessResponse response) async {
    // 3. Verify server-side; the function finalizes the order + purchases.
    try {
      final callable = _functions.httpsCallable(
        CloudFunctionNames.verifyRazorpayPayment,
      );
      final result = await callable
          .call<Map<String, dynamic>>(<String, dynamic>{
            'razorpay_order_id': response.orderId,
            'razorpay_payment_id': response.paymentId,
            'razorpay_signature': response.signature,
          });
      final data = Map<String, dynamic>.from(result.data as Map);
      if (data['success'] == true) {
        _settle(CheckoutResult.ok(orderId: _orderDocId));
      } else {
        _settle(CheckoutResult.fail('Payment verification failed'));
      }
    } on FirebaseFunctionsException catch (e) {
      AppLogger.logError(
        'verifyRazorpayPayment failed: ${e.code} ${e.message}',
      );
      _settle(CheckoutResult.fail(e.message ?? 'Verification failed'));
    } catch (e, s) {
      AppLogger.logError(
        'verifyRazorpayPayment error',
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
