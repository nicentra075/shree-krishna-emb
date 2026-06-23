import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_event.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_state.dart';
import 'package:shree_krishna_emb_admin/core/utils/responsive_snackbar.dart';
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
  late TextEditingController _passwordController;
  late TextEditingController _confirmPasswordController;
  // Profile + designer store fields.
  late TextEditingController _photoUrlController;
  late TextEditingController _storeNameController;
  late TextEditingController _storeImageUrlController;
  late TextEditingController _storeDescriptionController;
  late String _selectedRole;
  late bool _isActive;
  late bool _isAuthorisedSeller;
  late bool _showPassword;
  late bool _showConfirmPassword;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _phoneController = TextEditingController(text: widget.user?.phoneNumber ?? '');
    _passwordController = TextEditingController();
    _confirmPasswordController = TextEditingController();
    _photoUrlController =
        TextEditingController(text: widget.user?.photoUrl ?? '');
    _storeNameController =
        TextEditingController(text: widget.user?.storeName ?? '');
    _storeImageUrlController =
        TextEditingController(text: widget.user?.storeImageUrl ?? '');
    _storeDescriptionController =
        TextEditingController(text: widget.user?.storeDescription ?? '');
    _selectedRole = widget.user?.role ?? 'user';
    _isActive = widget.user?.isActive ?? true;
    _isAuthorisedSeller = widget.user?.isAuthorisedSeller ?? false;
    _showPassword = false;
    _showConfirmPassword = false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    _photoUrlController.dispose();
    _storeNameController.dispose();
    _storeImageUrlController.dispose();
    _storeDescriptionController.dispose();
    super.dispose();
  }

  bool _isValidUrl(String value) {
    final uri = Uri.tryParse(value.trim());
    return uri != null && (uri.isScheme('http') || uri.isScheme('https'));
  }

  String? _trimOrNull(String value) {
    final trimmed = value.trim();
    return trimmed.isEmpty ? null : trimmed;
  }

  /// Validates the optional designer image URLs; shows an error and returns
  /// false if a non-empty URL is malformed.
  bool _validateDesignerUrls(BuildContext context) {
    final photo = _photoUrlController.text.trim();
    final storeImg = _storeImageUrlController.text.trim();
    if (photo.isNotEmpty && !_isValidUrl(photo)) {
      ResponsiveSnackbar.showError(
          'Enter a valid Profile Image URL (http/https)', context);
      return false;
    }
    if (storeImg.isNotEmpty && !_isValidUrl(storeImg)) {
      ResponsiveSnackbar.showError(
          'Enter a valid Store Image URL (http/https)', context);
      return false;
    }
    return true;
  }

  bool _isValidEmail(String value) {
    final regex = RegExp(r'^[\w.+-]+@([\w-]+\.)+[\w-]{2,}$');
    return regex.hasMatch(value.trim());
  }

  /// Accepts an optional leading '+' followed by 10–15 digits
  /// (e.g. +911234567890 or 9876543210).
  bool _isValidPhone(String value) {
    final regex = RegExp(r'^\+?[0-9]{10,15}$');
    return regex.hasMatch(value.trim());
  }

  /// Role options for the dropdown. 'admin' is intentionally NOT offered so it
  /// can't be assigned from the panel. If the user being edited is already an
  /// admin, their current role is kept (and shown) so the dropdown stays valid.
  List<String> get _roleOptions {
    final options = <String>['user', 'designer'];
    if (!options.contains(_selectedRole)) {
      options.insert(0, _selectedRole);
    }
    return options;
  }

  @override
  Widget build(BuildContext context) {
    final isCreateMode = widget.user == null;
    final colorScheme = Theme.of(context).colorScheme;

    return BlocListener<UserListBloc, UserListState>(
      listener: (context, state) {
        if (state is UserActionSuccess && isCreateMode) {
          Navigator.pop(context);
        }
      },
      child: Dialog(
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
                  color: colorScheme.onSurfaceVariant,
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
                // Email is the auth identifier — not editable after creation.
                enabled: isCreateMode,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Phone Number',
                hint: 'Enter phone number',
                controller: _phoneController,
                keyboardType: TextInputType.phone,
              ),
              const SizedBox(height: 16),
              // Password fields (only in create mode)
              if (isCreateMode) ...[
                AppTextField(
                  label: 'Password',
                  hint: 'Enter password',
                  controller: _passwordController,
                  obscureText: !_showPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: GestureDetector(
                    onTap: () => setState(() => _showPassword = !_showPassword),
                    child: Icon(
                      _showPassword ? Icons.visibility : Icons.visibility_off,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                AppTextField(
                  label: 'Confirm Password',
                  hint: 'Confirm password',
                  controller: _confirmPasswordController,
                  obscureText: !_showConfirmPassword,
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: GestureDetector(
                    onTap: () =>
                        setState(() => _showConfirmPassword = !_showConfirmPassword),
                    child: Icon(
                      _showConfirmPassword
                          ? Icons.visibility
                          : Icons.visibility_off,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
              ],
              // Role Dropdown
              Container(
                decoration: BoxDecoration(
                  border: Border.all(
                    color: colorScheme.outline.withValues(alpha: 0.4),
                  ),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: DropdownButton<String>(
                  isExpanded: true,
                  underline: const SizedBox(),
                  value: _selectedRole,
                  dropdownColor: colorScheme.surface,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  items: _roleOptions
                      .map((role) => DropdownMenuItem(
                            value: role,
                            child: Text(
                              role.replaceFirst(
                                role[0],
                                role[0].toUpperCase(),
                              ),
                              style: AppTextStyles.bodyMedium(
                                color: colorScheme.onSurface,
                              ),
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
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
              const SizedBox(height: 16),
              // ---- Designer-only store details -------------------------------
              // Shown only when the selected role is 'designer'. These power the
              // user app's "Authorised Design Sellers" section.
              if (_selectedRole == 'designer') ...[
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppTheme.primaryLight.withValues(alpha: 0.05),
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(
                      color: AppTheme.primaryLight.withValues(alpha: 0.2),
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Designer Store Details',
                        style: AppTextStyles.labelMedium(
                          color: AppTheme.primaryDark,
                          fontWeight: FontWeight.w700,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Profile Image URL',
                        hint: 'https://...',
                        controller: _photoUrlController,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Store Name',
                        hint: 'Enter store name',
                        controller: _storeNameController,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Store Image URL',
                        hint: 'https://...',
                        controller: _storeImageUrlController,
                        keyboardType: TextInputType.url,
                      ),
                      const SizedBox(height: 12),
                      AppTextField(
                        label: 'Store Description',
                        hint: 'Describe the store',
                        controller: _storeDescriptionController,
                        maxLines: 3,
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
                                  'Authorised Seller',
                                  style: AppTextStyles.labelMedium(
                                    color: colorScheme.onSurface,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  'List this designer under Authorised Design Sellers',
                                  style: AppTextStyles.bodySmall(
                                    color: colorScheme.onSurfaceVariant,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ],
                            ),
                          ),
                          Switch(
                            value: _isAuthorisedSeller,
                            onChanged: (value) {
                              setState(() => _isAuthorisedSeller = value);
                            },
                            activeThumbColor: AppTheme.primaryDark,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],
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
                              color: colorScheme.onSurfaceVariant,
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
              // Password reset (edit mode). The admin can't set another user's
              // password directly on the current backend, so we send a reset
              // email and the user chooses their own new password.
              if (!isCreateMode) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () {
                      context.read<UserListBloc>().add(
                            SendPasswordResetEvent(widget.user!.email),
                          );
                      Navigator.pop(context);
                    },
                    icon: const Icon(Icons.lock_reset, size: 18),
                    label: const Text('Send password reset email'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppTheme.primaryDark,
                      side: BorderSide(
                        color: AppTheme.primaryDark.withValues(alpha: 0.4),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                    ),
                  ),
                ),
              ],
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
                          // Validate form
                          if (_nameController.text.isEmpty) {
                            ResponsiveSnackbar.showError(
                                'Please enter user name', context);
                            return;
                          }
                          if (_emailController.text.isEmpty) {
                            ResponsiveSnackbar.showError(
                                'Please enter email', context);
                            return;
                          }
                          if (!_isValidEmail(_emailController.text)) {
                            ResponsiveSnackbar.showError(
                                'Please enter a valid email address', context);
                            return;
                          }
                          if (_phoneController.text.isEmpty) {
                            ResponsiveSnackbar.showError(
                                'Please enter phone number', context);
                            return;
                          }
                          if (!_isValidPhone(_phoneController.text)) {
                            ResponsiveSnackbar.showError(
                                'Enter a valid phone number (10–15 digits, optional +)',
                                context);
                            return;
                          }
                          if (_passwordController.text.isEmpty) {
                            ResponsiveSnackbar.showError(
                                'Please enter password', context);
                            return;
                          }
                          if (_passwordController.text.length < 6) {
                            ResponsiveSnackbar.showError(
                                'Password must be at least 6 characters',
                                context);
                            return;
                          }
                          if (_passwordController.text != _confirmPasswordController.text) {
                            ResponsiveSnackbar.showError(
                                'Passwords do not match', context);
                            return;
                          }
                          if (_selectedRole == 'designer' &&
                              !_validateDesignerUrls(context)) {
                            return;
                          }

                          // Create user
                          context.read<UserListBloc>().add(CreateUserEvent(
                            name: _nameController.text,
                            email: _emailController.text,
                            password: _passwordController.text,
                            phoneNumber: _phoneController.text,
                            role: _selectedRole,
                            photoUrl: _trimOrNull(_photoUrlController.text),
                            storeName: _trimOrNull(_storeNameController.text),
                            storeImageUrl:
                                _trimOrNull(_storeImageUrlController.text),
                            storeDescription:
                                _trimOrNull(_storeDescriptionController.text),
                            isAuthorisedSeller: _isAuthorisedSeller,
                          ));
                          Navigator.pop(context);
                        } else {
                          if (_nameController.text.isEmpty) {
                            ResponsiveSnackbar.showError(
                                'Please enter user name', context);
                            return;
                          }
                          if (_phoneController.text.isNotEmpty &&
                              !_isValidPhone(_phoneController.text)) {
                            ResponsiveSnackbar.showError(
                                'Enter a valid phone number (10–15 digits, optional +)',
                                context);
                            return;
                          }
                          if (_selectedRole == 'designer' &&
                              !_validateDesignerUrls(context)) {
                            return;
                          }

                          final isDesigner = _selectedRole == 'designer';
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
                            // Profile image is editable for designers; preserved
                            // otherwise.
                            photoUrl: isDesigner
                                ? _trimOrNull(_photoUrlController.text)
                                : widget.user!.photoUrl,
                            loginAt: widget.user!.loginAt,
                            logoutAt: widget.user!.logoutAt,
                            // Store fields only persist for designers; cleared if
                            // the role is changed away from designer.
                            storeName: isDesigner
                                ? _trimOrNull(_storeNameController.text)
                                : null,
                            storeImageUrl: isDesigner
                                ? _trimOrNull(_storeImageUrlController.text)
                                : null,
                            storeDescription: isDesigner
                                ? _trimOrNull(_storeDescriptionController.text)
                                : null,
                            isAuthorisedSeller:
                                isDesigner ? _isAuthorisedSeller : false,
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
    ),
  );
}
}
