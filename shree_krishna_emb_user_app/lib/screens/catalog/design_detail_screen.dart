import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/local_recently_viewed_store.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/catalog/image_viewer_screen.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/widgets/favorite_heart.dart';

class DesignDetailScreen extends StatefulWidget {
  final String designId;
  const DesignDetailScreen({super.key, required this.designId});

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  DesignDetail? _design;
  bool _loading = true;
  String? _error;

  final _galleryController = PageController();
  int _galleryIndex = 0;

  @override
  void initState() {
    super.initState();
    getIt<RecentlyViewedStore>().add(widget.designId);
    _load();
  }

  @override
  void dispose() {
    _galleryController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    try {
      final d = await getIt<CatalogQueryDataSource>().designById(widget.designId);
      if (!mounted) return;
      setState(() {
        _design = d;
        _loading = false;
        _error = d == null ? AppLocalization.strings.error : null;
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
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    final d = _design;
    return Scaffold(
      appBar: AppAppBar(
        title: d?.name ?? strings.loading,
        onBack: () => Navigator.pop(context),
      ),
      body: _loading
          ? const Center(child: AppLoader())
          : (d == null)
              ? Center(child: Text(_error ?? strings.error))
              : SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Stack(
                        children: [
                          _gallery(d),
                          Positioned(
                            top: 12,
                            right: 16,
                            child: FavoriteHeart(
                              designId: widget.designId,
                              title: d.name,
                              thumbUrl:
                                  d.images.isNotEmpty ? d.images.first : null,
                              price: d.isFree ? 0 : d.finalPrice,
                              size: 24,
                            ),
                          ),
                        ],
                      ),
                      Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(d.name,
                                style: AppTextStyles.headlineMedium(
                                    fontWeight: FontWeight.bold),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                            const SizedBox(height: 8),
                            _priceRow(d, colorScheme),
                            if (d.description != null) ...[
                              const SizedBox(height: 12),
                              Text(d.description!,
                                  style: AppTextStyles.bodyMedium(
                                      color: colorScheme.onSurfaceVariant)),
                            ],
                            const SizedBox(height: 16),
                            _specs(d, strings, colorScheme),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }

  Widget _gallery(DesignDetail d) {
    final colorScheme = Theme.of(context).colorScheme;
    if (d.images.isEmpty) {
      return AppNetworkImage(
          imageUrl: null, height: 280, width: double.infinity);
    }
    return Column(
      children: [
        SizedBox(
          height: 280,
          child: PageView.builder(
            controller: _galleryController,
            itemCount: d.images.length,
            onPageChanged: (i) => setState(() => _galleryIndex = i),
            itemBuilder: (context, i) => GestureDetector(
              onTap: () => _openViewer(d.images, i),
              child: AppNetworkImage(
                  imageUrl: d.images[i], height: 280, width: double.infinity),
            ),
          ),
        ),
        // Dot indicators (only when there's more than one image).
        if (d.images.length > 1) ...[
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
              d.images.length,
              (i) => AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                margin: const EdgeInsets.symmetric(horizontal: 3),
                width: i == _galleryIndex ? 18 : 6,
                height: 6,
                decoration: BoxDecoration(
                  color: i == _galleryIndex
                      ? AppTheme.primaryLight
                      : colorScheme.onSurfaceVariant.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(3),
                ),
              ),
            ),
          ),
        ],
      ],
    );
  }

  void _openViewer(List<String> images, int index) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => ImageViewerScreen(images: images, initialIndex: index),
      ),
    );
  }

  Widget _priceRow(DesignDetail d, ColorScheme colorScheme) {
    if (d.isFree) {
      return Text(AppLocalization.strings.free,
          style: AppTextStyles.headlineMedium(
              color: AppTheme.primaryLight, fontWeight: FontWeight.bold));
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text('₹${d.finalPrice}',
            style: AppTextStyles.headlineMedium(
                color: AppTheme.primaryLight, fontWeight: FontWeight.bold)),
        if (d.discountAmount > 0) ...[
          const SizedBox(width: 8),
          Text('₹${d.price}',
              style: AppTextStyles.bodyMedium(
                color: colorScheme.onSurfaceVariant,
              ).copyWith(decoration: TextDecoration.lineThrough)),
        ],
      ],
    );
  }

  Widget _specs(DesignDetail d, dynamic strings, ColorScheme colorScheme) {
    final rows = <(String, String)>[
      if ((d.code ?? '').isNotEmpty) (strings.code, d.code!),
      if ((d.authorName ?? '').isNotEmpty) (strings.authorName, d.authorName!),
      if ((d.colorOrNeedleCount ?? '').isNotEmpty)
        (strings.colorOrNeedleCount, d.colorOrNeedleCount!),
      if ((d.designFormat ?? '').isNotEmpty)
        (strings.designFormat, d.designFormat!),
      if (d.stitchCount > 0) (strings.stitchCount, '${d.stitchCount}'),
      if (d.height > 0 || d.width > 0)
        ('${strings.heightLabel} × ${strings.widthLabel}',
            '${d.height} × ${d.width}'),
    ];
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rows
          .map((r) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    SizedBox(
                      width: 140,
                      child: Text(r.$1,
                          style: AppTextStyles.labelMedium(
                              color: colorScheme.onSurfaceVariant),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis),
                    ),
                    Expanded(
                      child: Text(r.$2,
                          style: AppTextStyles.bodyMedium(
                              color: colorScheme.onSurface),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis),
                    ),
                  ],
                ),
              ))
          .toList(),
    );
  }
}
