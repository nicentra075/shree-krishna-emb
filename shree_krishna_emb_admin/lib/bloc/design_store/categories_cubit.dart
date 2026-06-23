import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart'
    show CatalogStatus, kDefaultCatalogPageSize;
import 'package:shree_krishna_emb_admin/data/datasources/firebase_image_storage_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/category_model.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/catalog_repository.dart';

/// Active/inactive status filter for catalog lists.
enum CatalogStatusFilter { all, active, inactive }

class CategoriesState extends Equatable {
  final CatalogStatus status;
  final List<CategoryModel> categories;
  final String? collectionId; // collection filter (null = all)
  final CatalogStatusFilter statusFilter;
  final int page;
  final int pageSize;
  final String? error;

  const CategoriesState({
    this.status = CatalogStatus.initial,
    this.categories = const [],
    this.collectionId,
    this.statusFilter = CatalogStatusFilter.all,
    this.page = 1,
    this.pageSize = kDefaultCatalogPageSize,
    this.error,
  });

  /// Categories after applying the active/inactive status filter.
  List<CategoryModel> get visibleCategories => switch (statusFilter) {
        CatalogStatusFilter.all => categories,
        CatalogStatusFilter.active =>
          categories.where((c) => c.isActive).toList(),
        CatalogStatusFilter.inactive =>
          categories.where((c) => !c.isActive).toList(),
      };

  CategoriesState copyWith({
    CatalogStatus? status,
    List<CategoryModel>? categories,
    String? collectionId,
    CatalogStatusFilter? statusFilter,
    int? page,
    int? pageSize,
    String? error,
  }) =>
      CategoriesState(
        status: status ?? this.status,
        categories: categories ?? this.categories,
        collectionId: collectionId ?? this.collectionId,
        statusFilter: statusFilter ?? this.statusFilter,
        page: page ?? this.page,
        pageSize: pageSize ?? this.pageSize,
        error: error,
      );

  @override
  List<Object?> get props =>
      [status, categories, collectionId, statusFilter, page, pageSize, error];
}

class CategoriesCubit extends Cubit<CategoriesState> {
  final CatalogRepository repository;
  final ImageStorageDataSource imageStorage;

  CategoriesCubit({required this.repository, required this.imageStorage})
      : super(const CategoriesState());

  void setPage(int page) => emit(state.copyWith(page: page));

  void setStatusFilter(CatalogStatusFilter filter) =>
      emit(state.copyWith(statusFilter: filter, page: 1));

  void setPageSize(int size) =>
      emit(state.copyWith(pageSize: size, page: 1));

  Future<void> load({String? collectionId, bool forceRefresh = false}) async {
    emit(state.copyWith(
        status: CatalogStatus.loading, collectionId: collectionId));
    final result = await repository.getCategories(
      collectionId: collectionId,
      forceRefresh: forceRefresh,
    );
    if (isClosed) return;
    result.fold(
      (failure) =>
          emit(state.copyWith(status: CatalogStatus.error, error: failure.message)),
      (categories) => emit(CategoriesState(
        status: CatalogStatus.loaded,
        categories: categories,
        collectionId: collectionId,
        statusFilter: state.statusFilter,
        pageSize: state.pageSize,
      )),
    );
  }

  Future<String?> create(CategoryModel category) async {
    final result = await repository.createCategory(category);
    return result.fold((f) => f.message, (_) {
      load(collectionId: state.collectionId, forceRefresh: true);
      return null;
    });
  }

  Future<String?> update(CategoryModel category) async {
    final result = await repository.updateCategory(category);
    return result.fold((f) => f.message, (_) {
      load(collectionId: state.collectionId, forceRefresh: true);
      return null;
    });
  }

  Future<String?> remove(String id) async {
    final imageUrl = state.categories
        .where((c) => c.id == id)
        .map((c) => c.imageUrl ?? '')
        .join();
    final result = await repository.deleteCategory(id);
    final err = result.fold((f) => f.message, (_) => null);
    if (err == null) {
      await imageStorage.deleteByUrl(imageUrl);
      load(collectionId: state.collectionId, forceRefresh: true);
    }
    return err;
  }

  /// Number of designs that belong to [categoryId] — shown in the cascade
  /// confirmation.
  Future<int> designCount(String categoryId) async {
    final res =
        await repository.getDesigns(categoryId: categoryId, forceRefresh: true);
    return res.fold((_) => 0, (l) => l.length);
  }

  /// Deletes the category together with all of its designs. Returns an error
  /// message on the first failure, or null on success.
  Future<String?> removeCascade(String id) async {
    final imageUrls = <String>[];
    final res =
        await repository.getDesigns(categoryId: id, forceRefresh: true);
    final designs = res.fold((_) => <DesignModel>[], (l) => l);
    for (final d in designs) {
      imageUrls.addAll(d.images);
      final err = (await repository.deleteDesign(d.id))
          .fold((f) => f.message, (_) => null);
      if (err != null) return err;
    }
    final selfUrl = state.categories
        .where((c) => c.id == id)
        .map((c) => c.imageUrl ?? '')
        .join();
    if (selfUrl.isNotEmpty) imageUrls.add(selfUrl);

    final result = await repository.deleteCategory(id);
    final err = result.fold((f) => f.message, (_) => null);
    if (err == null) {
      await imageStorage.deleteUrls(imageUrls);
      load(collectionId: state.collectionId, forceRefresh: true);
    }
    return err;
  }
}
