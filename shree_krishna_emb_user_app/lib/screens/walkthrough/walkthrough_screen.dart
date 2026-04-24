import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/discover_page.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/collaborate_page.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/get_started_page.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/embroidery_designs_page.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/designer_community_page.dart';
import 'package:shree_krishna_emb/utils/constants.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';

class WalkthroughScreen extends StatefulWidget {
  const WalkthroughScreen({super.key});

  @override
  State<WalkthroughScreen> createState() => _WalkthroughScreenState();
}

class _WalkthroughScreenState extends State<WalkthroughScreen> {
  late PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController();
    context.read<WalkthroughBloc>().add(const InitializeWalkthroughEvent());
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return BlocListener<WalkthroughBloc, WalkthroughState>(
      listener: (context, state) {
        if (state is WalkthroughLoaded) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (_pageController.hasClients) {
              _pageController.animateToPage(
                state.currentPageIndex,
                duration: AppConstants.pageTransitionDuration,
                curve: Curves.easeInOut,
              );
            }
          });
        } else if (state is WalkthroughCompleted) {
          AppSnackbar.showSuccess('Welcome to ${strings.appName}!');
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (mounted) {
              AppRoutes.pushReplacementAll(context, AppRoutes.login);
            }
          });
        }
      },
      child: BlocBuilder<WalkthroughBloc, WalkthroughState>(
        builder: (context, state) {
          if (state is WalkthroughLoading) {
            return const Scaffold(body: Center(child: AppLoader()));
          }

          if (state is WalkthroughLoaded) {
            return Scaffold(
              body: Stack(
                children: [
                  // Full-screen PageView
                  PageView(
                    controller: _pageController,
                    onPageChanged: (index) {
                      context.read<WalkthroughBloc>().add(GoToPageEvent(index));
                    },
                    children: [
                      const GetStartedPage(),
                      const CollaboratePage(),
                      const EmbroideryDesignsPage(),
                      //const DesignerCommunityPage(),
                      const DiscoverPage(),
                    ],
                  ),

                  // Bottom Navigation Overlay
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    child: _buildBottomNavigation(context, state),
                  ),
                ],
              ),
            );
          }

          if (state is WalkthroughError) {
            return Scaffold(
              body: Center(child: Text('Error: ${state.message}')),
            );
          }

          return const Scaffold(body: Center(child: AppLoader()));
        },
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, WalkthroughLoaded state) {
    final strings = AppLocalization.strings;

    return FadeInUp(
      duration: AppConstants.buttonAnimationDuration,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.white.withValues(alpha: 0.0),
              Colors.white.withValues(alpha: 0.95),
            ],
          ),
        ),
        padding: const EdgeInsets.fromLTRB(
          AppConstants.horizontalPadding,
          32,
          AppConstants.horizontalPadding,
          24,
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            // Animated Page Indicator
            BounceInDown(
              duration: const Duration(milliseconds: 600),
              child: SmoothPageIndicator(
                controller: _pageController,
                count: 4, // 4 total pages
                effect: WormEffect(
                  dotHeight: 8,
                  dotWidth: 8,
                  spacing: 8,
                  activeDotColor: AppTheme.primaryDark,
                  dotColor: const Color(0xFFDDD9D0),
                ),
              ),
            ),
            const SizedBox(height: 24),

            // Animated Navigation Buttons
            ScaleTransition(
              scale: Tween<double>(begin: 0.8, end: 1.0).animate(
                CurvedAnimation(
                  parent: AlwaysStoppedAnimation(1.0),
                  curve: Curves.easeInOutBack,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  if (!state.isFirstPage)
                    BounceInLeft(
                      duration: const Duration(milliseconds: 600),
                      child: AppButton(
                        label: strings.back,
                        onPressed: () {
                          context.read<WalkthroughBloc>().add(
                            const PreviousPageEvent(),
                          );
                        },
                        variant: AppButtonVariant.outlined,
                        leadingIcon: Icons.arrow_back,
                        size: AppButtonSize.medium,
                      ),
                    ),
                  Expanded(
                    child: Padding(
                      padding: EdgeInsets.only(
                        left: state.isFirstPage ? 0 : 16,
                      ),
                      child: BounceInRight(
                        duration: const Duration(milliseconds: 600),
                        child: AppButton(
                          label: state.isLastPage
                              ? strings.walkthroughGetStarted
                              : strings.next,
                          onPressed: () {
                            if (state.isLastPage) {
                              context.read<WalkthroughBloc>().add(
                                const CompleteWalkthroughEvent(),
                              );
                            } else {
                              context.read<WalkthroughBloc>().add(
                                const NextPageEvent(),
                              );
                            }
                          },
                          variant: AppButtonVariant.primary,
                          size: AppButtonSize.medium,
                          isFullWidth: true,
                        ),
                      ),
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
