import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_event.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class UserEditDialog extends StatefulWidget {
  final UserListItemModel? user;

  const UserEditDialog({
    super.key,
    this.user,
  });

  @override
  State<UserEditDialog> createState() => _UserEditDialogState();
}

class _UserEditDialogState extends State<UserEditDialog> {
  late TextEditingController _nameController;
  late TextEditingController _emailController;
  late TextEditingController _phoneController;
  late String _selectedRole;
  late bool _isActive;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _selectedRole = widget.user?.role ?? 'user';
    _isActive = widget.user?.isActive ?? true;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreateMode = widget.user == null;

    return Dialog(
      child: Container(
        width: 500,
        padding: const EdgeInsets.all(24),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Text(
                isCreateMode ? 'Add New User' : 'Edit User',
                style: AppTextStyles.headlineMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                isCreateMode
                    ? 'Fill in the user details to create a new account'
                    : 'Update the user information below',
                style: AppTextStyles.bodyMedium(
                  color: AppTheme.textBrown.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 24),
              // Form Fields
              AppTextField(
                label: 'Full Name',
                hint: 'Enter user name',
                controller: _nameController,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Email Address',
                hint: 'Enter user email',
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Role Dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _selectedRole,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  items: ['admin', 'user', 'designer']
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role.replaceFirst(
                                role[0],
                                role[0].toUpperCase(),
                              ),
                              style: AppTextStyles.bodyMedium(),
                            ),
                          ))
                      .toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedRole = value);
                    }
                  },
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'Role',
                style: AppTextStyles.labelSmall(
                  color: AppTheme.textBrown.withValues(alpha: 0.6),
                ),
              ),
              const SizedBox(height: 16),
              // Status Toggle (only show for edit mode)
              if (!isCreateMode)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Account Status',
                            style: AppTextStyles.labelMedium(
                              color: AppTheme.primaryDark,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            _isActive ? 'Active' : 'Suspended',
                            style: AppTextStyles.bodySmall(
                              color: AppTheme.textBrown.withValues(alpha: 0.6),
                            ),
                          ),
                        ],
                      ),
                      Switch(
                        value: _isActive,
                        onChanged: (value) {
                          setState(() => _isActive = value);
                        },
                        activeThumbColor: const Color(0xFF4CAF50),
                        inactiveThumbColor: const Color(0xFFFF6B6B),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 24),
              // Action Buttons
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      style: TextButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        'Cancel',
                        style: AppTextStyles.labelMedium(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        if (isCreateMode) {
                          AppSnackbar.showSuccess('User creation functionality coming soon');
                          context.read<UserListBloc>().add(const RefreshUsersEvent());
                          Navigator.pop(context);
                        } else {
                          final updatedUser = UserListItemModel(
                            id: widget.user!.id,
                            name: _nameController.text,
                            email: _emailController.text,
                            role: _selectedRole,
                            isActive: _isActive,
                            createdAt: widget.user!.createdAt,
                            userId: widget.user!.userId,
                            phoneNumber: _phoneController.text.isNotEmpty ? _phoneController.text : null,
                            loginMethod: widget.user!.loginMethod,
                            photoUrl: widget.user!.photoUrl,
                            loginAt: widget.user!.loginAt,
                            logoutAt: widget.user!.logoutAt,
                          );

                          context.read<UserListBloc>().add(EditUserEvent(updatedUser));
                          Navigator.pop(context);
                        }
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.primaryDark,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                      ),
                      child: Text(
                        isCreateMode ? 'Create User' : 'Save Changes',
                        style: AppTextStyles.labelMedium(
                          color: Colors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
