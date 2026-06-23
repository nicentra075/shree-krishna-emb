import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/widgets/favorite_heart.dart';

/// Generic paginated-ish list for a section's "View All" target.
/// Targets: `sellers`, `collections`, `collection:<id>`, `category:<id>`,
/// `designs?sort=<x>`, `designs`.
class ViewAllScreen extends StatefulWidget {
  final String target;

  /// Optional app-bar title (e.g. the originating section's title). Falls back
  /// to a target-derived label when null.
  final String? titleOverride;

  const ViewAllScreen({super.key, required this.target, this.titleOverride});

  @override
  State<ViewAllScreen> createState() => _ViewAllScreenState();
}

class _ViewAllScreenState extends State<ViewAllScreen> {
  List<HomeItem> _items = const [];
  bool _loading = true;
  String? _error;

  CatalogQueryDataSource get _ds => getIt<CatalogQueryDataSource>();

  @override
  void initState() {
    super.initState();
    _load();
  }

  String get _title {
    // Prefer the section's own title when provided by the caller.
    final override = widget.titleOverride;
    if (override != null && override.trim().isNotEmpty) return override;
    final strings = AppLocalization.strings;
    final t = widget.target;
    if (t.startsWith('sellers')) return strings.authorizedSellers;
    if (t == 'collections') return strings.exploreCollections;
    if (t.startsWith('collection:')) {
      // A collection drills into its categories; if it has none we fall back
      // to showing its designs, so title follows what actually loaded.
      if (_items.isNotEmpty && _items.first is DesignItem) return strings.designs;
      return strings.categories;
    }
    if (t.startsWith('category:')) return strings.designs;
    return strings.designs;
  }

  Future<void> _load() async {
    try {
      final t = widget.target;
      List<HomeItem> items;
      if (t == 'sellers') {
        items = await _ds.sellers();
      } else if (t == 'collections') {
        items = await _ds.collections();
      } else if (t.startsWith('collection:')) {
        // Drill into the collection's categories first; fall back to its
        // designs when the collection has no categories so it's never a dead end.
        final collectionId = t.substring('collection:'.length);
        final cats = await _ds.categories(collectionId: collectionId);
        items = cats.isNotEmpty
            ? cats
            : await _ds.designs(collectionId: collectionId);
      } else if (t.startsWith('category:')) {
        items = await _ds.designs(categoryId: t.substring('category:'.length));
      } else if (t.startsWith('designs?sort=')) {
        items = await _ds.designs(sort: t.substring('designs?sort='.length));
      } else {
        items = await _ds.designs();
      }
      if (!mounted) return;
      setState(() {
        _items = items;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = AppLocalization.strings.error;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(title: _title, onBack: () => Navigator.pop(context)),
      body: _loading
          ? const Center(child: AppLoader())
          : _error != null
              ? Center(child: Text(_error!))
              : _items.isEmpty
                  ? Center(child: Text(AppLocalization.strings.noData))
                  : _grid(),
    );
  }

  Widget _grid() {
    final isSellers = _items.first is SellerItem;
    final isDesigns = _items.first is DesignItem;
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _items.length,
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: isSellers ? 3 : 2,
        mainAxisSpacing: 12,
        crossAxisSpacing: 12,
        childAspectRatio: isSellers ? 0.8 : (isDesigns ? 0.72 : 1.4),
      ),
      itemBuilder: (context, i) => _card(_items[i]),
    );
  }

  Widget _card(HomeItem item) {
    return switch (item) {
      DesignItem d => GestureDetector(
          onTap: () => AppRoutes.navigateToDesignDetail(context, d.id),
          child: _designCard(d),
        ),
      CollectionItem c => GestureDetector(
          onTap: () =>
              AppRoutes.navigateToViewAll(context, 'collection:${c.id}'),
          child: _tileCard(c.name, c.imageUrl),
        ),
      SellerItem s => _sellerCard(s),
      CategoryItem c => GestureDetector(
          onTap: () => AppRoutes.navigateToViewAll(context, 'category:${c.id}'),
          child: _tileCard(c.name, c.imageUrl),
        ),
      _ => const SizedBox.shrink(),
    };
  }

  Widget _designCard(DesignItem d) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
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
                    imageUrl: d.firstImageUrl, width: double.infinity),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteHeart(
                    designId: d.id,
                    title: d.name,
                    thumbUrl: d.firstImageUrl,
                    price: d.isFree ? 0 : d.finalPrice,
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
                Text(d.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style:
                        AppTextStyles.labelSmall(fontWeight: FontWeight.w600)),
                Text(d.isFree ? AppLocalization.strings.free : '₹${d.finalPrice}',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppTextStyles.labelSmall(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _tileCard(String name, String? imageUrl) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Stack(fit: StackFit.expand, children: [
        if (imageUrl != null) AppNetworkImage(imageUrl: imageUrl, fit: BoxFit.cover),
        Container(color: Colors.black.withValues(alpha: 0.25)),
        Center(
          child: Padding(
            padding: const EdgeInsets.all(8),
            child: Text(name,
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium(
                    color: Colors.white, fontWeight: FontWeight.w700)),
          ),
        ),
      ]),
    );
  }

  Widget _sellerCard(SellerItem s) {
    return Column(
      children: [
        CircleAvatar(
          radius: 36,
          backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
          backgroundImage: (s.storeImageUrl != null && s.storeImageUrl!.isNotEmpty)
              ? NetworkImage(s.storeImageUrl!)
              : null,
          child: (s.storeImageUrl == null || s.storeImageUrl!.isEmpty)
              ? Icon(Icons.store, color: AppTheme.primaryLight)
              : null,
        ),
        const SizedBox(height: 6),
        Text(s.displayName,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall(fontWeight: FontWeight.w600)),
      ],
    );
  }
}
