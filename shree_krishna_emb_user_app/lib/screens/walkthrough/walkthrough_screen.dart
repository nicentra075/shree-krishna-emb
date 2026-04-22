import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/discover_page.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/collaborate_page.dart';
import 'package:shree_krishna_emb/screens/walkthrough/pages/get_started_page.dart';
import 'package:shree_krishna_emb/utils/constants.dart';

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
          // Handle navigation to main app
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Welcome to Shree Krishna Embroidery!'),
            ),
          );
        }
      },
      child: BlocBuilder<WalkthroughBloc, WalkthroughState>(
        builder: (context, state) {
          if (state is WalkthroughLoading) {
            return const Scaffold(
              body: Center(child: CircularProgressIndicator()),
            );
          }

          if (state is WalkthroughLoaded) {
            return Scaffold(
              body: Column(
                children: [
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: (index) {
                        context.read<WalkthroughBloc>().add(
                          GoToPageEvent(index),
                        );
                      },
                      children: [
                        const DiscoverPage(),
                        const CollaboratePage(),
                        const GetStartedPage(),
                      ],
                    ),
                  ),
                  _buildBottomNavigation(context, state),
                ],
              ),
            );
          }

          if (state is WalkthroughError) {
            return Scaffold(
              body: Center(child: Text('Error: ${state.message}')),
            );
          }

          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        },
      ),
    );
  }

  Widget _buildBottomNavigation(BuildContext context, WalkthroughLoaded state) {
    return FadeInUp(
      duration: AppConstants.buttonAnimationDuration,
      child: Container(
        padding: const EdgeInsets.all(AppConstants.horizontalPadding),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            SmoothPageIndicator(
              controller: _pageController,
              count: state.pages.length,
              effect: const WormEffect(
                dotHeight: 8,
                dotWidth: 8,
                spacing: 8,
                activeDotColor: Color(0xFF6366F1),
                dotColor: Color(0xFFE2E8F0),
              ),
            ),
            const SizedBox(height: AppConstants.verticalPadding),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                if (!state.isFirstPage)
                  ElevatedButton.icon(
                    onPressed: () {
                      context.read<WalkthroughBloc>().add(
                        const PreviousPageEvent(),
                      );
                    },
                    icon: const Icon(Icons.arrow_back),
                    label: const Text('Back'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey[300],
                      foregroundColor: Colors.black87,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 20,
                        vertical: 12,
                      ),
                    ),
                  ),
                Expanded(
                  child: Padding(
                    padding: EdgeInsets.only(left: state.isFirstPage ? 0 : 16),
                    child: ElevatedButton(
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
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xFF6366F1),
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            AppConstants.borderRadiusMedium,
                          ),
                        ),
                      ),
                      child: Text(state.isLastPage ? 'Get Started' : 'Next'),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
