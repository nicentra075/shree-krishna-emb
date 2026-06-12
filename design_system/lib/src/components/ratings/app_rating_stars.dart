import 'package:flutter/material.dart';

/// Star rating widget.
///
/// Display mode (default): renders [rating] with fractional fill
/// (e.g. 4.3 → 4 full stars + 30% of the 5th).
/// Input mode: pass [onChanged] — taps select whole-star ratings 1..5.
class AppRatingStars extends StatelessWidget {
  final double rating;
  final double size;
  final ValueChanged<int>? onChanged;
  final Color? color;
  final int starCount;

  const AppRatingStars({
    super.key,
    this.rating = 0,
    this.size = 16,
    this.onChanged,
    this.color,
    this.starCount = 5,
  });

  bool get _isInput => onChanged != null;

  @override
  Widget build(BuildContext context) {
    final starColor = color ?? const Color(0xFFFFB300);
    final emptyColor =
        Theme.of(context).colorScheme.outline.withValues(alpha: 0.4);

    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(starCount, (index) {
        final fill = (rating - index).clamp(0.0, 1.0);
        final star = _buildStar(fill, starColor, emptyColor);
        if (!_isInput) return star;
        return GestureDetector(
          behavior: HitTestBehavior.opaque,
          onTap: () => onChanged!(index + 1),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 2),
            child: star,
          ),
        );
      }),
    );
  }

  Widget _buildStar(double fill, Color starColor, Color emptyColor) {
    if (fill >= 1) {
      return Icon(Icons.star_rounded, size: size, color: starColor);
    }
    if (fill <= 0) {
      return Icon(Icons.star_rounded, size: size, color: emptyColor);
    }
    // Fractional star: empty star with a clipped filled overlay.
    return Stack(
      children: [
        Icon(Icons.star_rounded, size: size, color: emptyColor),
        ClipRect(
          clipper: _FractionClipper(fill),
          child: Icon(Icons.star_rounded, size: size, color: starColor),
        ),
      ],
    );
  }
}

class _FractionClipper extends CustomClipper<Rect> {
  final double fraction;

  _FractionClipper(this.fraction);

  @override
  Rect getClip(Size size) =>
      Rect.fromLTRB(0, 0, size.width * fraction, size.height);

  @override
  bool shouldReclip(_FractionClipper oldClipper) =>
      oldClipper.fraction != fraction;
}
