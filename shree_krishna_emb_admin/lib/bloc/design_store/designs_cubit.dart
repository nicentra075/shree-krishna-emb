import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart'
    show CatalogStatus, kDefaultCatalogPageSize;
import 'package:shree_krishna_emb_admin/data/datasources/firebase_catalog_datasource.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_image_storage_datasource.dart';
import 'package:shree_krishna_emb_admin/data/models/design_model.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/catalog_repository.dart';

class DesignsState extends Equatable {
  final CatalogStatus status;
  final List<DesignModel> designs;
  final String? collectionId;
  final String? categoryId;
  final String? statusFilter;
  final String? search;
  final DesignSort sort;
  final int page;
  final int pageSize;
  final String? error;

  const DesignsState({
    this.status = CatalogStatus.initial,
    this.designs = const [],
    this.collectionId,
    this.categoryId,
    this.statusFilter,
    this.search,
    this.sort = DesignSort.newest,
    this.page = 1,
    this.pageSize = kDefaultCatalogPageSize,
    this.error,
  });

  /// True when any search/collection/category filter is active.
  bool get hasFilters =>
      (search != null && search!.isNotEmpty) ||
      collectionId != null ||
      categoryId != null;

  DesignsState copyWith({
    CatalogStatus? status,
    List<DesignModel>? designs,
    String? collectionId,
    String? categoryId,
    String? statusFilter,
    String? search,
    DesignSort? sort,
    int? page,
    int? pageSize,
    String? error,
  }) => DesignsState(
    status: status ?? this.status,
    designs: designs ?? this.designs,
    collectionId: collectionId ?? this.collectionId,
    categoryId: categoryId ?? this.categoryId,
    statusFilter: statusFilter ?? this.statusFilter,
    search: search ?? this.search,
    sort: sort ?? this.sort,
    page: page ?? this.page,
    pageSize: pageSize ?? this.pageSize,
    error: error,
  );

  @override
  List<Object?> get props => [
    status,
    designs,
    collectionId,
    categoryId,
    statusFilter,
    search,
    sort,
    page,
    pageSize,
    error,
  ];
}

class DesignsCubit extends Cubit<DesignsState> {
  final CatalogRepository repository;
  final ImageStorageDataSource imageStorage;

  /// When set (designer sessions — D2), every load is filtered to this
  /// author's designs. Injected by the service locator so no call site can
  /// forget the scope.
  final String? scopedAuthorId;

  DesignsCubit({
    required this.repository,
    required this.imageStorage,
    this.scopedAuthorId,
  }) : super(const DesignsState());

  Future<void> load({bool forceRefresh = false}) async {
    emit(state.copyWith(status: CatalogStatus.loading));
    final result = await repository.getDesigns(
      collectionId: state.collectionId,
      categoryId: state.categoryId,
      status: state.statusFilter,
      searchQuery: state.search,
      sort: state.sort,
      forceRefresh: forceRefresh,
      authorId: scopedAuthorId,
    );
    if (isClosed) return;
    result.fold(
      (failure) => emit(
        state.copyWith(status: CatalogStatus.error, error: failure.message),
      ),
      // A fresh load resets to the first page.
      (designs) => emit(
        state.copyWith(
          status: CatalogStatus.loaded,
          designs: designs,
          page: 1,
          error: null,
        ),
      ),
    );
  }

  void setPage(int page) => emit(state.copyWith(page: page));

  void setPageSize(int size) => emit(state.copyWith(pageSize: size, page: 1));

  void setSearch(String value) {
    emit(state.copyWith(search: value.isEmpty ? null : value));
    load();
  }

  void setSort(DesignSort sort) {
    emit(state.copyWith(sort: sort));
    load();
  }

  // Filters are set by constructing the state directly so a null value (the
  // "All" option) actually clears the filter (copyWith keeps the old value).
  void setCollectionFilter(String? collectionId) {
    emit(
      DesignsState(
        status: state.status,
        designs: state.designs,
        collectionId: collectionId,
        categoryId: null, // reset category when the collection changes
        statusFilter: state.statusFilter,
        search: state.search,
        sort: state.sort,
        pageSize: state.pageSize,
      ),
    );
    load();
  }

  void setCategoryFilter(String? categoryId) {
    emit(
      DesignsState(
        status: state.status,
        designs: state.designs,
        collectionId: state.collectionId,
        categoryId: categoryId,
        statusFilter: state.statusFilter,
        search: state.search,
        sort: state.sort,
        pageSize: state.pageSize,
      ),
    );
    load();
  }

  /// Clears search + collection + category filters and reloads (sort is kept).
  void clearFilters() {
    emit(
      DesignsState(
        status: state.status,
        designs: state.designs,
        sort: state.sort,
        pageSize: state.pageSize,
      ),
    );
    load();
  }

  Future<String?> create(DesignModel design) async {
    final result = await repository.createDesign(design);
    return result.fold((f) => f.message, (_) {
      load(forceRefresh: true);
      return null;
    });
  }

  Future<String?> update(DesignModel design) async {
    final result = await repository.updateDesign(design);
    return result.fold((f) => f.message, (_) {
      load(forceRefresh: true);
      return null;
    });
  }

  Future<String?> remove(String id) async {
    final images = state.designs
        .where((d) => d.id == id)
        .expand((d) => d.images)
        .toList();
    final result = await repository.deleteDesign(id);
    final err = result.fold((f) => f.message, (_) => null);
    if (err == null) {
      await imageStorage.deleteUrls(images);
      load(forceRefresh: true);
    }
    return err;
  }
}
