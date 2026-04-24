import 'package:flutter/material.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import '../../theme/design_system_theme.dart';
import 'package:shree_krishna_core/config/app_theme_config.dart';

/// Offline indicator banner component
class AppConnectivityBanner extends StatelessWidget {
  final Widget child;
  final AppThemeConfig? themeConfig;

  const AppConnectivityBanner({
    required this.child,
    this.themeConfig,
    super.key,
  });

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final isOffline = snapshot.data?.contains(ConnectivityResult.none) ?? false;

        return Column(
          children: [
            if (isOffline)
              Container(
                color: DesignSystemTheme.warningColor(themeConfig),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: Row(
                  children: [
                    const Icon(Icons.wifi_off, color: Colors.white, size: 18),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'No internet connection',
                        style: TextStyle(color: Colors.white, fontSize: 14),
                      ),
                    ),
                  ],
                ),
              ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
