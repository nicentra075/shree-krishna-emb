import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';
import 'package:shree_krishna_emb/core/di/service_locator.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_bloc.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_event.dart';
import 'package:shree_krishna_emb/bloc/auth/auth_state.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<AuthBloc>.value(
      value: getIt<AuthBloc>(),
      child: BlocConsumer<AuthBloc, AuthState>(
        listener: (context, state) {
          if (state is AuthUnauthenticated) {
            AppRoutes.navigateToLogin(context);
          } else if (state is AuthError) {
            AppSnackbar.showError(state.message);
          }
        },
        builder: (context, state) {
          return Stack(
            children: [
              Scaffold(
                backgroundColor: Theme.of(context).colorScheme.surface,
                body: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),

                      // User Header
                      _buildUserHeader(context),
                      const SizedBox(height: 24),

                      // Wallet Section
                      _buildWalletSection(context),
                      const SizedBox(height: 24),

                      // Membership Status
                      _buildMembershipSection(context),
                      const SizedBox(height: 24),

                      // My Work / My Selling Products
                      _buildStudioManagementSection(context),
                      const SizedBox(height: 24),

                      // Settings
                      _buildSettingsSection(context),
                      const SizedBox(height: 24),

                      // Support & Resources
                      _buildSupportSection(context),
                      const SizedBox(height: 24),

                      // Logout
                      _buildLogoutSection(context),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              if (state is AuthLoading)
                Positioned.fill(
                  child: ColoredBox(
                    color: Colors.black.withValues(alpha: 0.3),
                    child: const Center(child: AppLoader()),
                  ),
                ),
            ],
          );
        },
      ),
    );
  }

  static Widget _buildUserHeader(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            AppTheme.primaryLight.withValues(alpha: 0.12),
            AppTheme.secondaryLight.withValues(alpha: 0.12),
          ],
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 36,
            backgroundColor: AppTheme.secondaryLight,
            child: const Icon(
              Icons.person,
              size: 36,
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
                    Flexible(
                      child: Text(
                        // TODO: Replace with authenticated user's name
                        'Welcome back',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.headlineMedium(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Icon(
                      Icons.verified,
                      size: 18,
                      color: AppTheme.primaryLight,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  // TODO: Replace with authenticated user's phone
                  '+91 98765 43210',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
                Text(
                  // TODO: Replace with authenticated user's email
                  'user@example.com',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall(
                    color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildWalletSection(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            AppLocalization.strings.wallet,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium(),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      '₹4,250.00',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineMedium(
                        color: AppTheme.primaryLight,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      AppLocalization.strings.availableBalance,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.labelSmall(),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 12),
              ElevatedButton(
                onPressed: () {
                  // TODO: Add funds
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondaryLight,
                ),
                child: Text(
                  AppLocalization.strings.addFunds,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  static Widget _buildMembershipSection(BuildContext context) {
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
              Flexible(
                child: Text(
                  AppLocalization.strings.goldPlan,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
                ),
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
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: AppTextStyles.labelSmall(color: Colors.white),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            AppLocalization.strings.membershipExpires,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelSmall(
              color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6),
            ),
          ),
        ],
      ),
    );
  }

  static Widget _buildStudioManagementSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.studioManagement,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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
                  context,
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
                  context,
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
    BuildContext context,
    String label,
    IconData icon,
    VoidCallback onTap,
  ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Theme.of(context).colorScheme.outlineVariant),
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
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
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
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(context,
          AppLocalization.strings.favorites,
          Icons.favorite_outline,
          () => Navigator.pushNamed(context, AppRoutes.favorites),
        ),
        _buildSettingsTile(context,
          AppLocalization.strings.settings,
          Icons.settings_outlined,
          () => context.navigateToSettings(),
        ),
        _buildSettingsTile(context,
          AppLocalization.strings.notifications,
          Icons.notifications_outlined,
          () {
            // TODO: Navigate to notifications settings
          },
        ),
        BlocBuilder<ThemeCubit, ThemeMode>(
          builder: (context, themeMode) {
            return _buildSettingsTile(context,
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
        _buildSettingsTile(context,
          AppLocalization.strings.switchToDesigner,
          Icons.person_add_outlined,
          () {
            // TODO: Switch to designer account
          },
        ),
      ],
    );
  }

  static Widget _buildSupportSection(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Text(
            AppLocalization.strings.support,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.labelMedium(fontWeight: FontWeight.w600),
          ),
        ),
        const SizedBox(height: 12),
        _buildSettingsTile(context,
          AppLocalization.strings.whatsappSupport,
          Icons.chat_outlined,
          () {
            // TODO: Open WhatsApp
          },
        ),
        _buildSettingsTile(context,
          AppLocalization.strings.contactUs,
          Icons.mail_outlined,
          () {
            // TODO: Open contact form
          },
        ),
        _buildSettingsTile(context,
          AppLocalization.strings.aboutUs,
          Icons.info_outlined,
          () {
            // TODO: Navigate to about
          },
        ),
        _buildSettingsTile(context,
          AppLocalization.strings.privacyPolicy,
          Icons.privacy_tip_outlined,
          () {
            // TODO: Open privacy policy
          },
        ),
        _buildSettingsTile(context,
          AppLocalization.strings.termsConditions,
          Icons.description_outlined,
          () {
            // TODO: Open terms
          },
        ),
      ],
    );
  }

  static Widget _buildLogoutSection(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: AppButton(
        label: AppLocalization.strings.logout,
        variant: AppButtonVariant.destructive,
        isFullWidth: true,
        leadingIcon: Icons.logout,
        onPressed: () => _confirmLogout(context),
      ),
    );
  }

  static Future<void> _confirmLogout(BuildContext context) async {
    final confirmed = await AppDialog.showConfirm(
      context,
      title: AppLocalization.strings.logout,
      message: AppLocalization.strings.logoutConfirmMessage,
      confirmLabel: AppLocalization.strings.logout,
      cancelLabel: AppLocalization.strings.cancel,
      isDestructive: true,
    );

    if (confirmed == true && context.mounted) {
      context.read<AuthBloc>().add(const SignOutEvent());
    }
  }

  static Widget _buildSettingsTile(
    BuildContext context,
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
            Icon(icon, color: Theme.of(context).colorScheme.onSurface),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.labelMedium(),
              ),
            ),
            trailing ??
                Icon(
                  Icons.chevron_right,
                  color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5),
                ),
          ],
        ),
      ),
    );
  }
}
