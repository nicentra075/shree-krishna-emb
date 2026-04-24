import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/bloc/splash/splash_bloc.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';


class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SplashBloc>()..add(const InitializeSplashEvent()),
      child: BlocListener<SplashBloc, SplashState>(
        listener: (context, state) {
          // When splash completes, navigate to walkthrough
          if (state is SplashComplete) {
            context.navigateToWalkthrough();
          }
        },
        child: BlocBuilder<SplashBloc, SplashState>(
          builder: (context, state) {
            return Scaffold(
              backgroundColor: AppTheme.primaryDark,
              body: GestureDetector(
                onTap: () {
                  // Allow users to tap to skip splash
                  context.read<SplashBloc>().add(const SkipSplashEvent());
                },
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Logo/Brand Icon
                      _buildLogo(context),
                      const SizedBox(height: 32),

                      // App Title
                      Text(
                        'Shree Krishna',
                        style: Theme.of(context).textTheme.displayMedium?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                      ),
                      const SizedBox(height: 8),

                      // Subtitle
                      Text(
                        'Embroidery',
                        style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              color: AppTheme.primaryLight,
                              fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 48),

                      // Loading Indicator
                      if (state is SplashLoading)
                        _buildLoadingIndicator()
                      else
                        const SizedBox.shrink(),

                      const SizedBox(height: 32),

                      // Skip Text
                      Text(
                        'Tap to continue',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.white.withValues(alpha: 0.7),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Build animated logo with cultural touch
  Widget _buildLogo(BuildContext context) {
    return Container(
      width: 120,
      height: 120,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: AppTheme.primaryLight.withValues(alpha: 0.2),
        border: Border.all(
          color: AppTheme.primaryLight.withValues(alpha: 0.5),
          width: 2,
        ),
      ),
      child: Center(
        child: Icon(
          Icons.auto_awesome_mosaic,
          size: 60,
          color: AppTheme.primaryLight,
        ),
      ),
    );
  }

  /// Build animated loading indicator
  Widget _buildLoadingIndicator() {
    return SizedBox(
      width: 40,
      height: 40,
      child: CircularProgressIndicator(
        valueColor: AlwaysStoppedAnimation<Color>(AppTheme.primaryLight),
        strokeWidth: 3,
      ),
    );
  }
}
