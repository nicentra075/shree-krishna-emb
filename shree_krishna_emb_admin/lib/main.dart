import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/firebase_options.dart';
import 'package:shree_krishna_emb_admin/core/di/service_locator.dart';
import 'package:shree_krishna_emb_admin/core/utils/app_logger.dart';
import 'package:shree_krishna_emb_admin/core/utils/global_navigator.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'package:shree_krishna_emb_admin/routes/app_routes.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';

void main() {
  // Framework (build/layout/render) errors → console with stack trace.
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    AppLogger.logError(
      details.exceptionAsString(),
      error: details.exception,
      stackTrace: details.stack,
    );
  };

  // Uncaught async/platform errors → console with stack trace.
  PlatformDispatcher.instance.onError = (error, stack) {
    AppLogger.logError('Uncaught error', error: error, stackTrace: stack);
    return true;
  };

  // Run everything in a guarded zone so any other uncaught error is logged too.
  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    try {
      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );
    } catch (e, s) {
      // Firebase not configured for this platform (e.g., web)
      // This is expected for web - will be configured via FlutterFire CLI later
      AppLogger.logError('Firebase.initializeApp failed',
          error: e, stackTrace: s);
    }

    final prefs = await SharedPreferences.getInstance();
    await AppLocalization.initialize(prefs);

    await setupAdminServiceLocator(prefs);

    // Initialize snackbar with global navigator
    AppSnackbar.setNavigatorKey(GlobalNavigator.navigatorKey);

    runApp(const AdminApp());
  }, (error, stack) {
    AppLogger.logError('Uncaught zone error', error: error, stackTrace: stack);
  });
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider<AdminAuthBloc>(create: (context) => getIt<AdminAuthBloc>()),
        // Persistent theme mode (light/dark/system), shared via core package
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
      ],
      child: BlocBuilder<ThemeCubit, ThemeMode>(
        builder: (context, themeMode) {
          // Rebuild the whole tree on locale change (strings are static)
          return ValueListenableBuilder<String>(
            valueListenable: AppLocalization.localeNotifier,
            builder: (context, locale, _) {
              return MaterialApp(
                debugShowCheckedModeBanner: false,
                title: 'Shree Krishna Embroidery - Admin',
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
