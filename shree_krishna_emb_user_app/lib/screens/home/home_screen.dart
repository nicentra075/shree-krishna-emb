import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

class HomeScreenContent extends StatefulWidget {
  const HomeScreenContent({super.key});

  @override
  State<HomeScreenContent> createState() => _HomeScreenContentState();
}

class _HomeScreenContentState extends State<HomeScreenContent> {
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Search Bar
          FadeInUp(
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to search screen
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.onSurfaceLight.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppTheme.onSurfaceLight.withValues(alpha: 0.12),
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.search,
                        color: AppTheme.onSurfaceLight.withValues(alpha: 0.5),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        'Search designs...',
                        style: AppTextStyles.bodyMedium(
                          color: AppTheme.onSurfaceLight.withValues(alpha: 0.5),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Category Filter
          FadeInUp(
            delay: const Duration(milliseconds: 100),
            duration: const Duration(milliseconds: 500),
            child: _buildCategoryFilter(),
          ),

          // Featured Section
          FadeInUp(
            delay: const Duration(milliseconds: 200),
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Featured Designs',
                        style: AppTextStyles.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to see all
                        },
                        child: Text(
                          'See All',
                          style: AppTextStyles.bodyMedium(
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildDesignGrid(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Trending Section
          FadeInUp(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Trending Now',
                        style: AppTextStyles.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to see all
                        },
                        child: Text(
                          'See All',
                          style: AppTextStyles.bodyMedium(
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildTrendingCarousel(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Recently Viewed
          FadeInUp(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 500),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Recently Viewed',
                        style: AppTextStyles.headlineMedium(),
                      ),
                      TextButton(
                        onPressed: () {
                          // TODO: Navigate to history
                        },
                        child: Text(
                          'View All',
                          style: AppTextStyles.bodyMedium(
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  _buildRecentlyViewedList(),
                ],
              ),
            ),
          ),

          const SizedBox(height: 32),
        ],
      ),
    );
  }

  Widget _buildCategoryFilter() {
    final categories = ['All', 'Saree', 'Suit', 'Lehenga', 'Dupatta', 'Shawl'];

    return SizedBox(
      height: 40,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: categories.length,
        itemBuilder: (context, index) {
          final category = categories[index];
          final isSelected = index == 0;

          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: FilterChip(
              selected: isSelected,
              label: Text(category),
              onSelected: (selected) {
                // TODO: Filter by category
              },
              backgroundColor: Colors.transparent,
              side: BorderSide(
                color: isSelected
                    ? AppTheme.primaryLight
                    : AppTheme.onSurfaceLight.withValues(alpha: 0.2),
              ),
              labelStyle: AppTextStyles.bodySmall(
                color: isSelected
                    ? AppTheme.primaryLight
                    : AppTheme.onSurfaceLight,
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildDesignGrid() {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        childAspectRatio: 0.75,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
      ),
      itemCount: 4,
      itemBuilder: (context, index) {
        return FadeInUp(
          delay: Duration(milliseconds: 300 + (index * 100)),
          duration: const Duration(milliseconds: 500),
          child: _buildDesignCard('Design ${index + 1}', '₹${1500 + (index * 500)}'),
        );
      },
    );
  }

  Widget _buildDesignCard(String name, String price) {
    return GestureDetector(
      onTap: () {
        // TODO: Navigate to design detail
      },
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          color: AppTheme.onSurfaceLight.withValues(alpha: 0.05),
          border: Border.all(
            color: AppTheme.onSurfaceLight.withValues(alpha: 0.1),
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Design Image Placeholder
            Container(
              height: 140,
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  Icons.image_outlined,
                  color: AppTheme.primaryLight.withValues(alpha: 0.3),
                  size: 40,
                ),
              ),
            ),
            // Design Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      name,
                      style: AppTextStyles.bodyMedium(
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'By Designer',
                      style: AppTextStyles.bodySmall(
                        color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                      ),
                    ),
                    const Spacer(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          price,
                          style: AppTextStyles.bodyMedium(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            color: AppTheme.primaryLight.withValues(alpha: 0.1),
                          ),
                          child: Icon(
                            Icons.favorite_border,
                            size: 16,
                            color: AppTheme.primaryLight,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTrendingCarousel() {
    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: 5,
        itemBuilder: (context, index) {
          return FadeInRight(
            delay: Duration(milliseconds: 400 + (index * 100)),
            duration: const Duration(milliseconds: 500),
            child: Container(
              width: 160,
              margin: const EdgeInsets.only(right: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                color: AppTheme.primaryLight.withValues(alpha: 0.1),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    height: 120,
                    width: double.infinity,
                    decoration: const BoxDecoration(
                      borderRadius: BorderRadius.only(
                        topLeft: Radius.circular(12),
                        topRight: Radius.circular(12),
                      ),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppTheme.primaryLight.withValues(alpha: 0.3),
                        size: 40,
                      ),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Trending Design ${index + 1}',
                          style: AppTextStyles.bodySmall(
                            fontWeight: FontWeight.w500,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '₹${2000 + (index * 300)}',
                          style: AppTextStyles.bodySmall(
                            color: AppTheme.primaryLight,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
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

  Widget _buildRecentlyViewedList() {
    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: 3,
      itemBuilder: (context, index) {
        return FadeInLeft(
          delay: Duration(milliseconds: 500 + (index * 150)),
          duration: const Duration(milliseconds: 500),
          child: Padding(
            padding: const EdgeInsets.only(bottom: 12),
            child: Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(8),
                color: AppTheme.onSurfaceLight.withValues(alpha: 0.05),
              ),
              child: Row(
                children: [
                  Container(
                    width: 60,
                    height: 60,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(8),
                      color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    ),
                    child: Center(
                      child: Icon(
                        Icons.image_outlined,
                        color: AppTheme.primaryLight.withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Embroidered Saree ${index + 1}',
                          style: AppTextStyles.bodyMedium(
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'By Designer Name',
                          style: AppTextStyles.bodySmall(
                            color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₹${3000 + (index * 500)}',
                        style: AppTextStyles.bodyMedium(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.primaryLight,
                        ),
                      ),
                      Icon(
                        Icons.favorite_border,
                        size: 18,
                        color: AppTheme.primaryLight,
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }
}
