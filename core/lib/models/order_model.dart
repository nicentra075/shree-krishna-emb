import 'package:equatable/equatable.dart';

import '../enums/order_status.dart';

// Order line item — server-side snapshot written by createRazorpayOrder fn.
class OrderItemEntity extends Equatable {
  final String designId;
  final String title;
  final String? thumbUrl;

  /// Authoritative price in int paise (frozen at order creation).
  final int price;
  final String fileFormat;
  final String categoryId;
  final String categoryName;

  const OrderItemEntity({
    required this.designId,
    required this.title,
    this.thumbUrl,
    required this.price,
    this.fileFormat = '',
    this.categoryId = '',
    this.categoryName = '',
  });

  @override
  List<Object?> get props =>
      [designId, title, thumbUrl, price, fileFormat, categoryId, categoryName];
}

class OrderItemModel extends OrderItemEntity {
  const OrderItemModel({
    required super.designId,
    required super.title,
    super.thumbUrl,
    required super.price,
    super.fileFormat,
    super.categoryId,
    super.categoryName,
  });

  factory OrderItemModel.fromFirebaseJson(Map<String, dynamic> json) {
    return OrderItemModel(
      designId: json['designId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      fileFormat: json['fileFormat'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'designId': designId,
      'title': title,
      'thumbUrl': thumbUrl,
      'price': price,
      'fileFormat': fileFormat,
      'categoryId': categoryId,
      'categoryName': categoryName,
    };
  }

  factory OrderItemModel.fromApiJson(Map<String, dynamic> json) =>
      OrderItemModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}

// Refund details set by the initiateRefund fn / razorpayWebhook.
class OrderRefundEntity extends Equatable {
  final String refundId;

  /// Refunded amount in int paise.
  final int amount;
  final String reason;
  final String initiatedBy;
  final DateTime? initiatedAt;
  final String status;

  const OrderRefundEntity({
    required this.refundId,
    required this.amount,
    this.reason = '',
    this.initiatedBy = '',
    this.initiatedAt,
    this.status = '',
  });

  @override
  List<Object?> get props =>
      [refundId, amount, reason, initiatedBy, initiatedAt, status];
}

class OrderRefundModel extends OrderRefundEntity {
  const OrderRefundModel({
    required super.refundId,
    required super.amount,
    super.reason,
    super.initiatedBy,
    super.initiatedAt,
    super.status,
  });

  factory OrderRefundModel.fromFirebaseJson(Map<String, dynamic> json) {
    return OrderRefundModel(
      refundId: json['refundId'] as String? ?? '',
      amount: (json['amount'] as num?)?.toInt() ?? 0,
      reason: json['reason'] as String? ?? '',
      initiatedBy: json['initiatedBy'] as String? ?? '',
      initiatedAt: json['initiatedAt'] != null
          ? DateTime.parse(json['initiatedAt'] as String)
          : null,
      status: json['status'] as String? ?? '',
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'refundId': refundId,
      'amount': amount,
      'reason': reason,
      'initiatedBy': initiatedBy,
      'initiatedAt': initiatedAt?.toIso8601String(),
      'status': status,
    };
  }
}

// Entity - Domain layer.
// Doc id IS the Razorpay order id (order_xxx). Orders are written ONLY by
// Cloud Functions — both apps treat this model as read-only.
class OrderEntity extends Equatable {
  final String id;
  final String userId;
  final String buyerName;
  final String buyerEmail;
  final List<OrderItemEntity> items;

  /// All amounts in int paise, computed server-side (authoritative).
  final int itemsSubtotal;
  final int platformFee;
  final int gstAmount;
  final int totalAmount;

  /// Percentages frozen at order time.
  final double platformFeePercent;
  final double gstPercent;
  final String currency;
  final OrderStatus status;
  final String? razorpayPaymentId;

  /// e.g. `SKE-2026-00042`, minted on payment.
  final String? invoiceNumber;
  final OrderRefundEntity? refund;
  final DateTime createdAt;
  final DateTime? paidAt;
  final DateTime? refundedAt;

  const OrderEntity({
    required this.id,
    required this.userId,
    this.buyerName = '',
    this.buyerEmail = '',
    this.items = const [],
    required this.itemsSubtotal,
    required this.platformFee,
    required this.gstAmount,
    required this.totalAmount,
    this.platformFeePercent = 0,
    this.gstPercent = 0,
    this.currency = 'INR',
    this.status = OrderStatus.created,
    this.razorpayPaymentId,
    this.invoiceNumber,
    this.refund,
    required this.createdAt,
    this.paidAt,
    this.refundedAt,
  });

  bool get isPaid => status == OrderStatus.paid;

  @override
  List<Object?> get props => [
    id,
    userId,
    buyerName,
    buyerEmail,
    items,
    itemsSubtotal,
    platformFee,
    gstAmount,
    totalAmount,
    platformFeePercent,
    gstPercent,
    currency,
    status,
    razorpayPaymentId,
    invoiceNumber,
    refund,
    createdAt,
    paidAt,
    refundedAt,
  ];
}

// Model - Data layer
class OrderModel extends OrderEntity {
  const OrderModel({
    required super.id,
    required super.userId,
    super.buyerName,
    super.buyerEmail,
    super.items,
    required super.itemsSubtotal,
    required super.platformFee,
    required super.gstAmount,
    required super.totalAmount,
    super.platformFeePercent,
    super.gstPercent,
    super.currency,
    super.status,
    super.razorpayPaymentId,
    super.invoiceNumber,
    super.refund,
    required super.createdAt,
    super.paidAt,
    super.refundedAt,
  });

  factory OrderModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return OrderModel(
      id: id,
      userId: json['userId'] as String? ?? '',
      buyerName: json['buyerName'] as String? ?? '',
      buyerEmail: json['buyerEmail'] as String? ?? '',
      items: (json['items'] as List<dynamic>?)
              ?.map((item) =>
                  OrderItemModel.fromFirebaseJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      itemsSubtotal: (json['itemsSubtotal'] as num?)?.toInt() ?? 0,
      platformFee: (json['platformFee'] as num?)?.toInt() ?? 0,
      gstAmount: (json['gstAmount'] as num?)?.toInt() ?? 0,
      totalAmount: (json['totalAmount'] as num?)?.toInt() ?? 0,
      platformFeePercent: (json['platformFeePercent'] as num?)?.toDouble() ?? 0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      status: OrderStatus.fromString(json['status'] as String?),
      razorpayPaymentId: json['razorpayPaymentId'] as String?,
      invoiceNumber: json['invoiceNumber'] as String?,
      refund: json['refund'] != null
          ? OrderRefundModel.fromFirebaseJson(
              json['refund'] as Map<String, dynamic>)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      paidAt: json['paidAt'] != null
          ? DateTime.parse(json['paidAt'] as String)
          : null,
      refundedAt: json['refundedAt'] != null
          ? DateTime.parse(json['refundedAt'] as String)
          : null,
    );
  }

  // Serialization provided for caching/API parity; apps never write orders
  // to Firestore (security rules deny it — Cloud Functions only).
  Map<String, dynamic> toFirebaseJson() {
    return {
      'userId': userId,
      'buyerName': buyerName,
      'buyerEmail': buyerEmail,
      'items': items
          .map((item) =>
              OrderItemModel(
                designId: item.designId,
                title: item.title,
                thumbUrl: item.thumbUrl,
                price: item.price,
                fileFormat: item.fileFormat,
                categoryId: item.categoryId,
                categoryName: item.categoryName,
              ).toFirebaseJson())
          .toList(),
      'itemsSubtotal': itemsSubtotal,
      'platformFee': platformFee,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'platformFeePercent': platformFeePercent,
      'gstPercent': gstPercent,
      'currency': currency,
      'status': status.value,
      'razorpayPaymentId': razorpayPaymentId,
      'invoiceNumber': invoiceNumber,
      'refund': refund != null
          ? OrderRefundModel(
              refundId: refund!.refundId,
              amount: refund!.amount,
              reason: refund!.reason,
              initiatedBy: refund!.initiatedBy,
              initiatedAt: refund!.initiatedAt,
              status: refund!.status,
            ).toFirebaseJson()
          : null,
      'createdAt': createdAt.toIso8601String(),
      'paidAt': paidAt?.toIso8601String(),
      'refundedAt': refundedAt?.toIso8601String(),
    };
  }

  factory OrderModel.fromApiJson(Map<String, dynamic> json) =>
      OrderModel.fromFirebaseJson(json, json['id'] as String? ?? '');

  Map<String, dynamic> toApiJson() => {'id': id, ...toFirebaseJson()};
}
