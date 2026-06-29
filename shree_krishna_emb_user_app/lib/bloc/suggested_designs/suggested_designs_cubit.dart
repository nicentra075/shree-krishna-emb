import 'dart:math';

import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';

enum SuggestedDesignsStatus { initial, loading, loaded, error }

/// Holds a small list of designs picked from a random active category, shown to
/// the user as "Suggested for you" so they can discover and buy more designs.
class SuggestedDesignsState extends Equatable {
  final SuggestedDesignsStatus status;

  /// The category the suggestions were drawn from (null when pulled from the
  /// broad catalog as a fallback).
  final String? categoryName;
  final List<DesignItem> designs;
  final String? error;

  const SuggestedDesignsState({
    this.status = SuggestedDesignsStatus.initial,
    this.categoryName,
    this.designs = const [],
    this.error,
  });

  @override
  List<Object?> get props => [status, categoryName, designs, error];
}

/// Loads a handful of suggested designs from a randomly chosen category. Falls
/// back to the broad catalog when the picked category is empty.
class SuggestedDesignsCubit extends Cubit<SuggestedDesignsState> {
  final CatalogQueryDataSource catalog;
  final Random _random = Random();

  static const int _maxSuggestions = 10;

  SuggestedDesignsCubit({required this.catalog})
    : super(const SuggestedDesignsState());

  Future<void> load() async {
    if (state.status == SuggestedDesignsStatus.loading) return;
    emit(const SuggestedDesignsState(status: SuggestedDesignsStatus.loading));

    try {
      // Pick a random active category to seed the suggestions.
      final categories = await catalog.categories();
      String? categoryId;
      String? categoryName;
      if (categories.isNotEmpty) {
        final picked = categories[_random.nextInt(categories.length)];
        categoryId = picked.id;
        categoryName = picked.name;
      }

      var designs = await catalog.designs(
        categoryId: categoryId,
        sort: 'popularity',
      );

      // If that category has no live designs, fall back to the whole catalog.
      if (designs.isEmpty) {
        designs = await catalog.designs(sort: 'popularity');
        categoryName = null;
      }

      designs = List<DesignItem>.of(designs)..shuffle(_random);
      final limited = designs.take(_maxSuggestions).toList();

      if (isClosed) return;
      emit(
        SuggestedDesignsState(
          status: SuggestedDesignsStatus.loaded,
          categoryName: categoryName,
          designs: limited,
        ),
      );
    } catch (e) {
      if (isClosed) return;
      emit(
        SuggestedDesignsState(
          status: SuggestedDesignsStatus.error,
          error: e.toString(),
        ),
      );
    }
  }
}
