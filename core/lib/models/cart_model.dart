import 'package:equatable/equatable.dart';

// Entity - Domain layer. Digital goods → no quantity field.
// Item fields are display snapshots; checkout NEVER trusts these prices —
// the createRazorpayOrder function re-reads designs server-side.
class CartItemEntity extends Equatable {
  final String designId;
  final String title;
  final String? thumbUrl;

  /// Snapshot price in int paise (display only).
  final int price;
  final String categoryName;
  final DateTime addedAt;

  const CartItemEntity({
    required this.designId,
    required this.title,
    this.thumbUrl,
    required this.price,
    this.categoryName = '',
    required this.addedAt,
  });

  @override
  List<Object?> get props =>
      [designId, title, thumbUrl, price, categoryName, addedAt];
}

// Model - Data layer (array element inside the carts/{uid} doc)
class CartItemModel extends CartItemEntity {
  const CartItemModel({
    required super.designId,
    required super.title,
    super.thumbUrl,
    required super.price,
    super.categoryName,
    required super.addedAt,
  });

  factory CartItemModel.fromFirebaseJson(Map<String, dynamic> json) {
    return CartItemModel(
      designId: json['designId'] as String? ?? '',
      title: json['title'] as String? ?? '',
      thumbUrl: json['thumbUrl'] as String?,
      price: (json['price'] as num?)?.toInt() ?? 0,
      categoryName: json['categoryName'] as String? ?? '',
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
      'categoryName': categoryName,
      'addedAt': addedAt.toIso8601String(),
    };
  }

  factory CartItemModel.fromApiJson(Map<String, dynamic> json) =>
      CartItemModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();

  factory CartItemModel.fromEntity(CartItemEntity entity) {
    return CartItemModel(
      designId: entity.designId,
      title: entity.title,
      thumbUrl: entity.thumbUrl,
      price: entity.price,
      categoryName: entity.categoryName,
      addedAt: entity.addedAt,
    );
  }
}

/// The whole `carts/{uid}` document (doc id = uid, so no id field).
/// Cleared server-side by the finalizeOrder function after payment.
class CartEntity extends Equatable {
  /// Enforced client-side when adding items.
  static const int maxItems = 50;

  final List<CartItemEntity> items;
  final DateTime? updatedAt;

  const CartEntity({this.items = const [], this.updatedAt});

  bool get isEmpty => items.isEmpty;

  /// Sum of snapshot prices in paise (display only — server is authoritative).
  int get itemsSubtotal => items.fold(0, (sum, item) => sum + item.price);

  bool containsDesign(String designId) =>
      items.any((item) => item.designId == designId);

  @override
  List<Object?> get props => [items, updatedAt];
}

class CartModel extends CartEntity {
  const CartModel({super.items, super.updatedAt});

  factory CartModel.fromFirebaseJson(Map<String, dynamic> json) {
    return CartModel(
      items: (json['items'] as List<dynamic>?)
              ?.map((item) =>
                  CartItemModel.fromFirebaseJson(item as Map<String, dynamic>))
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
          .map((item) => CartItemModel.fromEntity(item).toFirebaseJson())
          .toList(),
      'updatedAt': updatedAt?.toIso8601String(),
    };
  }

  factory CartModel.fromApiJson(Map<String, dynamic> json) =>
      CartModel.fromFirebaseJson(json);

  Map<String, dynamic> toApiJson() => toFirebaseJson();
}
