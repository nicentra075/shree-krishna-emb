import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/firebase_options.dart';
import 'package:shree_krishna_emb_admin/core/di/service_locator.dart';
import 'package:shree_krishna_emb_admin/core/utils/global_navigator.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'package:shree_krishna_emb_admin/routes/app_routes.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // Firebase not configured for this platform (e.g., web)
    // This is expected for web - will be configured via FlutterFire CLI later
  }

  final prefs = await SharedPreferences.getInstance();
  await AppLocalization.initialize(prefs);

  await setupAdminServiceLocator(prefs);

  // Initialize snackbar with global navigator
  AppSnackbar.setNavigatorKey(GlobalNavigator.navigatorKey);

  runApp(const AdminApp());
}

class AdminApp extends StatefulWidget {
  const AdminApp({super.key});

  @override
  State<AdminApp> createState() => _AdminAppState();
}

class _AdminAppState extends State<AdminApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AdminAuthBloc>(
      create: (context) => getIt<AdminAuthBloc>(),
      child: MaterialApp(
        debugShowCheckedModeBanner: false,
        title: 'Shree Krishna Embroidery - Admin',
        // Apply custom theme with dark mode support
        theme: AppTheme.lightTheme,
        darkTheme: AppTheme.darkTheme,
        themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
        // Global navigator key for accessing context anywhere in the app
        navigatorKey: GlobalNavigator.navigatorKey,
        // Centralized routing system
        initialRoute: AppRoutes.splash,
        onGenerateRoute: AppRoutes.onGenerateRoute,
      ),
    );
  }

  /// Toggle between light and dark mode
  /// Usage: Get the AdminApp state and call this method
  void toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
}
