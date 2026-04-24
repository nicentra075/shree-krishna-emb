import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/utils/constants.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';

class CollaboratePage extends StatefulWidget {
  const CollaboratePage({super.key});

  @override
  State<CollaboratePage> createState() => _CollaboratePageState();
}

class _CollaboratePageState extends State<CollaboratePage> {

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
                  context.read<WalkthroughBloc>().add(
                    const CompleteWalkthroughEvent(),
                  );
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

                  // Large embroidery image with overlay
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Main embroidery image
                        Container(
                          width: double.infinity,
                          height: 280,
                          decoration: BoxDecoration(
                            borderRadius: BorderRadius.circular(24),
                            color: const Color(0xFFB8860B),
                            boxShadow: AppTheme.ambientShadow,
                          ),
                          child: ClipRRect(
                            borderRadius: BorderRadius.circular(24),
                            child: Stack(
                              children: [
                                // Embroidery pattern background
                                Container(
                                  color: const Color(0xFFD4A574),
                                  child: const Center(
                                    child: Icon(
                                      Icons.auto_awesome_mosaic,
                                      color: Color(0xFF8B6914),
                                      size: 120,
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
                                        Colors.black.withValues(alpha: 0.05),
                                        Colors.black.withValues(alpha: 0.2),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),

                        // Overlay card (Active Project)
                        Positioned(
                          bottom: 15,
                          right: 15,
                          child: FadeInUp(
                            duration: const Duration(milliseconds: 800),
                            delay: const Duration(milliseconds: 400),
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.white,
                                borderRadius: BorderRadius.circular(12),
                                boxShadow: AppTheme.ambientShadow,
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Row(
                                    children: [
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          shape: BoxShape.circle,
                                          color: AppTheme.primaryLight,
                                        ),
                                        child: const Center(
                                          child: Text(
                                            '👥',
                                            style: TextStyle(fontSize: 12),
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 6),
                                      Text(
                                        'ACTIVE PROJECT',
                                        style:
                                            Theme.of(context).textTheme.labelSmall?.copyWith(
                                                  color: const Color(0xFF554336),
                                                  fontWeight: FontWeight.bold,
                                                ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 6),
                                  Text(
                                    'Trending Designs',
                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: const Color(0xFF1A1C19),
                                          fontWeight: FontWeight.w600,
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

                  // Title: "Designers Meet Business"
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
                          const TextSpan(text: 'Designers Meet\n'),
                          TextSpan(
                            text: 'Business',
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
                      'Artists showcase their embroidery designs. Businesses discover and purchase stunning patterns directly from creators',
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
