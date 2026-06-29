import 'package:shree_krishna_emb/data/datasources/firebase_order_writer.dart';
import 'package:shree_krishna_emb/data/services/mock_checkout.dart';
import 'package:shree_krishna_emb/data/services/razorpay_test_checkout.dart';
import 'package:shree_krishna_emb/data/services/server_razorpay_checkout.dart';
import 'package:shree_krishna_emb/domain/services/checkout_service.dart';

/// Selects the right [CheckoutService] at runtime from the platform config.
///
/// - live mode (`paymentTestMode == false`)              → [ServerRazorpayCheckout]
/// - test mode + a `rzp_test_` key configured            → [RazorpayTestCheckout]
/// - test mode + no/invalid (non-test) key               → [MockCheckout]
///
/// SAFETY: Razorpay decides real-vs-test purely from the key prefix, not our
/// flag. So in test mode we ONLY ever open the sheet with a `rzp_test_` key —
/// if a live (or unknown) key is configured we fall back to the mock, so test
/// mode can never charge real money.
///
/// The returned service owns native resources; callers must `dispose()` it.
class CheckoutServiceFactory {
  final FirebaseOrderWriter orderWriter;

  CheckoutServiceFactory({required this.orderWriter});

  CheckoutService create({
    required bool paymentTestMode,
    required String razorpayKeyId,
    required String businessName,
  }) {
    if (!paymentTestMode) {
      return ServerRazorpayCheckout(businessName: businessName);
    }
    final key = razorpayKeyId.trim();
    if (key.startsWith('rzp_test_')) {
      return RazorpayTestCheckout(
        orderWriter: orderWriter,
        keyId: key,
        businessName: businessName,
      );
    }
    // Test mode but the key isn't a test key → never open a live sheet.
    return MockCheckout(orderWriter: orderWriter);
  }
}
