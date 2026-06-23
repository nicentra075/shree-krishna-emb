import 'package:equatable/equatable.dart';

/// A design product. `finalPrice` is computed on write
/// (`isFree ? 0 : price - discountAmount`). `authorId` is 'platform' for admin
/// uploads; a designer uid in a future phase.
class DesignEntity extends Equatable {
  final String id;
  final String name;
  final String? code;
  final List<String> images;
  final String authorId;
  final String? authorName;
  final String? description;
  final int price;
  final int discountAmount;
  final bool isFree;
  final int finalPrice;
  final String? colorOrNeedleCount;
  final String? designFormat;
  final int stitchCount;
  final int height;
  final int width;
  final String? collectionId;
  final String? categoryId;
  final String status; // active | pending | rejected | inactive
  final int popularity;
  final DateTime createdAt;

  const DesignEntity({
    required this.id,
    required this.name,
    required this.createdAt,
    this.code,
    this.images = const [],
    this.authorId = 'platform',
    this.authorName,
    this.description,
    this.price = 0,
    this.discountAmount = 0,
    this.isFree = false,
    this.finalPrice = 0,
    this.colorOrNeedleCount,
    this.designFormat,
    this.stitchCount = 0,
    this.height = 0,
    this.width = 0,
    this.collectionId,
    this.categoryId,
    this.status = 'active',
    this.popularity = 0,
  });

  /// Computes the final price from price/discount/isFree.
  static int computeFinalPrice({
    required bool isFree,
    required int price,
    required int discountAmount,
  }) {
    if (isFree) return 0;
    final result = price - discountAmount;
    return result < 0 ? 0 : result;
  }

  String? get firstImageUrl => images.isNotEmpty ? images.first : null;

  @override
  List<Object?> get props => [
        id,
        name,
        code,
        images,
        authorId,
        authorName,
        description,
        price,
        discountAmount,
        isFree,
        finalPrice,
        colorOrNeedleCount,
        designFormat,
        stitchCount,
        height,
        width,
        collectionId,
        categoryId,
        status,
        popularity,
        createdAt,
      ];
}
