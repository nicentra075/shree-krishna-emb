import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';

class AdminLoginScreen extends StatelessWidget {
  const AdminLoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppAppBar(
        title: AppLocalization.strings.login,
        centerTitle: true,
      ),
      body: const Center(
        child: Text('Admin Login Screen - Coming Soon (Task 6)'),
      ),
    );
  }
}
