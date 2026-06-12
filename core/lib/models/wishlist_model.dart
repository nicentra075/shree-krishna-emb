import 'package:equatable/equatable.dart';

// Entity - Domain layer (array element inside the wishlists/{uid} doc)
class WishlistItemEntity extends Equatable {
  final String designId;
  final String title;
  final String? thumbUrl;

  /// Snapshot price in int paise (display only).
  final int price;
  final double avgRating;
  final DateTime addedAt;

  const WishlistItemEntity({
    required this.designId,
    required this.title,
    this.thumbUrl,
    required this.price,
    this.avgRating = 0,
    required this.addedAt,
  });

  @override
  List<Object?> get props =>
      [designId, title, thumbUrl, price, avgRating, addedAt];
}

// Model - Data layer
class WishlistItemModel extends WishlistItemEntity {
  const WishlistItemModel({
    required super.designId,
    required super.title,
    super.thumbUrl,
    required super.price,
    super.avgRating,
    required super.addedAt,
  });

  factory WishlistItemModel.fromFirebaseJson(Map<String, dynamic> json) {
    return WishlistItemModel(
      designId: json['designId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      avgRating: (json['avgRating'] as num?)?.toDouble() ?? 0,
      addedAt: json['addedAt'] != null
          ? DateTime.parse(json['addedAt'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'designId': designId,
      'title': title,
      'thumbUrl': thumbUrl,
      'price': price,
      'avgRating': avgRating,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory WishlistItemModel.fromApiJson(Map<String, dynamic> json) =>
      WishlistItemModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();

  factory WishlistItemModel.fromEntity(WishlistItemEntity entity) {
    return WishlistItemModel(
      designId: entity.designId,
      title: entity.title,
      thumbUrl: entity.thumbUrl,
      price: entity.price,
      avgRating: entity.avgRating,
      addedAt: entity.addedAt,
    );
  }
}

/// The whole `wishlists/{uid}` document (doc id = uid).
/// One read renders the wishlist screen AND powers heart state app-wide.
class WishlistEntity extends Equatable {
  /// Enforced client-side when adding items.
  static const int maxItems = 100;

  final List<WishlistItemEntity> items;
  final DateTime? updatedAt;

  const WishlistEntity({this.items = const [], this.updatedAt});

  bool get isEmpty => items.isEmpty;

  bool containsDesign(String designId) =>
      items.any((item) => item.designId == designId);

  @override
  List<Object?> get props => [items, updatedAt];
}

class WishlistModel extends WishlistEntity {
  const WishlistModel({super.items, super.updatedAt});

  factory WishlistModel.fromFirebaseJson(Map<String, dynamic> json) {
    return WishlistModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) => WishlistItemModel.fromFirebaseJson(
                  item as Map<String, dynamic>))
              .toList() ??
          const [],
      updatedAt: json['updatedAt'] != null
          ? DateTime.parse(json['updatedAt'] as String)
          : null,
    );
  }

  Map<String, dynamic> toFirebaseJson() {
    return {
      'items': items
          .map((item) => WishlistItemModel.fromEntity(item).toFirebaseJson())
          .toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory WishlistModel.fromApiJson(Map<String, dynamic> json) =>
      WishlistModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
