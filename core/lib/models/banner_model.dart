import 'package:equatable/equatable.dart';

/// What tapping a home banner navigates to.
enum BannerTargetType {
  design('design'),
  category('category'),
  none('none');

  final String value;
  const BannerTargetType(this.value);

  static BannerTargetType fromString(String? value) {
    return BannerTargetType.values.firstWhere(
      (type) => type.value == value,
      orElse: () => BannerTargetType.none,
    );
  }
}

// Entity - Domain layer (pure Dart, no Firebase/API dependencies)
class BannerEntity extends Equatable {
  final String id;
  final String imageUrl;
  final String title;
  final BannerTargetType targetType;
  final String? targetId;
  final int sortOrder;
  final bool isActive;

  const BannerEntity({
    required this.id,
    required this.imageUrl,
    this.title = '',
    this.targetType = BannerTargetType.none,
    this.targetId,
    this.sortOrder = 0,
    this.isActive = true,
  });

  @override
  List<Object?> get props =>
      [id, imageUrl, title, targetType, targetId, sortOrder, isActive];

  BannerEntity copyWith({
    String? id,
    String? imageUrl,
    String? title,
    BannerTargetType? targetType,
    String? targetId,
    int? sortOrder,
    bool? isActive,
  }) {
    return BannerEntity(
      id: id ?? this.id,
      imageUrl: imageUrl ?? this.imageUrl,
      title: title ?? this.title,
      targetType: targetType ?? this.targetType,
      targetId: targetId ?? this.targetId,
      sortOrder: sortOrder ?? this.sortOrder,
      isActive: isActive ?? this.isActive,
    );
  }
}

// Model - Data layer (banners are embedded maps inside config/homeFeed,
// so JSON here is a map element, not a document)
class BannerModel extends BannerEntity {
  const BannerModel({
    required super.id,
    required super.imageUrl,
    super.title,
    super.targetType,
    super.targetId,
    super.sortOrder,
    super.isActive,
  });

  // Convert from Firebase Firestore JSON (array element of config/homeFeed)
  factory BannerModel.fromFirebaseJson(Map<String, dynamic> json) {
    return BannerModel(
      id: json['id'] as String? ?? '',
      imageUrl: json['imageUrl'] as String? ?? '',
      title: json['title'] as String? ?? '',
      targetType: BannerTargetType.fromString(json['targetType'] as String?),
      targetId: json['targetId'] as String?,
      sortOrder: (json['sortOrder'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }

  // Convert to Firebase Firestore JSON
  Map<String, dynamic> toFirebaseJson() {
    return {
      'id': id,
      'imageUrl': imageUrl,
      'title': title,
      'targetType': targetType.value,
      'targetId': targetId,
      'sortOrder': sortOrder,
      'isActive': isActive,
    };
  }

  // Convert from REST API JSON (future migration)
  factory BannerModel.fromApiJson(Map<String, dynamic> json) =>
      BannerModel.fromFirebaseJson(json);

  // Convert to REST API JSON
  Map<String, dynamic> toApiJson() => toFirebaseJson();

  // Convert entity to model
  factory BannerModel.fromEntity(BannerEntity entity) {
    return BannerModel(
      id: entity.id,
      imageUrl: entity.imageUrl,
      title: entity.title,
      targetType: entity.targetType,
      targetId: entity.targetId,
      sortOrder: entity.sortOrder,
      isActive: entity.isActive,
    );
  }
}

/// The `config/homeFeed` document: the whole home banner slider in ONE doc
/// (one Firestore read per home-screen open).
class HomeFeedEntity extends Equatable {
  final List<BannerEntity> banners;
  final DateTime? updatedAt;
  final String? updatedBy;

  const HomeFeedEntity({this.banners = const [], this.updatedAt, this.updatedBy});

  /// Banners the user app should render, ordered.
  List<BannerEntity> get activeBanners {
    final active = banners.where((banner) => banner.isActive).toList()
      ..sort((a, b) => a.sortOrder.compareTo(b.sortOrder));
    return active;
  }

  @override
  List<Object?> get props => [banners, updatedAt, updatedBy];
}

class HomeFeedModel extends HomeFeedEntity {
  const HomeFeedModel({super.banners, super.updatedAt, super.updatedBy});

  // Convert from Firebase Firestore JSON (fixed doc config/homeFeed)
  factory HomeFeedModel.fromFirebaseJson(Map<String, dynamic> json) {
    return HomeFeedModel(
      banners: (json['banners'] as List<dynamic>?)
              ?.map((item) =>
                  BannerModel.fromFirebaseJson(item as Map<String, dynamic>))
              .toList() ??
          const [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
      updatedBy: json['updatedBy'] as String?,
    );
  }

  // Convert to Firebase Firestore JSON
  Map<String, dynamic> toFirebaseJson() {
    return {
      'banners': banners
          .map((banner) => BannerModel.fromEntity(banner).toFirebaseJson())
          .toList(),
      'updatedAt': updatedAt?.toIso8601String(),
      'updatedBy': updatedBy,
    };
  }

  // Convert from REST API JSON (future migration)
  factory HomeFeedModel.fromApiJson(Map<String, dynamic> json) =>
      HomeFeedModel.fromFirebaseJson(json);

  // Convert to REST API JSON
  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
