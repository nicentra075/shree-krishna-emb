import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/utils/constants.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';

class DiscoverPage extends StatefulWidget {
  const DiscoverPage({super.key});

  @override
  State<DiscoverPage> createState() => _DiscoverPageState();
}

class _DiscoverPageState extends State<DiscoverPage> with TickerProviderStateMixin {
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
          // Top header with brand and skip
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
                      'Shree Krishna EMB',
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            color: const Color(0xFF554336),
                            fontWeight: FontWeight.bold,
                          ),
                    ),
                    GestureDetector(
                      onTap: () {
                        context.read<WalkthroughBloc>().add(
                          const CompleteWalkthroughEvent(),
                        );
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

                  // Golden embroidery design card
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
                            color: const Color(0xFFC9A961),
                            boxShadow: AppTheme.ambientShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // Golden background with pattern
                                Container(
                                  color: const Color(0xFFD4A76A),
                                  child: const Center(
                                    child: Icon(
                                      Icons.auto_awesome_mosaic,
                                      color: Color(0xFF8B6914),
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

                        // Label overlay
                        Positioned(
                          bottom: 15,
                          left: 15,
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
                                    Icons.verified,
                                    color: Color(0xFFC9A961),
                                    size: 14,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'HANDCRAFTED TRADITION',
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

                  // Title: "Shree Krishna Embroidery"
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
                          const TextSpan(text: 'Preserving\n'),
                          TextSpan(
                            text: 'Heritage Crafts',
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
                      'Connecting authentic artisans with global fashion businesses. Celebrating embroidery craftsmanship in the digital era',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF554336),
                            fontSize: 15,
                            height: 1.6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 65),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
