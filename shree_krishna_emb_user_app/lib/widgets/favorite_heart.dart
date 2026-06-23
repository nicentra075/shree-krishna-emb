import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/bloc/wishlist/wishlist_cubit.dart';

/// A tappable heart that reflects + toggles the design's favorite state from the
/// app-wide [WishlistCubit]. Drop it on any design card or the detail screen.
class FavoriteHeart extends StatelessWidget {
  final String designId;
  final String title;
  final String? thumbUrl;

  /// Display price snapshot (rupees) stored on the wishlist item.
  final int price;
  final double size;

  /// When true (default) a translucent circular backdrop is drawn so the heart
  /// stays visible over imagery.
  final bool withBackground;

  const FavoriteHeart({
    super.key,
    required this.designId,
    required this.title,
    this.thumbUrl,
    this.price = 0,
    this.size = 20,
    this.withBackground = true,
  });

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WishlistCubit, WishlistState>(
      buildWhen: (prev, curr) =>
          prev.isFavorite(designId) != curr.isFavorite(designId),
      builder: (context, state) {
        final isFav = state.isFavorite(designId);
        // Over imagery (with backdrop) the outline is white; on a plain surface
        // it follows the theme so it stays visible in light and dark mode.
        final inactiveColor = withBackground
            ? Colors.white
            : Theme.of(context).colorScheme.onSurfaceVariant;
        final icon = Icon(
          isFav ? Icons.favorite : Icons.favorite_border,
          size: size,
          color: isFav ? const Color(0xFFE53935) : inactiveColor,
        );
        return GestureDetector(
          onTap: () => context.read<WishlistCubit>().toggle(
                designId: designId,
                title: title,
                thumbUrl: thumbUrl,
                price: price,
              ),
          child: withBackground
              ? Container(
                  padding: const EdgeInsets.all(6),
                  decoration: BoxDecoration(
                    color: Colors.black.withValues(alpha: 0.35),
                    shape: BoxShape.circle,
                  ),
                  child: icon,
                )
              : icon,
        );
      },
    );
  }
}
