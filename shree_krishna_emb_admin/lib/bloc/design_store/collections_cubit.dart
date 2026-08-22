import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_image_storage_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/collection_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/catalog_repository.dart';

enum CatalogStatus { initial, loading, loaded, error }

/// Default rows-per-page for catalog lists, and the selectable options.
const int kDefaultCatalogPageSize = 10;
const List<int> kCatalogPageSizeOptions = [10, 25, 50, 100];

class CollectionsState extends Equatable {
  final CatalogStatus status;
  final List<CollectionModel> collections;
  final int page;
  final int pageSize;
  final String? error;

  const CollectionsState({
    this.status = CatalogStatus.initial,
    this.collections = const [],
    this.page = 1,
    this.pageSize = kDefaultCatalogPageSize,
    this.error,
  });

  CollectionsState copyWith({
    CatalogStatus? status,
    List<CollectionModel>? collections,
    int? page,
    int? pageSize,
    String? error,
  }) => CollectionsState(
    status: status ?? this.status,
    collections: collections ?? this.collections,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    error: error,
  );

  @override
  List<Object?> get props => [status, collections, page, pageSize, error];
}

class CollectionsCubit extends Cubit<CollectionsState> {
  final CatalogRepository repository;
  final ImageStorageDataSource imageStorage;

  CollectionsCubit({required this.repository, required this.imageStorage})
    : super(const CollectionsState());

  void setPage(int page) => emit(state.copyWith(page: page));

  void setPageSize(int size) => emit(state.copyWith(pageSize: size, page: 1));

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await repository.getCollections(forceRefresh: forceRefresh);
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: CatalogStatus.error, error: failure.message),
      ),
      (collections) => emit(
        CollectionsState(
          status: CatalogStatus.loaded,
          collections: collections,
          pageSize: state.pageSize,
        ),
      ),
    );
  }

  /// Returns an error message on failure, or null on success (and reloads).
  Future<String?> create(CollectionModel collection) async {
    final result = await repository.createCollection(collection);
    return result.fold((f) => f.message, (_) {
      load(forceRefresh: true);
      return null;
    });
  }

  Future<String?> update(CollectionModel collection) async {
    final result = await repository.updateCollection(collection);
    return result.fold((f) => f.message, (_) {
      load(forceRefresh: true);
      return null;
    });
  }

  Future<String?> remove(String id) async {
    final imageUrl = state.collections
        .where((c) => c.id == id)
        .map((c) => c.imageUrl ?? '')
        .join();
    final result = await repository.deleteCollection(id);
    final err = result.fold((f) => f.message, (_) => null);
    if (err == null) {
      // Best-effort: remove the Storage image (skips shared library assets).
      await imageStorage.deleteByUrl(imageUrl);
      load(forceRefresh: true);
    }
    return err;
  }

  /// Number of categories and designs that belong to [collectionId] — shown in
  /// the cascade-delete confirmation.
  Future<({int categories, int designs})> childCounts(
    String collectionId,
  ) async {
    final cats = await repository.getCategories(
      collectionId: collectionId,
      forceRefresh: true,
    );
    final designs = await repository.getDesigns(
      collectionId: collectionId,
      forceRefresh: true,
    );
    return (
      categories: cats.fold((_) => 0, (l) => l.length),
      designs: designs.fold((_) => 0, (l) => l.length),
    );
  }

  /// Deletes the collection together with all of its categories and designs.
  /// Returns an error message on the first failure, or null on success.
  Future<String?> removeCascade(String id) async {
    // Gather every image URL we'll orphan, to clean up Storage afterwards.
    final imageUrls = <String>[];
    final designsRes = await repository.getDesigns(
      collectionId: id,
      forceRefresh: true,
    );
    final designs = designsRes.fold((_) => <DesignModel>[], (l) => l);
    for (final d in designs) {
      imageUrls.addAll(d.images);
      final err = (await repository.deleteDesign(
        d.id,
      )).fold((f) => f.message, (_) => null);
      if (err != null) return err;
    }
    final catsRes = await repository.getCategories(
      collectionId: id,
      forceRefresh: true,
    );
    final cats = catsRes.fold((_) => <CategoryModel>[], (l) => l);
    for (final c in cats) {
      if ((c.imageUrl ?? '').isNotEmpty) imageUrls.add(c.imageUrl!);
      final err = (await repository.deleteCategory(
        c.id,
      )).fold((f) => f.message, (_) => null);
      if (err != null) return err;
    }
    final selfUrl = state.collections
        .where((c) => c.id == id)
        .map((c) => c.imageUrl ?? '')
        .join();
    if (selfUrl.isNotEmpty) imageUrls.add(selfUrl);

    final result = await repository.deleteCollection(id);
    final err = result.fold((f) => f.message, (_) => null);
    if (err == null) {
      await imageStorage.deleteUrls(imageUrls);
      load(forceRefresh: true);
    }
    return err;
  }
}
