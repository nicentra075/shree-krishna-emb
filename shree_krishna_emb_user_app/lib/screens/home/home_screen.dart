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
      height: 180,
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Stack(
        children: [
          Positioned.fill(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                gradient: LinearGradient(
                  colors: [
                    AppTheme.secondaryDark,
                    AppTheme.secondaryLight,
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(20),
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
                      ),
                    ),
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
                  ),
                  child: Text(AppLocalization.strings.explore),
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
              Text(
                AppLocalization.strings.authorizedSellers,
                style: AppTextStyles.headlineMedium(),
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
    return Container(
      width: 140,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowestLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: Column(
        children: [
          CircleAvatar(
            radius: 28,
            backgroundColor: AppTheme.secondaryLight,
            child: Icon(
              Icons.store,
              color: Colors.white,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            name,
            textAlign: TextAlign.center,
            style: AppTextStyles.labelMedium(),
          ),
          if (isVerified) ...[
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Icons.check_circle,
                  size: 14,
                  color: AppTheme.primaryLight,
                ),
                const SizedBox(width: 4),
                Text(
                  AppLocalization.strings.verified,
                  style: AppTextStyles.labelSmall(
                    color: AppTheme.primaryLight,
                  ),
                ),
              ],
            ),
          ],
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
                _buildDesignCard(
                  'Golden Peacock Mandala',
                  '₹1,249',
                  'Premium',
                ),
                const SizedBox(width: 12),
                _buildDesignCard(
                  'Silver Lotus Border',
                  '₹899',
                  'Classic',
                ),
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
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            height: 120,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowLight,
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(12),
                topRight: Radius.circular(12),
              ),
            ),
            child: Icon(
              Icons.image,
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.3),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium(),
                ),
                const SizedBox(height: 4),
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
                const SizedBox(height: 4),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 6,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.secondaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    tier,
                    style: AppTextStyles.labelSmall(
                      color: AppTheme.secondaryDark,
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
              _buildSareeDesignCard(
                'Banarasi Fusion',
                '12,000+ Stitches',
              ),
              const SizedBox(height: 12),
              _buildSareeDesignCard(
                'Pastel Sequin Flora',
                '8,500+ Stitches',
              ),
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
        color: AppTheme.surfaceContainerLowLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.borderLight,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 80,
            height: 80,
            decoration: BoxDecoration(
              color: AppTheme.surfaceContainerLowestLight,
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
                  style: AppTextStyles.labelMedium(
                    fontWeight: FontWeight.w600,
                  ),
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
                  Expanded(
                    child: _buildCollectionCard('Multi-head Designs'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCollectionCard('Cording Designs'),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: _buildCollectionCard('Small Machine\nDesigns'),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildCollectionCard('Other\nCategories'),
                  ),
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
        color: AppTheme.secondaryLight.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Text(
          name,
          textAlign: TextAlign.center,
          style: AppTextStyles.labelMedium(
            fontWeight: FontWeight.w600,
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
      ),
      child: Icon(
        Icons.image,
        color: AppTheme.onSurfaceLight.withValues(alpha: 0.3),
      ),
    );
  }
}
