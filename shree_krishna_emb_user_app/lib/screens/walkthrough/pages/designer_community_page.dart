import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_emb/utils/constants.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

class DesignerCommunityPage extends StatefulWidget {
  const DesignerCommunityPage({super.key});

  @override
  State<DesignerCommunityPage> createState() => _DesignerCommunityPageState();
}

class _DesignerCommunityPageState extends State<DesignerCommunityPage> {
  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            const Color(0xFFFAFAF5),
            const Color(0xFFFFF5E9),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Brand header
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: AppConstants.horizontalPadding,
                  vertical: 16,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      'For Designers',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF554336),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    GestureDetector(
                      onTap: () {
                        // Skip logic
                      },
                      child: Text(
                        'SKIP',
                        style: Theme.of(context).textTheme.labelSmall?.copyWith(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                              letterSpacing: 1.0,
                            ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
                vertical: 20,
              ),
              child: Column(
                children: [
                  const SizedBox(height: 50),

                  // Designer showcase card
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main card
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFF8B6914),
                            boxShadow: AppTheme.ambientShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // Designer pattern background
                                Container(
                                  color: const Color(0xFFD4A574),
                                  child: const Center(
                                    child: Icon(
                                      Icons.palette,
                                      color: Color(0xFF554336),
                                      size: 140,
                                    ),
                                  ),
                                ),
                                // Overlay texture
                                Container(
                                  decoration: BoxDecoration(
                                    borderRadius: BorderRadius.circular(24),
                                    gradient: LinearGradient(
                                      begin: Alignment.topLeft,
                                      end: Alignment.bottomRight,
                                      colors: [
                                        Colors.black.withValues(alpha: 0.08),
                                        Colors.black.withValues(alpha: 0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Badge overlay
                        Positioned(
                          bottom: 15,
                          right: 15,
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 400),
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                              decoration: BoxDecoration(
                                color: Colors.white.withValues(alpha: 0.9),
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.star,
                                    color: Color(0xFF8B6914),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'GROWING COMMUNITY',
                                    style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                          color: const Color(0xFF554336),
                                          fontWeight: FontWeight.bold,
                                          fontSize: 10,
                                        ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Title: "For Designers & Artisans"
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 300),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: const Color(0xFF1A1C19),
                              fontWeight: FontWeight.bold,
                            ),
                        children: [
                          const TextSpan(text: 'Monetize Your\n'),
                          TextSpan(
                            text: 'Embroidery',
                            style: TextStyle(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Description
                  FadeInRight(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 500),
                    child: Text(
                      'Upload your traditional & contemporary embroidery designs. Reach businesses worldwide and earn from every design sold',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF554336),
                            fontSize: 15,
                            height: 1.6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Benefits
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        _buildBenefitCard(
                          context,
                          icon: Icons.upload_file,
                          title: 'Easy Upload',
                          description: 'Upload designs in traditional, contemporary & fusion styles',
                          index: 0,
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitCard(
                          context,
                          icon: Icons.payments,
                          title: 'Instant Earnings',
                          description: 'Get paid for every design sold. No hidden charges',
                          index: 1,
                        ),
                        const SizedBox(height: 12),
                        _buildBenefitCard(
                          context,
                          icon: Icons.public,
                          title: 'Global Marketplace',
                          description: 'Your designs seen by fashion brands & businesses worldwide',
                          index: 2,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBenefitCard(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String description,
    required int index,
  }) {
    return BounceInLeft(
      duration: const Duration(milliseconds: 800),
      delay: Duration(milliseconds: 600 + (index * 100)),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
          color: Colors.white.withValues(alpha: 0.7),
          border: Border.all(
            color: AppTheme.primaryDark.withValues(alpha: 0.15),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: AppTheme.primaryDark.withValues(alpha: 0.1),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: AppTheme.primaryDark,
                  size: 24,
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFF1A1C19),
                        ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    description,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: const Color(0xFF554336),
                        ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
