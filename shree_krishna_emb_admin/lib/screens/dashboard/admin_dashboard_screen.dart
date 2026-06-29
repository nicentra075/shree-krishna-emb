import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get_it/get_it.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/categories_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/collections_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/design_store/designs_cubit.dart';
import 'package:intl/intl.dart';
import 'package:shree_krishna_core/shree_krishna_core.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/admin_auth/admin_auth_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/dashboard/dashboard_stats_cubit.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/data/datasources/firebase_dashboard_stats_datasource.dart'
    show DashboardStats;
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/routes/app_routes.dart';
import 'package:shree_krishna_emb_admin/domain/repositories/user_list_repository.dart';
import 'package:shree_krishna_emb_admin/screens/design_store/design_store_content_view.dart';
import 'package:shree_krishna_emb_admin/screens/payouts/payouts_content_view.dart';
import 'package:shree_krishna_emb_admin/screens/reports/reports_content_view.dart';
import 'package:shree_krishna_emb_admin/screens/settings/settings_content_view.dart';
import 'package:shree_krishna_emb_admin/screens/transactions/transactions_content_view.dart';
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

  /// Key for the mobile Scaffold so the app-bar menu button can open the
  /// drawer (Scaffold.of(context) from the build context can't reach it).
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  /// Build up-to-2-letter initials from a display name for the avatar.
  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty);
    if (parts.isEmpty) return 'A';
    final letters = parts.take(2).map((p) => p[0].toUpperCase()).join();
    return letters.isEmpty ? 'A' : letters;
  }

  @override
  Widget build(BuildContext context) {
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    // Rebuild the dashboard subtree (sidebar, app bar, content) when the app
    // language changes. The already-pushed route won't rebuild just because
    // MaterialApp does, so this screen listens to the locale notifier directly.
    return ValueListenableBuilder<String>(
      valueListenable: AppLocalization.localeNotifier,
      builder: (context, _, _) {
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
                  key: _scaffoldKey,
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
      },
    );
  }

  // Build content based on selected section
  Widget _buildContent() {
    switch (_selectedSection) {
      case 'user_management':
        return _buildUserManagementContent();
      case 'settings':
        return const SettingsContentView();
      case 'store':
        return const DesignStoreContentView();
      case 'transactions':
        return const TransactionsContentView();
      case 'reports':
        return const ReportsContentView();
      case 'payouts':
        return const PayoutsContentView();
      default:
        return _buildDashboardContent();
    }
  }

  // Dashboard content
  Widget _buildDashboardContent() {
    final isMobile = MediaQuery.of(context).size.width < 768;

    return BlocProvider<DashboardStatsCubit>(
      create: (_) => GetIt.instance<DashboardStatsCubit>()..load(),
      child: BlocBuilder<DashboardStatsCubit, DashboardStatsState>(
        builder: (context, statsState) {
          return SingleChildScrollView(
            padding: EdgeInsets.all(isMobile ? 16 : 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildHeader(),
                SizedBox(height: isMobile ? 24 : 32),
                _buildKPISection(isMobile, statsState),
                SizedBox(height: isMobile ? 24 : 32),
                if (!isMobile)
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        flex: 65,
                        child: Column(
                          children: [
                            _buildRevenueSection(isMobile, statsState),
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
                      _buildRevenueSection(isMobile, statsState),
                      const SizedBox(height: 24),
                      _buildApprovalCard(),
                      const SizedBox(height: 24),
                      _buildRecentActivitySection(),
                    ],
                  ),
              ],
            ),
          );
        },
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
                onPressed: () => _scaffoldKey.currentState?.openDrawer(),
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
                  // Acts as a launcher: tapping opens the global search dialog
                  // (designs / categories / collections by name).
                  readOnly: true,
                  onTap: () => _openGlobalSearch(context),
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
                  style: AppTextStyles.bodyMedium(
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            // Dark / light mode toggle
            BlocBuilder<ThemeCubit, ThemeMode>(
              builder: (context, themeMode) {
                final isDark = Theme.of(context).brightness == Brightness.dark;
                return IconButton(
                  tooltip: isDark
                      ? AppLocalization.strings.lightMode
                      : AppLocalization.strings.darkMode,
                  icon: Icon(
                    isDark
                        ? Icons.light_mode_outlined
                        : Icons.dark_mode_outlined,
                    size: 24,
                  ),
                  color: Colors.grey.withValues(alpha: 0.6),
                  onPressed: () => context.read<ThemeCubit>().setMode(
                    isDark ? ThemeMode.light : ThemeMode.dark,
                  ),
                );
              },
            ),
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
            BlocBuilder<AdminAuthBloc, AdminAuthState>(
              builder: (context, authState) {
                final isAuthed = authState is AdminAuthAuthenticated;
                final email = isAuthed ? authState.email : '';
                final displayName = isAuthed && authState.name.isNotEmpty
                    ? authState.name
                    : (email.contains('@')
                          ? email.split('@').first
                          : 'Admin User');
                final role = isAuthed ? authState.role : '';
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 8,
                  ),
                  child: Row(
                    // App bar is laid out with unbounded width, so the Row must
                    // shrink-wrap its children (no flex/Expanded here).
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            displayName,
                            style: AppTextStyles.labelMedium(
                              color: Theme.of(context).colorScheme.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                          if (role.isNotEmpty)
                            Text(
                              role.toUpperCase(),
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
                            _initials(displayName),
                            style: AppTextStyles.labelMedium(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              },
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
                  icon: Icons.logout,
                  label: AppLocalization.strings.logout,
                  isActive: false,
                  onTap: () => _confirmLogout(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // Confirms before signing out — navigation to login happens via the
  // AdminAuthBloc listener once the session is cleared.
  void _confirmLogout(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;
    showDialog(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: colorScheme.surface,
        title: Text(
          strings.logoutConfirmTitle,
          style: AppTextStyles.headlineMedium(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w700,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        content: Text(
          strings.logoutConfirmMessage,
          style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
          maxLines: 3,
          overflow: TextOverflow.ellipsis,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(dialogCtx);
              context.read<AdminAuthBloc>().add(const AdminSignOutEvent());
            },
            child: Text(
              strings.logout,
              style: const TextStyle(
                color: Color(0xFFFF6B6B),
                fontWeight: FontWeight.w700,
              ),
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
          onTap: () {
            onTap();
            // On mobile the sidebar is a drawer — close it after selecting.
            if (_scaffoldKey.currentState?.isDrawerOpen ?? false) {
              _scaffoldKey.currentState?.closeDrawer();
            }
          },
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

  // KPI Cards Section — live values from DashboardStatsCubit.
  Widget _buildKPISection(bool isMobile, DashboardStatsState statsState) {
    final strings = AppLocalization.strings;
    final stats = statsState.stats;
    final isLoading =
        statsState.status == DashboardStatsStatus.loading ||
        statsState.status == DashboardStatsStatus.initial;
    final isError = statsState.status == DashboardStatsStatus.error;

    String v(int? value) => isLoading || stats == null
        ? '—'
        : NumberFormat.decimalPattern().format(value);
    String money(int? value) => isLoading || stats == null
        ? '—'
        : '₹${NumberFormat.decimalPattern().format(value)}';

    return LayoutBuilder(
      builder: (context, constraints) {
        final cardWidth = isMobile
            ? constraints.maxWidth
            : (constraints.maxWidth - 32) / 3;

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (isError) ...[
              _buildStatsErrorBanner(context),
              const SizedBox(height: 16),
            ],
            Wrap(
              spacing: 16,
              runSpacing: 16,
              children: [
                _buildKPICard(
                  width: cardWidth,
                  icon: Icons.receipt_long_outlined,
                  label: strings.totalOrders,
                  value: v(stats?.totalOrders),
                  trend: '${strings.ordersToday}: ${v(stats?.ordersToday)}',
                  trendPositive: true,
                  isLoading: isLoading,
                ),
                _buildKPICard(
                  width: cardWidth,
                  icon: Icons.trending_up,
                  label: strings.totalRevenue,
                  value: money(stats?.revenueTotal),
                  trend:
                      '${strings.revenueToday}: ${money(stats?.revenueToday)}',
                  trendPositive: true,
                  isLoading: isLoading,
                ),
                _buildKPICard(
                  width: cardWidth,
                  icon: Icons.check_circle_outline,
                  label: strings.activeDesigns,
                  value: v(stats?.activeDesigns),
                  trend:
                      '${strings.pendingDesigns}: ${v(stats?.pendingDesigns)}',
                  trendPositive: true,
                  isLoading: isLoading,
                ),
              ],
            ),
          ],
        );
      },
    );
  }

  Widget _buildStatsErrorBanner(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFF6B6B).withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: const Color(0xFFFF6B6B).withValues(alpha: 0.4),
        ),
      ),
      child: Row(
        children: [
          const Icon(Icons.error_outline, color: Color(0xFFFF6B6B), size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              strings.error,
              style: AppTextStyles.bodySmall(color: colorScheme.onSurface),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          TextButton(
            onPressed: () => context.read<DashboardStatsCubit>().load(),
            child: Text(
              strings.retry,
              style: AppTextStyles.labelMedium(color: colorScheme.primary),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
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
    bool isLoading = false,
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
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
          if (isLoading)
            AppShimmer(
              child: Container(
                width: 90,
                height: 24,
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(6),
                ),
              ),
            )
          else
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

  // Revenue Section with a live fl_chart line chart (revenue per day).
  Widget _buildRevenueSection(bool isMobile, DashboardStatsState statsState) {
    final colorScheme = Theme.of(context).colorScheme;
    final strings = AppLocalization.strings;
    final stats = statsState.stats;
    final isLoading =
        statsState.status == DashboardStatsStatus.loading ||
        statsState.status == DashboardStatsStatus.initial;
    final money = NumberFormat.decimalPattern();

    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: colorScheme.surface,
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
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      strings.revenueTrend,
                      style: AppTextStyles.labelMedium(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 8),
                    if (isLoading || stats == null)
                      AppShimmer(
                        child: Container(
                          width: 140,
                          height: 26,
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      )
                    else
                      Text(
                        '₹${money.format(stats.revenue7d)}',
                        style: AppTextStyles.headlineMedium(
                          color: colorScheme.onSurface,
                          fontWeight: FontWeight.w900,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                  ],
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 6,
                ),
                decoration: BoxDecoration(
                  color: colorScheme.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  strings.last7Days,
                  style: AppTextStyles.labelSmall(color: colorScheme.primary),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
            ],
          ),
          SizedBox(height: isMobile ? 20 : 24),
          SizedBox(
            height: 160,
            child: isLoading || stats == null
                ? AppShimmer(
                    child: Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  )
                : _buildRevenueChart(stats),
          ),
        ],
      ),
    );
  }

  // Live revenue line chart built from the daily series.
  Widget _buildRevenueChart(DashboardStats stats) {
    final colorScheme = Theme.of(context).colorScheme;
    final points = stats.dailyRevenue;
    if (points.isEmpty) {
      return Center(
        child: Text(
          AppLocalization.strings.noReportData,
          style: AppTextStyles.bodySmall(color: colorScheme.onSurfaceVariant),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      );
    }

    final spots = <FlSpot>[
      for (var i = 0; i < points.length; i++)
        FlSpot(i.toDouble(), points[i].revenue.toDouble()),
    ];
    final maxRevenue = points
        .map((p) => p.revenue)
        .fold<int>(0, (max, v) => v > max ? v : max);
    final maxY = maxRevenue == 0 ? 10.0 : maxRevenue * 1.2;
    final dayFmt = DateFormat('E');

    return LineChart(
      LineChartData(
        minY: 0,
        maxY: maxY,
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          getDrawingHorizontalLine: (_) => FlLine(
            color: colorScheme.outline.withValues(alpha: 0.15),
            strokeWidth: 1,
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          rightTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          leftTitles: const AxisTitles(
            sideTitles: SideTitles(showTitles: false),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 22,
              interval: 1,
              getTitlesWidget: (value, meta) {
                final i = value.toInt();
                if (i < 0 || i >= points.length) return const SizedBox();
                return Padding(
                  padding: const EdgeInsets.only(top: 6),
                  child: Text(
                    dayFmt.format(points[i].day),
                    style: AppTextStyles.labelSmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              },
            ),
          ),
        ),
        borderData: FlBorderData(show: false),
        lineTouchData: LineTouchData(
          touchTooltipData: LineTouchTooltipData(
            getTooltipColor: (_) => colorScheme.inverseSurface,
            getTooltipItems: (touchedSpots) => touchedSpots
                .map(
                  (s) => LineTooltipItem(
                    '₹${s.y.toInt()}',
                    AppTextStyles.labelSmall(
                      color: colorScheme.onInverseSurface,
                    ),
                  ),
                )
                .toList(),
          ),
        ),
        lineBarsData: [
          LineChartBarData(
            spots: spots,
            isCurved: true,
            color: colorScheme.primary,
            barWidth: 3,
            dotData: const FlDotData(show: false),
            belowBarData: BarAreaData(
              show: true,
              color: colorScheme.primary.withValues(alpha: 0.12),
            ),
          ),
        ],
      ),
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
                style: AppTextStyles.bodyMedium(
                  color: Theme.of(context).colorScheme.onSurface,
                ),
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
              onPressed: () => setState(() => _selectedSection = 'store'),
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
        // Newest designs added to the system, shown as the activity feed.
        BlocProvider<DesignsCubit>(
          create: (_) => GetIt.instance<DesignsCubit>()..load(),
          child: BlocBuilder<DesignsCubit, DesignsState>(
            builder: (context, state) {
              final colorScheme = Theme.of(context).colorScheme;
              if (state.status == CatalogStatus.loading ||
                  state.status == CatalogStatus.initial) {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 24),
                  child: Center(child: AppLoader()),
                );
              }
              final recent = state.designs.take(5).toList();
              if (recent.isEmpty) {
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text(
                      AppLocalization.strings.noData,
                      style: AppTextStyles.bodyMedium(
                        color: colorScheme.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                );
              }
              return Column(
                children: [
                  for (var i = 0; i < recent.length; i++) ...[
                    if (i > 0) const SizedBox(height: 12),
                    _buildActivityItem(
                      type: AppLocalization.strings.newDesign,
                      title: recent[i].name,
                      description: (recent[i].authorName ?? '').isNotEmpty
                          ? '${AppLocalization.strings.by} ${recent[i].authorName}'
                          : '',
                      timestamp: _relativeTime(recent[i].createdAt),
                      icon: Icons.assignment_outlined,
                    ),
                  ],
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  /// A compact "x minutes/hours/days ago" label for the activity feed.
  String _relativeTime(DateTime dt) {
    final strings = AppLocalization.strings;
    final diff = DateTime.now().difference(dt);
    if (diff.inMinutes < 1) return strings.justNow;
    if (diff.inMinutes < 60) return strings.minutesAgo(diff.inMinutes);
    if (diff.inHours < 24) return strings.hoursAgo(diff.inHours);
    return strings.daysAgo(diff.inDays);
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
              color: Theme.of(
                context,
              ).colorScheme.primary.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: Theme.of(context).colorScheme.primary,
              size: 20,
            ),
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

  /// Opens the global search dialog. When the admin taps a result the dialog
  /// returns the section to navigate to (currently the Design Store).
  Future<void> _openGlobalSearch(BuildContext context) async {
    final target = await showDialog<String>(
      context: context,
      builder: (_) => const _GlobalSearchDialog(),
    );
    if (target != null && mounted) {
      setState(() => _selectedSection = target);
    }
  }
}

/// Command-palette style global search over designs, categories and collections
/// by name. Returns the section to navigate to (e.g. 'store') when a result is
/// tapped, or null if dismissed.
class _GlobalSearchDialog extends StatefulWidget {
  const _GlobalSearchDialog();

  @override
  State<_GlobalSearchDialog> createState() => _GlobalSearchDialogState();
}

class _GlobalSearchDialogState extends State<_GlobalSearchDialog> {
  final _controller = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final colorScheme = Theme.of(context).colorScheme;

    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => GetIt.instance<DesignsCubit>()..load()),
        BlocProvider(create: (_) => GetIt.instance<CategoriesCubit>()..load()),
        BlocProvider(create: (_) => GetIt.instance<CollectionsCubit>()..load()),
      ],
      child: Dialog(
        backgroundColor: colorScheme.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 560, maxHeight: 560),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                child: AppTextField(
                  controller: _controller,
                  hint: strings.searchPlaceholder,
                  prefixIcon: const Icon(Icons.search, size: 20),
                  onChanged: (v) => setState(() => _query = v.trim()),
                ),
              ),
              const Divider(height: 1),
              // Builder gives a context BELOW the providers so the watch()
              // calls inside _results can find the cubits.
              Flexible(
                child: Builder(
                  builder: (ctx) => _results(ctx, colorScheme, strings),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _results(BuildContext context, ColorScheme colorScheme, dynamic strings) {
    final q = _query.toLowerCase();
    if (q.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            strings.searchPlaceholder,
            style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    final designs = context
        .watch<DesignsCubit>()
        .state
        .designs
        .where((d) => d.name.toLowerCase().contains(q))
        .take(6)
        .toList();
    final categories = context
        .watch<CategoriesCubit>()
        .state
        .categories
        .where((c) => c.name.toLowerCase().contains(q))
        .take(6)
        .toList();
    final collections = context
        .watch<CollectionsCubit>()
        .state
        .collections
        .where((c) => c.name.toLowerCase().contains(q))
        .take(6)
        .toList();

    if (designs.isEmpty && categories.isEmpty && collections.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 40),
        child: Center(
          child: Text(
            strings.noData,
            style: AppTextStyles.bodyMedium(color: colorScheme.onSurfaceVariant),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      );
    }

    return ListView(
      shrinkWrap: true,
      padding: const EdgeInsets.symmetric(vertical: 8),
      children: [
        if (designs.isNotEmpty) ...[
          _sectionHeader(strings.designs, colorScheme),
          for (final d in designs)
            _resultTile(
              icon: Icons.image_outlined,
              title: d.name,
              colorScheme: colorScheme,
            ),
        ],
        if (collections.isNotEmpty) ...[
          _sectionHeader(strings.collections, colorScheme),
          for (final c in collections)
            _resultTile(
              icon: Icons.collections_bookmark_outlined,
              title: c.name,
              colorScheme: colorScheme,
            ),
        ],
        if (categories.isNotEmpty) ...[
          _sectionHeader(strings.categories, colorScheme),
          for (final c in categories)
            _resultTile(
              icon: Icons.category_outlined,
              title: c.name,
              colorScheme: colorScheme,
            ),
        ],
      ],
    );
  }

  Widget _sectionHeader(String label, ColorScheme colorScheme) => Padding(
    padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
    child: Text(
      label,
      style: AppTextStyles.labelSmall(
        color: colorScheme.onSurfaceVariant,
        fontWeight: FontWeight.w700,
      ),
      maxLines: 1,
      overflow: TextOverflow.ellipsis,
    ),
  );

  Widget _resultTile({
    required IconData icon,
    required String title,
    required ColorScheme colorScheme,
  }) {
    return ListTile(
      leading: Icon(icon, color: colorScheme.primary, size: 20),
      title: Text(
        title,
        style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
      ),
      // All catalog entities live under the Design Store section.
      onTap: () => Navigator.pop(context, 'store'),
    );
  }
}
