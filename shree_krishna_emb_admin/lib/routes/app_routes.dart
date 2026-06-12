import 'package:flutter/material.dart';
import 'package:shree_krishna_emb_admin/screens/splash/splash_screen.dart';
import 'package:shree_krishna_emb_admin/screens/login/admin_login_screen.dart';
import 'package:shree_krishna_emb_admin/screens/login/forgot_password_screen.dart';
import 'package:shree_krishna_emb_admin/screens/dashboard/admin_dashboard_screen.dart';
import 'package:shree_krishna_emb_admin/screens/settings/admin_settings_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String login = '/login';
  static const String forgotPassword = '/forgot-password';
  static const String home = '/home';
  static const String settings = '/settings';

  // Route generation
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case login:
        return MaterialPageRoute(
          builder: (_) => const AdminLoginScreen(),
          settings: settings,
        );
      case forgotPassword:
        return MaterialPageRoute(
          builder: (_) => const ForgotPasswordScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const AdminDashboardScreen(),
          settings: settings,
        );
      case AppRoutes.settings:
        return MaterialPageRoute(
          builder: (_) => const AdminSettingsScreen(),
          settings: settings,
        );
      default:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
    }
  }
}
