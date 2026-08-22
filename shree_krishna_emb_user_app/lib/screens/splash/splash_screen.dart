import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/splash/splash_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return MultiBlocProvider(
      providers: [
        BlocProvider.value(
          value: getIt<SplashBloc>()..add(const InitializeSplashEvent()),
        ),
        BlocProvider.value(
          value: getIt<AuthBloc>()..add(const CheckAuthStatusEvent()),
        ),
      ],
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          if (state is SplashComplete) {
            final authState = context.read<AuthBloc>().state;
            if (authState is AuthAuthenticated) {
              context.navigateToHome();
            } else {
              context.navigateToWalkthrough();
            }
          }
        },
        child: BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppTheme.primaryDark,
              body: GestureDetector(
                onTap: () {
                  context.read<SplashBloc>().add(const SkipSplashEvent());
                },
                child: Stack(
                  children: [
                    // Decorative gradient background
                    _buildBackgroundDecoration(),

                    // Main content
                    Center(
                      child: SingleChildScrollView(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            // Animated Logo
                            ZoomIn(
                              duration: const Duration(milliseconds: 800),
                              child: _buildAnimatedLogo(),
                            ),
                            const SizedBox(height: 40),

                            // Animated Title
                            FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 200),
                              child: Column(
                                children: [
                                  Text(
                                    strings.splashWelcomeTo,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.headlineMedium(
                                      color: Colors.white.withValues(
                                        alpha: 0.8,
                                      ),
                                      letterSpacing: 1.2,
                                      height: 1.0,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    strings.splashTitle,
                                    textAlign: TextAlign.center,
                                    style: AppTextStyles.displayLarge(
                                      color: Colors.white,
                                      fontWeight: FontWeight.w900,
                                      letterSpacing: 2.5,
                                      shadows: [
                                        Shadow(
                                          color: AppTheme.primaryLight,
                                          blurRadius: 12,
                                          offset: const Offset(0, 4),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(height: 60),

                            // Tagline
                            FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 400),
                              child: Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 32,
                                ),
                                child: Text(
                                  strings.splashTagline,
                                  textAlign: TextAlign.center,
                                  style: AppTextStyles.bodyLarge(
                                    color: AppTheme.primaryLight.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 80),

                            // Loading State
                            FadeInUp(
                              duration: const Duration(milliseconds: 800),
                              delay: const Duration(milliseconds: 600),
                              child: Column(
                                children: [
                                  if (state is SplashLoading)
                                    const AppLoader(size: 48)
                                  else
                                    const SizedBox(height: 48),
                                  const SizedBox(height: 24),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),

                    // Footer - Made with love
                    Positioned(
                      bottom: 32,
                      left: 0,
                      right: 0,
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 1000),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  strings.madeWithLove,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                Icon(
                                  Icons.favorite,
                                  size: 14,
                                  color: const Color(0xFFFF6B6B),
                                ),
                                Text(
                                  ' ${strings.byNicentra}',
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w500,
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
          },
        ),
      ),
    );
  }

  /// Build animated decorative background with gradients
  Widget _buildBackgroundDecoration() {
    return Stack(
      children: [
        // Gradient overlay
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                AppTheme.primaryDark,
                AppTheme.primaryDark.withValues(alpha: 0.95),
                AppTheme.primaryDark.withValues(alpha: 0.9),
              ],
            ),
          ),
        ),

        // Floating decorative circles (background)
        Positioned(
          top: -50,
          right: -50,
          child: Container(
            width: 200,
            height: 200,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppTheme.primaryLight.withValues(alpha: 0.05),
            ),
          ),
        ),
        Positioned(
          bottom: -30,
          left: -30,
          child: Container(
            width: 150,
            height: 150,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.blue.withValues(alpha: 0.05),
            ),
          ),
        ),
      ],
    );
  }

  /// Build animated logo with scale and glow effect
  Widget _buildAnimatedLogo() {
    return Container(
      width: 140,
      height: 140,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        boxShadow: [
          BoxShadow(
            color: AppTheme.primaryLight.withValues(alpha: 0.3),
            blurRadius: 30,
            spreadRadius: 5,
          ),
        ],
      ),
      child: Container(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          color: AppTheme.primaryLight.withValues(alpha: 0.15),
          border: Border.all(
            color: AppTheme.primaryLight.withValues(alpha: 0.6),
            width: 2.5,
          ),
        ),
        child: Center(
          child: Icon(Icons.spa, size: 70, color: AppTheme.primaryLight),
        ),
      ),
    );
  }
}
