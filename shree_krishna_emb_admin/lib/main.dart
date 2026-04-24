import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:shree_krishna_emb_admin/firebase_options.dart';
import 'package:shree_krishna_emb_admin/core/di/service_locator.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  final prefs = await SharedPreferences.getInstance();
  await AppLocalization.initialize(prefs);

  await setupAdminServiceLocator(prefs);

  runApp(const AdminApp());
}

class AdminApp extends StatelessWidget {
  const AdminApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Shree Krishna Embroidery - Admin',
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFF8f4e00), // Primary Saffron
          brightness: Brightness.light,
        ),
      ),
      darkTheme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xFFff9933), // Light Saffron
          brightness: Brightness.dark,
        ),
      ),
      themeMode: ThemeMode.light,
      home: const AdminHomePage(),
    );
  }
}

class AdminHomePage extends StatelessWidget {
  const AdminHomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin Dashboard'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Shree Krishna Embroidery',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 16),
            const Text(
              'Admin Panel - Coming Soon',
              style: TextStyle(fontSize: 16),
            ),
          ],
        ),
      ),
    );
  }
}
