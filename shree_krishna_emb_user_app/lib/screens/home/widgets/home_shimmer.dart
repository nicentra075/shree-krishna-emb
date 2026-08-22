import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

/// Loading skeleton for the Home feed — mirrors the real layout (banner + dots,
/// a "section header + horizontal design row", and a collections grid). Shown
/// while [HomeFeedStatus.loading]/initial instead of a spinner.
class HomeShimmer extends StatelessWidget {
  const HomeShimmer({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    // Theme-aware shimmer tones so it reads correctly in dark mode too.
    final base = colorScheme.onSurface.withValues(alpha: 0.08);
    final highlight = colorScheme.onSurface.withValues(alpha: 0.16);
    final bannerHeight = MediaQuery.of(context).size.width < 600
        ? 180.0
        : 220.0;

    return AppShimmer(
      baseColor: base,
      highlightColor: highlight,
      child: ListView(
        // Placeholder — not interactive.
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.only(top: 16, bottom: 24),
        children: [
          // ---- Banner + page dots ----
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: _box(double.infinity, bannerHeight, 16),
          ),
          const SizedBox(height: 12),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _box(20, 6, 3),
              const SizedBox(width: 6),
              _box(6, 6, 3),
              const SizedBox(width: 6),
              _box(6, 6, 3),
            ],
          ),
          const SizedBox(height: 24),

          // ---- Horizontal design row (e.g. Trending Designs) ----
          _sectionHeader(),
          const SizedBox(height: 12),
          _designRow(),
          const SizedBox(height: 28),

          // ---- Collections grid (e.g. New Collections) ----
          _sectionHeader(),
          const SizedBox(height: 12),
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Column(
              children: [
                Row(
                  children: [
                    Expanded(child: _box(double.infinity, 110, 12)),
                    const SizedBox(width: 12),
                    Expanded(child: _box(double.infinity, 110, 12)),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(child: _box(double.infinity, 110, 12)),
                    const SizedBox(width: 12),
                    Expanded(child: _box(double.infinity, 110, 12)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// A section title bar + "View All" bar.
  Widget _sectionHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [_box(160, 22, 6), _box(56, 16, 6)],
      ),
    );
  }

  /// A horizontal row of two-and-a-bit design-card skeletons.
  Widget _designRow() {
    return SizedBox(
      height: 210,
      child: ListView(
        scrollDirection: Axis.horizontal,
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16),
        children: [
          _designCard(),
          const SizedBox(width: 12),
          _designCard(),
          const SizedBox(width: 12),
          _designCard(),
        ],
      ),
    );
  }

  Widget _designCard() {
    return SizedBox(
      width: 170,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _box(170, 150, 12),
          const SizedBox(height: 8),
          _box(130, 14, 4),
          const SizedBox(height: 6),
          _box(70, 12, 4),
        ],
      ),
    );
  }

  /// Opaque rounded box — AppShimmer masks it with the moving gradient.
  Widget _box(double width, double height, double radius) {
    return Container(
      width: width,
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(radius),
      ),
    );
  }
}
