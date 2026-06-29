import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../loaders/app_shimmer.dart';

/// Cached network image with shimmer placeholder, themed error state, and
/// optional memory-cache downscaling ([memCacheWidth]) for list thumbnails.
///
/// Renders a branded, intentional **placeholder** when [imageUrl] is null/empty
/// (e.g. an admin saved a collection/category/design without an image) or when
/// the image fails to load — a soft tinted background with a centred icon that
/// scales to the available space. Pass [placeholderIcon] to tailor it per
/// content type (e.g. `Icons.collections_bookmark_outlined` for collections).
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Downscale decode size for grid/list thumbnails (logical px).
  final int? memCacheWidth;

  /// Icon shown in the placeholder when [imageUrl] is null/empty.
  final IconData placeholderIcon;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
    this.placeholderIcon = Icons.image_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(8);

    Widget fallback({required IconData icon}) {
      return Container(
        width: width,
        height: height,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              colorScheme.surfaceContainerHighest,
              colorScheme.surfaceContainerHigh,
            ],
          ),
        ),
        child: LayoutBuilder(
          builder: (context, c) {
            // Scale the icon to the available space so it reads as a real
            // placeholder at any size (thumbnail → full-width banner).
            final side = (c.hasBoundedWidth && c.hasBoundedHeight)
                ? (c.maxWidth < c.maxHeight ? c.maxWidth : c.maxHeight)
                : 96.0;
            final iconSize = (side * 0.38).clamp(18.0, 64.0);
            return Center(
              child: Icon(
                icon,
                size: iconSize,
                color: colorScheme.onSurfaceVariant.withValues(alpha: 0.45),
              ),
            );
          },
        ),
      );
    }

    final Widget image;
    if (imageUrl == null || imageUrl!.isEmpty) {
      image = fallback(icon: placeholderIcon);
    } else {
      image = CachedNetworkImage(
        imageUrl: imageUrl!,
        width: width,
        height: height,
        fit: fit,
        memCacheWidth: memCacheWidth,
        placeholder: (context, url) => AppShimmer(
          child: Container(
            width: width,
            height: height,
            color: colorScheme.surfaceContainerHighest,
          ),
        ),
        errorWidget: (context, url, error) =>
            fallback(icon: Icons.broken_image_outlined),
      );
    }

    return ClipRRect(borderRadius: radius, child: image);
  }
}
