import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  int _currentBannerIndex = 0;
  late PageController _bannerController;

  // Banner data
  final List<Map<String, String>> _banners = [
    {'label': 'New Arrival 2024', 'title': 'Royal Zardosi Collection'},
    {'label': 'Special Offer', 'title': 'Premium Embroidery Designs'},
    {'label': 'Limited Edition', 'title': 'Exclusive Collections'},
  ];

  @override
  void initState() {
    super.initState();
    _bannerController = PageController();
    _startAutoPlay();
  }

  @override
  void dispose() {
    _bannerController.dispose();
    super.dispose();
  }

  void _startAutoPlay() {
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted && _bannerController.hasClients) {
        _bannerController.nextPage(
          duration: const Duration(milliseconds: 800),
          curve: Curves.easeInOutCubic,
        );
        _startAutoPlay();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          // Branding Section
          _buildBrandingSection(context),
          const SizedBox(height: 24),

          // Hero Banner
          _buildHeroBanner(context),
          const SizedBox(height: 32),

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

  static Widget _buildBrandingSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      decoration: BoxDecoration(
        color: AppTheme.primaryLight.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.strings.appName,
            style: AppTextStyles.headlineMedium(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            AppLocalization.strings.appTagline,
            style: AppTextStyles.bodySmall(
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.65),
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeroBanner(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final carouselHeight = screenSize.width < 600 ? 180.0 : 220.0;

    return Column(
      children: [
        SizedBox(
          height: carouselHeight,
          child: PageView.builder(
            controller: _bannerController,
            onPageChanged: (index) {
              setState(() {
                _currentBannerIndex = index % _banners.length;
              });
            },
            itemBuilder: (context, index) {
              final banner = _banners[index % _banners.length];
              return _buildBannerCard(banner['label']!, banner['title']!);
            },
          ),
        ),
        const SizedBox(height: 12),
        // Indicator dots
        Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(
            _banners.length,
            (index) => Container(
              width: _currentBannerIndex == index ? 24 : 8,
              height: 8,
              margin: const EdgeInsets.symmetric(horizontal: 4),
              decoration: BoxDecoration(
                color: _currentBannerIndex == index
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

  static Widget _buildBannerCard(String label, String title) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 360;
        final padding = isSmallScreen ? 16.0 : 24.0;

        return Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
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
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          label,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.labelSmall(
                            color: Colors.white,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          title,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
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
                        padding: EdgeInsets.symmetric(
                          horizontal: isSmallScreen ? 16 : 20,
                          vertical: 8,
                        ),
                      ),
                      child: Text(
                        AppLocalization.strings.explore,
                        style: AppTextStyles.labelSmall(
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 80;
        final avatarRadius = isSmallScreen ? 32.0 : 40.0;

        return SizedBox(
          width: constraints.maxWidth > 0 ? constraints.maxWidth : 100,
          child: Column(
            children: [
              Stack(
                children: [
                  CircleAvatar(
                    radius: avatarRadius,
                    backgroundColor: AppTheme.primaryLight.withValues(
                      alpha: 0.1,
                    ),
                    child: Icon(
                      Icons.store,
                      color: AppTheme.primaryLight,
                      size: avatarRadius - 10,
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
                          border: Border.all(color: Colors.white, width: 2),
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
              Expanded(
                child: Text(
                  name,
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall(fontWeight: FontWeight.w600),
                ),
              ),
            ],
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 140;
        final cardWidth = isSmallScreen ? 140.0 : 160.0;
        final imageHeight = isSmallScreen ? 100.0 : 120.0;
        final padding = isSmallScreen ? 8.0 : 10.0;

        return Container(
          width: cardWidth,
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
                height: imageHeight,
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
                padding: EdgeInsets.all(padding),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    SizedBox(
                      width: double.infinity,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              price,
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: AppTextStyles.labelSmall(
                                color: AppTheme.primaryLight,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          Icon(
                            Icons.favorite_border,
                            size: 14,
                            color: AppTheme.primaryLight,
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: AppTheme.secondaryLight.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        tier,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 300;
        final imageSize = isSmallScreen ? 70.0 : 80.0;
        final padding = isSmallScreen ? 10.0 : 12.0;

        return Container(
          padding: EdgeInsets.all(padding),
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
                width: imageSize,
                height: imageSize,
                decoration: BoxDecoration(
                  color: AppTheme.surfaceContainerLowLight,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Icon(
                  Icons.image,
                  color: AppTheme.onSurfaceLight.withValues(alpha: 0.3),
                  size: imageSize * 0.4,
                ),
              ),
              SizedBox(width: isSmallScreen ? 8 : 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      stitches,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
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
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 150;
        final cardHeight = isSmallScreen ? 80.0 : 100.0;

        return Container(
          height: cardHeight,
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
                maxLines: 3,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelSmall(
                  fontWeight: FontWeight.w600,
                  color: AppTheme.onSurfaceLight,
                ),
              ),
            ),
          ),
        );
      },
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
    return LayoutBuilder(
      builder: (context, constraints) {
        final isSmallScreen = constraints.maxWidth < 90;
        final cardSize = isSmallScreen ? 85.0 : 100.0;

        return Container(
          width: cardSize,
          height: cardSize,
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
            size: cardSize * 0.4,
          ),
        );
      },
    );
  }
}
