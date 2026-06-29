import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:shree_krishna_emb/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_emb/bloc/purchases/purchases_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_catalog_query_datasource.dart';
import 'package:shree_krishna_emb/data/datasources/firebase_order_writer.dart';
import 'package:shree_krishna_emb/data/datasources/local_recently_viewed_store.dart';
import 'package:shree_krishna_emb/domain/entities/order_draft.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/screens/catalog/image_viewer_screen.dart';
import 'package:shree_krishna_emb/screens/catalog/widgets/related_designs_section.dart';
import 'package:shree_krishna_emb/screens/purchases/my_purchases_screen.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/widgets/add_to_cart_button.dart';
import 'package:shree_krishna_emb/widgets/favorite_heart.dart';
import 'package:shree_krishna_emb/widgets/watermark_overlay.dart';

class DesignDetailScreen extends StatefulWidget {
  final String designId;

  /// True when opened from the My Purchases screen. The owned "My Purchases"
  /// CTA is redundant there, so it's hidden in that case.
  final bool fromPurchases;

  const DesignDetailScreen({
    super.key,
    required this.designId,
    this.fromPurchases = false,
  });

  @override
  State<DesignDetailScreen> createState() => _DesignDetailScreenState();
}

class _DesignDetailScreenState extends State<DesignDetailScreen> {
  DesignDetail? _design;
  bool _loading = true;
  String? _error;
  bool _claimingFree = false;

  final _galleryController = PageController();
  int _galleryIndex = 0;
  Timer? _autoPlayTimer;

  @override
  void initState() {
    super.initState();
    getIt<RecentlyViewedStore>().add(widget.designId);
    _load();
  }

  @override
  void dispose() {
    _autoPlayTimer?.cancel();
    _galleryController.dispose();
    super.dispose();
  }

  /// Auto-advances the gallery every few seconds. Restarted whenever the page
  /// changes (manually or programmatically) so the cadence stays steady and a
  /// user swipe isn't immediately overridden.
  void _startAutoPlay(int count) {
    _autoPlayTimer?.cancel();
    if (count <= 1) return;
    _autoPlayTimer = Timer.periodic(const Duration(seconds: 4), (_) {
      if (!mounted || !_galleryController.hasClients) return;
      final next = (_galleryIndex + 1) % count;
      _galleryController.animateToPage(
        next,
        duration: const Duration(milliseconds: 450),
        curve: Curves.easeInOut,
      );
    });
  }

  Future<void> _load() async {
    try {
      final d = await getIt<CatalogQueryDataSource>().designById(
        widget.designId,
      );
      if (!mounted) return;
      setState(() {
        _design = d;
        _loading = false;
        _error = d == null ? AppLocalization.strings.error : null;
      });
      if (d != null) _startAutoPlay(d.images.length);
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
      bottomNavigationBar: (d == null) ? null : _bottomActionBar(d),
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
                          thumbUrl: d.images.isNotEmpty ? d.images.first : null,
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
                        Text(
                          d.name,
                          style: AppTextStyles.headlineMedium(
                            fontWeight: FontWeight.bold,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 8),
                        _priceRow(d, colorScheme),
                        if ((d.description ?? '').trim().isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _sectionLabel(strings.designDescription),
                          const SizedBox(height: 8),
                          Text(
                            d.description!.trim(),
                            style: AppTextStyles.bodyMedium(
                              color: colorScheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                        if (_specRows(d, strings).isNotEmpty) ...[
                          const SizedBox(height: 20),
                          _sectionLabel(strings.designInformation),
                          const SizedBox(height: 10),
                          _specs(d, strings, colorScheme),
                        ],
                        // Design files are a My Purchases–only feature: shown
                        // strictly when the screen was opened from there (and the
                        // design is owned). Hidden everywhere in the catalog.
                        if (d.designFiles.isNotEmpty && widget.fromPurchases)
                          BlocBuilder<PurchasesCubit, PurchasesState>(
                            buildWhen: (prev, curr) =>
                                prev.isOwned(d.id) != curr.isOwned(d.id),
                            builder: (context, purchases) {
                              if (!purchases.isOwned(d.id)) {
                                return const SizedBox.shrink();
                              }
                              return Padding(
                                padding: const EdgeInsets.only(top: 20),
                                child: _downloads(
                                  d,
                                  strings,
                                  colorScheme,
                                  owned: true,
                                ),
                              );
                            },
                          ),
                      ],
                    ),
                  ),
                  // Discovery lists (full width, so placed outside the padded
                  // content column): more designs from this category + sibling
                  // categories to keep the user exploring.
                  RelatedDesignsSection(
                    currentDesignId: d.id,
                    categoryId: d.categoryId,
                    collectionId: d.collectionId,
                  ),
                  const SizedBox(height: 8),
                ],
              ),
            ),
    );
  }

  Widget _sectionLabel(String label) {
    return Text(
      label,
      style: AppTextStyles.bodyLarge(fontWeight: FontWeight.bold),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    );
  }

  Widget _gallery(DesignDetail d) {
    final colorScheme = Theme.of(context).colorScheme;
    if (d.images.isEmpty) {
      return AppNetworkImage(
        imageUrl: null,
        height: 280,
        width: double.infinity,
      );
    }
    return Column(
      children: [
        WatermarkOverlay(
          text: AppLocalization.strings.appName,
          color: Colors.white,
          child: SizedBox(
            height: 280,
            child: PageView.builder(
              controller: _galleryController,
              itemCount: d.images.length,
              onPageChanged: (i) {
                setState(() => _galleryIndex = i);
                // Keep the auto-advance cadence steady after any page change.
                _startAutoPlay(d.images.length);
              },
              itemBuilder: (context, i) => GestureDetector(
                onTap: () => _openViewer(d.images, i),
                child: AppNetworkImage(
                  imageUrl: d.images[i],
                  height: 280,
                  width: double.infinity,
                ),
              ),
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
      return Text(
        AppLocalization.strings.free,
        style: AppTextStyles.headlineMedium(
          color: AppTheme.primaryLight,
          fontWeight: FontWeight.bold,
        ),
      );
    }
    return Row(
      crossAxisAlignment: CrossAxisAlignment.end,
      children: [
        Text(
          '₹${d.finalPrice}',
          style: AppTextStyles.headlineMedium(
            color: AppTheme.primaryLight,
            fontWeight: FontWeight.bold,
          ),
        ),
        if (d.discountAmount > 0) ...[
          const SizedBox(width: 8),
          Text(
            '₹${d.price}',
            style: AppTextStyles.bodyMedium(
              color: colorScheme.onSurfaceVariant,
            ).copyWith(decoration: TextDecoration.lineThrough),
          ),
        ],
      ],
    );
  }

  List<(String, String)> _specRows(DesignDetail d, dynamic strings) {
    return <(String, String)>[
      if ((d.code ?? '').isNotEmpty) (strings.code, d.code!),
      if ((d.authorName ?? '').isNotEmpty) (strings.authorName, d.authorName!),
      if ((d.colorOrNeedleCount ?? '').isNotEmpty)
        (strings.colorOrNeedleCount, d.colorOrNeedleCount!),
      if (d.formatsForDisplay.isNotEmpty)
        (strings.designFormat, d.formatsForDisplay.join(', ')),
      if (d.stitchCount > 0) (strings.stitchCount, '${d.stitchCount}'),
      if (d.height > 0 || d.width > 0)
        (
          '${strings.heightLabel} × ${strings.widthLabel}',
          '${d.height} × ${d.width}',
        ),
    ];
  }

  Widget _specs(DesignDetail d, dynamic strings, ColorScheme colorScheme) {
    final rows = _specRows(d, strings);
    if (rows.isEmpty) return const SizedBox.shrink();
    return Column(
      children: rows
          .map(
            (r) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SizedBox(
                    width: 140,
                    child: Text(
                      r.$1,
                      style: AppTextStyles.labelMedium(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Expanded(
                    child: Text(
                      r.$2,
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _downloads(
    DesignDetail d,
    dynamic strings,
    ColorScheme colorScheme, {
    bool owned = false,
  }) {
    // Downloads are enabled only for designs the user owns. Free designs become
    // owned via "Get for Free"; until then their files stay hidden/locked.
    final canDownload = owned;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          strings.designFiles,
          style: AppTextStyles.bodyLarge(fontWeight: FontWeight.bold),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 10),
        ...d.designFiles.map(
          (f) => Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: colorScheme.outline.withValues(alpha: 0.3),
                ),
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.insert_drive_file_outlined,
                    color: AppTheme.primaryLight,
                    size: 22,
                  ),
                  const SizedBox(width: 10),
                  if (f.format.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.primaryLight.withValues(alpha: 0.14),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        f.format,
                        style: AppTextStyles.labelSmall(
                          color: AppTheme.primaryLight,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 10),
                  ],
                  Expanded(
                    child: Text(
                      f.name.isEmpty ? f.format : f.name,
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurface,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  canDownload
                      ? AppButton(
                          label: strings.download,
                          leadingIcon: Icons.download_outlined,
                          size: AppButtonSize.small,
                          onPressed: () => _downloadFile(f.url),
                        )
                      : Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.lock_outline,
                              size: 16,
                              color: colorScheme.onSurfaceVariant,
                            ),
                            const SizedBox(width: 4),
                            Flexible(
                              child: Text(
                                strings.purchaseToDownload,
                                style: AppTextStyles.labelSmall(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                            ),
                          ],
                        ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Sticky CTA reflecting ownership:
  ///  - owned        → "Owned" + a button to open My Purchases
  ///  - free         → "Get for Free" (writes a free purchase, then owned)
  ///  - paid         → Add-to-Cart / Go-to-Cart
  Widget _bottomActionBar(DesignDetail d) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    return BlocBuilder<PurchasesCubit, PurchasesState>(
      buildWhen: (prev, curr) => prev.isOwned(d.id) != curr.isOwned(d.id),
      builder: (context, purchases) {
        final owned = purchases.isOwned(d.id);

        // Already inside My Purchases → the "My Purchases" CTA is redundant, so
        // drop the bottom bar entirely for owned designs opened from there.
        if (owned && widget.fromPurchases) {
          return const SizedBox.shrink();
        }

        final Widget cta;
        if (owned) {
          cta = AppButton(
            label: strings.viewMyPurchases,
            leadingIcon: Icons.download_done_outlined,
            variant: AppButtonVariant.outlined,
            isFullWidth: true,
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(builder: (_) => const MyPurchasesScreen()),
            ),
          );
        } else if (d.isFree) {
          cta = AppButton(
            label: strings.getForFree,
            leadingIcon: Icons.download_outlined,
            isFullWidth: true,
            isLoading: _claimingFree,
            onPressed: _claimingFree ? null : () => _claimFree(d),
          );
        } else {
          cta = AddToCartButton(
            designId: d.id,
            title: d.name,
            thumbUrl: d.images.isNotEmpty ? d.images.first : null,
            price: d.finalPrice,
          );
        }
        return SafeArea(
          minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
          child: DecoratedBox(
            decoration: BoxDecoration(color: colorScheme.surface),
            child: cta,
          ),
        );
      },
    );
  }

  /// Records ownership for a free design via the client order writer (a paid
  /// order with total 0 + purchase docs), then refreshes ownership.
  Future<void> _claimFree(DesignDetail d) async {
    setState(() => _claimingFree = true);
    final config = context.read<PlatformConfigCubit>().state;
    final draft = OrderDraft.fromCart(
      items: [
        CartItemModel(
          designId: d.id,
          title: d.name,
          thumbUrl: d.images.isNotEmpty ? d.images.first : null,
          price: 0,
          addedAt: DateTime.now(),
        ),
      ],
      platformFeePercent: config.feePercent,
      gstPercent: config.gstPercent,
    );
    try {
      await getIt<FirebaseOrderWriter>().writePaidOrder(draft);
      if (!mounted) return;
      await context.read<PurchasesCubit>().refresh();
      if (!mounted) return;
      AppSnackbar.showSuccess(AppLocalization.strings.paymentSuccessMessage);
    } catch (e) {
      if (!mounted) return;
      AppSnackbar.showError(AppLocalization.strings.error);
    } finally {
      if (mounted) setState(() => _claimingFree = false);
    }
  }

  Future<void> _downloadFile(String url) async {
    final uri = Uri.tryParse(url);
    if (uri == null) {
      AppSnackbar.showError(AppLocalization.strings.error);
      return;
    }
    final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
    if (!ok) AppSnackbar.showError(AppLocalization.strings.error);
  }
}
