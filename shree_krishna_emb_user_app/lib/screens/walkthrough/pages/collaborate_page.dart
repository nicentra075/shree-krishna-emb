import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_emb/utils/constants.dart';

class CollaboratePage extends StatefulWidget {
  const CollaboratePage({super.key});

  @override
  State<CollaboratePage> createState() => _CollaboratePageState();
}

class _CollaboratePageState extends State<CollaboratePage> with TickerProviderStateMixin {
  late AnimationController _pulseController;
  late AnimationController _slideController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat();

    _slideController = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 3),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    _slideController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topRight,
          end: Alignment.bottomLeft,
          colors: [
            Color(int.parse('0xFF8B5CF6')),
            Color(int.parse('0xFFEC4899')).withValues(alpha: 0.8),
          ],
        ),
      ),
      child: Stack(
        children: [
          // Animated background circles
          Positioned(
            top: 100,
            left: 30,
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.3).animate(_pulseController),
              child: Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.15),
                ),
              ),
            ),
          ),
          Positioned(
            bottom: 150,
            right: 40,
            child: ScaleTransition(
              scale: Tween(begin: 1.0, end: 1.2).animate(_pulseController),
              child: Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.white.withValues(alpha: 0.1),
                ),
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
                // Icon with pulse effect
                FadeInUp(
                  duration: const Duration(milliseconds: 900),
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
                        Icons.people,
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
                    'Collaborate',
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
                    'Work together with other designers to create amazing embroidery masterpieces',
                    textAlign: TextAlign.center,
                    style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: Colors.white.withValues(alpha: 0.9),
                      fontSize: 16,
                    ),
                  ),
                ),
                const SizedBox(height: 60),
                // Collaboration cards
                FadeInUp(
                  duration: const Duration(milliseconds: 1000),
                  delay: const Duration(milliseconds: 600),
                  child: _buildCollaborationFeatures(),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCollaborationFeatures() {
    return Column(
      children: [
        _buildCollapseCard(
          'Share Ideas',
          'Real-time collaboration with team members',
          Icons.share,
        ),
        const SizedBox(height: 12),
        _buildCollapseCard(
          'Feedback',
          'Get constructive feedback from community',
          Icons.feedback,
        ),
        const SizedBox(height: 12),
        _buildCollapseCard(
          'Grow Together',
          'Learn from experienced designers',
          Icons.trending_up,
        ),
      ],
    );
  }

  Widget _buildCollapseCard(String title, String subtitle, IconData icon) {
    return SlideInLeft(
      duration: const Duration(milliseconds: 800),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(AppConstants.borderRadiusMedium),
          border: Border.all(
            color: Colors.white.withValues(alpha: 0.2),
          ),
        ),
        child: Row(
          children: [
            Container(
              width: 50,
              height: 50,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.white.withValues(alpha: 0.2),
              ),
              child: Center(
                child: Icon(
                  icon,
                  color: Colors.white,
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
          ],
        ),
      ),
    );
  }
}
