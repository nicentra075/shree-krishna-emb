import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_seller_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

/// A downloadable design source file (tagged with its format), resolved for the
/// detail screen.
class DesignFileDownload {
  final String format;
  final String name;
  final String url;
  const DesignFileDownload({
    required this.format,
    required this.name,
    required this.url,
  });
}

/// Full design fields for the detail screen.
class DesignDetail {
  final String id;
  final String name;
  final String? code;
  final List<String> images;
  final String? authorName;
  final String? description;
  final int price;
  final int discountAmount;
  final bool isFree;
  final int finalPrice;
  final String? colorOrNeedleCount;
  final String? designFormat;
  final List<String> designFormats;
  final List<DesignFileDownload> designFiles;
  final int stitchCount;
  final int height;
  final int width;

  /// Category/collection the design belongs to — used to surface related
  /// designs and sibling categories on the detail screen.
  final String? categoryId;
  final String? collectionId;

  /// Review aggregates maintained by the onReviewWritten Cloud Function.
  final double avgRating;
  final int reviewCount;

  const DesignDetail({
    required this.id,
    required this.name,
    this.code,
    this.images = const [],
    this.authorName,
    this.description,
    this.price = 0,
    this.discountAmount = 0,
    this.isFree = false,
    this.finalPrice = 0,
    this.colorOrNeedleCount,
    this.designFormat,
    this.designFormats = const [],
    this.designFiles = const [],
    this.stitchCount = 0,
    this.height = 0,
    this.width = 0,
    this.categoryId,
    this.collectionId,
    this.avgRating = 0,
    this.reviewCount = 0,
  });

  String? get firstImageUrl => images.isNotEmpty ? images.first : null;

  /// The formats to show — prefers the multi-select list, falls back to the
  /// legacy single string.
  List<String> get formatsForDisplay {
    if (designFormats.isNotEmpty) return designFormats;
    final legacy = (designFormat ?? '').trim();
    if (legacy.isEmpty) return const [];
    return legacy
        .split(RegExp(r'[,/]'))
        .map((e) => e.trim())
        .where((e) => e.isNotEmpty)
        .toList();
  }
}

/// Filters applied by the search screen. All fields optional — null/empty
/// means "no constraint". Prices are the rupee ints used by the live schema.
class SearchFilters {
  final String? categoryId;
  final int? minPrice;
  final int? maxPrice;
  final bool freeOnly;
  final String sort;

  const SearchFilters({
    this.categoryId,
    this.minPrice,
    this.maxPrice,
    this.freeOnly = false,
    this.sort = 'newest',
  });

  bool get hasActiveFilters =>
      categoryId != null || minPrice != null || maxPrice != null || freeOnly;

  SearchFilters copyWith({
    String? categoryId,
    int? minPrice,
    int? maxPrice,
    bool? freeOnly,
    String? sort,
    bool clearCategory = false,
    bool clearMinPrice = false,
    bool clearMaxPrice = false,
  }) {
    return SearchFilters(
      categoryId: clearCategory ? null : (categoryId ?? this.categoryId),
      minPrice: clearMinPrice ? null : (minPrice ?? this.minPrice),
      maxPrice: clearMaxPrice ? null : (maxPrice ?? this.maxPrice),
      freeOnly: freeOnly ?? this.freeOnly,
      sort: sort ?? this.sort,
    );
  }
}

/// Queries for the View-All screens and design detail. Filtering/sorting is
/// client-side over a capped fetch (index-free; fine for launch catalog sizes).
class CatalogQueryDataSource {
  final FirebaseFirestore _firestore;
  final SellerDataSource _sellerDataSource;
  static const _cap = 150;

  /// Search sweeps a larger slice than the browse cap so results don't miss
  /// items that happen to fall outside the first page of a category.
  static const _searchCap = 400;

  CatalogQueryDataSource({
    required FirebaseFirestore firestore,
    required SellerDataSource sellerDataSource,
  }) : _firestore = firestore,
       _sellerDataSource = sellerDataSource;

  Future<List<DesignItem>> designs({
    String? collectionId,
    String? categoryId,
    String sort = 'newest',
  }) async {
    try {
      Query<Map<String, dynamic>> q = _firestore
          .collection('designs')
          .where('status', isEqualTo: 'active');
      if (collectionId != null) {
        q = q.where('collectionId', isEqualTo: collectionId);
      }
      if (categoryId != null) {
        q = q.where('categoryId', isEqualTo: categoryId);
      }
      final snap = await q.limit(_cap).get();
      final docs = snap.docs.toList();
      docs.sort((a, b) {
        final da = a.data();
        final db = b.data();
        switch (sort) {
          case 'popularity':
            return ((db['popularity'] as num?) ?? 0).compareTo(
              (da['popularity'] as num?) ?? 0,
            );
          case 'priceAsc':
            return ((da['finalPrice'] as num?) ?? 0).compareTo(
              (db['finalPrice'] as num?) ?? 0,
            );
          case 'priceDesc':
            return ((db['finalPrice'] as num?) ?? 0).compareTo(
              (da['finalPrice'] as num?) ?? 0,
            );
          default:
            return (db['createdAt']?.toString() ?? '').compareTo(
              da['createdAt']?.toString() ?? '',
            );
        }
      });
      return docs.map((d) => _mapDesignItem(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load designs');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  DesignItem _mapDesignItem(String id, Map<String, dynamic> data) {
    final images = (data['images'] as List?)?.map((e) => e.toString()).toList();
    return DesignItem(
      id: id,
      name: data['name']?.toString() ?? 'Design',
      finalPrice: (data['finalPrice'] as num?)?.toInt() ?? 0,
      isFree: data['isFree'] == true,
      firstImageUrl: (images != null && images.isNotEmpty)
          ? images.first
          : null,
      description: data['description']?.toString(),
      avgRating: (data['avgRating'] as num?)?.toDouble() ?? 0,
      reviewCount: (data['reviewCount'] as num?)?.toInt() ?? 0,
    );
  }

  /// Case-insensitive substring match of every query token against the
  /// design's name / code / description. Client-side over a capped fetch —
  /// same index-free approach as the rest of the catalog (fine at launch
  /// scale; move to a keyword index when the catalog outgrows [_searchCap]).
  Future<List<DesignItem>> searchDesigns({
    required String query,
    SearchFilters filters = const SearchFilters(),
  }) async {
    try {
      Query<Map<String, dynamic>> q = _firestore
          .collection('designs')
          .where('status', isEqualTo: 'active');
      if (filters.categoryId != null) {
        q = q.where('categoryId', isEqualTo: filters.categoryId);
      }
      final snap = await q.limit(_searchCap).get();

      final tokens = query
          .toLowerCase()
          .split(RegExp(r'\s+'))
          .where((t) => t.isNotEmpty)
          .toList();

      bool matches(Map<String, dynamic> data) {
        if (tokens.isNotEmpty) {
          final haystack = [
            data['name']?.toString() ?? '',
            data['code']?.toString() ?? '',
            data['description']?.toString() ?? '',
          ].join(' ').toLowerCase();
          if (!tokens.every(haystack.contains)) return false;
        }
        final price = (data['finalPrice'] as num?)?.toInt() ?? 0;
        final isFree = data['isFree'] == true;
        if (filters.freeOnly && !isFree) return false;
        if (filters.minPrice != null && price < filters.minPrice!) {
          return false;
        }
        if (filters.maxPrice != null && price > filters.maxPrice!) {
          return false;
        }
        return true;
      }

      final docs = snap.docs.where((d) => matches(d.data())).toList();
      docs.sort((a, b) {
        final da = a.data();
        final db = b.data();
        switch (filters.sort) {
          case 'popularity':
            return ((db['popularity'] as num?) ?? 0).compareTo(
              (da['popularity'] as num?) ?? 0,
            );
          case 'priceAsc':
            return ((da['finalPrice'] as num?) ?? 0).compareTo(
              (db['finalPrice'] as num?) ?? 0,
            );
          case 'priceDesc':
            return ((db['finalPrice'] as num?) ?? 0).compareTo(
              (da['finalPrice'] as num?) ?? 0,
            );
          default:
            return (db['createdAt']?.toString() ?? '').compareTo(
              da['createdAt']?.toString() ?? '',
            );
        }
      });
      return docs.map((d) => _mapDesignItem(d.id, d.data())).toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to search designs');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<List<CollectionItem>> collections() async {
    try {
      final snap = await _firestore
          .collection('collections')
          .where('isActive', isEqualTo: true)
          .limit(_cap)
          .get();
      final docs = snap.docs.toList()
        ..sort(
          (a, b) => ((a.data()['position'] as num?) ?? 0).compareTo(
            (b.data()['position'] as num?) ?? 0,
          ),
        );
      return docs
          .map(
            (d) => CollectionItem(
              id: d.id,
              name: d.data()['name']?.toString() ?? 'Collection',
              imageUrl: d.data()['imageUrl']?.toString(),
            ),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load collections');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<List<CategoryItem>> categories({String? collectionId}) async {
    try {
      Query<Map<String, dynamic>> q = _firestore
          .collection('categories')
          .where('isActive', isEqualTo: true);
      if (collectionId != null) {
        q = q.where('collectionId', isEqualTo: collectionId);
      }
      final snap = await q.limit(_cap).get();
      final docs = snap.docs.toList()
        ..sort(
          (a, b) => ((a.data()['position'] as num?) ?? 0).compareTo(
            (b.data()['position'] as num?) ?? 0,
          ),
        );
      return docs
          .map(
            (d) => CategoryItem(
              id: d.id,
              name: d.data()['name']?.toString() ?? 'Category',
              imageUrl: d.data()['imageUrl']?.toString(),
            ),
          )
          .toList();
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load categories');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  Future<List<SellerItem>> sellers() async {
    final list = await _sellerDataSource.getAuthorisedSellers(limit: _cap);
    return list
        .map(
          (s) => SellerItem(
            uid: s.uid,
            displayName: s.displayName,
            storeImageUrl: s.storeImageUrl,
          ),
        )
        .toList();
  }

  Future<DesignDetail?> designById(String id) async {
    try {
      final doc = await _firestore.collection('designs').doc(id).get();
      if (!doc.exists || doc.data() == null) return null;
      final d = doc.data()!;
      return DesignDetail(
        id: doc.id,
        name: d['name']?.toString() ?? 'Design',
        code: d['code']?.toString(),
        images:
            (d['images'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        authorName: d['authorName']?.toString(),
        description: d['description']?.toString(),
        price: (d['price'] as num?)?.toInt() ?? 0,
        discountAmount: (d['discountAmount'] as num?)?.toInt() ?? 0,
        isFree: d['isFree'] == true,
        finalPrice: (d['finalPrice'] as num?)?.toInt() ?? 0,
        colorOrNeedleCount: d['colorOrNeedleCount']?.toString(),
        designFormat: d['designFormat']?.toString(),
        designFormats:
            (d['designFormats'] as List?)?.map((e) => e.toString()).toList() ??
            const [],
        designFiles:
            (d['designFiles'] as List?)
                ?.whereType<Map>()
                .map(
                  (m) => DesignFileDownload(
                    format: (m['format'] ?? '').toString(),
                    name: (m['name'] ?? '').toString(),
                    url: (m['url'] ?? '').toString(),
                  ),
                )
                .where((f) => f.url.isNotEmpty)
                .toList() ??
            const [],
        stitchCount: (d['stitchCount'] as num?)?.toInt() ?? 0,
        height: (d['height'] as num?)?.toInt() ?? 0,
        width: (d['width'] as num?)?.toInt() ?? 0,
        categoryId: d['categoryId']?.toString(),
        collectionId: d['collectionId']?.toString(),
        avgRating: (d['avgRating'] as num?)?.toDouble() ?? 0,
        reviewCount: (d['reviewCount'] as num?)?.toInt() ?? 0,
      );
    } on FirebaseException catch (e) {
      throw ServerException(message: e.message ?? 'Failed to load design');
    } catch (e) {
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
