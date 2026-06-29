import 'package:equatable/equatable.dart';

/// How a home section is rendered. String values match the admin's
/// `config/homeFeed` section types.
enum HomeSectionType {
  banner,
  authorisedSellersHorizontal,
  designsHorizontal,
  designsVertical,
  collectionsGrid,
  categoriesHorizontal,
  recentlyViewed;

  static HomeSectionType? fromValue(String? v) {
    for (final t in HomeSectionType.values) {
      if (t.name == v) return t;
    }
    return null;
  }
}

/// Polymorphic item rendered inside a section.
sealed class HomeItem extends Equatable {
  const HomeItem();
}

class BannerItem extends HomeItem {
  final String imageUrl;
  final String? label;
  final String? title;
  final String? ctaTarget;
  const BannerItem(
      {required this.imageUrl, this.label, this.title, this.ctaTarget});
  @override
  List<Object?> get props => [imageUrl, label, title, ctaTarget];
}

class SellerItem extends HomeItem {
  final String uid;
  final String displayName;
  final String? storeImageUrl;
  const SellerItem(
      {required this.uid, required this.displayName, this.storeImageUrl});
  @override
  List<Object?> get props => [uid, displayName, storeImageUrl];
}

class DesignItem extends HomeItem {
  final String id;
  final String name;
  final int finalPrice;
  final bool isFree;
  final String? firstImageUrl;
  final String? description;
  const DesignItem({
    required this.id,
    required this.name,
    required this.finalPrice,
    required this.isFree,
    this.firstImageUrl,
    this.description,
  });
  @override
  List<Object?> get props =>
      [id, name, finalPrice, isFree, firstImageUrl, description];
}

class CollectionItem extends HomeItem {
  final String id;
  final String name;
  final String? imageUrl;
  const CollectionItem({required this.id, required this.name, this.imageUrl});
  @override
  List<Object?> get props => [id, name, imageUrl];
}

class CategoryItem extends HomeItem {
  final String id;
  final String name;
  final String? imageUrl;
  const CategoryItem({required this.id, required this.name, this.imageUrl});
  @override
  List<Object?> get props => [id, name, imageUrl];
}

class HomeViewAll extends Equatable {
  final bool enabled;
  final String? target;
  const HomeViewAll({this.enabled = false, this.target});
  @override
  List<Object?> get props => [enabled, target];
}

class HomeSection extends Equatable {
  final String id;
  final HomeSectionType type;
  final String? title;
  final String? subtitle;
  final HomeViewAll viewAll;
  final List<HomeItem> items;

  /// The collection this section is bound to (if any) — lets a category row's
  /// "View All" default to that collection's categories.
  final String? sourceCollectionId;

  const HomeSection({
    required this.id,
    required this.type,
    required this.items,
    this.title,
    this.subtitle,
    this.viewAll = const HomeViewAll(),
    this.sourceCollectionId,
  });
  @override
  List<Object?> get props =>
      [id, type, title, subtitle, viewAll, items, sourceCollectionId];
}

class HomeFeed extends Equatable {
  final int version;
  final List<HomeSection> sections;
  const HomeFeed({this.version = 0, this.sections = const []});
  @override
  List<Object?> get props => [version, sections];
}
