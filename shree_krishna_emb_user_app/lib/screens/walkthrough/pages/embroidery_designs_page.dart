import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_emb/utils/constants.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

class EmbroideryDesignsPage extends StatefulWidget {
  const EmbroideryDesignsPage({super.key});

  @override
  State<EmbroideryDesignsPage> createState() => _EmbroideryDesignsPageState();
}

class _EmbroideryDesignsPageState extends State<EmbroideryDesignsPage> {
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
          // Skip button - top right
          Positioned(
            top: 20,
            right: 24,
            child: FadeInDown(
              duration: const Duration(milliseconds: 600),
              child: GestureDetector(
                onTap: () {
                  // Navigate or skip logic
                },
                child: Text(
                  'Skip',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: const Color(0xFF554336),
                        fontWeight: FontWeight.w600,
                      ),
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
                  const SizedBox(height: 30),

                  // Title: "Explore Every Style"
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
                          const TextSpan(text: 'Explore Every\n'),
                          TextSpan(
                            text: 'Style',
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
                      'From traditional Zari work to modern thread embroidery. Traditional Indian, Contemporary fusion, Ethnic patterns, and more',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF554336),
                            fontSize: 15,
                            height: 1.6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Design Categories Grid
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 600),
                    child: Column(
                      children: [
                        _buildCategoryRow([
                          _CategoryCard(
                            icon: Icons.diamond,
                            title: 'Zari Work',
                            color: const Color(0xFFC9A961),
                            description: 'Gold & metallic',
                          ),
                          _CategoryCard(
                            icon: Icons.brush,
                            title: 'Thread Art',
                            color: const Color(0xFFD4A574),
                            description: 'Fine embroidery',
                          ),
                        ]),
                        const SizedBox(height: 16),
                        _buildCategoryRow([
                          _CategoryCard(
                            icon: Icons.blur_on,
                            title: 'Mirror Work',
                            color: const Color(0xFF8B6914),
                            description: 'Reflective designs',
                          ),
                          _CategoryCard(
                            icon: Icons.grain,
                            title: 'Bead & Stone',
                            color: const Color(0xFFB8860B),
                            description: 'Embellished pieces',
                          ),
                        ]),
                      ],
                    ),
                  ),

                  const SizedBox(height: 40),

                  // Feature highlight
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 700),
                    child: Container(
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(16),
                        color: Colors.white.withValues(alpha: 0.6),
                        border: Border.all(
                          color: AppTheme.primaryDark.withValues(alpha: 0.2),
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
                                Icons.bolt,
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
                                  '50,000+ Designs',
                                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                                        fontWeight: FontWeight.bold,
                                        color: const Color(0xFF1A1C19),
                                      ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  'From master craftsmen',
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

  Widget _buildCategoryRow(List<_CategoryCard> cards) {
    return Row(
      children: cards.asMap().entries.map((entry) {
        final index = entry.key;
        final card = entry.value;
        return Expanded(
          child: Padding(
            padding: EdgeInsets.only(right: index == 0 ? 8 : 0),
            child: BounceInUp(
              duration: const Duration(milliseconds: 900),
              delay: Duration(milliseconds: 500 + (index * 100)),
              child: _buildCategoryCard(card),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCategoryCard(_CategoryCard card) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(20),
        color: card.color,
        boxShadow: AppTheme.ambientShadow,
      ),
      child: Column(
        children: [
          Icon(
            card.icon,
            size: 42,
            color: Colors.white,
          ),
          const SizedBox(height: 10),
          Text(
            card.title,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 6),
          Text(
            card.description,
            style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.white.withValues(alpha: 0.85),
                  fontSize: 11,
                ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }
}

class _CategoryCard {
  final IconData icon;
  final String title;
  final String description;
  final Color color;

  _CategoryCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
  });
}
