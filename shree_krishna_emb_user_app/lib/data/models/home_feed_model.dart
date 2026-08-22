import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

/// Parsed (but not yet resolved) section from `config/homeFeed`. The datasource
/// turns each spec into a [HomeSection] by resolving its source to items.
class HomeSectionSpec {
  final String id;
  final HomeSectionType type;
  final String? title;
  final String? subtitle;
  final bool enabled;
  final int position;
  final HomeViewAll viewAll;
  final String sourceKind;
  final List<BannerItem> bannerItems;
  final String? collectionId;
  final String? categoryId;
  final String sort;
  final bool onlyActive;
  final int limit;

  /// When true, the section shows exactly [manualIds] (in order); otherwise it
  /// auto-resolves all active items.
  final bool manual;

  /// Hand-picked collection / category / design ids, in display order.
  final List<String> manualIds;

  const HomeSectionSpec({
    required this.id,
    required this.type,
    required this.sourceKind,
    this.title,
    this.subtitle,
    this.enabled = true,
    this.position = 0,
    this.viewAll = const HomeViewAll(),
    this.bannerItems = const [],
    this.collectionId,
    this.categoryId,
    this.sort = 'newest',
    this.onlyActive = true,
    this.limit = 10,
    this.manual = false,
    this.manualIds = const [],
  });
}

class HomeFeedConfigParse {
  final int version;
  final List<HomeSectionSpec> specs;
  const HomeFeedConfigParse({required this.version, required this.specs});

  static String? _str(dynamic v) {
    if (v == null) return null;
    final s = v.toString();
    return s.isEmpty ? null : s;
  }

  static int _int(dynamic v, [int fallback = 0]) {
    if (v is int) return v;
    if (v is num) return v.toInt();
    return int.tryParse('${v ?? ''}') ?? fallback;
  }

  static bool _bool(dynamic v, [bool fallback = false]) {
    if (v is bool) return v;
    if (v is String) return v.toLowerCase() == 'true';
    return fallback;
  }

  factory HomeFeedConfigParse.fromJson(Map<String, dynamic> json) {
    final rawSections = (json['sections'] as List?) ?? const [];
    final specs = <HomeSectionSpec>[];
    for (final raw in rawSections.whereType<Map>()) {
      final s = Map<String, dynamic>.from(raw);
      final type = HomeSectionType.fromValue(_str(s['type']));
      if (type == null) continue; // unknown type → forward-compatible skip
      if (!_bool(s['enabled'], true)) continue; // hidden
      final viewAllRaw = (s['viewAll'] as Map?) ?? const {};
      final sourceRaw = Map<String, dynamic>.from(
        (s['source'] as Map?) ?? const {},
      );
      final banners = ((sourceRaw['items'] as List?) ?? const [])
          .whereType<Map>()
          .map(
            (i) => BannerItem(
              imageUrl: _str(i['imageUrl']) ?? '',
              label: _str(i['label']),
              title: _str(i['title']),
              ctaTarget: _str(i['ctaTarget']),
            ),
          )
          .where((b) => b.imageUrl.isNotEmpty)
          .toList();
      final manualIds = ((sourceRaw['manualIds'] as List?) ?? const [])
          .map((e) => e?.toString())
          .whereType<String>()
          .where((e) => e.isNotEmpty)
          .toList();
      specs.add(
        HomeSectionSpec(
          id: _str(s['id']) ?? 'section',
          type: type,
          title: _str(s['title']),
          subtitle: _str(s['subtitle']),
          enabled: true,
          position: _int(s['position']),
          viewAll: HomeViewAll(
            enabled: _bool(viewAllRaw['enabled']),
            target: _str(viewAllRaw['target']),
          ),
          sourceKind: _str(sourceRaw['kind']) ?? 'query',
          bannerItems: banners,
          collectionId: _str(sourceRaw['collectionId']),
          categoryId: _str(sourceRaw['categoryId']),
          sort: _str(sourceRaw['sort']) ?? 'newest',
          onlyActive: _bool(sourceRaw['onlyActive'], true),
          limit: _int(sourceRaw['limit'], 10),
          manual: _bool(sourceRaw['manual'], false),
          manualIds: manualIds,
        ),
      );
    }
    specs.sort((a, b) => a.position.compareTo(b.position));
    return HomeFeedConfigParse(version: _int(json['version']), specs: specs);
  }
}
