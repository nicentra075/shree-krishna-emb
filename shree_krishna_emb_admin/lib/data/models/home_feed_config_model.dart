import 'package:shree_krishna_emb_admin/data/models/catalog_parse.dart';
import 'package:shree_krishna_emb_admin/domain/entities/home_section.dart';

/// The full home layout document (`config/homeFeed`).
class HomeFeedConfig {
  final int version;
  final DateTime? updatedAt;
  final List<HomeSectionConfig> sections;

  const HomeFeedConfig({
    this.version = 1,
    this.updatedAt,
    this.sections = const [],
  });

  HomeFeedConfig copyWith({int? version, List<HomeSectionConfig>? sections}) =>
      HomeFeedConfig(
        version: version ?? this.version,
        updatedAt: updatedAt,
        sections: sections ?? this.sections,
      );

  factory HomeFeedConfig.fromFirebaseJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List?) ?? const [];
    final sections =
        rawSections
            .whereType<Map>()
            .map((s) => _sectionFromJson(Map<String, dynamic>.from(s)))
            .whereType<HomeSectionConfig>()
            .toList()
          ..sort((a, b) => a.position.compareTo(b.position));
    return HomeFeedConfig(
      version: toInt(json['version'], 1),
      updatedAt: json['updatedAt'] != null
          ? parseTimestamp(json['updatedAt'])
          : null,
      sections: sections,
    );
  }

  Map<String, dynamic> toFirebaseJson() => {
    'version': version,
    'updatedAt': DateTime.now().toIso8601String(),
    'sections': [
      for (var i = 0; i < sections.length; i++)
        _sectionToJson(sections[i].copyWith(position: i)),
    ],
  };

  /// The 6 launch sections, used to seed the document when it doesn't exist.
  factory HomeFeedConfig.defaultConfig() => HomeFeedConfig(
    version: 1,
    sections: [
      const HomeSectionConfig(
        id: 'banner-1',
        type: HomeSectionType.banner,
        position: 0,
        source: HomeSourceConfig(kind: HomeSourceKind.manual),
      ),
      const HomeSectionConfig(
        id: 'sellers-1',
        type: HomeSectionType.authorisedSellersHorizontal,
        title: 'Authorised Sellers',
        position: 1,
        viewAll: HomeViewAll(enabled: true, target: 'sellers'),
        source: HomeSourceConfig(
          kind: HomeSourceKind.authorisedSellers,
          limit: 12,
        ),
      ),
      const HomeSectionConfig(
        id: 'trending-1',
        type: HomeSectionType.designsHorizontal,
        title: 'Trending Designs',
        position: 2,
        viewAll: HomeViewAll(enabled: true, target: 'designs?sort=popularity'),
        source: HomeSourceConfig(
          kind: HomeSourceKind.query,
          sort: 'popularity',
          limit: 10,
        ),
      ),
      const HomeSectionConfig(
        id: 'collections-1',
        type: HomeSectionType.collectionsGrid,
        title: 'Explore Collections',
        position: 3,
        viewAll: HomeViewAll(enabled: true, target: 'collections'),
        source: HomeSourceConfig(kind: HomeSourceKind.query, limit: 8),
      ),
      const HomeSectionConfig(
        id: 'recent-1',
        type: HomeSectionType.recentlyViewed,
        title: 'Recently Viewed',
        position: 4,
        source: HomeSourceConfig(
          kind: HomeSourceKind.recentlyViewed,
          limit: 10,
        ),
      ),
    ],
  );

  static HomeSectionConfig? _sectionFromJson(Map<String, dynamic> json) {
    final type = HomeSectionType.fromValue(toStringOrNull(json['type']));
    if (type == null) return null;
    final viewAllRaw = (json['viewAll'] as Map?) ?? const {};
    final sourceRaw = (json['source'] as Map?) ?? const {};
    return HomeSectionConfig(
      id: toStringOrNull(json['id']) ?? 'section',
      type: type,
      title: toStringOrNull(json['title']),
      subtitle: toStringOrNull(json['subtitle']),
      enabled: toBool(json['enabled'], true),
      position: toInt(json['position']),
      viewAll: HomeViewAll(
        enabled: toBool(viewAllRaw['enabled']),
        target: toStringOrNull(viewAllRaw['target']),
      ),
      source: _sourceFromJson(Map<String, dynamic>.from(sourceRaw)),
    );
  }

  static HomeSourceConfig _sourceFromJson(Map<String, dynamic> json) {
    final items = ((json['items'] as List?) ?? const [])
        .whereType<Map>()
        .map(
          (i) => BannerItemConfig(
            imageUrl: toStringOrNull(i['imageUrl']) ?? '',
            label: toStringOrNull(i['label']),
            title: toStringOrNull(i['title']),
            ctaTarget: toStringOrNull(i['ctaTarget']),
          ),
        )
        .where((b) => b.imageUrl.isNotEmpty)
        .toList();
    final manualIds = ((json['manualIds'] as List?) ?? const [])
        .map((e) => e?.toString())
        .whereType<String>()
        .where((e) => e.isNotEmpty)
        .toList();
    return HomeSourceConfig(
      kind: HomeSourceKind.fromValue(toStringOrNull(json['kind'])),
      items: items,
      collectionId: toStringOrNull(json['collectionId']),
      categoryId: toStringOrNull(json['categoryId']),
      sort: toStringOrNull(json['sort']) ?? 'newest',
      onlyActive: toBool(json['onlyActive'], true),
      limit: toInt(json['limit'], 10),
      manual: toBool(json['manual'], false),
      manualIds: manualIds,
    );
  }

  static Map<String, dynamic> _sectionToJson(HomeSectionConfig s) => {
    'id': s.id,
    'type': s.type.value,
    'title': s.title,
    'subtitle': s.subtitle,
    'enabled': s.enabled,
    'position': s.position,
    'viewAll': {'enabled': s.viewAll.enabled, 'target': s.viewAll.target},
    'source': {
      'kind': s.source.kind.value,
      'items': [
        for (final b in s.source.items)
          {
            'imageUrl': b.imageUrl,
            'label': b.label,
            'title': b.title,
            'ctaTarget': b.ctaTarget,
          },
      ],
      'collectionId': s.source.collectionId,
      'categoryId': s.source.categoryId,
      'sort': s.source.sort,
      'onlyActive': s.source.onlyActive,
      'limit': s.source.limit,
      'manual': s.source.manual,
      'manualIds': s.source.manualIds,
    },
  };
}
