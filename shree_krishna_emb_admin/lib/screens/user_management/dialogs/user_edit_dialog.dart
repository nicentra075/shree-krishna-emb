import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_bloc.dart';
import 'package:shree_krishna_emb_admin/bloc/user_management/user_list_event.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';

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
  late String _selectedRole;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.user?.name ?? '');
    _emailController = TextEditingController(text: widget.user?.email ?? '');
    _selectedRole = widget.user?.role ?? 'user';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isCreateMode = widget.user == null;

    return AlertDialog(
      title: Text(isCreateMode ? 'Add User' : 'Edit User'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            AppTextField(
              label: 'Name',
              hint: 'Enter user name',
              controller: _nameController,
            ),
            const SizedBox(height: 16),
            AppTextField(
              label: 'Email',
              hint: 'Enter user email',
              controller: _emailController,
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              initialValue: _selectedRole,
              decoration: InputDecoration(
                labelText: 'Role',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              items: ['admin', 'user', 'designer']
                  .map((role) => DropdownMenuItem(
                        value: role,
                        child: Text(
                          role.replaceFirst(
                            role[0],
                            role[0].toUpperCase(),
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
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: () {
            if (isCreateMode) {
              // For add user: refresh the list (future: implement proper create)
              AppSnackbar.showSuccess('User creation functionality coming soon');
              context.read<UserListBloc>().add(const RefreshUsersEvent());
              Navigator.pop(context);
            } else {
              // Edit existing user
              final updatedUser = UserListItemModel(
                id: widget.user!.id,
                name: _nameController.text,
                email: _emailController.text,
                role: _selectedRole,
                isActive: widget.user!.isActive,
                createdAt: widget.user!.createdAt,
              );

              context
                  .read<UserListBloc>()
                  .add(EditUserEvent(updatedUser));
              Navigator.pop(context);
            }
          },
          child: Text(isCreateMode ? 'Create' : 'Save'),
        ),
      ],
    );
  }
}
