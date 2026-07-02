import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/models/app_notification_model.dart';
import 'package:shree_krishna_design_system/shree_krishna_design_system.dart';

import '../../bloc/notifications/notification_cubit.dart';
import '../../bloc/notifications/notification_state.dart';
import '../../localisations/app_localization.dart';
import '../../routes/app_routes.dart';

/// In-app notification center. Reads the app-wide [NotificationCubit] and
/// lets the user mark items read, swipe-delete, or tap through to the
/// related design.
class NotificationsScreen extends StatelessWidget {
  const NotificationsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppLocalization.strings;

    return Scaffold(
      appBar: AppAppBar(
        title: strings.notifications,
        onBack: () => Navigator.pop(context),
        actions: [
          BlocBuilder<NotificationCubit, NotificationState>(
            buildWhen: (prev, curr) => prev.unreadCount != curr.unreadCount,
            builder: (context, state) {
              if (state.unreadCount == 0) return const SizedBox.shrink();
              return TextButton(
                onPressed: () => context.read<NotificationCubit>().markAllRead(),
                child: Text(
                  strings.markAllRead,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              );
            },
          ),
        ],
      ),
      body: SafeArea(
        child: BlocBuilder<NotificationCubit, NotificationState>(
          builder: (context, state) {
            if (state.status == NotificationStatus.loading &&
                state.items.isEmpty) {
              return const Center(child: AppLoader());
            }

            if (state.items.isEmpty) {
              return AppEmptyState(
                icon: Icons.notifications_none,
                message: strings.noNotifications,
                subtitle: strings.notificationsEmptyHint,
              );
            }

            return LayoutBuilder(
              builder: (context, constraints) {
                final isSmallScreen = constraints.maxWidth < 400;
                return ListView.separated(
                  padding: EdgeInsets.symmetric(
                    horizontal: isSmallScreen ? 8 : 16,
                    vertical: 8,
                  ),
                  itemCount: state.items.length,
                  separatorBuilder: (context, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final item = state.items[index];
                    return _NotificationTile(
                      item: item,
                      isSmallScreen: isSmallScreen,
                      onDismissed: () {
                        context.read<NotificationCubit>().delete(item.id);
                        AppSnackbar.showInfo(strings.deleteNotification);
                      },
                      onTap: () {
                        context.read<NotificationCubit>().markRead(item.id);
                        final designId = item.designId;
                        if (designId != null && designId.isNotEmpty) {
                          AppRoutes.navigateToDesignDetail(context, designId);
                        }
                      },
                    );
                  },
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class _NotificationTile extends StatelessWidget {
  final AppNotificationModel item;
  final bool isSmallScreen;
  final VoidCallback onDismissed;
  final VoidCallback onTap;

  const _NotificationTile({
    required this.item,
    required this.isSmallScreen,
    required this.onDismissed,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        color: colorScheme.errorContainer,
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 12 : 20),
        child: Icon(Icons.delete_outline, color: colorScheme.onErrorContainer),
      ),
      onDismissed: (_) => onDismissed(),
      child: Material(
        color: item.read
            ? Colors.transparent
            : colorScheme.primaryContainer.withValues(alpha: 0.18),
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: EdgeInsets.symmetric(
              horizontal: isSmallScreen ? 12 : 16,
              vertical: 12,
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  item.read
                      ? Icons.notifications_none
                      : Icons.notifications_active,
                  color: item.read ? colorScheme.outline : colorScheme.primary,
                  size: isSmallScreen ? 20 : 24,
                ),
                SizedBox(width: isSmallScreen ? 8 : 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.title,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelMedium(
                          color: colorScheme.onSurface,
                          fontWeight:
                              item.read ? FontWeight.normal : FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        item.body,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.bodySmall(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _formatTimestamp(item.createdAt),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall(
                          color: colorScheme.outline,
                        ),
                      ),
                    ],
                  ),
                ),
                if (!item.read) ...[
                  SizedBox(width: isSmallScreen ? 4 : 8),
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: colorScheme.error,
                      shape: BoxShape.circle,
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return 'now';
    if (diff.inHours < 1) return '${diff.inMinutes}m';
    if (diff.inDays < 1) return '${diff.inHours}h';
    if (diff.inDays < 7) return '${diff.inDays}d';
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
