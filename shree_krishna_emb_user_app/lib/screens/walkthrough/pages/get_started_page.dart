import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_emb/utils/constants.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

/// Get Started Page - "Your Digital Atelier"
/// First walkthrough screen from Stitch design

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage>
    with TickerProviderStateMixin {
  late AnimationController _floatingController;

  @override
  void initState() {
    super.initState();
    _floatingController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _floatingController.dispose();
    super.dispose();
  }

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
          // Background decorative circles
          Positioned(
            top: -50,
            left: -50,
            child: FadeInDown(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 200,
                height: 200,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: const Color(0xFFE8D4C4).withValues(alpha: 0.3),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: -30,
            right: -30,
            child: FadeInUp(
              duration: const Duration(milliseconds: 800),
              child: Container(
                width: 150,
                height: 150,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                ),
              ),
            ),
          ),

          // Main content
          SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: AppConstants.horizontalPadding,
                vertical: 30,
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const SizedBox(height: 30),

                  // Orange shopping bag icon with floating animation
                  FadeInDown(
                    duration: const Duration(milliseconds: 800),
                    child: AnimatedBuilder(
                      animation: _floatingController,
                      builder: (context, child) {
                        return Transform.translate(
                          offset: Offset(0, _floatingController.value * 15 - 7.5),
                          child: child,
                        );
                      },
                      child: Container(
                        width: 60,
                        height: 60,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          color: AppTheme.primaryLight,
                          boxShadow: AppTheme.ambientShadow,
                        ),
                        child: const Icon(
                          Icons.shopping_bag_outlined,
                          color: Colors.white,
                          size: 32,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 40),

                  // Product showcase cards
                  FadeInUp(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 200),
                    child: Stack(
                      alignment: Alignment.center,
                      children: [
                        // Back card (dark phone mockup)
                        Transform.translate(
                          offset: const Offset(-20, -15),
                          child: Container(
                            width: 110,
                            height: 170,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFF1A1A1A),
                              boxShadow: [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.2),
                                  blurRadius: 20,
                                  offset: const Offset(5, 10),
                                ),
                              ],
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Container(
                                color: const Color(0xFF2A2A2A),
                                child: const Center(
                                  child: Icon(
                                    Icons.phone_iphone,
                                    color: Color(0xFF444),
                                    size: 45,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),

                        // Front card (embroidery/craft)
                        Transform.translate(
                          offset: const Offset(20, 15),
                          child: Container(
                            width: 130,
                            height: 140,
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(20),
                              color: const Color(0xFFB8860B),
                              boxShadow: AppTheme.ambientShadow,
                            ),
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(20),
                              child: Stack(
                                children: [
                                  // Embroidery pattern
                                  Container(
                                    color: const Color(0xFFD4A574),
                                    child: const Center(
                                      child: Icon(
                                        Icons.auto_awesome_mosaic,
                                        color: Color(0xFF8B6914),
                                        size: 70,
                                      ),
                                    ),
                                  ),
                                  // Texture overlay
                                  Container(
                                    decoration: BoxDecoration(
                                      borderRadius: BorderRadius.circular(20),
                                      gradient: LinearGradient(
                                        begin: Alignment.topLeft,
                                        end: Alignment.bottomRight,
                                        colors: [
                                          Colors.black.withValues(alpha: 0.05),
                                          Colors.black.withValues(alpha: 0.15),
                                        ],
                                      ),
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
                  const SizedBox(height: 50),

                  // Headline: "One Platform, Infinite Possibilities"
                  FadeInLeft(
                    duration: const Duration(milliseconds: 900),
                    delay: const Duration(milliseconds: 400),
                    child: RichText(
                      textAlign: TextAlign.center,
                      text: TextSpan(
                        style: Theme.of(context).textTheme.headlineLarge?.copyWith(
                              color: const Color(0xFF1A1C19),
                              fontWeight: FontWeight.bold,
                            ),
                        children: [
                          const TextSpan(text: 'One Platform,\n'),
                          TextSpan(
                            text: 'Infinite Possibilities',
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
                    delay: const Duration(milliseconds: 600),
                    child: Text(
                      'Buy premium embroidery designs or sell your creations. Connect directly with artisans and businesses worldwide',
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                            color: const Color(0xFF554336),
                            fontSize: 15,
                            height: 1.6,
                          ),
                    ),
                  ),
                  const SizedBox(height: 35),

                  // Footer text
                  FadeInUp(
                    duration: const Duration(milliseconds: 800),
                    delay: const Duration(milliseconds: 800),
                    child: Text(
                      'SHREE KRISHNA EMB • PREMIUMCRAFTS',
                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                            color: const Color(0xFF554336).withValues(alpha: 0.5),
                            letterSpacing: 1.2,
                          ),
                    ),
                  ),
                  const SizedBox(height: 30),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

}
