import 'package:equatable/equatable.dart';

import '../enums/design_status.dart';

// Entity - Domain layer (pure Dart, no Firebase/API dependencies)
class DesignEntity extends Equatable {
  final String id;
  final String title;
  final String titleLower;

  /// Search tokens built by `KeywordBuilder` — never hand-written.
  final List<String> keywords;
  final String description;
  final String categoryId;

  /// Denormalized; kept in sync by the `onCategoryWrite` Cloud Function.
  final String categoryName;

  /// Values from `DesignTechniques.all`.
  final List<String> techniques;
  final String threadType;
  final int estimatedTimeMinutes;

  /// Price in int paise (₹149.00 == 14900).
  final int price;
  final String currency;

  /// Watermarked 1200px public URL — written by `onDesignAssetUpload` fn.
  final String? previewUrl;

  /// 400px public URL — written by `onDesignAssetUpload` fn.
  final String? thumbUrl;
  final DesignProcessingStatus processingStatus;

  /// PRIVATE Storage path of the EMB/pattern source (never a URL).
  final String fileStoragePath;
  final String fileName;
  final String fileFormat;
  final int fileSizeBytes;
  final DesignStatus status;
  final bool isTrending;

  /// Aggregates maintained by Cloud Functions — never written by apps.
  final double avgRating;
  final int ratingCount;
  final int ratingSum;
  final int salesCount;
  final DateTime createdAt;
  final DateTime? updatedAt;
  final String createdBy;

  const DesignEntity({
    required this.id,
    required this.title,
    required this.titleLower,
    this.keywords = const [],
    this.description = '',
    required this.categoryId,
    required this.categoryName,
    this.techniques = const [],
    this.threadType = '',
    this.estimatedTimeMinutes = 0,
    required this.price,
    this.currency = 'INR',
    this.previewUrl,
    this.thumbUrl,
    this.processingStatus = DesignProcessingStatus.pending,
    this.fileStoragePath = '',
    this.fileName = '',
    this.fileFormat = '',
    this.fileSizeBytes = 0,
    this.status = DesignStatus.draft,
    this.isTrending = false,
    this.avgRating = 0,
    this.ratingCount = 0,
    this.ratingSum = 0,
    this.salesCount = 0,
    required this.createdAt,
    this.updatedAt,
    this.createdBy = '',
  });

  bool get isActive => status == DesignStatus.active;
  bool get isReady => processingStatus == DesignProcessingStatus.ready;

  @override
  List<Object?> get props => [
    id,
    title,
    titleLower,
    keywords,
    description,
    categoryId,
    categoryName,
    techniques,
    threadType,
    estimatedTimeMinutes,
    price,
    currency,
    previewUrl,
    thumbUrl,
    processingStatus,
    fileStoragePath,
    fileName,
    fileFormat,
    fileSizeBytes,
    status,
    isTrending,
    avgRating,
    ratingCount,
    ratingSum,
    salesCount,
    createdAt,
    updatedAt,
    createdBy,
  ];

  DesignEntity copyWith({
    String? id,
    String? title,
    String? titleLower,
    List<String>? keywords,
    String? description,
    String? categoryId,
    String? categoryName,
    List<String>? techniques,
    String? threadType,
    int? estimatedTimeMinutes,
    int? price,
    String? currency,
    String? previewUrl,
    String? thumbUrl,
    DesignProcessingStatus? processingStatus,
    String? fileStoragePath,
    String? fileName,
    String? fileFormat,
    int? fileSizeBytes,
    DesignStatus? status,
    bool? isTrending,
    double? avgRating,
    int? ratingCount,
    int? ratingSum,
    int? salesCount,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? createdBy,
  }) {
    return DesignEntity(
      id: id ?? this.id,
      title: title ?? this.title,
      titleLower: titleLower ?? this.titleLower,
      keywords: keywords ?? this.keywords,
      description: description ?? this.description,
      categoryId: categoryId ?? this.categoryId,
      categoryName: categoryName ?? this.categoryName,
      techniques: techniques ?? this.techniques,
      threadType: threadType ?? this.threadType,
      estimatedTimeMinutes: estimatedTimeMinutes ?? this.estimatedTimeMinutes,
      price: price ?? this.price,
      currency: currency ?? this.currency,
      previewUrl: previewUrl ?? this.previewUrl,
      thumbUrl: thumbUrl ?? this.thumbUrl,
      processingStatus: processingStatus ?? this.processingStatus,
      fileStoragePath: fileStoragePath ?? this.fileStoragePath,
      fileName: fileName ?? this.fileName,
      fileFormat: fileFormat ?? this.fileFormat,
      fileSizeBytes: fileSizeBytes ?? this.fileSizeBytes,
      status: status ?? this.status,
      isTrending: isTrending ?? this.isTrending,
      avgRating: avgRating ?? this.avgRating,
      ratingCount: ratingCount ?? this.ratingCount,
      ratingSum: ratingSum ?? this.ratingSum,
      salesCount: salesCount ?? this.salesCount,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      createdBy: createdBy ?? this.createdBy,
    );
  }
}

// Model - Data layer (can be converted from Firebase/API)
class DesignModel extends DesignEntity {
  const DesignModel({
    required super.id,
    required super.title,
    required super.titleLower,
    super.keywords,
    super.description,
    required super.categoryId,
    required super.categoryName,
    super.techniques,
    super.threadType,
    super.estimatedTimeMinutes,
    required super.price,
    super.currency,
    super.previewUrl,
    super.thumbUrl,
    super.processingStatus,
    super.fileStoragePath,
    super.fileName,
    super.fileFormat,
    super.fileSizeBytes,
    super.status,
    super.isTrending,
    super.avgRating,
    super.ratingCount,
    super.ratingSum,
    super.salesCount,
    required super.createdAt,
    super.updatedAt,
    super.createdBy,
  });

  // Convert from Firebase Firestore JSON
  factory DesignModel.fromFirebaseJson(Map<String, dynamic> json, String id) {
    return DesignModel(
      id: id,
      title: json['title'] as String? ?? '',
      titleLower: json['titleLower'] as String? ?? '',
      keywords:
          (json['keywords'] as List<dynamic>?)?.cast<String>() ?? const [],
      description: json['description'] as String? ?? '',
      categoryId: json['categoryId'] as String? ?? '',
      categoryName: json['categoryName'] as String? ?? '',
      techniques:
          (json['techniques'] as List<dynamic>?)?.cast<String>() ?? const [],
      threadType: json['threadType'] as String? ?? '',
      estimatedTimeMinutes:
          (json['estimatedTimeMinutes'] as num?)?.toInt() ?? 0,
      price: (json['price'] as num?)?.toInt() ?? 0,
      currency: json['currency'] as String? ?? 'INR',
      previewUrl: json['previewUrl'] as String?,
      thumbUrl: json['thumbUrl'] as String?,
      processingStatus:
          DesignProcessingStatus.fromString(json['processingStatus'] as String?),
      fileStoragePath: json['fileStoragePath'] as String? ?? '',
      fileName: json['fileName'] as String? ?? '',
      fileFormat: json['fileFormat'] as String? ?? '',
      fileSizeBytes: (json['fileSizeBytes'] as num?)?.toInt() ?? 0,
      status: DesignStatus.fromString(json['status'] as String?),
      isTrending: json['isTrending'] as bool? ?? false,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      ratingCount: (json['ratingCount'] as num?)?.toInt() ?? 0,
      ratingSum: (json['ratingSum'] as num?)?.toInt() ?? 0,
      salesCount: (json['salesCount'] as num?)?.toInt() ?? 0,
      createdAt: json['createdAt'] != null
          ? DateTime.parse(json['createdAt'] as String)
          : DateTime.now(),
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      createdBy: json['createdBy'] as String? ?? '',
    );
  }

  // Convert to Firebase Firestore JSON — full payload, valid for CREATE only.
  // NOTE: previewUrl/thumbUrl/processingStatus and the aggregate fields
  // (avgRating, ratingCount, ratingSum, salesCount) are function-maintained.
  // Datasources must use field-specific update maps on EDIT, never this map.
  Map<String, dynamic> toFirebaseJson() {
    return {
      'title': title,
      'titleLower': titleLower,
      'keywords': keywords,
      'description': description,
      'categoryId': categoryId,
      'categoryName': categoryName,
      'techniques': techniques,
      'threadType': threadType,
      'estimatedTimeMinutes': estimatedTimeMinutes,
      'price': price,
      'currency': currency,
      'previewUrl': previewUrl,
      'thumbUrl': thumbUrl,
      'processingStatus': processingStatus.value,
      'fileStoragePath': fileStoragePath,
      'fileName': fileName,
      'fileFormat': fileFormat,
      'fileSizeBytes': fileSizeBytes,
      'status': status.value,
      'isTrending': isTrending,
      'avgRating': avgRating,
      'ratingCount': ratingCount,
      'ratingSum': ratingSum,
      'salesCount': salesCount,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt?.toIso8601String(),
      'createdBy': createdBy,
    };
  }

  // Convert from REST API JSON (future migration)
  factory DesignModel.fromApiJson(Map<String, dynamic> json) {
    return DesignModel.fromFirebaseJson(json, json['id'] as String? ?? '');
  }

  // Convert to REST API JSON
  Map<String, dynamic> toApiJson() {
    return {'id': id, ...toFirebaseJson()};
  }

  // Convert entity to model
  factory DesignModel.fromEntity(DesignEntity entity) {
    return DesignModel(
      id: entity.id,
      title: entity.title,
      titleLower: entity.titleLower,
      keywords: entity.keywords,
      description: entity.description,
      categoryId: entity.categoryId,
      categoryName: entity.categoryName,
      techniques: entity.techniques,
      threadType: entity.threadType,
      estimatedTimeMinutes: entity.estimatedTimeMinutes,
      price: entity.price,
      currency: entity.currency,
      previewUrl: entity.previewUrl,
      thumbUrl: entity.thumbUrl,
      processingStatus: entity.processingStatus,
      fileStoragePath: entity.fileStoragePath,
      fileName: entity.fileName,
      fileFormat: entity.fileFormat,
      fileSizeBytes: entity.fileSizeBytes,
      status: entity.status,
      isTrending: entity.isTrending,
      avgRating: entity.avgRating,
      ratingCount: entity.ratingCount,
      ratingSum: entity.ratingSum,
      salesCount: entity.salesCount,
      createdAt: entity.createdAt,
      updatedAt: entity.updatedAt,
      createdBy: entity.createdBy,
    );
  }
}
