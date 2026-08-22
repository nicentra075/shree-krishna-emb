import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

enum SearchStatus { initial, loading, loaded, error }

class SearchState extends Equatable {
  final String query;
  final SearchFilters filters;
  final List<DesignItem> results;
  final List<CategoryItem> categories;
  final SearchStatus status;
  final String? error;

  const SearchState({
    this.query = '',
    this.filters = const SearchFilters(),
    this.results = const [],
    this.categories = const [],
    this.status = SearchStatus.initial,
    this.error,
  });

  /// Nothing typed and no filters — show the "start typing" hint.
  bool get isIdle => query.trim().isEmpty && !filters.hasActiveFilters;

  SearchState copyWith({
    String? query,
    SearchFilters? filters,
    List<DesignItem>? results,
    List<CategoryItem>? categories,
    SearchStatus? status,
    String? error,
  }) {
    return SearchState(
      query: query ?? this.query,
      filters: filters ?? this.filters,
      results: results ?? this.results,
      categories: categories ?? this.categories,
      status: status ?? this.status,
      error: error,
    );
  }

  @override
  List<Object?> get props => [
    query,
    filters,
    results,
    categories,
    status,
    error,
  ];
}

/// Drives the search screen. Text debouncing lives in AppSearchBar; this cubit
/// guards against out-of-order responses with a request sequence number.
class SearchCubit extends Cubit<SearchState> {
  final CatalogQueryDataSource _catalog;
  int _seq = 0;

  SearchCubit({required CatalogQueryDataSource catalog})
    : _catalog = catalog,
      super(const SearchState());

  Future<void> loadCategories() async {
    try {
      final categories = await _catalog.categories();
      emit(state.copyWith(categories: categories));
    } catch (_) {
      // Filter sheet just shows no category chips — search itself still works.
    }
  }

  Future<void> updateQuery(String query) {
    emit(state.copyWith(query: query));
    return _run();
  }

  Future<void> applyFilters(SearchFilters filters) {
    emit(state.copyWith(filters: filters));
    return _run();
  }

  Future<void> clearFilters() {
    emit(state.copyWith(filters: SearchFilters(sort: state.filters.sort)));
    return _run();
  }

  Future<void> _run() async {
    final seq = ++_seq;
    if (state.isIdle) {
      emit(state.copyWith(status: SearchStatus.initial, results: const []));
      return;
    }
    emit(state.copyWith(status: SearchStatus.loading));
    try {
      final results = await _catalog.searchDesigns(
        query: state.query,
        filters: state.filters,
      );
      if (seq != _seq) return; // stale response — a newer search superseded it
      emit(state.copyWith(status: SearchStatus.loaded, results: results));
    } catch (e) {
      if (seq != _seq) return;
      emit(state.copyWith(status: SearchStatus.error, error: e.toString()));
    }
  }
}
