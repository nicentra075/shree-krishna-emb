import 'package:equatable/equatable.dart';

// Entity - Domain layer.
// `users/{uid}/purchases/{designId}` — doc id = designId. Written ONLY by
// the finalizeOrder Cloud Function; DELETED by initiateRefund (revokes the
// download). Existence of this doc == the user owns the design.
class PurchaseEntity extends Equatable {
  final String designId;
  final String orderId;
  final String title;
  final String? thumbUrl;
  final String fileFormat;

  /// Price paid in int paise.
  final int pricePaid;
  final DateTime purchasedAt;

  const PurchaseEntity({
    required this.designId,
    required this.orderId,
    required this.title,
    this.thumbUrl,
    this.fileFormat = '',
    required this.pricePaid,
    required this.purchasedAt,
  });

  @override
  List<Object?> get props =>
      [designId, orderId, title, thumbUrl, fileFormat, pricePaid, purchasedAt];
}

// Model - Data layer (read-only for apps)
class PurchaseModel extends PurchaseEntity {
  const PurchaseModel({
    required super.designId,
    required super.orderId,
    required super.title,
    super.thumbUrl,
    super.fileFormat,
    required super.pricePaid,
    required super.purchasedAt,
  });

  factory PurchaseModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return PurchaseModel(
      designId: id,
      orderId: json['orderId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String?,
      fileFormat: json['fileFormat'] as String? ?? '',
      pricePaid: (json['pricePaid'] as num?)?.toInt() ?? 0,
      purchasedAt: json['purchasedAt'] != null
          ? DateTime.parse(json['purchasedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'designId': designId,
      'orderId': orderId,
      'title': title,
      'thumbUrl': thumbUrl,
      'fileFormat': fileFormat,
      'pricePaid': pricePaid,
      'purchasedAt': purchasedAt.toIso8601String(),
    };
  }

  factory PurchaseModel.fromApiJson(Map<String, dynamic> json) =>
      PurchaseModel.fromFirebaseJson(json, json['designId'] as String? ?? '');

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
