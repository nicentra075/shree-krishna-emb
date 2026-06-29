import 'package:shree_krishna_emb/core/utils/app_logger.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_order_writer.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';
import 'package:shree_krishna_emb/domain/services/checkout_service.dart';

/// Demo checkout: simulates a successful payment after a short delay, then
/// writes the order + purchases + clears the cart client-side. Used in test
/// mode when no Razorpay test key is configured. No real money moves.
class MockCheckout implements CheckoutService {
  final FirebaseOrderWriter _orderWriter;

  MockCheckout({required FirebaseOrderWriter orderWriter})
    : _orderWriter = orderWriter;

  @override
  Future<CheckoutResult> pay(OrderDraft draft) async {
    try {
      // Simulate the payment-sheet round trip.
      await Future<void>.delayed(const Duration(milliseconds: 900));
      final orderId = await _orderWriter.writePaidOrder(draft);
      return CheckoutResult.ok(orderId: orderId);
    } catch (e, s) {
      AppLogger.logError('Mock checkout failed', error: e, stackTrace: s);
      return CheckoutResult.fail(e.toString());
    }
  }

  @override
  void dispose() {}
}
