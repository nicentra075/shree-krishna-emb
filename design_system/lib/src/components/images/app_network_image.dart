import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';

import '../loaders/app_shimmer.dart';

/// Cached network image with shimmer placeholder, themed error state, and
/// optional memory-cache downscaling ([memCacheWidth]) for list thumbnails.
/// Renders a neutral placeholder when [imageUrl] is null/empty.
class AppNetworkImage extends StatelessWidget {
  final String? imageUrl;
  final double? width;
  final double? height;
  final BoxFit fit;
  final BorderRadius? borderRadius;

  /// Downscale decode size for grid/list thumbnails (logical px).
  final int? memCacheWidth;

  const AppNetworkImage({
    super.key,
    required this.imageUrl,
    this.width,
    this.height,
    this.fit = BoxFit.cover,
    this.borderRadius,
    this.memCacheWidth,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final radius = borderRadius ?? BorderRadius.circular(8);

    Widget fallback({required IconData icon}) {
      return Container(
        width: width,
        height: height,
        color: colorScheme.surfaceContainerHighest,
        child: Icon(
          icon,
          color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
          size: 24,
        ),
      );
    }

    final Widget image;
    if (imageUrl == null || imageUrl!.isEmpty) {
      image = fallback(icon: Icons.image_outlined);
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
