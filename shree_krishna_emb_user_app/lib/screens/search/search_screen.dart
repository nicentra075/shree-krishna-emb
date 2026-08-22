import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/search/search_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/screens/search/widgets/filter_sheet.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/widgets/favorite_heart.dart';

/// Full-text product search with a filter sheet (category, price, free-only)
/// and sort presets. WS-B1.
class SearchScreen extends StatefulWidget {
  const SearchScreen({super.key});

  @override
  State<SearchScreen> createState() => _SearchScreenState();
}

class _SearchScreenState extends State<SearchScreen> {
  late final SearchCubit _cubit;

  @override
  void initState() {
    super.initState();
    _cubit = getIt<SearchCubit>();
    _cubit.loadCategories();
  }

  @override
  void dispose() {
    _cubit.close();
    super.dispose();
  }

  Future<void> _openFilters(SearchState state) async {
    final applied = await showModalBottomSheet<SearchFilters>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => SearchFilterSheet(
        initial: state.filters,
        categories: state.categories,
      ),
    );
    if (applied != null) {
      _cubit.applyFilters(applied);
    }
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    return BlocProvider.value(
      value: _cubit,
      child: Scaffold(
        appBar: AppAppBar(
          title: strings.search,
          onBack: () => Navigator.pop(context),
        ),
        body: SafeArea(
          child: BlocBuilder<SearchCubit, SearchState>(
            builder: (context, state) {
              return Column(
                children: [
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                    child: Row(
                      children: [
                        Expanded(
                          child: AppSearchBar(
                            hint: strings.searchProducts,
                            autofocus: true,
                            onChanged: _cubit.updateQuery,
                          ),
                        ),
                        const SizedBox(width: 12),
                        _FilterButton(
                          active: state.filters.hasActiveFilters,
                          onTap: () => _openFilters(state),
                        ),
                      ],
                    ),
                  ),
                  if (state.filters.hasActiveFilters)
                    _ActiveFilterChips(state: state),
                  Expanded(child: _buildBody(state, strings)),
                ],
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildBody(SearchState state, dynamic strings) {
    switch (state.status) {
      case SearchStatus.initial:
        return AppEmptyState(
          icon: Icons.search,
          message: strings.searchStartTyping,
        );
      case SearchStatus.loading:
        return const Center(child: AppLoader());
      case SearchStatus.error:
        return AppEmptyState(
          icon: Icons.error_outline,
          message: strings.somethingWentWrong,
          actionLabel: strings.retry,
          onAction: () => _cubit.updateQuery(state.query),
        );
      case SearchStatus.loaded:
        if (state.results.isEmpty) {
          return AppEmptyState(
            icon: Icons.search_off,
            message: strings.noResults,
          );
        }
        return GridView.builder(
          padding: const EdgeInsets.all(16),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            childAspectRatio: 0.72,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: state.results.length,
          itemBuilder: (context, i) =>
              _SearchResultCard(design: state.results[i]),
        );
    }
  }
}

class _FilterButton extends StatelessWidget {
  final bool active;
  final VoidCallback onTap;

  const _FilterButton({required this.active, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: active
              ? colorScheme.primary
              : colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: colorScheme.outlineVariant),
        ),
        child: Icon(
          Icons.tune,
          size: 20,
          color: active ? colorScheme.onPrimary : colorScheme.onSurface,
        ),
      ),
    );
  }
}

class _ActiveFilterChips extends StatelessWidget {
  final SearchState state;

  const _ActiveFilterChips({required this.state});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final filters = state.filters;
    final cubit = context.read<SearchCubit>();

    String? categoryName;
    if (filters.categoryId != null) {
      for (final c in state.categories) {
        if (c.id == filters.categoryId) {
          categoryName = c.name;
          break;
        }
      }
    }

    final chips = <Widget>[
      if (categoryName != null)
        _chip(
          context,
          categoryName,
          () => cubit.applyFilters(filters.copyWith(clearCategory: true)),
        ),
      if (filters.minPrice != null || filters.maxPrice != null)
        _chip(
          context,
          '₹${filters.minPrice ?? 0} - ${filters.maxPrice != null ? '₹${filters.maxPrice}' : '∞'}',
          () => cubit.applyFilters(
            filters.copyWith(clearMinPrice: true, clearMaxPrice: true),
          ),
        ),
      if (filters.freeOnly)
        _chip(
          context,
          strings.freeOnly,
          () => cubit.applyFilters(filters.copyWith(freeOnly: false)),
        ),
      TextButton(
        onPressed: cubit.clearFilters,
        child: Text(
          strings.clearFilters,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: AppTextStyles.labelSmall(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    ];

    return SizedBox(
      height: 44,
      child: ListView(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
        children: [
          for (final c in chips)
            Padding(padding: const EdgeInsets.only(right: 8), child: c),
        ],
      ),
    );
  }

  Widget _chip(BuildContext context, String label, VoidCallback onRemove) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            label,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall(color: colorScheme.onSurface),
          ),
          const SizedBox(width: 4),
          GestureDetector(
            onTap: onRemove,
            child: Icon(Icons.close, size: 14, color: colorScheme.onSurface),
          ),
        ],
      ),
    );
  }
}

class _SearchResultCard extends StatelessWidget {
  final DesignItem design;

  const _SearchResultCard({required this.design});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;
    return GestureDetector(
      onTap: () => AppRoutes.navigateToDesignDetail(context, design.id),
      child: Container(
        clipBehavior: Clip.antiAlias,
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Stack(
                fit: StackFit.expand,
                children: [
                  AppNetworkImage(
                    imageUrl: design.firstImageUrl,
                    width: double.infinity,
                  ),
                  Positioned(
                    top: 8,
                    right: 8,
                    child: FavoriteHeart(
                      designId: design.id,
                      title: design.name,
                      thumbUrl: design.firstImageUrl,
                      price: design.isFree ? 0 : design.finalPrice,
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    design.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          design.isFree
                              ? strings.free
                              : '₹${design.finalPrice}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ),
                      if (design.reviewCount > 0) ...[
                        Icon(
                          Icons.star_rounded,
                          size: 14,
                          color: Colors.amber.shade600,
                        ),
                        Text(
                          design.avgRating.toStringAsFixed(1),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall(
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
