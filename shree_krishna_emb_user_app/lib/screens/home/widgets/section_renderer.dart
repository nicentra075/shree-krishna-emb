import 'dart:async';

import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/domain/entities/home_feed.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/widgets/favorite_heart.dart';

/// Maps a [HomeSection] to its widget. [onNavigate] receives a target string
/// (e.g. `design:<id>`, `collection:<id>`, `sellers`, or a banner ctaTarget);
/// Phase D wires it to real navigation.
class SectionRenderer extends StatelessWidget {
  final HomeSection section;
  final void Function(String? target) onNavigate;

  /// Optional handler for the "View All" button so the destination can carry
  /// the section's title. Falls back to [onNavigate] when not provided.
  final void Function(String? target, String? title)? onViewAll;

  const SectionRenderer({
    super.key,
    required this.section,
    required this.onNavigate,
    this.onViewAll,
  });

  @override
  Widget build(BuildContext context) {
    if (section.items.isEmpty) return const SizedBox.shrink();
    final body = switch (section.type) {
      HomeSectionType.banner =>
        _BannerCarousel(items: section.items.whereType<BannerItem>().toList(), onNavigate: onNavigate),
      HomeSectionType.authorisedSellersHorizontal =>
        _SellersRow(items: section.items.whereType<SellerItem>().toList(), onNavigate: onNavigate),
      HomeSectionType.designsHorizontal =>
        _DesignsRow(items: section.items.whereType<DesignItem>().toList(), onNavigate: onNavigate),
      HomeSectionType.designsVertical =>
        _DesignsVertical(items: section.items.whereType<DesignItem>().toList(), onNavigate: onNavigate),
      HomeSectionType.collectionsGrid =>
        _CollectionsGrid(items: section.items.whereType<CollectionItem>().toList(), onNavigate: onNavigate),
      HomeSectionType.categoriesHorizontal =>
        _CategoriesRow(items: section.items.whereType<CategoryItem>().toList(), onNavigate: onNavigate),
      HomeSectionType.recentlyViewed =>
        _DesignsRow(items: section.items.whereType<DesignItem>().toList(), onNavigate: onNavigate),
    };

    final showHeader = section.type != HomeSectionType.banner;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (showHeader) _header(context),
        body,
        const SizedBox(height: 24),
      ],
    );
  }

  /// Where "View All" navigates. Uses the admin-configured target when set,
  /// otherwise falls back to a sensible default based on the section type so
  /// the button is never a dead end.
  String get _viewAllTarget {
    final configured = section.viewAll.target;
    if (configured != null && configured.isNotEmpty) return configured;
    final boundCollection = section.sourceCollectionId;
    return switch (section.type) {
      HomeSectionType.collectionsGrid => 'collections',
      // A category row bound to a collection opens that collection's
      // categories; otherwise fall back to all collections.
      HomeSectionType.categoriesHorizontal =>
        (boundCollection != null && boundCollection.isNotEmpty)
            ? 'collection:$boundCollection'
            : 'collections',
      HomeSectionType.authorisedSellersHorizontal => 'sellers',
      _ => 'designs',
    };
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Expanded(
            child: Text(
              section.title ?? '',
              style: AppTextStyles.headlineMedium(),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (section.viewAll.enabled)
            TextButton(
              onPressed: () => onViewAll != null
                  ? onViewAll!(_viewAllTarget, section.title)
                  : onNavigate(_viewAllTarget),
              child: Text(
                AppLocalization.strings.viewAll,
                style: AppTextStyles.labelMedium(color: AppTheme.primaryLight),
              ),
            ),
        ],
      ),
    );
  }
}

// ---------------- Banner ----------------
class _BannerCarousel extends StatefulWidget {
  final List<BannerItem> items;
  final void Function(String?) onNavigate;
  const _BannerCarousel({required this.items, required this.onNavigate});

  @override
  State<_BannerCarousel> createState() => _BannerCarouselState();
}

class _BannerCarouselState extends State<_BannerCarousel> {
  final _controller = PageController();
  int _index = 0;
  Timer? _autoPlay;

  @override
  void initState() {
    super.initState();
    if (widget.items.length > 1) {
      _autoPlay = Timer.periodic(const Duration(seconds: 4), (_) {
        if (!mounted || !_controller.hasClients) return;
        final next = (_index + 1) % widget.items.length;
        _controller.animateToPage(
          next,
          duration: const Duration(milliseconds: 450),
          curve: Curves.easeInOut,
        );
      });
    }
  }

  @override
  void dispose() {
    _autoPlay?.cancel();
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final height = screenWidth < 600 ? 180.0 : 220.0;
    return Column(
      children: [
        SizedBox(
          height: height,
          child: PageView.builder(
            controller: _controller,
            onPageChanged: (i) => setState(() => _index = i),
            itemCount: widget.items.length,
            itemBuilder: (context, i) {
              final b = widget.items[i];
              return GestureDetector(
                onTap: () => widget.onNavigate(b.ctaTarget),
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  clipBehavior: Clip.antiAlias,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      AppNetworkImage(imageUrl: b.imageUrl, fit: BoxFit.cover),
                      Container(
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            colors: [
                              Colors.black.withValues(alpha: 0.45),
                              Colors.transparent,
                            ],
                            begin: Alignment.bottomLeft,
                            end: Alignment.topRight,
                          ),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.all(20),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            if (b.label != null)
                              Text(b.label!,
                                  style: AppTextStyles.labelSmall(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w600),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis),
                            if (b.title != null)
                              Text(b.title!,
                                  style: AppTextStyles.headlineMedium(
                                      color: Colors.white,
                                      fontWeight: FontWeight.bold),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            widget.items.length,
            (i) => Container(
              width: _index == i ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _index == i
                    ? AppTheme.primaryLight
                    : AppTheme.onSurfaceLight.withValues(alpha: 0.2),
                borderRadius: BorderRadius.circular(4),
              ),
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- Sellers ----------------
class _SellersRow extends StatelessWidget {
  final List<SellerItem> items;
  final void Function(String?) onNavigate;
  const _SellersRow({required this.items, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 110,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final s = items[i];
          return GestureDetector(
            onTap: () => onNavigate('seller:${s.uid}'),
            child: SizedBox(
              width: 84,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 36,
                    backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                    backgroundImage:
                        (s.storeImageUrl != null && s.storeImageUrl!.isNotEmpty)
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
                      style:
                          AppTextStyles.labelSmall(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Designs (horizontal) ----------------
class _DesignsRow extends StatelessWidget {
  final List<DesignItem> items;
  final void Function(String?) onNavigate;
  const _DesignsRow({required this.items, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 190,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        // Align to the top so the card sizes to its content instead of being
        // stretched to the row height (which left a tall blank area below the
        // price and an apparent gap before the next section).
        itemBuilder: (context, i) => Align(
          alignment: Alignment.topCenter,
          child: SizedBox(
            width: 160,
            child: _DesignCard(item: items[i], onNavigate: onNavigate),
          ),
        ),
      ),
    );
  }
}

// ---------------- Designs (vertical) ----------------
class _DesignsVertical extends StatelessWidget {
  final List<DesignItem> items;
  final void Function(String?) onNavigate;
  const _DesignsVertical({required this.items, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: items
            .map((d) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: GestureDetector(
                    onTap: () => onNavigate('design:${d.id}'),
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: colorScheme.surfaceContainerLowest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(children: [
                        AppNetworkImage(
                            imageUrl: d.firstImageUrl,
                            width: 72,
                            height: 72,
                            borderRadius: BorderRadius.circular(8)),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(d.name,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelMedium(
                                      fontWeight: FontWeight.w600)),
                              const SizedBox(height: 4),
                              Text(d.isFree ? AppLocalization.strings.free : '₹${d.finalPrice}',
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.labelSmall(
                                      color: AppTheme.primaryLight,
                                      fontWeight: FontWeight.bold)),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        FavoriteHeart(
                          designId: d.id,
                          title: d.name,
                          thumbUrl: d.firstImageUrl,
                          price: d.isFree ? 0 : d.finalPrice,
                          withBackground: false,
                        ),
                      ]),
                    ),
                  ),
                ))
            .toList(),
      ),
    );
  }
}

class _DesignCard extends StatelessWidget {
  final DesignItem item;
  final void Function(String?) onNavigate;
  const _DesignCard({required this.item, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return GestureDetector(
      onTap: () => onNavigate('design:${item.id}'),
      child: Container(
        decoration: BoxDecoration(
          color: colorScheme.surfaceContainerLowest,
          borderRadius: BorderRadius.circular(14),
        ),
        clipBehavior: Clip.antiAlias,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Stack(
              children: [
                AppNetworkImage(
                    imageUrl: item.firstImageUrl,
                    height: 120,
                    width: double.infinity),
                Positioned(
                  top: 8,
                  right: 8,
                  child: FavoriteHeart(
                    designId: item.id,
                    title: item.name,
                    thumbUrl: item.firstImageUrl,
                    price: item.isFree ? 0 : item.finalPrice,
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(item.name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTextStyles.labelSmall(fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  Text(item.isFree ? AppLocalization.strings.free : '₹${item.finalPrice}',
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
      ),
    );
  }
}

// ---------------- Collections ----------------
class _CollectionsGrid extends StatelessWidget {
  final List<CollectionItem> items;
  final void Function(String?) onNavigate;
  const _CollectionsGrid({required this.items, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: GridView.builder(
        shrinkWrap: true,
        physics: const NeverScrollableScrollPhysics(),
        itemCount: items.length,
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          mainAxisSpacing: 12,
          crossAxisSpacing: 12,
          childAspectRatio: 1.6,
        ),
        itemBuilder: (context, i) {
          final c = items[i];
          return GestureDetector(
            onTap: () => onNavigate('collection:${c.id}'),
            child: Container(
              clipBehavior: Clip.antiAlias,
              decoration: BoxDecoration(
                color: AppTheme.secondaryLight.withValues(alpha: 0.12),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Stack(
                fit: StackFit.expand,
                children: [
                  if (c.imageUrl != null)
                    AppNetworkImage(imageUrl: c.imageUrl, fit: BoxFit.cover),
                  Container(color: Colors.black.withValues(alpha: 0.25)),
                  Center(
                    child: Padding(
                      padding: const EdgeInsets.all(8),
                      child: Text(c.name,
                          textAlign: TextAlign.center,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelMedium(
                              color: Colors.white, fontWeight: FontWeight.w700)),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

// ---------------- Categories ----------------
class _CategoriesRow extends StatelessWidget {
  final List<CategoryItem> items;
  final void Function(String?) onNavigate;
  const _CategoriesRow({required this.items, required this.onNavigate});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 100,
      child: ListView.separated(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: items.length,
        separatorBuilder: (_, _) => const SizedBox(width: 12),
        itemBuilder: (context, i) {
          final c = items[i];
          return GestureDetector(
            onTap: () => onNavigate('category:${c.id}'),
            child: SizedBox(
              width: 80,
              child: Column(
                children: [
                  AppNetworkImage(
                      imageUrl: c.imageUrl,
                      width: 64,
                      height: 64,
                      borderRadius: BorderRadius.circular(32)),
                  const SizedBox(height: 6),
                  Text(c.name,
                      textAlign: TextAlign.center,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style:
                          AppTextStyles.labelSmall(fontWeight: FontWeight.w600)),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
