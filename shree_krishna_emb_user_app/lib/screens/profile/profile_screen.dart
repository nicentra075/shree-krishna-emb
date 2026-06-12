import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            // Branding Section
            _buildBrandingSection(),
            const SizedBox(height: 24),

            // User Header
            _buildUserHeader(),
            const SizedBox(height: 24),

            // Wallet Section
            _buildWalletSection(),
            const SizedBox(height: 24),

            // Membership Status
            _buildMembershipSection(),
            const SizedBox(height: 24),

            // My Work / My Selling Products
            _buildStudioManagementSection(),
            const SizedBox(height: 24),

            // Settings
            _buildSettingsSection(context),
            const SizedBox(height: 24),

            // Support & Resources
            _buildSupportSection(),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  static Widget _buildBrandingSection() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.strings.appName,
            style: AppTextStyles.headlineLarge(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            AppLocalization.strings.appTagline,
            style: AppTextStyles.bodyMedium(
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.7),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildUserHeader() {
    return Container(
      padding: const EdgeInsets.all(16),
      child: Row(
        children: [
          CircleAvatar(
            radius: 40,
            backgroundColor: AppTheme.secondaryLight,
            child: Icon(
              Icons.person,
              size: 40,
              color: Colors.white,
            ),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      'Shree Krishna EMB',
                      style: AppTextStyles.headlineMedium(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.verified,
                      size: 16,
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '+91 98765 43210',
                  style: AppTextStyles.labelSmall(
                    color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  'user@example.com',
                  style: AppTextStyles.labelSmall(
                    color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildWalletSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.surfaceContainerLowLight,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.strings.wallet,
            style: AppTextStyles.labelMedium(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '₹4,250.00',
                    style: AppTextStyles.headlineMedium(
                      color: AppTheme.primaryLight,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    AppLocalization.strings.availableBalance,
                    style: AppTextStyles.labelSmall(),
                  ),
                ],
              ),
              ElevatedButton(
                onPressed: () {
                  // TODO: Add funds
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryLight,
                ),
                child: Text(AppLocalization.strings.addFunds),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildMembershipSection() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.secondaryLight.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                AppLocalization.strings.goldPlan,
                style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.primaryLight,
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '24 days',
                  style: AppTextStyles.labelSmall(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalization.strings.membershipExpires,
            style: AppTextStyles.labelSmall(
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStudioManagementSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.studioManagement,
            style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Row(
            children: [
              Expanded(
                child: _buildStudioCard(
                  AppLocalization.strings.myWork,
                  Icons.work_outline,
                  () {
                    // TODO: Navigate to my work
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildStudioCard(
                  AppLocalization.strings.mySellingProducts,
                  Icons.storefront_outlined,
                  () {
                    // TODO: Navigate to selling products
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  static Widget _buildStudioCard(
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppTheme.surfaceContainerLowLight,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppTheme.borderLight),
        ),
        child: Column(
          children: [
            Icon(
              icon,
              color: AppTheme.primaryLight,
              size: 24,
            ),
            const SizedBox(height: 8),
            Text(
              label,
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall(),
            ),
          ],
        ),
      ),
    );
  }

  static Widget _buildSettingsSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.settings,
            style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(
          AppLocalization.strings.settings,
          Icons.settings_outlined,
          () => context.navigateToSettings(),
        ),
        _buildSettingsTile(
          AppLocalization.strings.notifications,
          Icons.notifications_outlined,
          () {
            // TODO: Navigate to notifications settings
          },
        ),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return _buildSettingsTile(
              AppLocalization.strings.darkMode,
              Icons.dark_mode_outlined,
              () => context.read<ThemeCubit>().toggle(),
              trailing: Switch(
                value: themeMode == ThemeMode.dark,
                onChanged: (_) => context.read<ThemeCubit>().toggle(),
              ),
            );
          },
        ),
        _buildSettingsTile(
          AppLocalization.strings.switchToDesigner,
          Icons.person_add_outlined,
          () {
            // TODO: Switch to designer account
          },
        ),
      ],
    );
  }

  static Widget _buildSupportSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.support,
            style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(
          AppLocalization.strings.whatsappSupport,
          Icons.chat_outlined,
          () {
            // TODO: Open WhatsApp
          },
        ),
        _buildSettingsTile(
          AppLocalization.strings.contactUs,
          Icons.mail_outlined,
          () {
            // TODO: Open contact form
          },
        ),
        _buildSettingsTile(
          AppLocalization.strings.aboutUs,
          Icons.info_outlined,
          () {
            // TODO: Navigate to about
          },
        ),
        _buildSettingsTile(
          AppLocalization.strings.privacyPolicy,
          Icons.privacy_tip_outlined,
          () {
            // TODO: Open privacy policy
          },
        ),
        _buildSettingsTile(
          AppLocalization.strings.termsConditions,
          Icons.description_outlined,
          () {
            // TODO: Open terms
          },
        ),
      ],
    );
  }

  static Widget _buildSettingsTile(
    String label,
    IconData icon,
    VoidCallback onTap, {
    Widget? trailing,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            Icon(icon, color: AppTheme.onSurfaceLight),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: AppTextStyles.labelMedium(),
              ),
            ),
            trailing ?? Icon(
              Icons.chevron_right,
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}
