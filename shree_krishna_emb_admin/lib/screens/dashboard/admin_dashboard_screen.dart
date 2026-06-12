import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/routes/app_routes.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';
import 'package:shree_krishna_emb_admin/screens/settings/settings_content_view.dart';
import 'package:shree_krishna_emb_admin/screens/user_management/desktop_user_list_view.dart';
import 'package:shree_krishna_emb_admin/screens/user_management/mobile_user_list_view.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class AdminDashboardScreen extends StatefulWidget {
  const AdminDashboardScreen({super.key});

  @override
  State<AdminDashboardScreen> createState() => _AdminDashboardScreenState();
}

class _AdminDashboardScreenState extends State<AdminDashboardScreen> {
  String _selectedSection = 'dashboard'; // Track selected sidebar section

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    // Leave the dashboard only after the session is actually cleared,
    // so a refresh after sign-out can never restore it
    return BlocListener<AdminAuthBloc, AdminAuthState>(
      listener: (context, state) {
        if (state is AdminAuthUnauthenticated) {
          Navigator.of(
            context,
          ).pushNamedAndRemoveUntil(AppRoutes.login, (route) => false);
        } else if (state is AdminAuthError) {
          AppSnackbar.showError(state.message);
        }
      },
      child: isMobile
          // Mobile layout with drawer
          ? Scaffold(
              appBar: PreferredSize(
                preferredSize: const Size.fromHeight(70),
                child: _buildAppBar(isMobile),
              ),
              drawer: _buildSidebar(),
              body: _buildContent(),
            )
          // Desktop layout with fixed sidebar
          : Scaffold(
              body: Row(
                children: [
                  // Sidebar (fixed left)
                  _buildSidebar(),
                  // Main content area (right side)
                  Expanded(
                    child: Column(
                      children: [
                        // App bar
                        _buildAppBar(isMobile),
                        // Main content
                        Expanded(child: _buildContent()),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  // Build content based on selected section
  Widget _buildContent() {
    switch (_selectedSection) {
      case 'user_management':
        return _buildUserManagementContent();
      case 'settings':
        return const SettingsContentView();
      default:
        return _buildDashboardContent();
    }
  }

  // Dashboard content
  Widget _buildDashboardContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return SingleChildScrollView(
      padding: EdgeInsets.all(isMobile ? 16 : 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHeader(),
          SizedBox(height: isMobile ? 24 : 32),
          _buildKPISection(isMobile),
          SizedBox(height: isMobile ? 24 : 32),
          if (!isMobile)
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  flex: 65,
                  child: Column(
                    children: [
                      _buildRevenueSection(isMobile),
                      const SizedBox(height: 24),
                      _buildRecentActivitySection(),
                    ],
                  ),
                ),
                const SizedBox(width: 24),
                Expanded(
                  flex: 35,
                  child: Column(
                    children: [
                      _buildApprovalCard(),
                      const SizedBox(height: 24),
                      _buildSystemHealthCard(),
                    ],
                  ),
                ),
              ],
            )
          else
            Column(
              children: [
                _buildRevenueSection(isMobile),
                const SizedBox(height: 24),
                _buildApprovalCard(),
                const SizedBox(height: 24),
                _buildRecentActivitySection(),
              ],
            ),
        ],
      ),
    );
  }

  // User Management content with proper Material wrapper
  Widget _buildUserManagementContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Material(
      color: Theme.of(context).scaffoldBackgroundColor,
      child: BlocProvider(
        create: (context) =>
            UserListBloc(repository: GetIt.instance<UserListRepository>()),
        child: isMobile
            ? const MobileUserListView()
            : const DesktopUserListView(),
      ),
    );
  }

  // App Bar Widget
  Widget _buildAppBar(bool isMobile) {
    return Container(
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(
          horizontal: isMobile ? 12 : 24,
          vertical: 8,
        ),
        child: Row(
          children: [
            if (isMobile)
              IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () {
                  Scaffold.of(context).openDrawer();
                },
              ),
            if (!isMobile) const SizedBox(width: 8),
            Expanded(
              child: Container(
                height: 44,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Colors.grey.withValues(alpha: 0.2),
                    width: 1,
                  ),
                ),
                child: TextField(
                  decoration: InputDecoration(
                    hintText: AppLocalization.strings.searchPlaceholder,
                    hintStyle: AppTextStyles.bodyMedium(
                      color: Colors.grey.withValues(alpha: 0.5),
                    ),
                    prefixIcon: Icon(
                      Icons.search,
                      color: Colors.grey.withValues(alpha: 0.5),
                      size: 20,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 12,
                    ),
                  ),
                  style: AppTextStyles.bodyMedium(color: Theme.of(context).colorScheme.onSurface),
                ),
              ),
            ),
            const SizedBox(width: 16),
            IconButton(
              icon: const Icon(Icons.notifications_outlined, size: 24),
              color: Colors.grey.withValues(alpha: 0.6),
              onPressed: () {},
            ),
            IconButton(
              icon: const Icon(Icons.settings_outlined, size: 24),
              color: Colors.grey.withValues(alpha: 0.6),
              onPressed: () => setState(() => _selectedSection = 'settings'),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              child: Row(
                children: [
                  Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        'Admin User',
                        style: AppTextStyles.labelMedium(
                          color: Theme.of(context).colorScheme.onSurface,
                          fontWeight: FontWeight.w600,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      Text(
                        'LEAD AUDITOR',
                        style: AppTextStyles.labelSmall(
                          color: Colors.grey.withValues(alpha: 0.6),
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                  const SizedBox(width: 12),
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppTheme.primaryDark,
                    ),
                    child: Center(
                      child: Text(
                        'AU',
                        style: AppTextStyles.labelMedium(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Sidebar Widget
  Widget _buildSidebar() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return Container(
      width: isMobile ? 280 : 260,
      decoration: BoxDecoration(
        color: AppTheme.primaryDark,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 8,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        children: [
          // Logo Section
          Padding(
            padding: EdgeInsets.all(isMobile ? 20 : 16),
            child: Column(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(
                    Icons.spa,
                    color: AppTheme.primaryLight,
                    size: 28,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  AppLocalization.strings.adminPanel,
                  style: AppTextStyles.labelMedium(
                    color: Colors.white,
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
          const Divider(color: Colors.white24, height: 1),

          // Menu Items
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Column(
                children: [
                  _buildSidebarItem(
                    icon: Icons.dashboard_outlined,
                    label: AppLocalization.strings.dashboard,
                    isActive: _selectedSection == 'dashboard',
                    onTap: () => setState(() => _selectedSection = 'dashboard'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.assignment_outlined,
                    label: AppLocalization.strings.approvalQueue,
                    isActive: _selectedSection == 'approval',
                    onTap: () => setState(() => _selectedSection = 'approval'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.store_outlined,
                    label: AppLocalization.strings.designStore,
                    isActive: _selectedSection == 'store',
                    onTap: () => setState(() => _selectedSection = 'store'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.people_outline,
                    label: AppLocalization.strings.userManagement,
                    isActive: _selectedSection == 'user_management',
                    onTap: () =>
                        setState(() => _selectedSection = 'user_management'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.swap_horiz,
                    label: AppLocalization.strings.transactions,
                    isActive: _selectedSection == 'transactions',
                    onTap: () =>
                        setState(() => _selectedSection = 'transactions'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.trending_up,
                    label: AppLocalization.strings.platformFees,
                    isActive: _selectedSection == 'fees',
                    onTap: () => setState(() => _selectedSection = 'fees'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.account_balance_wallet,
                    label: AppLocalization.strings.payouts,
                    isActive: _selectedSection == 'payouts',
                    onTap: () => setState(() => _selectedSection = 'payouts'),
                  ),
                  _buildSidebarItem(
                    icon: Icons.assessment_outlined,
                    label: AppLocalization.strings.reports,
                    isActive: _selectedSection == 'reports',
                    onTap: () => setState(() => _selectedSection = 'reports'),
                  ),
                ],
              ),
            ),
          ),

          const Divider(color: Colors.white24, height: 1),

          // Footer
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                _buildSidebarItem(
                  icon: Icons.settings_outlined,
                  label: AppLocalization.strings.settings,
                  isActive: _selectedSection == 'settings',
                  onTap: () => setState(() => _selectedSection = 'settings'),
                ),
                const SizedBox(height: 12),
                _buildSidebarItem(
                  icon: Icons.support_agent_outlined,
                  label: AppLocalization.strings.support,
                  isActive: false,
                  onTap: () {},
                ),
                const SizedBox(height: 12),
                _buildSidebarItem(
                  icon: Icons.logout,
                  label: AppLocalization.strings.logout,
                  isActive: false,
                  onTap: () {
                    // Clears Firebase session + cached login; navigation to
                    // the login screen happens via the AdminAuthBloc listener
                    context.read<AdminAuthBloc>().add(
                      const AdminSignOutEvent(),
                    );
                  },
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Sidebar Menu Item
  Widget _buildSidebarItem({
    required IconData icon,
    required String label,
    required bool isActive,
    required VoidCallback onTap,
  }) {
    return Container(
      color: isActive
          ? Colors.white.withValues(alpha: 0.1)
          : Colors.transparent,
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            child: Row(
              children: [
                Icon(
                  icon,
                  color: isActive ? Colors.white : Colors.white70,
                  size: 20,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    label,
                    style: AppTextStyles.bodyMedium(
                      color: isActive ? Colors.white : Colors.white70,
                      fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                if (isActive)
                  Container(
                    width: 4,
                    height: 20,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight,
                      borderRadius: const BorderRadius.horizontal(
                        left: Radius.circular(2),
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          AppLocalization.strings.insightsTitle,
          style: AppTextStyles.headlineMedium(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          AppLocalization.strings.dashboardWelcome,
          style: AppTextStyles.bodyMedium(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // KPI Cards Section
  Widget _buildKPISection(bool isMobile) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth - 16) / 3;

        return Wrap(
          spacing: 16,
          runSpacing: 16,
          children: [
            _buildKPICard(
              width: cardWidth,
              icon: Icons.people_outline,
              label: AppLocalization.strings.totalOrders,
              value: '2,450',
              trend: '+12% vs last month',
              trendPositive: true,
            ),
            _buildKPICard(
              width: cardWidth,
              icon: Icons.trending_up,
              label: AppLocalization.strings.totalRevenue,
              value: '\$45,320',
              trend: '+8% growth',
              trendPositive: true,
            ),
            _buildKPICard(
              width: cardWidth,
              icon: Icons.check_circle_outline,
              label: AppLocalization.strings.approvedDesigns,
              value: '856',
              trend: '+24 this week',
              trendPositive: true,
            ),
          ],
        );
      },
    );
  }

  // KPI Card Widget
  Widget _buildKPICard({
    required double width,
    required IconData icon,
    required String label,
    required String value,
    required String trend,
    required bool trendPositive,
  }) {
    return Container(
      width: width,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTextStyles.labelSmall(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium(
              color: Theme.of(context).colorScheme.onSurface,
              fontWeight: FontWeight.w900,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            trend,
            style: AppTextStyles.bodySmall(
              color: trendPositive
                  ? const Color(0xFF4CAF50)
                  : const Color(0xFFFF6B6B),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }

  // Revenue Section with Chart
  Widget _buildRevenueSection(bool isMobile) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Revenue Snapshot',
                    style: AppTextStyles.labelMedium(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$142,509.30',
                    style: AppTextStyles.headlineMedium(
                      color: Theme.of(context).colorScheme.onSurface,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '↑ 14.2% weekly',
                  style: AppTextStyles.labelSmall(
                    color: const Color(0xFF4CAF50),
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 24),

          // Simple revenue chart
          SizedBox(height: 120, child: _buildRevenueChart()),
          SizedBox(height: isMobile ? 16 : 20),

          // Revenue metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBadge(label: 'Platform Fees', value: '8.5%'),
              _buildMetricBadge(
                label: 'Weekly Growth',
                value: '14.2%',
                isPositive: true,
              ),
              _buildMetricBadge(label: 'Monthly Target', value: '₹5.2L'),
            ],
          ),
        ],
      ),
    );
  }

  // Simple revenue chart visualization
  Widget _buildRevenueChart() {
    final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
    final values = [0.4, 0.5, 0.6, 0.8, 1.0, 0.7, 0.9];
    final maxValue = 1.0;

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
      crossAxisAlignment: CrossAxisAlignment.end,
      children: List.generate(days.length, (index) {
        final height = values[index] * 100;
        final isHighest = values[index] == maxValue;

        return Column(
          mainAxisAlignment: MainAxisAlignment.end,
          children: [
            Expanded(
              child: Container(
                width: 12,
                decoration: BoxDecoration(
                  color: isHighest
                      ? Theme.of(context).colorScheme.primary
                      : Theme.of(context).colorScheme.primary.withValues(alpha: 0.45),
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(4),
                  ),
                ),
                margin: EdgeInsets.only(top: 100 - height),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              days[index],
              style: AppTextStyles.labelSmall(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        );
      }),
    );
  }

  // Metric badge for revenue section
  Widget _buildMetricBadge({
    required String label,
    required String value,
    bool isPositive = false,
  }) {
    return Column(
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelMedium(
            color: isPositive ? const Color(0xFF4CAF50) : Theme.of(context).colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  // Approval Queue Card
  Widget _buildApprovalCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [AppTheme.primaryDark, const Color(0xFFFF9933)],
        ),
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(
              Icons.assignment_outlined,
              color: Colors.white,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '42 Designs Awaiting Review',
            style: AppTextStyles.headlineMedium(
              color: Colors.white,
              fontWeight: FontWeight.w700,
            ),
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 12),
          Text(
            'Maintain marketplace quality. Pending submissions from 12 verified designers.',
            style: AppTextStyles.bodySmall(
              color: Colors.white.withValues(alpha: 0.9),
            ),
            maxLines: 3,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () {},
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.white,
                foregroundColor: AppTheme.primaryDark,
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              child: Text(
                'Launch Approval Queue',
                style: AppTextStyles.button(color: AppTheme.primaryDark),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // System Health Card
  Widget _buildSystemHealthCard() {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'System Status',
            style: AppTextStyles.labelMedium(
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 20),
          Row(
            children: [
              Container(
                width: 12,
                height: 12,
                decoration: BoxDecoration(
                  color: const Color(0xFF4CAF50),
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Text(
                'Operational',
                style: AppTextStyles.bodyMedium(color: Theme.of(context).colorScheme.onSurface),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
          const SizedBox(height: 20),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFF4CAF50).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Payout Cycle',
                  style: AppTextStyles.labelSmall(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 8),
                Text(
                  'In 3 Days',
                  style: AppTextStyles.labelMedium(
                    color: const Color(0xFF4CAF50),
                    fontWeight: FontWeight.w700,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Recent Activity Section
  Widget _buildRecentActivitySection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              AppLocalization.strings.recentActivity,
              style: AppTextStyles.headlineMedium(
                color: Theme.of(context).colorScheme.onSurface,
                fontWeight: FontWeight.w700,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            TextButton(
              onPressed: () {},
              child: Text(
                'View All Feed →',
                style: AppTextStyles.labelMedium(
                  color: Theme.of(context).colorScheme.primary,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        _buildActivityItem(
          type: 'NEW DESIGN',
          title: 'Golden Mandala Tapestry',
          description: 'by Ananya Sharma',
          timestamp: '2 minutes ago',
          icon: Icons.assignment_outlined,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          type: 'VERIFIED',
          title: 'Rajesh Kumar verified as "Master"',
          description: 'Identity and Portfolio audit successful',
          timestamp: '1 hour ago',
          icon: Icons.verified_user_outlined,
        ),
        const SizedBox(height: 12),
        _buildActivityItem(
          type: 'NEW SALE',
          title: 'Botanical Flora Pattern Set',
          description: 'Sold for \$24.00 to buyer ID #3201',
          timestamp: '3 hours ago',
          icon: Icons.shopping_bag_outlined,
        ),
      ],
    );
  }

  // Activity Item Widget
  Widget _buildActivityItem({
    required String type,
    required String title,
    required String description,
    required String timestamp,
    required IconData icon,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Theme.of(context).colorScheme.primary, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      type,
                      style: AppTextStyles.labelSmall(
                        color: Theme.of(context).colorScheme.primary,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timestamp,
                      style: AppTextStyles.bodySmall(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  title,
                  style: AppTextStyles.bodyMedium(
                    color: Theme.of(context).colorScheme.onSurface,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall(
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
