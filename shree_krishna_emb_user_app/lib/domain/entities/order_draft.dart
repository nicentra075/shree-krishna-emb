import 'package:equatable/equatable.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';

/// A pre-payment order computed client-side for display + the test/demo write
/// path. ALL amounts are integer rupees. The live server path recomputes these
/// authoritatively; this draft is the display/test source.
class OrderDraft extends Equatable {
  final List<CartItemEntity> items;
  final String buyerName;
  final String buyerEmail;
  final String buyerPhone;

  /// Integer rupees.
  final int subtotal;
  final int platformFee;
  final int gst;
  final int total;

  final double platformFeePercent;
  final double gstPercent;

  const OrderDraft({
    required this.items,
    this.buyerName = '',
    this.buyerEmail = '',
    this.buyerPhone = '',
    required this.subtotal,
    required this.platformFee,
    required this.gst,
    required this.total,
    required this.platformFeePercent,
    required this.gstPercent,
  });

  bool get isFree => total <= 0;

  /// Razorpay `prefill` map built from the known buyer details, so the checkout
  /// sheet (and UPI flow) doesn't prompt for email/phone again. Empty entries
  /// are omitted.
  Map<String, dynamic> get razorpayPrefill => <String, dynamic>{
    if (buyerEmail.isNotEmpty) 'email': buyerEmail,
    if (buyerPhone.isNotEmpty) 'contact': buyerPhone,
  };

  /// Builds a draft from cart items and the platform fee/gst percentages.
  /// Mirrors the server fee formula (round each step) but in integer rupees.
  factory OrderDraft.fromCart({
    required List<CartItemEntity> items,
    required double platformFeePercent,
    required double gstPercent,
    String buyerName = '',
    String buyerEmail = '',
    String buyerPhone = '',
  }) {
    final subtotal = items.fold<int>(0, (sum, i) => sum + i.price);
    final platformFee = (subtotal * platformFeePercent / 100).round();
    final gst = ((subtotal + platformFee) * gstPercent / 100).round();
    final total = subtotal + platformFee + gst;
    return OrderDraft(
      items: items,
      buyerName: buyerName,
      buyerEmail: buyerEmail,
      buyerPhone: buyerPhone,
      subtotal: subtotal,
      platformFee: platformFee,
      gst: gst,
      total: total,
      platformFeePercent: platformFeePercent,
      gstPercent: gstPercent,
    );
  }

  OrderDraft copyWith({
    String? buyerName,
    String? buyerEmail,
    String? buyerPhone,
  }) => OrderDraft(
    items: items,
    buyerName: buyerName ?? this.buyerName,
    buyerEmail: buyerEmail ?? this.buyerEmail,
    buyerPhone: buyerPhone ?? this.buyerPhone,
    subtotal: subtotal,
    platformFee: platformFee,
    gst: gst,
    total: total,
    platformFeePercent: platformFeePercent,
    gstPercent: gstPercent,
  );

  @override
  List<Object?> get props => [
    items,
    buyerName,
    buyerEmail,
    buyerPhone,
    subtotal,
    platformFee,
    gst,
    total,
    platformFeePercent,
    gstPercent,
  ];
}
