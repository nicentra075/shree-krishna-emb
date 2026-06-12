/// Order lifecycle status. Transitions are performed ONLY by Cloud Functions:
/// `created → paid | failed`; `paid → refund_initiated → refunded`.
enum OrderStatus {
  created('created'),
  paid('paid'),
  failed('failed'),
  refundInitiated('refund_initiated'),
  refunded('refunded');

  final String value;
  const OrderStatus(this.value);

  /// Unknown values fall back to [created] (the initial state).
  static OrderStatus fromString(String? value) {
    return OrderStatus.values.firstWhere(
      (status) => status.value == value,
      orElse: () => OrderStatus.created,
    );
  }
}
