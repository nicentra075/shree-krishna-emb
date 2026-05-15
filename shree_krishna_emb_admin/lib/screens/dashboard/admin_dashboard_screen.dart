import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/l10n/app_localization.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class AdminDashboardScreen extends StatelessWidget {
  const AdminDashboardScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;
    final screenSize = MediaQuery.of(context).size;
    final isMobile = screenSize.width < 768;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F7F5),
      appBar: AppAppBar(
        title: strings.adminDashboard,
        actions: [
          IconButton(
            icon: const Icon(Icons.notifications_outlined),
            onPressed: () {},
          ),
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {},
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: EdgeInsets.all(isMobile ? 16 : 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Section
            _buildHeader(),
            SizedBox(height: isMobile ? 24 : 32),

            // KPI Cards
            _buildKPISection(isMobile),
            SizedBox(height: isMobile ? 24 : 32),

            // Main Content Grid
            if (isMobile)
              Column(
                children: [
                  _buildRevenueSection(isMobile),
                  const SizedBox(height: 24),
                  _buildApprovalCard(),
                  const SizedBox(height: 24),
                  _buildRecentActivitySection(),
                ],
              )
            else
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
              ),
          ],
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
          'Shree Krishna Insights',
          style: AppTextStyles.headlineMedium(
            color: AppTheme.primaryDark,
            fontWeight: FontWeight.w900,
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 8),
        Text(
          'Good Morning, Admin. Here\'s your embroidery business overview.',
          style: AppTextStyles.bodyMedium(
            color: AppTheme.textBrown.withValues(alpha: 0.7),
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
              label: 'Total Orders',
              value: '2,450',
              trend: '+12% vs last month',
              trendPositive: true,
            ),
            _buildKPICard(
              width: cardWidth,
              icon: Icons.trending_up,
              label: 'Total Revenue',
              value: '\$45,320',
              trend: '+8% growth',
              trendPositive: true,
            ),
            _buildKPICard(
              width: cardWidth,
              icon: Icons.check_circle_outline,
              label: 'Approved Designs',
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textBrown.withValues(alpha: 0.1),
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
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryDark,
              size: 20,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            label,
            style: AppTextStyles.labelSmall(
              color: AppTheme.textBrown.withValues(alpha: 0.6),
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTextStyles.headlineMedium(
              color: AppTheme.textDark,
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
        color: Colors.white,
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
                      color: AppTheme.textBrown.withValues(alpha: 0.6),
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '\$142,509.30',
                    style: AppTextStyles.headlineMedium(
                      color: AppTheme.textDark,
                      fontWeight: FontWeight.w900,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
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
          SizedBox(
            height: 120,
            child: _buildRevenueChart(),
          ),
          SizedBox(height: isMobile ? 16 : 20),

          // Revenue metrics row
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildMetricBadge(
                label: 'Platform Fees',
                value: '8.5%',
              ),
              _buildMetricBadge(
                label: 'Weekly Growth',
                value: '14.2%',
                isPositive: true,
              ),
              _buildMetricBadge(
                label: 'Monthly Target',
                value: '₹5.2L',
              ),
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
                      ? AppTheme.primaryDark
                      : AppTheme.primaryLight.withValues(alpha: 0.6),
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
                color: AppTheme.textBrown.withValues(alpha: 0.5),
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
            color: AppTheme.textBrown.withValues(alpha: 0.5),
          ),
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.labelMedium(
            color: isPositive ? const Color(0xFF4CAF50) : AppTheme.textDark,
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
                style: AppTextStyles.button(
                  color: AppTheme.primaryDark,
                ),
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
        color: Colors.white,
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
              color: AppTheme.textBrown.withValues(alpha: 0.6),
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
                  color: AppTheme.textDark,
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
                    color: AppTheme.textBrown.withValues(alpha: 0.6),
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
              'Recent Activity',
              style: AppTextStyles.headlineMedium(
                color: AppTheme.textDark,
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
                  color: AppTheme.primaryDark,
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
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppTheme.textBrown.withValues(alpha: 0.1),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: AppTheme.primaryLight.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(
              icon,
              color: AppTheme.primaryDark,
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
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    Text(
                      timestamp,
                      style: AppTextStyles.bodySmall(
                        color: AppTheme.textBrown.withValues(alpha: 0.5),
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
                    color: AppTheme.textDark,
                    fontWeight: FontWeight.w600,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: AppTextStyles.bodySmall(
                    color: AppTheme.textBrown.withValues(alpha: 0.6),
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
