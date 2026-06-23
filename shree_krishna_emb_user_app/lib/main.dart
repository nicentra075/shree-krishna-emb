import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/firebase_options.dart';
import 'package:shree_krishna_emb/bloc/wishlist/wishlist_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/core/utils/app_logger.dart';
import 'package:shree_krishna_emb/core/utils/global_navigator.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

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

  runZonedGuarded(() async {
    WidgetsFlutterBinding.ensureInitialized();

    await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform);

    final prefs = await SharedPreferences.getInstance();
    await AppLocalization.initialize(prefs);

    await setupServiceLocator(prefs);

    // Initialize snackbar with global navigator
    AppSnackbar.setNavigatorKey(GlobalNavigator.navigatorKey);

    runApp(const MainApp());
  }, (error, stack) {
    AppLogger.logError('Uncaught zone error', error: error, stackTrace: stack);
  });
}

class MainApp extends StatelessWidget {
  const MainApp({super.key});

  @override
  Widget build(BuildContext context) {
    // Persistent theme mode (light/dark/system) + app-wide favorites state.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        BlocProvider<WishlistCubit>.value(value: getIt<WishlistCubit>()),
      ],
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
