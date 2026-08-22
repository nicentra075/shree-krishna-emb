import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_event.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_state.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'dialogs/user_edit_dialog.dart';
import 'dialogs/user_details_dialog.dart';

class MobileUserListView extends StatefulWidget {
  const MobileUserListView({super.key});

  @override
  State<MobileUserListView> createState() => _MobileUserListViewState();
}

class _MobileUserListViewState extends State<MobileUserListView> {
  late TextEditingController _searchController;

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    context.read<UserListBloc>().add(const LoadUsersEvent());
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: AppTextStyles.headlineMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              // Search field and Add User button
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 44,
                      decoration: BoxDecoration(
                        color: const Color(0xFFF5F5F5),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: Colors.grey.withValues(alpha: 0.2),
                        ),
                      ),
                      child: TextField(
                        controller: _searchController,
                        onChanged: (query) {
                          context.read<UserListBloc>().add(
                            SearchUsersEvent(query),
                          );
                        },
                        decoration: InputDecoration(
                          hintText: 'Search by name or email',
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
                            horizontal: 12,
                            vertical: 10,
                          ),
                        ),
                        style: AppTextStyles.bodyMedium(color: Colors.black87),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    height: 44,
                    width: 44,
                    decoration: BoxDecoration(
                      color: AppTheme.primaryDark,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: IconButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => BlocProvider.value(
                            value: context.read<UserListBloc>(),
                            child: const UserEditDialog(user: null),
                          ),
                        );
                      },
                      icon: const Icon(
                        Icons.add,
                        size: 20,
                        color: Colors.white,
                      ),
                      tooltip: 'Add User',
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Cards list
        Expanded(
          child: BlocListener<UserListBloc, UserListState>(
            listener: (context, state) {
              if (state is UserActionSuccess) {
                ResponsiveSnackbar.showSuccess(state.message, context);
              } else if (state is UserActionError) {
                ResponsiveSnackbar.showError(state.message, context);
              }
            },
            child: BlocBuilder<UserListBloc, UserListState>(
              // Show the loader while an action is in flight and keep the last
              // list visible during transient action states, instead of
              // flashing the "No data" fallback.
              buildWhen: (previous, current) =>
                  current is UserListInitial ||
                  current is UserListLoading ||
                  current is UserListLoaded ||
                  current is UserListError ||
                  current is UserActionLoading,
              builder: (context, state) {
                if (state is UserListLoading || state is UserActionLoading) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const AppLoader(),
                        const SizedBox(height: 16),
                        Text(
                          'Loading users...',
                          style: AppTextStyles.bodyMedium(
                            color: AppTheme.textBrown.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UserListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          state.message,
                          style: AppTextStyles.bodyMedium(),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context.read<UserListBloc>().add(
                            const LoadUsersEvent(),
                          ),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UserListLoaded) {
                  if (state.users.isEmpty) {
                    return Center(
                      child: Text(
                        state.searchQuery != null
                            ? 'No users match your search'
                            : 'No users found',
                        style: AppTextStyles.bodyMedium(
                          color: AppTheme.textBrown.withValues(alpha: 0.6),
                        ),
                      ),
                    );
                  }

                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(12),
                      child: Column(
                        children: [
                          // Results info
                          Text(
                            '${state.users.length} of ${state.totalUsers} users',
                            style: AppTextStyles.labelSmall(
                              color: AppTheme.textBrown.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 12),
                          // Cards
                          ...state.users.map(
                            (user) => _buildUserCard(context, user),
                          ),
                          const SizedBox(height: 16),
                          // Pagination
                          _buildMobilePagination(context, state),
                        ],
                      ),
                    ),
                  );
                }

                return const Center(child: Text('No data'));
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserCard(BuildContext context, UserListItemModel user) {
    final colorScheme = Theme.of(context).colorScheme;
    final activeColor = const Color(0xFF4CAF50);
    final suspendedColor = const Color(0xFFFF6B6B);
    final statusColor = user.isActive ? activeColor : suspendedColor;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Name + status badge
            Row(
              children: [
                Expanded(
                  child: Text(
                    user.name,
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                      fontWeight: FontWeight.w600,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: statusColor.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.isActive ? 'Active' : 'Suspended',
                    style: AppTextStyles.labelSmall(
                      color: statusColor,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            // Email
            Text(
              user.email,
              style: AppTextStyles.bodySmall(
                color: colorScheme.onSurfaceVariant,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 8),
            // Role badge + User ID
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 2,
                  ),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.15),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    user.role.replaceFirst(
                      user.role[0],
                      user.role[0].toUpperCase(),
                    ),
                    style: AppTextStyles.labelSmall(
                      color: AppTheme.primaryDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    'ID: ${user.userId ?? '-'}',
                    style: AppTextStyles.labelSmall(
                      color: colorScheme.onSurfaceVariant,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Action buttons
            Row(
              children: [
                Expanded(
                  child: ElevatedButton(
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryLight.withValues(
                        alpha: 0.2,
                      ),
                      foregroundColor: AppTheme.primaryDark,
                      padding: const EdgeInsets.symmetric(vertical: 10),
                    ),
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => UserDetailsDialog(user: user),
                      );
                    },
                    child: const Text(
                      'View',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ),
                // Admin users are protected: no Edit / Suspend / Delete so an
                // admin account can't be changed or removed by mistake.
                if (user.role != 'admin') ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppTheme.primaryDark,
                        side: BorderSide(color: AppTheme.primaryDark),
                        padding: const EdgeInsets.symmetric(vertical: 10),
                      ),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => BlocProvider.value(
                            value: context.read<UserListBloc>(),
                            child: UserEditDialog(user: user),
                          ),
                        );
                      },
                      child: const Text(
                        'Edit',
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    onSelected: (value) {
                      if (value == 'suspend') {
                        context.read<UserListBloc>().add(
                          SuspendUserEvent(user.id, user.isActive),
                        );
                      } else if (value == 'delete') {
                        _showDeleteConfirmation(context, user);
                      }
                    },
                    itemBuilder: (BuildContext context) => [
                      PopupMenuItem(
                        value: 'suspend',
                        child: Text(user.isActive ? 'Suspend' : 'Activate'),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: colorScheme.outline.withValues(alpha: 0.4),
                        ),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Icon(
                        Icons.more_vert,
                        size: 20,
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMobilePagination(BuildContext context, UserListLoaded state) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        IconButton(
          onPressed: state.currentPage > 1
              ? () =>
                    context.read<UserListBloc>().add(const PreviousPageEvent())
              : null,
          icon: const Icon(Icons.chevron_left),
        ),
        Text(
          'Page ${state.currentPage} of ${state.totalPages}',
          style: AppTextStyles.bodySmall(
            color: AppTheme.textBrown.withValues(alpha: 0.7),
          ),
        ),
        IconButton(
          onPressed: state.currentPage < state.totalPages
              ? () => context.read<UserListBloc>().add(const NextPageEvent())
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(BuildContext context, UserListItemModel user) {
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Delete User'),
        content: Text(
          'Are you sure you want to delete ${user.name}? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.read<UserListBloc>().add(DeleteUserEvent(user.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
