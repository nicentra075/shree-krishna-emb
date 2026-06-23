import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb/bloc/work/work_bloc.dart';
import 'package:shree_krishna_emb/bloc/work/work_event.dart';
import 'package:shree_krishna_emb/bloc/work/work_state.dart';
import 'package:shree_krishna_emb/theme/app_theme.dart';
import 'package:shree_krishna_emb/localisations/app_localization.dart';

class WorkScreen extends StatefulWidget {
  const WorkScreen({super.key});

  @override
  State<WorkScreen> createState() => _WorkScreenState();
}

class _WorkScreenState extends State<WorkScreen> {
  @override
  void initState() {
    super.initState();
    context.read<WorkBloc>().add(const InitializeWorkEvent());
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<WorkBloc, WorkState>(
      builder: (context, state) {
        if (state is WorkLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (state is WorkError) {
          return Center(
            child: Text(state.message),
          );
        }

        if (state is WorkLoaded) {
          return _buildWorkContent(context, state);
        }

        return const SizedBox.shrink();
      },
    );
  }

  Widget _buildWorkContent(BuildContext context, WorkLoaded state) {
    return RefreshIndicator(
      onRefresh: () async {
        context.read<WorkBloc>().add(const RefreshWorkDataEvent());
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Column(
          children: [
            // Vendor Section (show if user is vendor)
            if (state.userRole == 'vendor')
              _buildVendorSection(context, state),

            // Buyer Section (show if user is buyer)
            if (state.userRole == 'buyer')
              _buildBuyerSection(context, state),
          ],
        ),
      ),
    );
  }

  Widget _buildVendorSection(BuildContext context, WorkLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalization.strings.myWorkDashboard,
            style: AppTextStyles.headlineMedium(),
          ),
        ),

        // Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: AppLocalization.strings.all,
                  isSelected: state.vendorFilter == 'all',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterVendorWorkEvent('all'),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppLocalization.strings.open,
                  isSelected: state.vendorFilter == 'open',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterVendorWorkEvent('open'),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppLocalization.strings.inProgress,
                  isSelected: state.vendorFilter == 'inProgress',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterVendorWorkEvent('inProgress'),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppLocalization.strings.completed,
                  isSelected: state.vendorFilter == 'completed',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterVendorWorkEvent('completed'),
                        );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Project Cards (placeholder for now)
        if (state.vendorProjects.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(AppLocalization.strings.noProjectsFound),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.vendorProjects.length,
            itemBuilder: (context, index) {
              // TODO: Build project card
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildBuyerSection(BuildContext context, WorkLoaded state) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: Text(
            AppLocalization.strings.myPurchases,
            style: AppTextStyles.headlineMedium(),
          ),
        ),

        // Filter Tabs
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: Row(
              children: [
                _buildFilterChip(
                  label: AppLocalization.strings.all,
                  isSelected: state.buyerFilter == 'all',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterBuyerOrdersEvent('all'),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppLocalization.strings.orderPending,
                  isSelected: state.buyerFilter == 'pending',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterBuyerOrdersEvent('pending'),
                        );
                  },
                ),
                const SizedBox(width: 8),
                _buildFilterChip(
                  label: AppLocalization.strings.orderDelivered,
                  isSelected: state.buyerFilter == 'delivered',
                  onTap: () {
                    context.read<WorkBloc>().add(
                          const FilterBuyerOrdersEvent('delivered'),
                        );
                  },
                ),
              ],
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Order Cards (placeholder for now)
        if (state.buyerOrders.isEmpty)
          Padding(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: Text(AppLocalization.strings.noOrdersFound),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.buyerOrders.length,
            itemBuilder: (context, index) {
              // TODO: Build order card
              return const SizedBox.shrink();
            },
          ),
      ],
    );
  }

  Widget _buildFilterChip({
    required String label,
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected
              ? AppTheme.primaryLight
              : Theme.of(context).colorScheme.surfaceContainerHighest,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Text(
          label,
          style: AppTextStyles.labelMedium(
            color: isSelected
                ? Colors.white
                : Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ),
    );
  }
}
