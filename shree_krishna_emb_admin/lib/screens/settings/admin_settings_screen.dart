import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/screens/settings/settings_content_view.dart';

/// Standalone settings route (used when navigated directly, e.g. /settings).
/// Inside the dashboard, [SettingsContentView] is embedded in the content
/// area instead — see AdminDashboardScreen._buildContent.
class AdminSettingsScreen extends StatelessWidget {
  const AdminSettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalization.strings.settings,
        onBack: () => Navigator.of(context).pop(),
      ),
      body: const SafeArea(child: SettingsContentView()),
    );
  }
}
