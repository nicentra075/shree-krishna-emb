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
              Row(
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundImage: user.photoUrl != null && user.photoUrl!.isNotEmpty
                        ? NetworkImage(user.photoUrl!)
                        : null,
                    child: user.photoUrl == null || user.photoUrl!.isEmpty
                        ? Text(user.name.isNotEmpty ? user.name[0].toUpperCase() : '?')
                        : null,
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          user.name,
                          style: AppTextStyles.headlineMedium(
                            color: AppTheme.primaryDark,
                            fontWeight: FontWeight.w700,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: user.isActive
                          ? const Color(0xFF4CAF50).withValues(alpha: 0.15)
                          : const Color(0xFFFF6B6B).withValues(alpha: 0.15),
                      borderRadius: BorderRadius.circular(4),
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
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              Divider(
                  color: Theme.of(context).colorScheme.outline.withValues(
                        alpha: 0.2,
                      )),
              const SizedBox(height: 24),
              // Account Details Section
              Text(
                'Account Details',
                style: AppTextStyles.labelMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(context, 'User ID', user.id),
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Email', user.email),
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Phone Number', user.phoneNumber ?? 'N/A'),
              // Designer store details
              if (user.role == 'designer') ...[
                const SizedBox(height: 24),
                Divider(
                    color: Theme.of(context).colorScheme.outline.withValues(
                          alpha: 0.2,
                        )),
                const SizedBox(height: 24),
                Text(
                  'Designer Store',
                  style: AppTextStyles.labelMedium(
                    color: AppTheme.primaryDark,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 12),
                _buildDetailRow(context, 'Store Name', user.storeName ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailRow(
                    context, 'Store Image URL', user.storeImageUrl ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailRow(
                    context, 'Store Description', user.storeDescription ?? 'N/A'),
                const SizedBox(height: 12),
                _buildDetailRow(context, 'Authorised Seller',
                    user.isAuthorisedSeller ? 'Yes' : 'No'),
              ],
              const SizedBox(height: 24),
              Divider(
                  color: Theme.of(context).colorScheme.outline.withValues(
                        alpha: 0.2,
                      )),
              const SizedBox(height: 24),
              // Activity Details Section
              Text(
                'Activity',
                style: AppTextStyles.labelMedium(
                  color: AppTheme.primaryDark,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 12),
              _buildDetailRow(context, 'Login Method', user.loginMethod ?? 'N/A'),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'First Login',
                user.loginAt != null ? _formatDateTime(user.loginAt!) : 'Never',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Last Logout',
                user.logoutAt != null ? _formatDateTime(user.logoutAt!) : 'N/A',
              ),
              const SizedBox(height: 12),
              _buildDetailRow(
                context,
                'Account Created',
                _formatDateTime(user.createdAt),
              ),
              const SizedBox(height: 24),
              // Close Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () => Navigator.pop(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryDark,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                  child: Text(
                    'Close',
                    style: AppTextStyles.labelMedium(
                      color: Colors.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(BuildContext context, String label, String value) {
    final colorScheme = Theme.of(context).colorScheme;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: AppTextStyles.labelSmall(
            color: colorScheme.onSurfaceVariant,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: AppTextStyles.bodyMedium(
            color: colorScheme.onSurface,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatDateTime(DateTime date) {
    return '${date.day}/${date.month}/${date.year} ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}
