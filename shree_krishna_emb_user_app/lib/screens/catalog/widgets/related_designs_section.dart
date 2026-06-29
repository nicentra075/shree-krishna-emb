import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/widgets/favorite_heart.dart';

/// Two horizontal discovery lists shown at the bottom of a design's detail
/// screen so the user can keep browsing:
///  1. More designs from the same category (popularity sorted).
///  2. Sibling categories within the same collection (to explore further).
///
/// Both lists are loaded independently and each is hidden when it has no data,
/// so the section degrades gracefully when category/collection info is missing.
class RelatedDesignsSection extends StatefulWidget {
  final String currentDesignId;
  final String? categoryId;
  final String? collectionId;

  const RelatedDesignsSection({
    super.key,
    required this.currentDesignId,
    this.categoryId,
    this.collectionId,
  });

  @override
  State<RelatedDesignsSection> createState() => _RelatedDesignsSectionState();
}

class _RelatedDesignsSectionState extends State<RelatedDesignsSection> {
  List<DesignItem> _designs = const [];
  List<CategoryItem> _categories = const [];
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final ds = getIt<CatalogQueryDataSource>();
    try {
      final results = await Future.wait([
        widget.categoryId != null
            ? ds.designs(categoryId: widget.categoryId, sort: 'popularity')
            : Future.value(<DesignItem>[]),
        widget.collectionId != null
            ? ds.categories(collectionId: widget.collectionId)
            : Future.value(<CategoryItem>[]),
      ]);
      if (!mounted) return;
      final designs = (results[0] as List<DesignItem>)
          .where((d) => d.id != widget.currentDesignId)
          .take(12)
          .toList();
      // Drop the design's own category so the list nudges the user elsewhere.
      final categories = (results[1] as List<CategoryItem>)
          .where((c) => c.id != widget.categoryId)
          .take(12)
          .toList();
      setState(() {
        _designs = designs;
        _categories = categories;
        _loading = false;
      });
    } catch (_) {
      if (!mounted) return;
      setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_loading || (_designs.isEmpty && _categories.isEmpty)) {
      return const SizedBox.shrink();
    }
    final strings = AppLocalization.strings;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (_designs.isNotEmpty) ...[
          _header(strings.moreInThisCategory, strings.moreInThisCategorySubtitle),
          const SizedBox(height: 12),
          _designsList(),
          const SizedBox(height: 24),
        ],
        if (_categories.isNotEmpty) ...[
          _header(strings.exploreCategories, strings.exploreCategoriesSubtitle),
          const SizedBox(height: 12),
          _categoriesList(),
          const SizedBox(height: 24),
        ],
      ],
    );
  }

  Widget _header(String title, String subtitle) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: AppTextStyles.bodyLarge(fontWeight: FontWeight.bold),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: AppTextStyles.bodySmall(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  Widget _designsList() {
    return SizedBox(
      height: 214,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _designs.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _DesignCard(item: _designs[i]),
      ),
    );
  }

  Widget _categoriesList() {
    return SizedBox(
      height: 112,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) => _CategoryCard(item: _categories[i]),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final DesignItem item;
  const _DesignCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.navigateToDesignDetail(context, item.id),
      child: SizedBox(
        width: 150,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                  imageUrl: item.firstImageUrl,
                  width: 150,
                  height: 130,
                  borderRadius: BorderRadius.circular(12),
                ),
                Positioned(
                  top: 6,
                  right: 6,
                  child: FavoriteHeart(
                    designId: item.id,
                    title: item.name,
                    thumbUrl: item.firstImageUrl,
                    price: item.isFree ? 0 : item.finalPrice,
                    size: 18,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 2),
            Text(
              item.isFree
                  ? AppLocalization.strings.free
                  : '₹${item.finalPrice}',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: AppTextStyles.labelSmall(
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  final CategoryItem item;
  const _CategoryCard({required this.item});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => AppRoutes.navigateToViewAll(
        context,
        'category:${item.id}',
        title: item.name,
      ),
      child: SizedBox(
        width: 76,
        child: Column(
          children: [
            AppNetworkImage(
              imageUrl: item.imageUrl,
              width: 64,
              height: 64,
              borderRadius: BorderRadius.circular(32),
            ),
            const SizedBox(height: 6),
            Text(
              item.name,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall(),
            ),
          ],
        ),
      ),
    );
  }
}
