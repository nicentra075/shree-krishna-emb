import 'package:equatable/equatable.dart';
import 'package:intl/intl.dart';

/// Order amount breakdown. ALL values are int paise (INR minor units).
class OrderAmounts extends Equatable {
  final int itemsSubtotal;
  final int platformFee;
  final int gstAmount;
  final int totalAmount;

  const OrderAmounts({
    required this.itemsSubtotal,
    required this.platformFee,
    required this.gstAmount,
    required this.totalAmount,
  });

  @override
  List<Object?> get props => [itemsSubtotal, platformFee, gstAmount, totalAmount];
}

/// Money helpers. Convention: money is ALWAYS int paise (₹149.00 == 14900).
class Money {
  Money._();

  static final NumberFormat _inr = NumberFormat.currency(
    locale: 'en_IN',
    symbol: '₹',
    decimalDigits: 2,
  );

  /// Formats paise as Indian Rupees with lakh grouping: 149000 → ₹1,490.00.
  static String formatPaise(int paise) => _inr.format(paise / 100);

  /// THE fee formula — single source of truth, mirrored byte-for-byte in
  /// `functions/src/utils/money.ts`. The golden values in
  /// `core/test/money_test.dart` and `functions/test/amounts.test.ts` must
  /// stay identical. Server-computed amounts are always authoritative.
  ///
  ///   platformFee = round(subtotal * feePct / 100)
  ///   gst         = round((subtotal + platformFee) * gstPct / 100)
  ///   total       = subtotal + platformFee + gst
  static OrderAmounts computeOrderAmounts({
    required int itemsSubtotal,
    required double platformFeePercent,
    required double gstPercent,
  }) {
    final platformFee = (itemsSubtotal * platformFeePercent / 100).round();
    final gstAmount = ((itemsSubtotal + platformFee) * gstPercent / 100).round();
    return OrderAmounts(
      itemsSubtotal: itemsSubtotal,
      platformFee: platformFee,
      gstAmount: gstAmount,
      totalAmount: itemsSubtotal + platformFee + gstAmount,
    );
  }
}
