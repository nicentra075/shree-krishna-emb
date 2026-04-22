import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_emb/bloc/walkthrough/walkthrough_bloc.dart';
import 'package:shree_krishna_emb/screens/walkthrough/walkthrough_screen.dart';
import 'package:shree_krishna_emb/screens/splash/splash_screen.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  bool _isDarkMode = false;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shree Krishna Embroidery',
      // Apply custom theme with dark mode support
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: _isDarkMode ? ThemeMode.dark : ThemeMode.light,
      // Splash screen is the initial route
      home: const SplashScreen(),
      // Named routes for navigation
      routes: {
        '/splash': (context) => const SplashScreen(),
        '/walkthrough': (context) => BlocProvider(
          create: (context) => WalkthroughBloc(),
          child: const WalkthroughScreen(),
        ),
      },
    );
  }

  /// Toggle between light and dark mode
  /// Usage: Get the MainApp state and call this method
  void toggleDarkMode() {
    setState(() {
      _isDarkMode = !_isDarkMode;
    });
  }
}
