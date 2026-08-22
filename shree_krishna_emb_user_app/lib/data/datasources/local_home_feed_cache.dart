import 'dart:convert';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

/// Persists the resolved home feed so the Home renders instantly / offline.
/// Serializes the polymorphic [HomeItem] family with a `kind` tag.
class LocalHomeFeedCache {
  final Box<String> _box;
  static const _key = 'home_feed';
  static const _ttl = Duration(hours: 6);

  LocalHomeFeedCache(this._box);

  HomeFeed? read() {
    final raw = _box.get(_key);
    if (raw == null) return null;
    try {
      final json = jsonDecode(raw) as Map<String, dynamic>;
      final cachedAt = DateTime.tryParse(json['cachedAt'] as String? ?? '');
      if (cachedAt == null || DateTime.now().difference(cachedAt) > _ttl) {
        return null;
      }
      return _feedFromJson(json);
    } catch (_) {
      return null;
    }
  }

  Future<void> write(HomeFeed feed) async {
    final json = _feedToJson(feed)
      ..['cachedAt'] = DateTime.now().toIso8601String();
    await _box.put(_key, jsonEncode(json));
  }

  // ---- serialization ----
  Map<String, dynamic> _feedToJson(HomeFeed feed) => {
    'version': feed.version,
    'sections': feed.sections.map(_sectionToJson).toList(),
  };

  Map<String, dynamic> _sectionToJson(HomeSection s) => {
    'id': s.id,
    'type': s.type.name,
    'title': s.title,
    'subtitle': s.subtitle,
    'viewAll': {'enabled': s.viewAll.enabled, 'target': s.viewAll.target},
    'items': s.items.map(_itemToJson).toList(),
  };

  Map<String, dynamic> _itemToJson(HomeItem item) => switch (item) {
    BannerItem b => {
      'kind': 'banner',
      'imageUrl': b.imageUrl,
      'label': b.label,
      'title': b.title,
      'ctaTarget': b.ctaTarget,
    },
    SellerItem s => {
      'kind': 'seller',
      'uid': s.uid,
      'displayName': s.displayName,
      'storeImageUrl': s.storeImageUrl,
    },
    DesignItem d => {
      'kind': 'design',
      'id': d.id,
      'name': d.name,
      'finalPrice': d.finalPrice,
      'isFree': d.isFree,
      'firstImageUrl': d.firstImageUrl,
      'description': d.description,
    },
    CollectionItem c => {
      'kind': 'collection',
      'id': c.id,
      'name': c.name,
      'imageUrl': c.imageUrl,
    },
    CategoryItem c => {
      'kind': 'category',
      'id': c.id,
      'name': c.name,
      'imageUrl': c.imageUrl,
    },
  };

  HomeFeed _feedFromJson(Map<String, dynamic> json) {
    final sections = ((json['sections'] as List?) ?? const [])
        .whereType<Map>()
        .map((s) => _sectionFromJson(Map<String, dynamic>.from(s)))
        .whereType<HomeSection>()
        .toList();
    return HomeFeed(
      version: (json['version'] as num?)?.toInt() ?? 0,
      sections: sections,
    );
  }

  HomeSection? _sectionFromJson(Map<String, dynamic> json) {
    final type = HomeSectionType.fromValue(json['type'] as String?);
    if (type == null) return null;
    final viewAll = (json['viewAll'] as Map?) ?? const {};
    final items = ((json['items'] as List?) ?? const [])
        .whereType<Map>()
        .map((i) => _itemFromJson(Map<String, dynamic>.from(i)))
        .whereType<HomeItem>()
        .toList();
    return HomeSection(
      id: json['id'] as String? ?? 'section',
      type: type,
      title: json['title'] as String?,
      subtitle: json['subtitle'] as String?,
      viewAll: HomeViewAll(
        enabled: viewAll['enabled'] == true,
        target: viewAll['target'] as String?,
      ),
      items: items,
    );
  }

  HomeItem? _itemFromJson(Map<String, dynamic> j) {
    switch (j['kind']) {
      case 'banner':
        return BannerItem(
          imageUrl: j['imageUrl'] as String? ?? '',
          label: j['label'] as String?,
          title: j['title'] as String?,
          ctaTarget: j['ctaTarget'] as String?,
        );
      case 'seller':
        return SellerItem(
          uid: j['uid'] as String? ?? '',
          displayName: j['displayName'] as String? ?? '',
          storeImageUrl: j['storeImageUrl'] as String?,
        );
      case 'design':
        return DesignItem(
          id: j['id'] as String? ?? '',
          name: j['name'] as String? ?? '',
          finalPrice: (j['finalPrice'] as num?)?.toInt() ?? 0,
          isFree: j['isFree'] == true,
          firstImageUrl: j['firstImageUrl'] as String?,
          description: j['description'] as String?,
        );
      case 'collection':
        return CollectionItem(
          id: j['id'] as String? ?? '',
          name: j['name'] as String? ?? '',
          imageUrl: j['imageUrl'] as String?,
        );
      case 'category':
        return CategoryItem(
          id: j['id'] as String? ?? '',
          name: j['name'] as String? ?? '',
          imageUrl: j['imageUrl'] as String?,
        );
      default:
        return null;
    }
  }
}
