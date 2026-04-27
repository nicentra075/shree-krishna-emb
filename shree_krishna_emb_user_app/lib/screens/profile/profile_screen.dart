import 'package:flutter/material.dart';
import 'package:animate_do/animate_do.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';
import 'package:shree_krishna_emb/routes/app_routes.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return Scaffold(
      backgroundColor: AppTheme.surfaceLight,
      body: SingleChildScrollView(
        child: Column(
          children: [
            _buildProfileHeader(context),
            _buildStatsSection(context),
            _buildMenuSection(context, strings),
            _buildLogoutButton(context, strings),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context) {
    return FadeInDown(
      duration: const Duration(milliseconds: 500),
      child: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              AppTheme.primaryLight,
              AppTheme.primaryDark,
            ],
          ),
        ),
        child: Column(
          children: [
            const SizedBox(height: 40),
            // Avatar
            FadeInUp(
              delay: const Duration(milliseconds: 200),
              duration: const Duration(milliseconds: 600),
              child: Container(
                width: 100,
                height: 100,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: Colors.white,
                    width: 4,
                  ),
                  boxShadow: [
                    BoxShadow(
                      color: AppTheme.primaryDark.withValues(alpha: 0.3),
                      blurRadius: 20,
                      offset: const Offset(0, 8),
                    ),
                  ],
                ),
                child: Container(
                  decoration: const BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.white10,
                  ),
                  child: Center(
                    child: Icon(
                      Icons.person,
                      size: 50,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),

            // User Name
            FadeInUp(
              delay: const Duration(milliseconds: 300),
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Aisha Patel',
                style: AppTextStyles.headlineMedium(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),

            // User Role/Status
            FadeInUp(
              delay: const Duration(milliseconds: 400),
              duration: const Duration(milliseconds: 600),
              child: Text(
                'Embroidery Enthusiast',
                style: AppTextStyles.bodyMedium(
                  color: Colors.white70,
                ),
              ),
            ),
            const SizedBox(height: 24),

            // User Info Row
            FadeInUp(
              delay: const Duration(milliseconds: 500),
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.email_outlined,
                        label: 'aisha@email.com',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 8),

            FadeInUp(
              delay: const Duration(milliseconds: 550),
              duration: const Duration(milliseconds: 600),
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: Row(
                  children: [
                    Expanded(
                      child: _buildInfoChip(
                        icon: Icons.phone_outlined,
                        label: '+91 98765 43210',
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoChip({required IconData icon, required String label}) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: Colors.white70, size: 18),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            label,
            style: AppTextStyles.bodySmall(
              color: Colors.white70,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  Widget _buildStatsSection(BuildContext context) {
    return FadeInUp(
      delay: const Duration(milliseconds: 600),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: Row(
          children: [
            Expanded(
              child: _buildStatCard(
                icon: Icons.shopping_bag_outlined,
                value: '12',
                label: 'Orders',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.favorite_outline,
                value: '8',
                label: 'Wishlist',
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: _buildStatCard(
                icon: Icons.star_outline,
                value: '4.8',
                label: 'Rating',
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatCard({
    required IconData icon,
    required String value,
    required String label,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        color: AppTheme.onSurfaceLight.withValues(alpha: 0.05),
        border: Border.all(
          color: AppTheme.onSurfaceLight.withValues(alpha: 0.1),
        ),
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            icon,
            color: AppTheme.primaryLight,
            size: 24,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium(
              color: AppTheme.primaryLight,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: AppTextStyles.bodySmall(
              color: AppTheme.onSurfaceLight.withValues(alpha: 0.6),
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildMenuSection(BuildContext context, dynamic strings) {
    final menuItems = [
      {
        'icon': Icons.person_outline,
        'label': 'Edit Profile',
        'onTap': () {
          // TODO: Navigate to edit profile
        },
      },
      {
        'icon': Icons.location_on_outlined,
        'label': 'Saved Addresses',
        'onTap': () {
          // TODO: Navigate to saved addresses
        },
      },
      {
        'icon': Icons.payment_outlined,
        'label': 'Payment Methods',
        'onTap': () {
          // TODO: Navigate to payment methods
        },
      },
      {
        'icon': Icons.notifications_outlined,
        'label': 'Notifications',
        'onTap': () {
          // TODO: Navigate to notifications settings
        },
      },
      {
        'icon': Icons.help_outline,
        'label': 'Help & Support',
        'onTap': () {
          // TODO: Navigate to help
        },
      },
      {
        'icon': Icons.privacy_tip_outlined,
        'label': 'Privacy & Terms',
        'onTap': () {
          // TODO: Navigate to privacy
        },
      },
    ];

    return FadeInUp(
      delay: const Duration(milliseconds: 700),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: AppTheme.textDark.withValues(alpha: 0.06),
                blurRadius: 16,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          child: Column(
            children: List.generate(
              menuItems.length,
              (index) {
                final item = menuItems[index];
                final isLast = index == menuItems.length - 1;

                return FadeInLeft(
                  delay: Duration(milliseconds: 750 + (index * 80)),
                  duration: const Duration(milliseconds: 500),
                  child: Column(
                    children: [
                      _buildMenuItem(
                        icon: item['icon'] as IconData,
                        label: item['label'] as String,
                        onTap: item['onTap'] as VoidCallback,
                      ),
                      if (!isLast)
                        Divider(
                          height: 1,
                          color: AppTheme.onSurfaceLight.withValues(alpha: 0.1),
                        ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildMenuItem({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(10),
                  color: AppTheme.primaryLight.withValues(alpha: 0.1),
                ),
                child: Icon(
                  icon,
                  color: AppTheme.primaryLight,
                  size: 20,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Text(
                  label,
                  style: AppTextStyles.bodyMedium(
                    color: AppTheme.textDark,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios,
                size: 16,
                color: AppTheme.onSurfaceLight.withValues(alpha: 0.4),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLogoutButton(BuildContext context, dynamic strings) {
    return FadeInUp(
      delay: const Duration(milliseconds: 1200),
      duration: const Duration(milliseconds: 500),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
        child: SizedBox(
          width: double.infinity,
          child: Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
                colors: [
                  Colors.red.shade600,
                  Colors.red.shade700,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: ElevatedButton(
              onPressed: () {
                _showLogoutDialog(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.transparent,
                shadowColor: Colors.transparent,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.logout, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    'Logout',
                    style: AppTextStyles.button(
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _showLogoutDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => ZoomIn(
        duration: const Duration(milliseconds: 300),
        child: AlertDialog(
          title: Text(
            'Logout',
            style: AppTextStyles.headlineMedium(),
          ),
          content: Text(
            'Are you sure you want to logout?',
            style: AppTextStyles.bodyMedium(),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: Text(
                'Cancel',
                style: AppTextStyles.bodyMedium(
                  color: AppTheme.primaryLight,
                ),
              ),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
                // TODO: Add actual logout logic (clear token, user data, etc.)
                // Steps:
                // 1. Clear authentication token
                // 2. Clear user session from SharedPreferences/SecureStorage
                // 3. Clear cached user data
                // 4. Navigate to login screen
                AppRoutes.navigateToLogin(context);
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.red.shade600,
              ),
              child: Text(
                'Logout',
                style: AppTextStyles.button(
                  color: Colors.white,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
