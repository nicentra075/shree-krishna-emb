import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/user_model.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/screens/splash/splash_screen.dart';
import 'package:shree_krishna_emb/screens/walkthrough/walkthrough_screen.dart';
import 'package:shree_krishna_emb/screens/auth/login_screen.dart';
import 'package:shree_krishna_emb/screens/auth/signup_screen.dart';
import 'package:shree_krishna_emb/screens/auth/otp_verification_screen.dart';
import 'package:shree_krishna_emb/screens/auth/forgot_password_screen.dart';
import 'package:shree_krishna_emb/screens/auth/complete_profile_screen.dart';
import 'package:shree_krishna_emb/screens/main/main_screen.dart';
import 'package:shree_krishna_emb/screens/catalog/view_all_screen.dart';
import 'package:shree_krishna_emb/screens/catalog/design_detail_screen.dart';
import 'package:shree_krishna_emb/screens/catalog/favorites_screen.dart';
import 'package:shree_krishna_emb/screens/settings/settings_screen.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/core/utils/app_logger.dart';

// ==================== Route Arguments ====================
/// Container for passing arguments to walkthrough screen
class WalkthroughArgs {
  final bool skipAnimation;

  WalkthroughArgs({this.skipAnimation = false});
}

// Add more argument classes here as needed
// Example:
// class ProfileArgs {
//   final String userId;
//   ProfileArgs({required this.userId});
// }

/// App Routes - Centralized Route Management
///
/// This class manages all routes, arguments, and navigation in the app.
/// Using this ensures:
/// - Consistent navigation across the app
/// - Easy to add/modify routes
/// - Type-safe route arguments
/// - All screens in one place
///
/// USAGE:
/// Instead of:
///   Navigator.of(context).pushNamed('/walkthrough')
/// Use:
///   AppRoutes.navigateToWalkthrough(context)
///
/// Instead of:
///   MaterialApp(home: SplashScreen())
/// Use:
///   MaterialApp(
///     initialRoute: AppRoutes.splash,
///     onGenerateRoute: AppRoutes.onGenerateRoute,
///   )

class AppRoutes {
  // ==================== Route Names (as constants) ====================
  /// Splash screen - Entry point of the app
  static const String splash = '/splash';

  /// Walkthrough screen - Onboarding flow
  static const String walkthrough = '/walkthrough';

  /// Login screen - User authentication
  static const String login = '/login';

  /// Sign up screen - User registration
  static const String signup = '/signup';

  /// OTP verification screen - OTP confirmation
  static const String otpVerification = '/otp-verification';

  /// Forgot password screen - Password reset
  static const String forgotPassword = '/forgot-password';

  /// Complete profile screen - Complete Google/Phone profile
  static const String completeProfile = '/complete-profile';

  /// Home/Main screen (add later)
  static const String home = '/home';

  /// Profile screen (add later)
  static const String profile = '/profile';

  /// Settings screen (add later)
  static const String settings = '/settings';

  /// View-All list screen (designs/collections/categories/sellers).
  static const String viewAll = '/view-all';

  /// Design detail screen.
  static const String designDetail = '/design-detail';

  /// Favorites (wishlist) screen.
  static const String favorites = '/favorites';

  // Add more routes here as you build the app
  // Convention: use lowercase with forward slash prefix

  // ==================== Route Generation ====================
  /// Main route generator - called by MaterialApp.onGenerateRoute
  ///
  /// This method determines which screen to show based on the route name
  /// and passes any arguments to the screen.
  ///
  /// QUBIT GUIDE:
  /// This function acts as the "router" in your app.
  /// Every time navigation happens, this is called to build the screen.
  ///
  /// Why centralize?
  /// - Single source of truth for all routes
  /// - Easy to add middleware (logging, analytics, etc.)
  /// - Type-safe argument passing
  /// - Prevents "route not found" errors
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    // Log navigation with arguments
    AppLogger.logNavigation(
      settings.name ?? 'unknown',
      arguments: settings.arguments,
    );

    switch (settings.name) {
      case splash:
        return _buildRoute(
          settings: settings,
          builder: (context) => const SplashScreen(),
          transitionType: _TransitionType.none,
        );

      case walkthrough:
        return _buildRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: getIt<WalkthroughBloc>(),
            child: const WalkthroughScreen(),
          ),
          transitionType: _TransitionType.fadeInSlide,
        );

      case login:
        return _buildRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: getIt<AuthBloc>(),
            child: const LoginScreen(),
          ),
          transitionType: _TransitionType.fadeInSlide,
        );

      case signup:
        return _buildRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: getIt<AuthBloc>(),
            child: const SignupScreen(),
          ),
          transitionType: _TransitionType.fadeInSlide,
        );

      case otpVerification:
        return _buildRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: getIt<AuthBloc>(),
            child: const OtpVerificationScreen(),
          ),
          transitionType: _TransitionType.fadeInSlide,
        );

      case forgotPassword:
        return _buildRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: getIt<AuthBloc>(),
            child: const ForgotPasswordScreen(),
          ),
          transitionType: _TransitionType.fadeInSlide,
        );

      case completeProfile:
        final args = settings.arguments as CompleteProfileArgs?;
        return _buildRoute(
          settings: settings,
          builder: (context) => BlocProvider.value(
            value: getIt<AuthBloc>(),
            child: CompleteProfileScreen(
              args:
                  args ??
                  CompleteProfileArgs(
                    type: 'google',
                    user: UserModel(
                      id: '',
                      email: '',
                      createdAt: DateTime.now(),
                      isActive: true,
                    ),
                  ),
            ),
          ),
          transitionType: _TransitionType.fadeInSlide,
        );

      case home:
        return _buildRoute(
          settings: settings,
          builder: (context) => const MainScreen(),
          transitionType: _TransitionType.fadeInSlide,
        );

      case AppRoutes.settings:
        return _buildRoute(
          settings: settings,
          builder: (context) => const SettingsScreen(),
          transitionType: _TransitionType.fadeInSlide,
        );

      case viewAll:
        final args = settings.arguments;
        // Supports both the legacy String argument and the {target,title} map.
        final target = args is Map
            ? (args['target'] as String? ?? 'designs')
            : (args as String? ?? 'designs');
        final title = args is Map ? args['title'] as String? : null;
        return _buildRoute(
          settings: settings,
          builder: (context) =>
              ViewAllScreen(target: target, titleOverride: title),
          transitionType: _TransitionType.fadeInSlide,
        );

      case designDetail:
        final designId = settings.arguments as String? ?? '';
        return _buildRoute(
          settings: settings,
          builder: (context) => DesignDetailScreen(designId: designId),
          transitionType: _TransitionType.fadeInSlide,
        );

      case favorites:
        return _buildRoute(
          settings: settings,
          builder: (context) => const FavoritesScreen(),
          transitionType: _TransitionType.fadeInSlide,
        );

      // Add more routes here:
      // case home:
      //   return _buildRoute(
      //     settings: settings,
      //     builder: (context) => const HomeScreen(),
      //     transitionType: _TransitionType.fadeInSlide,
      //   );
      //
      // case profile:
      //   final args = settings.arguments as ProfileArgs?;
      //   return _buildRoute(
      //     settings: settings,
      //     builder: (context) => ProfileScreen(userId: args?.userId ?? ''),
      //   );

      default:
        return _buildErrorRoute(settings);
    }
  }

  // ==================== Navigation Methods ====================
  /// Navigate to Splash Screen
  ///
  /// This is the entry point of the app. Usually called from main.dart
  /// or when user logs out.
  static Future<void> navigateToSplash(BuildContext context) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(splash, (route) => false);
  }

  /// Navigate to Walkthrough Screen
  ///
  /// Shows the onboarding flow. Called from SplashBloc when splash completes.
  static Future<void> navigateToWalkthrough(
    BuildContext context, {
    bool skipAnimation = false,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      walkthrough,
      (route) => false,
      arguments: WalkthroughArgs(skipAnimation: skipAnimation),
    );
  }

  /// Navigate to Complete Profile Screen
  ///
  /// Called after new user signs in with Google or Phone.
  /// Expects CompleteProfileArgs as arguments.
  static Future<void> navigateToCompleteProfile(
    BuildContext context,
    CompleteProfileArgs args,
  ) {
    return Navigator.of(context).pushNamed(completeProfile, arguments: args);
  }

  /// Navigate to Home Screen
  ///
  /// Called after successful login/signup.
  /// Removes all previous routes (no back button).
  static Future<void> navigateToHome(BuildContext context) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(home, (route) => false);
  }

  /// Navigate to Login Screen
  ///
  /// Called on logout. Clears all previous routes.
  static Future<void> navigateToLogin(BuildContext context) {
    return Navigator.of(
      context,
    ).pushNamedAndRemoveUntil(login, (route) => false);
  }

  /// Navigate to a View-All list. [target] e.g. `sellers`, `collections`,
  /// `collection:<id>`, `category:<id>`, `designs?sort=popularity`. [title]
  /// overrides the screen's app-bar title (e.g. the section's own title).
  static Future<void> navigateToViewAll(BuildContext context, String target,
      {String? title}) {
    return Navigator.of(context)
        .pushNamed(viewAll, arguments: {'target': target, 'title': title});
  }

  /// Navigate to a design's detail screen.
  static Future<void> navigateToDesignDetail(
      BuildContext context, String designId) {
    return Navigator.of(context)
        .pushNamed(designDetail, arguments: designId);
  }

  /// Routes a home/section target string to the right screen.
  static void handleTarget(BuildContext context, String? target) {
    if (target == null || target.isEmpty) return;
    if (target.startsWith('design:')) {
      navigateToDesignDetail(context, target.substring('design:'.length));
    } else if (target.startsWith('seller:')) {
      // No seller detail screen yet — show all sellers.
      navigateToViewAll(context, 'sellers');
    } else {
      // sellers | collections | collection:<id> | category:<id> | designs...
      navigateToViewAll(context, target);
    }
  }

  //###############################################

  static Future<void> push(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamed(routeName, arguments: arguments);
  }

  /// Remove all previous routes and replacance with new route (no back button)
  ///
  /// Use when:
  /// - Navigating after login/logout
  /// - Navigating to a new major section
  /// - User shouldn't be able to go back
  static Future<void> pushReplacementAll(
    BuildContext context,
    String routeName, {
    Object? arguments,
  }) {
    return Navigator.of(context).pushNamedAndRemoveUntil(
      routeName,
      (route) => false,
      arguments: arguments,
    );
  }

  // ==================== Helper Methods ====================
  /// Build a route with custom transition animation
  ///
  /// This creates the actual Route object that Flutter uses.
  /// Supports different transition types for visual variety.
  static Route<dynamic> _buildRoute({
    required RouteSettings settings,
    required WidgetBuilder builder,
    required _TransitionType transitionType,
  }) {
    return PageRouteBuilder(
      settings: settings,
      pageBuilder: (context, animation, secondaryAnimation) {
        return builder(context);
      },
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return _buildTransition(
          animation: animation,
          child: child,
          transitionType: transitionType,
        );
      },
    );
  }

  /// Build transition animation based on type
  static Widget _buildTransition({
    required Animation<double> animation,
    required Widget child,
    required _TransitionType transitionType,
  }) {
    switch (transitionType) {
      case _TransitionType.none:
        // No animation
        return child;

      case _TransitionType.fadeInSlide:
        // Fade in + slide from right
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(1.0, 0.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: FadeTransition(opacity: animation, child: child),
        );

      case _TransitionType.fadeOnly:
        // Just fade in
        return FadeTransition(opacity: animation, child: child);

      case _TransitionType.slideFromBottom:
        // Slide from bottom
        return SlideTransition(
          position:
              Tween<Offset>(
                begin: const Offset(0.0, 1.0),
                end: Offset.zero,
              ).animate(
                CurvedAnimation(parent: animation, curve: Curves.easeInOut),
              ),
          child: child,
        );

      case _TransitionType.scale:
        // Scale animation
        return ScaleTransition(scale: animation, child: child);
    }
  }

  /// Build error route when route not found
  static Route<dynamic> _buildErrorRoute(RouteSettings settings) {
    return MaterialPageRoute(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Error')),
        body: Center(
          child: Text(
            'Route not found: ${settings.name}',
            style: const TextStyle(fontSize: 16),
          ),
        ),
      ),
    );
  }
}

/// Transition types for route animations
enum _TransitionType { none, fadeInSlide, fadeOnly, slideFromBottom, scale }

/// Extension on BuildContext for easier navigation
///
/// Usage:
///   context.navigateToWalkthrough()
/// instead of:
///   AppRoutes.navigateToWalkthrough(context)
extension AppNavigationExtension on BuildContext {
  /// Navigate to Walkthrough
  Future<void> navigateToWalkthrough({bool skipAnimation = false}) {
    return AppRoutes.navigateToWalkthrough(this, skipAnimation: skipAnimation);
  }

  /// Navigate to Splash
  Future<void> navigateToSplash() {
    return AppRoutes.navigateToSplash(this);
  }

  /// Navigate to Login
  Future<void> navigateToLogin() {
    return AppRoutes.push(this, AppRoutes.login);
  }

  /// Navigate to Signup
  Future<void> navigateToSignup() {
    return AppRoutes.push(this, AppRoutes.signup);
  }

  /// Navigate to OTP Verification
  Future<void> navigateToOtpVerification() {
    return AppRoutes.push(this, AppRoutes.otpVerification);
  }

  /// Navigate to Forgot Password
  Future<void> navigateToForgotPassword() {
    return AppRoutes.push(this, AppRoutes.forgotPassword);
  }

  /// Navigate to Complete Profile
  Future<void> navigateToCompleteProfile(CompleteProfileArgs args) {
    return AppRoutes.navigateToCompleteProfile(this, args);
  }

  /// Navigate to Home
  Future<void> navigateToHome() {
    return AppRoutes.navigateToHome(this);
  }

  /// Navigate to Settings
  Future<void> navigateToSettings() {
    return AppRoutes.push(this, AppRoutes.settings);
  }
}

// ==================== Navigation Documentation ====================
/// QUICK START GUIDE:
///
/// 1. IN MAIN.dart:
///    ```dart
///    MaterialApp(
///      initialRoute: AppRoutes.splash,
///      onGenerateRoute: AppRoutes.onGenerateRoute,
///    )
///    ```
///
/// 2. TO NAVIGATE FROM A SCREEN:
///    ```dart
///    // Method 1: Using AppRoutes directly
///    AppRoutes.navigateToWalkthrough(context);
///
///    // Method 2: Using extension (shorter)
///    context.navigateToWalkthrough();
///
///    // Method 3: Using generic push
///    AppRoutes.push(context, AppRoutes.walkthrough);
///    ```
///
/// 3. TO ADD A NEW ROUTE:
///    a) Add route name constant:
///       static const String newScreen = '/new-screen';
///
///    b) Add case in onGenerateRoute:
///       case newScreen:
///         return _buildRoute(
///           settings: settings,
///           builder: (context) => const NewScreen(),
///         );
///
///    c) Add navigation method:
///       static Future<void> navigateToNewScreen(BuildContext context) {
///         return Navigator.of(context).pushNamed(newScreen);
///       }
///
///    d) (Optional) Add extension method for easier access:
///       Future<void> navigateToNewScreen() =>
///           AppRoutes.navigateToNewScreen(this);
///
/// 4. TO PASS ARGUMENTS:
///    a) Create argument class:
///       static class NewScreenArgs {
///         final String title;
///         NewScreenArgs({required this.title});
///       }
///
///    b) Pass in navigation:
///       AppRoutes.push(
///         context,
///         AppRoutes.newScreen,
///         arguments: NewScreenArgs(title: 'Hello'),
///       )
///
///    c) Receive in onGenerateRoute:
///       case newScreen:
///         final args = settings.arguments as NewScreenArgs?;
///         return _buildRoute(
///           settings: settings,
///           builder: (context) => NewScreen(title: args?.title ?? ''),
///         );
///
/// BENEFITS:
/// ✅ All routes in one file
/// ✅ Type-safe arguments
/// ✅ Consistent navigation
/// ✅ Easy to add middleware
/// ✅ Easy to debug
/// ✅ Easy to add animations
