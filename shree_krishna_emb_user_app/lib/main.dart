import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/firebase_options.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/core/utils/global_navigator.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);

  final prefs = await SharedPreferences.getInstance();
  await AppLocalization.initialize(prefs);

  await setupServiceLocator(prefs);

  // Initialize snackbar with global navigator
  AppSnackbar.setNavigatorKey(GlobalNavigator.navigatorKey);

  runApp(const MainApp());
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Persistent theme mode (light/dark/system), shared via core package
    return BlocProvider<ThemeCubit>.value(
      value: getIt<ThemeCubit>(),
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          // Rebuild the whole tree on locale change (strings are static)
          return ValueListenableBuilder<String>(
            valueListenable: AppLocalization.localeNotifier,
            builder: (context, locale, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Shree Krishna Embroidery',
                theme: AppTheme.lightTheme,
                darkTheme: AppTheme.darkTheme,
                themeMode: themeMode,
                // Global navigator key for accessing context anywhere in the app
                navigatorKey: GlobalNavigator.navigatorKey,
                // Centralized routing system
                initialRoute: AppRoutes.splash,
                onGenerateRoute: AppRoutes.onGenerateRoute,
              );
            },
          );
        },
      ),
    );
  }
}
