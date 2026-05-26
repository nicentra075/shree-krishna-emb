import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_event.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_state.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';
import 'dialogs/user_edit_dialog.dart';
import 'dialogs/user_details_dialog.dart';

class DesktopUserListView extends StatefulWidget {
  const DesktopUserListView({super.key});

  @override
  State<DesktopUserListView> createState() => _DesktopUserListViewState();
}

class _DesktopUserListViewState extends State<DesktopUserListView> {
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
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'User Management',
                style: AppTextStyles.headlineMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 24),
              // Search field and Add User button
              Row(
                children: [
                  // Search field
                  Container(
                    width: 400,
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
                        context
                            .read<UserListBloc>()
                            .add(SearchUsersEvent(query));
                      },
                      decoration: InputDecoration(
                        hintText: 'Search by name or email...',
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
                      style: AppTextStyles.bodyMedium(color: Colors.black87),
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add User Button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => const UserEditDialog(user: null),
                      );
                    },
                    icon: const Icon(Icons.add, size: 18),
                    label: const Text('Add User'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppTheme.primaryDark,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 16,
                        vertical: 12,
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(8),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
        // Table
        Expanded(
          child: BlocListener<UserListBloc, UserListState>(
            listener: (context, state) {
              if (state is UserActionSuccess) {
                AppSnackbar.showSuccess(state.message);
              } else if (state is UserActionError) {
                AppSnackbar.showError(state.message);
              }
            },
            child: BlocBuilder<UserListBloc, UserListState>(
              builder: (context, state) {
                if (state is UserListLoading) {
                  return Center(
                    child: const AppLoader(),
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
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => context
                              .read<UserListBloc>()
                              .add(const LoadUsersEvent()),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (state is UserListLoaded) {
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results info
                          Text(
                            'Showing ${state.users.length} of ${state.totalUsers} users',
                            style: AppTextStyles.labelSmall(
                              color: AppTheme.textBrown.withValues(alpha: 0.6),
                            ),
                          ),
                          const SizedBox(height: 16),
                          // Table
                          Container(
                            decoration: BoxDecoration(
                              color: Colors.white,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: AppTheme.textBrown.withValues(alpha: 0.1),
                              ),
                            ),
                            child: Column(
                              children: [
                                // Header row
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 16,
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFFF8F7F5),
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          'Name',
                                          style: AppTextStyles.labelMedium(
                                            color: AppTheme.textBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 30,
                                        child: Text(
                                          'Email',
                                          style: AppTextStyles.labelMedium(
                                            color: AppTheme.textBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text(
                                          'Role',
                                          style: AppTextStyles.labelMedium(
                                            color: AppTheme.textBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Text(
                                          'Status',
                                          style: AppTextStyles.labelMedium(
                                            color: AppTheme.textBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          'Actions',
                                          style: AppTextStyles.labelMedium(
                                            color: AppTheme.textBrown,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          textAlign: TextAlign.right,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                                // Data rows
                                ...state.users.map((user) {
                                  final isLastItem =
                                      state.users.last.id == user.id;
                                  return _buildUserRow(context, user,
                                      isLast: isLastItem);
                                }),
                              ],
                            ),
                          ),
                          const SizedBox(height: 24),
                          // Pagination
                          _buildPagination(context, state),
                        ],
                      ),
                    ),
                  );
                }

                return const Center(
                  child: Text('No data'),
                );
              },
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildUserRow(
    BuildContext context,
    UserListItemModel user, {
    required bool isLast,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: AppTheme.textBrown.withValues(alpha: 0.1),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // Name
            Expanded(
              flex: 20,
              child: Text(
                user.name,
                style: AppTextStyles.bodyMedium(
                  color: AppTheme.textDark,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Email
            Expanded(
              flex: 30,
              child: Text(
                user.email,
                style: AppTextStyles.bodyMedium(
                  color: AppTheme.textBrown.withValues(alpha: 0.7),
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Role - Chip Style
            Expanded(
              flex: 15,
              child: Chip(
                label: Text(
                  user.role.replaceFirst(user.role[0], user.role[0].toUpperCase()),
                  style: AppTextStyles.labelSmall(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: AppTheme.primaryLight.withValues(alpha: 0.15),
                side: BorderSide(
                  color: AppTheme.primaryDark.withValues(alpha: 0.2),
                ),
              ),
            ),
            // Status - Chip Style
            Expanded(
              flex: 15,
              child: Chip(
                label: Text(
                  user.isActive ? 'Active' : 'Suspended',
                  style: AppTextStyles.labelSmall(
                    color: user.isActive
                        ? const Color(0xFF4CAF50)
                        : const Color(0xFFFF6B6B),
                    fontWeight: FontWeight.w600,
                  ),
                ),
                backgroundColor: user.isActive
                    ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                    : const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                side: BorderSide(
                  color: user.isActive
                      ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                      : const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                ),
              ),
            ),
            // Actions
            Expanded(
              flex: 20,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => UserDetailsDialog(user: user),
                      );
                    },
                    child: const Text('View'),
                  ),
                  const SizedBox(width: 8),
                  TextButton(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => UserEditDialog(user: user),
                      );
                    },
                    child: const Text('Edit'),
                  ),
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
                        child: Text(
                          user.isActive ? 'Suspend' : 'Activate',
                        ),
                      ),
                      const PopupMenuItem(
                        value: 'delete',
                        child: Text('Delete'),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPagination(BuildContext context, UserListLoaded state) {
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
        ...List.generate(state.totalPages, (index) {
          final pageNum = index + 1;
          return GestureDetector(
            onTap: () => context
                .read<UserListBloc>()
                .add(GoToPageEvent(pageNum)),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: state.currentPage == pageNum
                    ? AppTheme.primaryDark
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                '$pageNum',
                style: AppTextStyles.labelSmall(
                  color: state.currentPage == pageNum
                      ? Colors.white
                      : AppTheme.textBrown,
                ),
              ),
            ),
          );
        }),
        IconButton(
          onPressed: state.currentPage < state.totalPages
              ? () => context.read<UserListBloc>().add(const NextPageEvent())
              : null,
          icon: const Icon(Icons.chevron_right),
        ),
      ],
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    UserListItemModel user,
  ) {
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
              context
                  .read<UserListBloc>()
                  .add(DeleteUserEvent(user.id));
            },
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }
}
