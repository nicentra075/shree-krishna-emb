import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/splash/splash_bloc.dart';
import 'package:shree_krishna_emb_admin/routes/app_routes.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  bool _splashComplete = false;
  bool _hasNavigated = false;

  @override
  void initState() {
    super.initState();
    // Restore any cached session while the splash animation plays
    context.read<AdminAuthBloc>().add(const AdminCheckAuthStatusEvent());
  }

  /// Navigate once both the splash duration has elapsed and the cached
  /// session check has resolved — dashboard if a session was restored,
  /// login otherwise.
  void _navigateWhenReady(BuildContext context) {
    if (!_splashComplete || _hasNavigated) return;

    final authState = context.read<AdminAuthBloc>().state;
    if (authState is AdminAuthAuthenticated) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed(AppRoutes.home);
    } else if (authState is AdminAuthUnauthenticated ||
        authState is AdminAuthError) {
      _hasNavigated = true;
      Navigator.of(context).pushReplacementNamed(AppRoutes.login);
    }
    // Still checking — the AdminAuthBloc listener retries when it resolves
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final screenSize = MediaQuery.of(context).size;
    final isSmallScreen = screenSize.width < 600;

    return BlocProvider(
      create: (context) => SplashBloc()..add(const InitializeSplashEvent()),
      child: MultiBlocListener(
        listeners: [
          BlocListener<SplashBloc, SplashState>(
            listener: (context, state) {
              if (state is SplashComplete) {
                _splashComplete = true;
                _navigateWhenReady(context);
              }
            },
          ),
          BlocListener<AdminAuthBloc, AdminAuthState>(
            listener: (context, state) => _navigateWhenReady(context),
          ),
        ],
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
                        child: Padding(
                          padding: EdgeInsets.symmetric(
                            horizontal: isSmallScreen ? 24 : 48,
                          ),
                          child: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              // Animated Logo
                              ZoomIn(
                                duration: const Duration(milliseconds: 800),
                                child: _buildAnimatedLogo(isSmallScreen),
                              ),
                              SizedBox(height: isSmallScreen ? 32 : 40),

                              // Animated Title
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 200),
                                child: Column(
                                  children: [
                                    Text(
                                      strings.splashWelcomeTo,
                                      textAlign: TextAlign.center,
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
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
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
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
                              SizedBox(height: isSmallScreen ? 48 : 60),

                              // Tagline
                              FadeInUp(
                                duration: const Duration(milliseconds: 800),
                                delay: const Duration(milliseconds: 400),
                                child: Text(
                                  strings.splashTagline,
                                  textAlign: TextAlign.center,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  style: AppTextStyles.bodyLarge(
                                    color: AppTheme.primaryLight.withValues(
                                      alpha: 0.9,
                                    ),
                                  ),
                                ),
                              ),
                              SizedBox(height: isSmallScreen ? 64 : 80),

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
                    ),

                    // Footer - Made with love
                    Positioned(
                      bottom: isSmallScreen ? 24 : 32,
                      left: 0,
                      right: 0,
                      child: FadeInUp(
                        duration: const Duration(milliseconds: 800),
                        delay: const Duration(milliseconds: 1000),
                        child: Center(
                          child: SingleChildScrollView(
                            scrollDirection: Axis.horizontal,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  strings.madeWithLove,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: Theme.of(context).textTheme.bodySmall
                                      ?.copyWith(
                                        color: Colors.white.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontWeight: FontWeight.w500,
                                      ),
                                ),
                                const SizedBox(width: 4),
                                Icon(
                                  Icons.favorite,
                                  size: 14,
                                  color: const Color(0xFFFF6B6B),
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  strings.byNicentra,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
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
                          ),
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
  Widget _buildAnimatedLogo(bool isSmallScreen) {
    final size = isSmallScreen ? 120.0 : 140.0;
    final iconSize = isSmallScreen ? 60.0 : 70.0;

    return Container(
      width: size,
      height: size,
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
          child: Icon(Icons.spa, size: iconSize, color: AppTheme.primaryLight),
        ),
      ),
    );
  }
}
