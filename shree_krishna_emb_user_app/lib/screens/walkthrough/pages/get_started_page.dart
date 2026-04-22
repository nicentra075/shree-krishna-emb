import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_emb/utils/constants.dart';

class GetStartedPage extends StatefulWidget {
  const GetStartedPage({super.key});

  @override
  State<GetStartedPage> createState() => _GetStartedPageState();
}

class _GetStartedPageState extends State<GetStartedPage> with TickerProviderStateMixin {
  late AnimationController _sparkleController;
  late AnimationController _bounceController;

  @override
  void initState() {
    super.initState();
    _sparkleController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1000),
    )..repeat();
  }

  @override
  void dispose() {
    _sparkleController.dispose();
    _bounceController.dispose();
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
            Color(int.parse('0xFFEC4899')),
            Color(int.parse('0xFFF97316')).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Sparkle effects
          Positioned(
            top: 80,
            left: 50,
            child: FadeTransition(
              opacity: Tween(begin: 0.3, end: 1.0).animate(_sparkleController),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 24,
              ),
            ),
          ),
          Positioned(
            top: 120,
            right: 40,
            child: FadeTransition(
              opacity: Tween(begin: 0.5, end: 1.0).animate(
                CurvedAnimation(parent: _sparkleController, curve: const Interval(0.3, 0.7)),
              ),
              child: const Icon(
                Icons.star,
                color: Colors.white,
                size: 20,
              ),
            ),
          ),
          Positioned(
            bottom: 200,
            right: 30,
            child: FadeTransition(
              opacity: Tween(begin: 0.4, end: 0.9).animate(
                CurvedAnimation(parent: _sparkleController, curve: const Interval(0.6, 1.0)),
              ),
              child: const Icon(
                Icons.star_half,
                color: Colors.white,
                size: 22,
              ),
            ),
          ),
          // Main content
          Padding(
            padding: const EdgeInsets.symmetric(
              horizontal: AppConstants.horizontalPadding,
              vertical: AppConstants.verticalPadding,
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Bouncing icon
                BounceInDown(
                  duration: const Duration(milliseconds: 1000),
                  child: Container(
                    width: 120,
                    height: 120,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.white.withValues(alpha: 0.2),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.3),
                        width: 2,
                      ),
                    ),
                    child: const Center(
                      child: Icon(
                        Icons.rocket_launch,
                        size: 60,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 40),
                // Title
                FadeInLeft(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 200),
                  child: Text(
                    'Get Started',
                    style: Theme.of(context).textTheme.displaySmall?.copyWith(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                // Description
                FadeInRight(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 400),
                  child: Text(
                    'Join our community and start creating your own embroidery designs today',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Call to action items
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 600),
                  child: _buildCtaCards(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCtaCards() {
    return Column(
      children: [
        _buildCtaCard(
          '👤',
          'Create Account',
          'Get started in minutes',
        ),
        const SizedBox(height: 12),
        _buildCtaCard(
          '🎓',
          'Learn & Explore',
          'Access tutorials and guides',
        ),
        const SizedBox(height: 12),
        _buildCtaCard(
          '🏆',
          'Showcase Work',
          'Build your portfolio',
        ),
      ],
    );
  }

  Widget _buildCtaCard(String emoji, String title, String subtitle) {
    return BounceInRight(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.3),
            width: 1.5,
          ),
        ),
        child: Row(
          children: [
            Text(
              emoji,
              style: const TextStyle(fontSize: 32),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.white.withValues(alpha: 0.8),
                      fontSize: 12,
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward,
              color: Colors.white.withValues(alpha: 0.6),
              size: 18,
            ),
          ],
        ),
      ),
    );
  }
}
