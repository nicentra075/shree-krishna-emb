import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/screens/home/home_screen.dart';
import 'package:shree_krishna_emb/screens/profile/profile_screen.dart';
import 'package:shree_krishna_emb/screens/work/work_screen.dart';
import 'package:shree_krishna_emb/bloc/work/work_bloc.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedBottomNav = 0;
  DateTime? _lastBackPressTime;

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: AppTheme.surfaceLight,
        appBar: _buildAppBar(context),
        body: _buildCurrentScreen(context),
        bottomNavigationBar: SlideInUp(
          duration: const Duration(milliseconds: 600),
          delay: const Duration(milliseconds: 800),
          child: _buildBottomNavigation(),
        ),
      ),
    );
  }

  /// Handle back button press
  /// Shows toast on first press, exits app on second press within 2 seconds
  Future<bool> _onWillPop() async {
    final now = DateTime.now();
    final isDoublePress =
        _lastBackPressTime != null &&
        now.difference(_lastBackPressTime!) < const Duration(seconds: 2);

    if (!isDoublePress) {
      _lastBackPressTime = now;
      AppSnackbar.showError('Press back again to exit');
      return false;
    }

    return true; // Allow app exit on second press
  }

  PreferredSizeWidget? _buildAppBar(BuildContext context) {
    // Hide AppBar when on Account screen
    if (_selectedBottomNav == 2) {
      return null;
    }

    return AppBar(
      backgroundColor: AppTheme.surfaceLight,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            FadeInDown(
              duration: const Duration(milliseconds: 500),
              child: Text(
                AppLocalization.strings.appName,
                style: AppTextStyles.headlineLarge(
                  color: AppTheme.primaryLight,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 4),
            FadeInDown(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 500),
              child: Text(
                AppLocalization.strings.appTagline,
                style: AppTextStyles.bodySmall(
                  color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                ),
              ),
            ),
          ],
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FadeInDown(
            delay: const Duration(milliseconds: 400),
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // TODO: Navigate to notifications
                },
                child: Stack(
                  children: [
                    Icon(
                      Icons.notifications_outlined,
                      color: AppTheme.primaryLight,
                      size: 24,
                    ),
                    Positioned(
                      right: 0,
                      top: 0,
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCurrentScreen(BuildContext context) {
    switch (_selectedBottomNav) {
      case 0:
        return const HomeScreenContent();
      case 1:
        return BlocProvider(
          create: (context) => WorkBloc(),
          child: const WorkScreen(),
        );
      case 2:
        return const ProfileScreen();
      default:
        return const HomeScreenContent();
    }
  }

  Widget _buildBottomNavigation() {
    return Container(
      decoration: BoxDecoration(
        border: Border(
          top: BorderSide(
            color: AppTheme.onSurfaceLight.withValues(alpha: 0.1),
          ),
        ),
      ),
      child: BottomNavigationBar(
        currentIndex: _selectedBottomNav,
        onTap: (index) {
          setState(() {
            _selectedBottomNav = index;
          });
        },
        type: BottomNavigationBarType.fixed,
        backgroundColor: AppTheme.surfaceLight,
        selectedItemColor: AppTheme.primaryLight,
        unselectedItemColor: AppTheme.onSurfaceLight.withValues(alpha: 0.5),
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Home',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.work_outline),
            activeIcon: Icon(Icons.work),
            label: 'Work',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person_outline),
            activeIcon: Icon(Icons.person),
            label: 'Account',
          ),
        ],
      ),
    );
  }
}
