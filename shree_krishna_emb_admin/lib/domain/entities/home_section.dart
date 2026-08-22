import 'package:equatable/equatable.dart';

/// Render types for a home section. String values are what is stored in
/// `config/homeFeed` and parsed by the user app's SectionRenderer.
enum HomeSectionType {
  banner,
  authorisedSellersHorizontal,
  designsHorizontal,
  designsVertical,
  collectionsGrid,
  categoriesHorizontal,
  recentlyViewed;

  String get value => switch (this) {
    HomeSectionType.banner => 'banner',
    HomeSectionType.authorisedSellersHorizontal =>
      'authorisedSellersHorizontal',
    HomeSectionType.designsHorizontal => 'designsHorizontal',
    HomeSectionType.designsVertical => 'designsVertical',
    HomeSectionType.collectionsGrid => 'collectionsGrid',
    HomeSectionType.categoriesHorizontal => 'categoriesHorizontal',
    HomeSectionType.recentlyViewed => 'recentlyViewed',
  };

  static HomeSectionType? fromValue(String? v) {
    for (final t in HomeSectionType.values) {
      if (t.value == v) return t;
    }
    return null;
  }
}

/// Source kinds — how a section's items are resolved.
enum HomeSourceKind {
  manual,
  query,
  collection,
  category,
  authorisedSellers,
  recentlyViewed;

  String get value => name;

  static HomeSourceKind fromValue(String? v) => HomeSourceKind.values
      .firstWhere((k) => k.value == v, orElse: () => HomeSourceKind.query);
}

/// A banner entry (used by `manual` banner sections).
class BannerItemConfig extends Equatable {
  final String imageUrl;
  final String? label;
  final String? title;
  final String? ctaTarget;

  const BannerItemConfig({
    required this.imageUrl,
    this.label,
    this.title,
    this.ctaTarget,
  });

  BannerItemConfig copyWith({
    String? imageUrl,
    String? label,
    String? title,
    String? ctaTarget,
  }) => BannerItemConfig(
    imageUrl: imageUrl ?? this.imageUrl,
    label: label ?? this.label,
    title: title ?? this.title,
    ctaTarget: ctaTarget ?? this.ctaTarget,
  );

  @override
  List<Object?> get props => [imageUrl, label, title, ctaTarget];
}

/// Data binding for a section.
class HomeSourceConfig extends Equatable {
  final HomeSourceKind kind;
  final List<BannerItemConfig> items; // manual banners
  final String? collectionId;
  final String? categoryId;
  final String sort; // popularity | newest | priceAsc | priceDesc
  final bool onlyActive;
  final int limit;

  /// When true, the section shows exactly [manualIds] (in this order) instead
  /// of auto-resolving all active items. Applies to collections / categories /
  /// designs sections. Default false = auto (all active, sorted, limited).
  final bool manual;

  /// Hand-picked item ids (collection / category / design ids) shown when
  /// [manual] is true, in display order.
  final List<String> manualIds;

  const HomeSourceConfig({
    this.kind = HomeSourceKind.query,
    this.items = const [],
    this.collectionId,
    this.categoryId,
    this.sort = 'newest',
    this.onlyActive = true,
    this.limit = 10,
    this.manual = false,
    this.manualIds = const [],
  });

  HomeSourceConfig copyWith({
    HomeSourceKind? kind,
    List<BannerItemConfig>? items,
    String? collectionId,
    String? categoryId,
    String? sort,
    bool? onlyActive,
    int? limit,
    bool? manual,
    List<String>? manualIds,
  }) => HomeSourceConfig(
    kind: kind ?? this.kind,
    items: items ?? this.items,
    collectionId: collectionId ?? this.collectionId,
    categoryId: categoryId ?? this.categoryId,
    sort: sort ?? this.sort,
    onlyActive: onlyActive ?? this.onlyActive,
    limit: limit ?? this.limit,
    manual: manual ?? this.manual,
    manualIds: manualIds ?? this.manualIds,
  );

  @override
  List<Object?> get props => [
    kind,
    items,
    collectionId,
    categoryId,
    sort,
    onlyActive,
    limit,
    manual,
    manualIds,
  ];
}

/// "View All" config for a section.
class HomeViewAll extends Equatable {
  final bool enabled;
  final String? target;

  const HomeViewAll({this.enabled = false, this.target});

  HomeViewAll copyWith({bool? enabled, String? target}) => HomeViewAll(
    enabled: enabled ?? this.enabled,
    target: target ?? this.target,
  );

  @override
  List<Object?> get props => [enabled, target];
}

/// A configured home section.
class HomeSectionConfig extends Equatable {
  final String id;
  final HomeSectionType type;
  final String? title;
  final String? subtitle;
  final bool enabled;
  final int position;
  final HomeViewAll viewAll;
  final HomeSourceConfig source;

  const HomeSectionConfig({
    required this.id,
    required this.type,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.position = 0,
    this.viewAll = const HomeViewAll(),
    this.source = const HomeSourceConfig(),
  });

  HomeSectionConfig copyWith({
    String? title,
    String? subtitle,
    bool? enabled,
    int? position,
    HomeViewAll? viewAll,
    HomeSourceConfig? source,
  }) => HomeSectionConfig(
    id: id,
    type: type,
    title: title ?? this.title,
    subtitle: subtitle ?? this.subtitle,
    enabled: enabled ?? this.enabled,
    position: position ?? this.position,
    viewAll: viewAll ?? this.viewAll,
    source: source ?? this.source,
  );

  @override
  List<Object?> get props => [
    id,
    type,
    title,
    subtitle,
    enabled,
    position,
    viewAll,
    source,
  ];
}
