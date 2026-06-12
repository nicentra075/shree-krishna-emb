import 'package:equatable/equatable.dart';

// Entity - Domain layer.
// The `config/platform` document (fixed doc id). Read by both apps
// (Hive-cached 6h); written by admin. Percentages here are display defaults —
// the createRazorpayOrder function re-reads them server-side and freezes a
// snapshot on each order.
class PlatformSettingsEntity extends Equatable {
  final double platformFeePercent;
  final double gstPercent;

  /// Razorpay PUBLISHABLE key id (test/live) — safe on clients,
  /// rotatable without an app release.
  final String razorpayKeyId;
  final String supportEmail;
  final String invoicePrefix;
  final String sellerName;
  final String sellerAddress;
  final String sellerGstin;
  final DateTime? updatedAt;
  final String? updatedBy;

  const PlatformSettingsEntity({
    this.platformFeePercent = 0,
    this.gstPercent = 0,
    this.razorpayKeyId = '',
    this.supportEmail = '',
    this.invoicePrefix = 'SKE',
    this.sellerName = '',
    this.sellerAddress = '',
    this.sellerGstin = '',
    this.updatedAt,
    this.updatedBy,
  });

  @override
  List<Object?> get props => [
    platformFeePercent,
    gstPercent,
    razorpayKeyId,
    supportEmail,
    invoicePrefix,
    sellerName,
    sellerAddress,
    sellerGstin,
    updatedAt,
    updatedBy,
  ];

  PlatformSettingsEntity copyWith({
    double? platformFeePercent,
    double? gstPercent,
    String? razorpayKeyId,
    String? supportEmail,
    String? invoicePrefix,
    String? sellerName,
    String? sellerAddress,
    String? sellerGstin,
    DateTime? updatedAt,
    String? updatedBy,
  }) {
    return PlatformSettingsEntity(
      platformFeePercent: platformFeePercent ?? this.platformFeePercent,
      gstPercent: gstPercent ?? this.gstPercent,
      razorpayKeyId: razorpayKeyId ?? this.razorpayKeyId,
      supportEmail: supportEmail ?? this.supportEmail,
      invoicePrefix: invoicePrefix ?? this.invoicePrefix,
      sellerName: sellerName ?? this.sellerName,
      sellerAddress: sellerAddress ?? this.sellerAddress,
      sellerGstin: sellerGstin ?? this.sellerGstin,
      updatedAt: updatedAt ?? this.updatedAt,
      updatedBy: updatedBy ?? this.updatedBy,
    );
  }
}

// Model - Data layer
class PlatformSettingsModel extends PlatformSettingsEntity {
  const PlatformSettingsModel({
    super.platformFeePercent,
    super.gstPercent,
    super.razorpayKeyId,
    super.supportEmail,
    super.invoicePrefix,
    super.sellerName,
    super.sellerAddress,
    super.sellerGstin,
    super.updatedAt,
    super.updatedBy,
  });

  factory PlatformSettingsModel.fromFirebaseJson(Map<String, dynamic> json) {
    return PlatformSettingsModel(
      platformFeePercent: (json['platformFeePercent'] as num?)?.toDouble() ?? 0,
      gstPercent: (json['gstPercent'] as num?)?.toDouble() ?? 0,
      razorpayKeyId: json['razorpayKeyId'] as String? ?? '',
      supportEmail: json['supportEmail'] as String? ?? '',
      invoicePrefix: json['invoicePrefix'] as String? ?? 'SKE',
      sellerName: json['sellerName'] as String? ?? '',
      sellerAddress: json['sellerAddress'] as String? ?? '',
      sellerGstin: json['sellerGstin'] as String? ?? '',
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'platformFeePercent': platformFeePercent,
      'gstPercent': gstPercent,
      'razorpayKeyId': razorpayKeyId,
      'supportEmail': supportEmail,
      'invoicePrefix': invoicePrefix,
      'sellerName': sellerName,
      'sellerAddress': sellerAddress,
      'sellerGstin': sellerGstin,
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  factory PlatformSettingsModel.fromApiJson(Map<String, dynamic> json) =>
      PlatformSettingsModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();

  factory PlatformSettingsModel.fromEntity(PlatformSettingsEntity entity) {
    return PlatformSettingsModel(
      platformFeePercent: entity.platformFeePercent,
      gstPercent: entity.gstPercent,
      razorpayKeyId: entity.razorpayKeyId,
      supportEmail: entity.supportEmail,
      invoicePrefix: entity.invoicePrefix,
      sellerName: entity.sellerName,
      sellerAddress: entity.sellerAddress,
      sellerGstin: entity.sellerGstin,
      updatedAt: entity.updatedAt,
      updatedBy: entity.updatedBy,
    );
  }
}
