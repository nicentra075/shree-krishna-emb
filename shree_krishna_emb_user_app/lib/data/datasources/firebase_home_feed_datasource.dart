import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_seller_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/local_recently_viewed_store.dart';
import 'package:shree_krishna_emb/data/models/home_feed_model.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

abstract class HomeFeedDataSource {
  Future<HomeFeed> getHomeFeed();
}

/// Resolves `config/homeFeed` into a fully-built [HomeFeed] in one load cycle:
/// reads the config doc, then resolves each section's items via parallel
/// queries. Filtering/sorting is done client-side (small limits) so no
/// composite indexes are required.
class FirebaseHomeFeedDataSource implements HomeFeedDataSource {
  final FirebaseFirestore _firestore;
  final SellerDataSource _sellerDataSource;
  final RecentlyViewedStore _recentStore;

  FirebaseHomeFeedDataSource({
    required FirebaseFirestore firestore,
    required SellerDataSource sellerDataSource,
    required RecentlyViewedStore recentStore,
  })  : _firestore = firestore,
        _sellerDataSource = sellerDataSource,
        _recentStore = recentStore;

  @override
  Future<HomeFeed> getHomeFeed() async {
    try {
      final doc =
          await _firestore.collection('config').doc('homeFeed').get();
      if (!doc.exists || doc.data() == null) {
        return const HomeFeed();
      }
      final config = HomeFeedConfigParse.fromJson(doc.data()!);
      final sections = await Future.wait(config.specs.map(_resolveSection));
      return HomeFeed(
        version: config.version,
        sections: sections.whereType<HomeSection>().toList(),
      );
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load home');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<HomeSection?> _resolveSection(HomeSectionSpec spec) async {
    final items = await _resolveItems(spec);
    return HomeSection(
      id: spec.id,
      type: spec.type,
      title: spec.title,
      subtitle: spec.subtitle,
      viewAll: spec.viewAll,
      items: items,
      sourceCollectionId: spec.collectionId,
    );
  }

  Future<List<HomeItem>> _resolveItems(HomeSectionSpec spec) async {
    switch (spec.type) {
      case HomeSectionType.banner:
        return spec.bannerItems;
      case HomeSectionType.authorisedSellersHorizontal:
        final sellers =
            await _sellerDataSource.getAuthorisedSellers(limit: spec.limit);
        return sellers
            .map((s) => SellerItem(
                uid: s.uid,
                displayName: s.displayName,
                storeImageUrl: s.storeImageUrl))
            .toList();
      case HomeSectionType.designsHorizontal:
      case HomeSectionType.designsVertical:
        return _queryDesigns(spec);
      case HomeSectionType.collectionsGrid:
        return _queryCollections(spec);
      case HomeSectionType.categoriesHorizontal:
        return _queryCategories(spec);
      case HomeSectionType.recentlyViewed:
        return _recentDesigns(spec);
    }
  }

  DesignItem _designItem(String id, Map<String, dynamic> d) {
    final images = (d['images'] as List?)?.map((e) => e.toString()).toList();
    return DesignItem(
      id: id,
      name: d['name']?.toString() ?? 'Design',
      finalPrice: (d['finalPrice'] as num?)?.toInt() ?? 0,
      isFree: d['isFree'] == true,
      firstImageUrl: (images != null && images.isNotEmpty) ? images.first : null,
    );
  }

  /// Fetches documents by id (in chunks of 30 for whereIn) → id→data map.
  Future<Map<String, Map<String, dynamic>>> _fetchByIds(
      String collection, List<String> ids) async {
    final result = <String, Map<String, dynamic>>{};
    for (var i = 0; i < ids.length; i += 30) {
      final chunk = ids.sublist(i, (i + 30) > ids.length ? ids.length : i + 30);
      final snap = await _firestore
          .collection(collection)
          .where(FieldPath.documentId, whereIn: chunk)
          .get();
      for (final d in snap.docs) {
        result[d.id] = d.data();
      }
    }
    return result;
  }

  Future<List<HomeItem>> _queryDesigns(HomeSectionSpec spec) async {
    // Hand-picked: show exactly the chosen designs, in the admin's order.
    if (spec.manual && spec.manualIds.isNotEmpty) {
      final byId = await _fetchByIds('designs', spec.manualIds);
      return spec.manualIds
          .where((id) => byId[id]?['status'] == 'active')
          .map((id) => _designItem(id, byId[id]!))
          .toList();
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection('designs')
        .where('status', isEqualTo: 'active');
    if (spec.collectionId != null) {
      q = q.where('collectionId', isEqualTo: spec.collectionId);
    }
    if (spec.categoryId != null) {
      q = q.where('categoryId', isEqualTo: spec.categoryId);
    }
    final snap = await q.limit(80).get();
    final docs = snap.docs.toList();
    int cmp(QueryDocumentSnapshot<Map<String, dynamic>> a,
        QueryDocumentSnapshot<Map<String, dynamic>> b) {
      final da = a.data();
      final db = b.data();
      switch (spec.sort) {
        case 'popularity':
          return ((db['popularity'] as num?) ?? 0)
              .compareTo((da['popularity'] as num?) ?? 0);
        case 'priceAsc':
          return ((da['finalPrice'] as num?) ?? 0)
              .compareTo((db['finalPrice'] as num?) ?? 0);
        case 'priceDesc':
          return ((db['finalPrice'] as num?) ?? 0)
              .compareTo((da['finalPrice'] as num?) ?? 0);
        case 'newest':
        default:
          return (db['createdAt']?.toString() ?? '')
              .compareTo(da['createdAt']?.toString() ?? '');
      }
    }

    docs.sort(cmp);
    return docs
        .take(spec.limit)
        .map((d) => _designItem(d.id, d.data()))
        .toList();
  }

  Future<List<HomeItem>> _queryCollections(HomeSectionSpec spec) async {
    // Hand-picked: show exactly the chosen collections, in the admin's order.
    if (spec.manual && spec.manualIds.isNotEmpty) {
      final byId = await _fetchByIds('collections', spec.manualIds);
      return spec.manualIds
          .where((id) => byId[id]?['isActive'] == true)
          .map((id) => CollectionItem(
                id: id,
                name: byId[id]!['name']?.toString() ?? 'Collection',
                imageUrl: byId[id]!['imageUrl']?.toString(),
              ))
          .toList();
    }
    final snap = await _firestore
        .collection('collections')
        .where('isActive', isEqualTo: true)
        .limit(spec.limit * 2)
        .get();
    final docs = snap.docs.toList()
      ..sort((a, b) => ((a.data()['position'] as num?) ?? 0)
          .compareTo((b.data()['position'] as num?) ?? 0));
    return docs
        .take(spec.limit)
        .map((d) => CollectionItem(
              id: d.id,
              name: d.data()['name']?.toString() ?? 'Collection',
              imageUrl: d.data()['imageUrl']?.toString(),
            ))
        .toList();
  }

  Future<List<HomeItem>> _queryCategories(HomeSectionSpec spec) async {
    // Hand-picked: show exactly the chosen categories, in the admin's order.
    if (spec.manual && spec.manualIds.isNotEmpty) {
      final byId = await _fetchByIds('categories', spec.manualIds);
      return spec.manualIds
          .where((id) => byId[id]?['isActive'] == true)
          .map((id) => CategoryItem(
                id: id,
                name: byId[id]!['name']?.toString() ?? 'Category',
                imageUrl: byId[id]!['imageUrl']?.toString(),
              ))
          .toList();
    }
    Query<Map<String, dynamic>> q = _firestore
        .collection('categories')
        .where('isActive', isEqualTo: true);
    if (spec.collectionId != null) {
      q = q.where('collectionId', isEqualTo: spec.collectionId);
    }
    final snap = await q.limit(spec.limit * 2).get();
    final docs = snap.docs.toList()
      ..sort((a, b) => ((a.data()['position'] as num?) ?? 0)
          .compareTo((b.data()['position'] as num?) ?? 0));
    return docs
        .take(spec.limit)
        .map((d) => CategoryItem(
              id: d.id,
              name: d.data()['name']?.toString() ?? 'Category',
              imageUrl: d.data()['imageUrl']?.toString(),
            ))
        .toList();
  }

  Future<List<HomeItem>> _recentDesigns(HomeSectionSpec spec) async {
    final ids = _recentStore.getIds().take(spec.limit).toList();
    if (ids.isEmpty) return const [];
    // whereIn supports up to 30 ids; recently-viewed is capped well under that.
    final snap = await _firestore
        .collection('designs')
        .where(FieldPath.documentId, whereIn: ids)
        .get();
    final byId = {for (final d in snap.docs) d.id: d.data()};
    return ids
        .where((id) => byId.containsKey(id) && byId[id]!['status'] == 'active')
        .map((id) => _designItem(id, byId[id]!))
        .toList();
  }
}
