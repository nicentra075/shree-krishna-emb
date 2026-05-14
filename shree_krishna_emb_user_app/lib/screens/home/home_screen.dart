import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class HomeScreenContent extends StatelessWidget {
  const HomeScreenContent({super.key});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Hero Banner
          _buildHeroBanner(context),
          const SizedBox(height: 24),

          // Authorized Sellers
          _buildAuthorizedSellers(context),
          const SizedBox(height: 24),

          // Trending Designs
          _buildTrendingDesigns(context),
          const SizedBox(height: 24),

          // Saree Designs
          _buildSareeDesigns(context),
          const SizedBox(height: 24),

          // Explore Collections
          _buildExploreCollections(context),
          const SizedBox(height: 24),

          // Recently Viewed
          _buildRecentlyViewed(context),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  static Widget _buildHeroBanner(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      height: 220,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Stack(
        children: [
          // Gradient overlay background
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryDark.withValues(alpha: 0.6),
                    AppTheme.secondaryLight.withValues(alpha: 0.3),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          // Content
          Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      AppLocalization.strings.newArrival2024,
                      style: AppTextStyles.labelSmall(
                        color: Colors.white,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      AppLocalization.strings.royalZardosiCollection,
                      style: AppTextStyles.headlineMedium(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                ElevatedButton(
                  onPressed: () {
                    // TODO: Navigate to collection
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryLight,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(24),
                    ),
                    padding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 10,
                    ),
                  ),
                  child: Text(
                    AppLocalization.strings.explore,
                    style: AppTextStyles.labelMedium(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildAuthorizedSellers(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    AppLocalization.strings.authorizedSellers,
                    style: AppTextStyles.headlineMedium(),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    AppLocalization.strings.verifiedArtisansStudios,
                    style: AppTextStyles.labelSmall(
                      color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                    ),
                  ),
                ],
              ),
              TextButton(
                onPressed: () {
                  // TODO: Navigate to all sellers
                },
                child: Text(
                  AppLocalization.strings.viewAll,
                  style: AppTextStyles.labelMedium(
                    color: AppTheme.primaryLight,
                  ),
                ),
              ),
            ],
          ),
        ),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildSellerCard('V. Textiles', true),
                const SizedBox(width: 12),
                _buildSellerCard('Surat Kraft', true),
                const SizedBox(width: 12),
                _buildSellerCard('Elite Motif', true),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildSellerCard(String name, bool isVerified) {
    return SizedBox(
      width: 100,
      child: Column(
        children: [
          Stack(
            children: [
              CircleAvatar(
                radius: 40,
                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.1),
                child: Icon(
                  Icons.store,
                  color: AppTheme.primaryLight,
                  size: 40,
                ),
              ),
              if (isVerified)
                Positioned(
                  bottom: 0,
                  right: 0,
                  child: Container(
                    decoration: BoxDecoration(
                      color: AppTheme.secondaryLight,
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.white,
                        width: 2,
                      ),
                    ),
                    padding: const EdgeInsets.all(4),
                    child: const Icon(
                      Icons.check,
                      color: Colors.white,
                      size: 12,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  static Widget _buildTrendingDesigns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.trendingDesigns,
            style: AppTextStyles.headlineMedium(),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildDesignCard('Golden Peacock Mandala', '₹1,249', 'Premium'),
                const SizedBox(width: 12),
                _buildDesignCard('Silver Lotus Border', '₹899', 'Classic'),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildDesignCard(String name, String price, String tier) {
    return Container(
      width: 160,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowestLight,
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(14),
                topRight: Radius.circular(14),
              ),
            ),
            child: Icon(
              Icons.image,
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(10),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      price,
                      style: AppTextStyles.labelMedium(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Icon(
                      Icons.favorite_border,
                      size: 16,
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    tier,
                    style: AppTextStyles.labelSmall(
                      color: AppTheme.secondaryDark,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildSareeDesigns(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.sareeDesigns,
            style: AppTextStyles.headlineMedium(),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildSareeDesignCard('Banarasi Fusion', '12,000+ Stitches'),
              const SizedBox(height: 12),
              _buildSareeDesignCard('Pastel Sequin Flora', '8,500+ Stitches'),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildSareeDesignCard(String name, String stitches) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowestLight,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 6,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowLight,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              Icons.image,
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.3),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 4),
                Text(
                  stitches,
                  style: AppTextStyles.labelSmall(
                    color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildExploreCollections(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.exploreCollections,
            style: AppTextStyles.headlineMedium(),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              Row(
                children: [
                  Expanded(child: _buildCollectionCard('Multi-head Designs')),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCollectionCard('Cording Designs')),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCollectionCard('Small Machine\nDesigns'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(child: _buildCollectionCard('Other\nCategories')),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildCollectionCard(String name) {
    return Container(
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.03),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          child: Text(
            name,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium(
              fontWeight: FontWeight.w600,
              color: AppTheme.onSurfaceLight,
            ),
          ),
        ),
      ),
    );
  }

  static Widget _buildRecentlyViewed(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.recentlyViewed,
            style: AppTextStyles.headlineMedium(),
          ),
        ),
        const SizedBox(height: 12),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildRecentlyViewedCard(),
                const SizedBox(width: 12),
                _buildRecentlyViewedCard(),
                const SizedBox(width: 12),
                _buildRecentlyViewedCard(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  static Widget _buildRecentlyViewedCard() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowLight,
        borderRadius: BorderRadius.circular(8),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 4,
            offset: const Offset(0, 1),
          ),
        ],
      ),
      child: Icon(
        Icons.image,
        color: AppTheme.onSurfaceLight.withValues(alpha: 0.3),
      ),
    );
  }
}
