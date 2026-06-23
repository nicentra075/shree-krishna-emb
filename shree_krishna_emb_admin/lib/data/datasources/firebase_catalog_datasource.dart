import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:shree_krishna_emb_admin/core/errors/exceptions.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';

/// Design sort options for the designs query.
enum DesignSort { popularity, newest, priceAsc, priceDesc }

abstract class CatalogDataSource {
  Future<List<CollectionModel>> getCollections({bool forceRefresh});
  Future<CollectionModel> createCollection(CollectionModel collection);
  Future<void> updateCollection(CollectionModel collection);
  Future<void> deleteCollection(String id);

  Future<List<CategoryModel>> getCategories({
    String? collectionId,
    bool forceRefresh,
  });
  Future<CategoryModel> createCategory(CategoryModel category);
  Future<void> updateCategory(CategoryModel category);
  Future<void> deleteCategory(String id);

  Future<List<DesignModel>> getDesigns({
    String? collectionId,
    String? categoryId,
    String? status,
    String? searchQuery,
    DesignSort sort,
    bool forceRefresh,
  });
  Future<DesignModel> createDesign(DesignModel design);
  Future<void> updateDesign(DesignModel design);
  Future<void> deleteDesign(String id);
}

/// Firestore implementation. Like the user-list datasource, each collection is
/// fetched once into an in-memory cache and all filtering/sorting/search runs
/// client-side; mutations invalidate the relevant cache.
class FirebaseCatalogDataSource implements CatalogDataSource {
  final FirebaseFirestore _firestore;

  FirebaseCatalogDataSource({required FirebaseFirestore firestore})
      : _firestore = firestore;

  static const Duration _ttl = Duration(minutes: 2);

  List<CollectionModel>? _collections;
  DateTime? _collectionsAt;
  List<CategoryModel>? _categories;
  DateTime? _categoriesAt;
  List<DesignModel>? _designs;
  DateTime? _designsAt;

  bool _fresh(DateTime? at) =>
      at != null && DateTime.now().difference(at) < _ttl;

  CollectionReference<Map<String, dynamic>> get _collectionsRef =>
      _firestore.collection('collections');
  CollectionReference<Map<String, dynamic>> get _categoriesRef =>
      _firestore.collection('categories');
  CollectionReference<Map<String, dynamic>> get _designsRef =>
      _firestore.collection('designs');

  // ---------------- Collections ----------------
  @override
  Future<List<CollectionModel>> getCollections({bool forceRefresh = false}) async {
    if (!forceRefresh && _collections != null && _fresh(_collectionsAt)) {
      return _collections!;
    }
    try {
      final snap = await _collectionsRef.orderBy('position').get();
      _collections = snap.docs
          .map((d) => CollectionModel.fromFirebaseJson({...d.data(), 'id': d.id}))
          .toList();
      _collectionsAt = DateTime.now();
      return _collections!;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getCollections', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to load collections');
    } catch (e, s) {
      AppLogger.logError('getCollections', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<CollectionModel> createCollection(CollectionModel collection) async {
    try {
      final ref = _collectionsRef.doc();
      final withId = CollectionModel.fromFirebaseJson({
        ...collection.toFirebaseJson(),
        'id': ref.id,
      });
      await ref.set(withId.toFirebaseJson());
      _collections = null;
      return withId;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('createCollection', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to create collection');
    } catch (e, s) {
      AppLogger.logError('createCollection', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> updateCollection(CollectionModel collection) async {
    try {
      await _collectionsRef.doc(collection.id).update(collection.toFirebaseJson());
      _collections = null;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('updateCollection', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to update collection');
    } catch (e, s) {
      AppLogger.logError('updateCollection', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteCollection(String id) async {
    try {
      await _collectionsRef.doc(id).delete();
      _collections = null;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('deleteCollection', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to delete collection');
    } catch (e, s) {
      AppLogger.logError('deleteCollection', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  // ---------------- Categories ----------------
  @override
  Future<List<CategoryModel>> getCategories({
    String? collectionId,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh || _categories == null || !_fresh(_categoriesAt)) {
        final snap = await _categoriesRef.orderBy('position').get();
        _categories = snap.docs
            .map((d) => CategoryModel.fromFirebaseJson({...d.data(), 'id': d.id}))
            .toList();
        _categoriesAt = DateTime.now();
      }
      if (collectionId == null || collectionId.isEmpty) return _categories!;
      return _categories!.where((c) => c.collectionId == collectionId).toList();
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getCategories', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to load categories');
    } catch (e, s) {
      AppLogger.logError('getCategories', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<CategoryModel> createCategory(CategoryModel category) async {
    try {
      final ref = _categoriesRef.doc();
      final withId = CategoryModel.fromFirebaseJson({
        ...category.toFirebaseJson(),
        'id': ref.id,
      });
      await ref.set(withId.toFirebaseJson());
      _categories = null;
      return withId;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('createCategory', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to create category');
    } catch (e, s) {
      AppLogger.logError('createCategory', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> updateCategory(CategoryModel category) async {
    try {
      await _categoriesRef.doc(category.id).update(category.toFirebaseJson());
      _categories = null;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('updateCategory', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to update category');
    } catch (e, s) {
      AppLogger.logError('updateCategory', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteCategory(String id) async {
    try {
      await _categoriesRef.doc(id).delete();
      _categories = null;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('deleteCategory', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to delete category');
    } catch (e, s) {
      AppLogger.logError('deleteCategory', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  // ---------------- Designs ----------------
  @override
  Future<List<DesignModel>> getDesigns({
    String? collectionId,
    String? categoryId,
    String? status,
    String? searchQuery,
    DesignSort sort = DesignSort.newest,
    bool forceRefresh = false,
  }) async {
    try {
      if (forceRefresh || _designs == null || !_fresh(_designsAt)) {
        final snap = await _designsRef.get();
        _designs = snap.docs
            .map((d) => DesignModel.fromFirebaseJson({...d.data(), 'id': d.id}))
            .toList();
        _designsAt = DateTime.now();
      }
      var result = _designs!.toList();
      if (collectionId != null && collectionId.isNotEmpty) {
        result = result.where((d) => d.collectionId == collectionId).toList();
      }
      if (categoryId != null && categoryId.isNotEmpty) {
        result = result.where((d) => d.categoryId == categoryId).toList();
      }
      if (status != null && status.isNotEmpty) {
        result = result.where((d) => d.status == status).toList();
      }
      if (searchQuery != null && searchQuery.isNotEmpty) {
        final q = searchQuery.toLowerCase();
        result = result
            .where((d) =>
                d.name.toLowerCase().contains(q) ||
                (d.code ?? '').toLowerCase().contains(q))
            .toList();
      }
      switch (sort) {
        case DesignSort.popularity:
          result.sort((a, b) => b.popularity.compareTo(a.popularity));
        case DesignSort.newest:
          result.sort((a, b) => b.createdAt.compareTo(a.createdAt));
        case DesignSort.priceAsc:
          result.sort((a, b) => a.finalPrice.compareTo(b.finalPrice));
        case DesignSort.priceDesc:
          result.sort((a, b) => b.finalPrice.compareTo(a.finalPrice));
      }
      return result;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('getDesigns', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to load designs');
    } catch (e, s) {
      AppLogger.logError('getDesigns', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<DesignModel> createDesign(DesignModel design) async {
    try {
      final ref = _designsRef.doc();
      final withId = DesignModel.fromFirebaseJson({
        ...design.toFirebaseJson(),
        'id': ref.id,
      });
      await ref.set(withId.toFirebaseJson());
      _designs = null;
      return withId;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('createDesign', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to create design');
    } catch (e, s) {
      AppLogger.logError('createDesign', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> updateDesign(DesignModel design) async {
    try {
      await _designsRef.doc(design.id).update(design.toFirebaseJson());
      _designs = null;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('updateDesign', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to update design');
    } catch (e, s) {
      AppLogger.logError('updateDesign', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }

  @override
  Future<void> deleteDesign(String id) async {
    try {
      await _designsRef.doc(id).delete();
      _designs = null;
    } on FirebaseException catch (e, s) {
      AppLogger.logError('deleteDesign', error: e, stackTrace: s);
      throw ServerException(message: e.message ?? 'Failed to delete design');
    } catch (e, s) {
      AppLogger.logError('deleteDesign', error: e, stackTrace: s);
      throw ServerException(message: 'Unexpected error: $e');
    }
  }
}
