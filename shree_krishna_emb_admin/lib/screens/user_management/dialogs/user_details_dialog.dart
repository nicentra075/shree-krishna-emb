import 'package:flutter/material.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';
import 'package:shree_krishna_emb_admin/data/models/user_list_item_model.dart';
import 'package:shree_krishna_emb_admin/theme/app_theme.dart';

class UserDetailsDialog extends StatelessWidget {
  final UserListItemModel user;

  const UserDetailsDialog({
    super.key,
    required this.user,
  });

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('User Details'),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildDetailRow('Name', user.name),
            const SizedBox(height: 16),
            _buildDetailRow('Email', user.email),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Role',
              user.role.replaceFirst(
                user.role[0],
                user.role[0].toUpperCase(),
              ),
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Status',
              user.isActive ? 'Active' : 'Suspended',
            ),
            const SizedBox(height: 16),
            _buildDetailRow(
              'Created At',
              _formatDate(user.createdAt),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Close'),
        ),
      ],
    );
  }

  Widget _buildDetailRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(
            color: AppTheme.textBrown.withValues(alpha: 0.6),
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            color: AppTheme.textDark,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDate(DateTime date) {
    return '${date.day}/${date.month}/${date.year}';
  }
}
