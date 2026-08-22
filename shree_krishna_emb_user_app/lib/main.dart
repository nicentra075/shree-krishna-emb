import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:screen_protector/screen_protector.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/firebase_options.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';
import 'package:shree_krishna_emb/bloc/wishlist/wishlist_cubit.dart';
import 'package:shree_krishna_emb/bloc/cart/cart_cubit.dart';
import 'package:shree_krishna_emb/bloc/purchases/purchases_cubit.dart';
import 'package:shree_krishna_emb/bloc/platform_config/platform_config_cubit.dart';
import 'package:shree_krishna_emb/bloc/notifications/notification_cubit.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/core/utils/app_logger.dart';
import 'package:shree_krishna_emb/core/utils/global_navigator.dart';
import 'package:shree_krishna_emb/data/services/notification_service.dart';
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

  runZonedGuarded(
    () async {
      WidgetsFlutterBinding.ensureInitialized();

      // Block screenshots/screen recording app-wide to protect design previews.
      await _enableScreenProtection();

      await Firebase.initializeApp(
        options: DefaultFirebaseOptions.currentPlatform,
      );

      // Must be registered before runApp so background/terminated pushes are
      // handled even if the app was launched by tapping a notification.
      FirebaseMessaging.onBackgroundMessage(fcmBackgroundHandler);

      final prefs = await SharedPreferences.getInstance();
      await AppLocalization.initialize(prefs);

      await setupServiceLocator(prefs);

      // Sets up local-notification display + foreground/background tap
      // listeners. Token registration happens per-user in the auth listener.
      await getIt<NotificationService>().init();

      // Initialize snackbar with global navigator
      AppSnackbar.setNavigatorKey(GlobalNavigator.navigatorKey);

      runApp(const MainApp());
    },
    (error, stack) {
      AppLogger.logError(
        'Uncaught zone error',
        error: error,
        stackTrace: stack,
      );
    },
  );
}

/// Enables app-wide capture protection:
///  - Android: sets FLAG_SECURE, which blocks screenshots AND makes screen
///    recordings/casts render black for every screen.
///  - iOS: prevents screenshots (captures come out blank) and obscures the app
///    snapshot in the app switcher. (iOS has no API to fully block recording.)
/// Wrapped in try/catch so a platform that doesn't support it never blocks
/// startup.
Future<void> _enableScreenProtection() async {
  try {
    await ScreenProtector.preventScreenshotOn();
    await ScreenProtector.protectDataLeakageOn();
  } catch (e) {
    AppLogger.logError('Failed to enable screen protection', error: e);
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  // Cached uid of the last authenticated user. AuthUnauthenticated/
  // AuthSuspended fire *after* FirebaseAuth.signOut() completes, so
  // FirebaseAuth.instance.currentUser is already null by then - we can't
  // rely on it to know whose FCM token to remove. Track it ourselves.
  String? _lastUid;

  @override
  Widget build(BuildContext context) {
    // Persistent theme mode (light/dark/system) + app-wide favorites state.
    return MultiBlocProvider(
      providers: [
        BlocProvider<ThemeCubit>.value(value: getIt<ThemeCubit>()),
        BlocProvider<AuthBloc>.value(value: getIt<AuthBloc>()),
        BlocProvider<WishlistCubit>.value(value: getIt<WishlistCubit>()),
        BlocProvider<CartCubit>.value(value: getIt<CartCubit>()),
        BlocProvider<PurchasesCubit>.value(value: getIt<PurchasesCubit>()),
        BlocProvider<PlatformConfigCubit>.value(
          value: getIt<PlatformConfigCubit>(),
        ),
        BlocProvider<NotificationCubit>.value(
          value: getIt<NotificationCubit>(),
        ),
      ],
      // App-wide push/notification-feed lifecycle: register/clear the FCM
      // token and start/stop the in-app notification stream as the signed-in
      // user changes, regardless of which screen is currently active.
      child: BlocListener<AuthBloc, AuthState>(
        listener: (context, state) async {
          final svc = getIt<NotificationService>();
          if (state is AuthAuthenticated) {
            _lastUid = state.user.id;
            await svc.onLogin(state.user.id);
            getIt<NotificationCubit>().start(state.user.id);
          } else if (state is AuthUnauthenticated || state is AuthSuspended) {
            final uid =
                _lastUid ?? FirebaseAuth.instance.currentUser?.uid ?? '';
            await svc.onLogout(uid);
            getIt<NotificationCubit>().stop();
            _lastUid = null;
          }
        },
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
      ),
    );
  }
}
