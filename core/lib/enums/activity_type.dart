/// Admin activity-feed entry types (`activity` collection).
/// [unknown] absorbs forward-compatible types added by newer functions.
enum ActivityType {
  userSignup('user_signup'),
  orderPaid('order_paid'),
  designCreated('design_created'),
  designUpdated('design_updated'),
  categoryCreated('category_created'),
  refundInitiated('refund_initiated'),
  refundCompleted('refund_completed'),
  unknown('unknown');

  final String value;
  const ActivityType(this.value);

  static ActivityType fromString(String? value) {
    return ActivityType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => ActivityType.unknown,
    );
  }
}
