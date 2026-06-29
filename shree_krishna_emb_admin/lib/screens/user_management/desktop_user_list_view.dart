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

class DesktopUserListView extends StatefulWidget {
  const DesktopUserListView({super.key});

  @override
  State<DesktopUserListView> createState() => _DesktopUserListViewState();
}

class _DesktopUserListViewState extends State<DesktopUserListView> {
  late TextEditingController _searchController;

  /// Selected role filter for the dropdown. 'all' = no filter.
  String _selectedRoleFilter = 'all';

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
    final colorScheme = Theme.of(context).colorScheme;
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
              // Search + role filter on the left, Add User on the right.
              // The search field flexes (up to 400) so the row never overflows
              // on narrow widths instead of wrapping onto new lines.
              Row(
                children: [
                  Expanded(
                    child: Row(
                      children: [
                        // Search field
                        Flexible(
                          child: ConstrainedBox(
                            constraints: const BoxConstraints(maxWidth: 400),
                            child: Container(
                              height: 44,
                        decoration: BoxDecoration(
                          color: colorScheme.surfaceContainerHighest,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                            color: colorScheme.outline.withValues(alpha: 0.2),
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
                            hintText: 'Search by name or email...',
                            hintStyle: AppTextStyles.bodyMedium(
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                            ),
                            prefixIcon: Icon(
                              Icons.search,
                              color: colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.6,
                              ),
                              size: 20,
                            ),
                            border: InputBorder.none,
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16,
                              vertical: 12,
                            ),
                          ),
                          style: AppTextStyles.bodyMedium(
                            color: colorScheme.onSurface,
                          ),
                        ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        _buildRoleFilter(colorScheme),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  // Add User Button
                  ElevatedButton.icon(
                    onPressed: () {
                      showDialog(
                        context: context,
                        builder: (_) => BlocProvider.value(
                          value: context.read<UserListBloc>(),
                          child: const UserEditDialog(user: null),
                        ),
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
                ResponsiveSnackbar.showSuccess(state.message, context);
              } else if (state is UserActionError) {
                ResponsiveSnackbar.showError(state.message, context);
              }
            },
            child: BlocBuilder<UserListBloc, UserListState>(
              // Keep the last list state visible during transient action
              // states (success/error) and show the loader while an action
              // (create/edit/etc.) is in flight — otherwise the screen would
              // flash the "No data" fallback.
              buildWhen: (previous, current) =>
                  current is UserListInitial ||
                  current is UserListLoading ||
                  current is UserListLoaded ||
                  current is UserListError ||
                  current is UserActionLoading,
              builder: (context, state) {
                if (state is UserListLoading || state is UserActionLoading) {
                  return Center(child: const AppLoader());
                }

                if (state is UserListError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(state.message, style: AppTextStyles.bodyMedium()),
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
                  return SingleChildScrollView(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Results info + rows-per-page selector
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Showing ${state.users.length} of ${state.totalUsers} users',
                                  style: AppTextStyles.labelSmall(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                              IconButton(
                                tooltip: 'Refresh',
                                icon: const Icon(Icons.refresh, size: 20),
                                color: colorScheme.onSurfaceVariant,
                                onPressed: () =>
                                    context.read<UserListBloc>().add(
                                          const LoadUsersEvent(
                                            forceRefresh: true,
                                          ),
                                        ),
                              ),
                              const SizedBox(width: 8),
                              Text(
                                'Rows per page:',
                                style: AppTextStyles.labelSmall(
                                  color: colorScheme.onSurfaceVariant,
                                ),
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                              ),
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 10,
                                ),
                                decoration: BoxDecoration(
                                  border: Border.all(
                                    color: colorScheme.outline.withValues(
                                      alpha: 0.4,
                                    ),
                                  ),
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: DropdownButton<int>(
                                  value: context.read<UserListBloc>().pageSize,
                                  underline: const SizedBox(),
                                  isDense: true,
                                  dropdownColor: colorScheme.surface,
                                  items: UserListBloc.pageSizeOptions
                                      .map(
                                        (size) => DropdownMenuItem(
                                          value: size,
                                          child: Text(
                                            '$size',
                                            style: AppTextStyles.bodyMedium(
                                              color: colorScheme.onSurface,
                                            ),
                                          ),
                                        ),
                                      )
                                      .toList(),
                                  onChanged: (size) {
                                    if (size != null) {
                                      context.read<UserListBloc>().add(
                                        ChangePageSizeEvent(size),
                                      );
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 16),
                          // Table — horizontally scrollable so columns never
                          // overflow on narrow widths; a min width keeps the
                          // Actions column readable.
                          LayoutBuilder(
                            builder: (context, constraints) {
                              const minTableWidth = 820.0;
                              final tableWidth =
                                  constraints.maxWidth < minTableWidth
                                      ? minTableWidth
                                      : constraints.maxWidth;
                              return SingleChildScrollView(
                                scrollDirection: Axis.horizontal,
                                child: SizedBox(
                                  width: tableWidth,
                                  child: Container(
                            decoration: BoxDecoration(
                              color: colorScheme.surface,
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: colorScheme.outline.withValues(
                                  alpha: 0.2,
                                ),
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
                                    color: colorScheme.surfaceContainerHighest,
                                    borderRadius: const BorderRadius.vertical(
                                      top: Radius.circular(8),
                                    ),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        flex: 12,
                                        child: Text(
                                          'User ID',
                                          style: AppTextStyles.labelMedium(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          'Name',
                                          style: AppTextStyles.labelMedium(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 30,
                                        child: Text(
                                          'Email',
                                          style: AppTextStyles.labelMedium(
                                            color: colorScheme.onSurfaceVariant,
                                            fontWeight: FontWeight.w600,
                                          ),
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Row(
                                          mainAxisAlignment: .center,
                                          children: [
                                            Text(
                                              'Role',
                                              style: AppTextStyles.labelMedium(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 15,
                                        child: Row(
                                          mainAxisAlignment: .center,
                                          children: [
                                            Text(
                                              'Status',
                                              style: AppTextStyles.labelMedium(
                                                color: colorScheme
                                                    .onSurfaceVariant,
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Expanded(
                                        flex: 20,
                                        child: Text(
                                          'Actions',
                                          style: AppTextStyles.labelMedium(
                                            color: colorScheme.onSurfaceVariant,
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
                                  return _buildUserRow(
                                    context,
                                    user,
                                    isLast: isLastItem,
                                  );
                                }),
                              ],
                            ),
                                  ),
                                ),
                              );
                            },
                          ),
                          const SizedBox(height: 24),
                          // Pagination
                          _buildPagination(context, state),
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

  Widget _buildUserRow(
    BuildContext context,
    UserListItemModel user, {
    required bool isLast,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      decoration: BoxDecoration(
        border: !isLast
            ? Border(
                bottom: BorderSide(
                  color: colorScheme.outline.withValues(alpha: 0.15),
                ),
              )
            : null,
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        child: Row(
          children: [
            // User ID
            Expanded(
              flex: 12,
              child: Text(
                user.userId ?? '-',
                style: AppTextStyles.bodyMedium(
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Name
            Expanded(
              flex: 20,
              child: Text(
                user.name,
                style: AppTextStyles.bodyMedium(color: colorScheme.onSurface),
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
                  color: colorScheme.onSurfaceVariant,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            // Role - Badge Style
            Expanded(
              flex: 15,
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.primaryLight.withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: AppTheme.primaryDark.withValues(alpha: 0.2),
                      ),
                    ),
                    child: Text(
                      user.role.replaceFirst(
                        user.role[0],
                        user.role[0].toUpperCase(),
                      ),
                      style: AppTextStyles.labelSmall(
                        color: AppTheme.primaryDark,
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
              ),
            ),
            // Status - Badge Style
            Expanded(
              flex: 15,
              child: Row(
                mainAxisAlignment: .center,
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(
                        color: user.isActive
                            ? const Color(0xFF4CAF50).withValues(alpha: 0.3)
                            : const Color(0xFFFF6B6B).withValues(alpha: 0.3),
                      ),
                    ),
                    child: Text(
                      user.isActive ? 'Active' : 'Suspended',
                      style: AppTextStyles.labelSmall(
                        color: user.isActive
                            ? const Color(0xFF4CAF50)
                            : const Color(0xFFFF6B6B),
                        fontWeight: FontWeight.w600,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                ],
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
                  // Admin users are protected: no Edit / Suspend / Delete so an
                  // admin account can't be changed or removed by mistake.
                  if (user.role != 'admin') ...[
                    const SizedBox(width: 8),
                    TextButton(
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (_) => BlocProvider.value(
                            value: context.read<UserListBloc>(),
                            child: UserEditDialog(user: user),
                          ),
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
                          child: Text(user.isActive ? 'Suspend' : 'Activate'),
                        ),
                        const PopupMenuItem(
                          value: 'delete',
                          child: Text('Delete'),
                        ),
                      ],
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleFilter(ColorScheme colorScheme) {
    const roles = [
      ('all', 'All Roles'),
      ('admin', 'Admin'),
      ('user', 'User'),
      ('designer', 'Designer'),
    ];
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 12),
      decoration: BoxDecoration(
        color: colorScheme.surfaceContainerHighest,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: colorScheme.outline.withValues(alpha: 0.2)),
      ),
      child: Align(
        alignment: .center,
        child: DropdownButton<String>(
          value: _selectedRoleFilter,
          underline: const SizedBox(),
          isDense: true,
          dropdownColor: colorScheme.surface,
          icon: Icon(
            Icons.filter_list,
            size: 18,
            color: colorScheme.onSurfaceVariant,
          ),
          items: roles
              .map(
                (r) => DropdownMenuItem(
                  value: r.$1,
                  child: Text(
                    r.$2,
                    style: AppTextStyles.bodyMedium(
                      color: colorScheme.onSurface,
                    ),
                  ),
                ),
              )
              .toList(),
          onChanged: (value) {
            if (value == null) return;
            setState(() => _selectedRoleFilter = value);
            context.read<UserListBloc>().add(
              FilterByRoleEvent(value == 'all' ? null : value),
            );
          },
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
            onTap: () =>
                context.read<UserListBloc>().add(GoToPageEvent(pageNum)),
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
                      : Theme.of(context).colorScheme.onSurfaceVariant,
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
