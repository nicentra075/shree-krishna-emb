import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/screens/home/home_screen.dart';
import 'package:shree_krishna_emb/screens/profile/profile_screen.dart';
import 'package:shree_krishna_emb/screens/purchases/my_purchases_screen.dart';
import 'package:shree_krishna_emb/bloc/cart/cart_cubit.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_state.dart';
import 'package:shree_krishna_emb/screens/cart/cart_screen.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/data/services/notification_service.dart';

class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedBottomNav = 0;
  DateTime? _lastBackPressTime;
  bool _consumedInitialMessage = false;

  @override
  void initState() {
    super.initState();
    // Deferred from NotificationService.onLogin: at that point the splash
    // screen still owns the navigator, so a terminated-launch deep link
    // pushed there would be wiped out when splash clears the stack on its
    // way to home. By the time MainScreen (the `home` route target) is
    // mounted, that stack-clear has already happened, so it's safe to push
    // the design detail screen on top now.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_consumedInitialMessage) return;
      _consumedInitialMessage = true;
      getIt<NotificationService>().consumeInitialMessage();
    });
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) async {
        if (didPop) return;
        await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.surface,
        appBar: _buildAppBar(context),
        // Offline banner sits above every tab's content (WS-B4).
        body: AppConnectivityBanner(child: _buildCurrentScreen(context)),
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
    // Get screen name based on selected tab
    String screenName;
    switch (_selectedBottomNav) {
      case 0:
        screenName = AppLocalization.strings.home;
        break;
      case 1:
        screenName = AppLocalization.strings.myPurchases;
        break;
      case 2:
        screenName = AppLocalization.strings.profile;
        break;
      default:
        screenName = AppLocalization.strings.home;
    }

    return AppBar(
      backgroundColor: Theme.of(context).colorScheme.surface,
      elevation: 0,
      automaticallyImplyLeading: false,
      titleSpacing: 0,
      leadingWidth: 56,
      leading: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: FadeInDown(
          delay: const Duration(milliseconds: 400),
          duration: const Duration(milliseconds: 500),
          child: Center(child: _buildNotificationAction(context)),
        ),
      ),
      title: Padding(
        padding: const EdgeInsets.only(left: 16),
        child: FadeInDown(
          duration: const Duration(milliseconds: 500),
          child: Text(
            screenName,
            style: AppTextStyles.headlineMedium(
              fontWeight: FontWeight.bold,
              color: AppTheme.primaryDark,
            ),
          ),
        ),
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FadeInDown(
            delay: const Duration(milliseconds: 300),
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: GestureDetector(
                onTap: () => AppRoutes.navigateToSearch(context),
                child: Icon(
                  Icons.search,
                  color: AppTheme.primaryDark,
                  size: 24,
                ),
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 12),
          child: FadeInDown(
            delay: const Duration(milliseconds: 350),
            duration: const Duration(milliseconds: 500),
            child: Center(child: _buildCartAction(context)),
          ),
        ),
        Padding(
          padding: const EdgeInsets.only(right: 16),
          child: FadeInDown(
            delay: const Duration(milliseconds: 500),
            duration: const Duration(milliseconds: 500),
            child: Center(
              child: GestureDetector(
                onTap: () {
                  // Navigate to Account screen
                  setState(() {
                    // Profile is tab index 2 now that My Work is Phase 2.
                    _selectedBottomNav = 2;
                  });
                },
                child: Container(
                  width: 32,
                  height: 32,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline,
                    color: AppTheme.primaryLight,
                    size: 18,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }

  /// Notification bell with a live unread-count badge, bound to the
  /// app-wide [NotificationCubit].
  Widget _buildNotificationAction(BuildContext context) {
    return BlocBuilder<NotificationCubit, NotificationState>(
      buildWhen: (prev, curr) => prev.unreadCount != curr.unreadCount,
      builder: (context, state) {
        final count = state.unreadCount;
        return GestureDetector(
          onTap: () => AppRoutes.navigateToNotifications(context),
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.notifications_outlined,
                color: AppTheme.primaryLight,
                size: 24,
              ),
              if (count > 0)
                Positioned(
                  right: -4,
                  top: -4,
                  child: Container(
                    padding: const EdgeInsets.all(3),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 9 ? '9+' : '$count',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ).copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  /// Cart icon with an item-count badge, wired to the app-wide [CartCubit].
  Widget _buildCartAction(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(
        context,
      ).push(MaterialPageRoute(builder: (_) => const CartScreen())),
      child: BlocBuilder<CartCubit, CartState>(
        buildWhen: (prev, curr) => prev.itemCount != curr.itemCount,
        builder: (context, state) {
          final count = state.itemCount;
          return Stack(
            clipBehavior: Clip.none,
            children: [
              Icon(
                Icons.shopping_cart_outlined,
                color: AppTheme.primaryLight,
                size: 24,
              ),
              if (count > 0)
                Positioned(
                  right: -6,
                  top: -6,
                  child: Container(
                    padding: const EdgeInsets.all(2),
                    constraints: const BoxConstraints(
                      minWidth: 16,
                      minHeight: 16,
                    ),
                    decoration: const BoxDecoration(
                      color: Colors.red,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(
                        count > 99 ? '99+' : '$count',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        textAlign: TextAlign.center,
                        style: AppTextStyles.labelSmall(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                        ).copyWith(fontSize: 9),
                      ),
                    ),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  Widget _buildCurrentScreen(BuildContext context) {
    switch (_selectedBottomNav) {
      case 0:
        return const HomeScreenContent();
      case 1:
        return MyPurchasesContent(
          onBrowse: () => setState(() => _selectedBottomNav = 0),
        );
      // "My Work" (job posting) is Phase 2 — WorkScreen/WorkBloc stay in the
      // codebase but are not reachable in the Phase 1 shell.
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
            color: Theme.of(
              context,
            ).colorScheme.onSurface.withValues(alpha: 0.1),
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
        backgroundColor: Theme.of(context).colorScheme.surface,
        selectedItemColor: AppTheme.primaryLight,
        unselectedItemColor: Theme.of(
          context,
        ).colorScheme.onSurface.withValues(alpha: 0.5),
        items: [
          BottomNavigationBarItem(
            icon: const Icon(Icons.home_outlined),
            activeIcon: const Icon(Icons.home),
            label: AppLocalization.strings.home,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.shopping_bag_outlined),
            activeIcon: const Icon(Icons.shopping_bag),
            label: AppLocalization.strings.myPurchases,
          ),
          BottomNavigationBarItem(
            icon: const Icon(Icons.person_outline),
            activeIcon: const Icon(Icons.person),
            label: AppLocalization.strings.profile,
          ),
        ],
      ),
    );
  }
}
