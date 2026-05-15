import 'package:flutter/material.dart';
import 'package:shree_krishna_emb_admin/screens/splash/splash_screen.dart';

class AppRoutes {
  // Route names
  static const String splash = '/splash';
  static const String home = '/home';

  // Route generation
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case splash:
        return MaterialPageRoute(
          builder: (_) => const SplashScreen(),
          settings: settings,
        );
      case home:
        return MaterialPageRoute(
          builder: (_) => const AdminHomePage(),
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

// Temporary home page - replace with actual dashboard later
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
