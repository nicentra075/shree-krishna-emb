import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shree_krishna_core/enums/app_notification_type.dart';
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
                        AppSnackbar.showError(
                          AppLocalization.strings.notificationDeleted,
                          customIcon: Icons.delete_outline,
                        );
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
    final badge = _badgeFor(item.type, colorScheme);
    final horizontalPad = isSmallScreen ? 12.0 : 16.0;

    return Dismissible(
      key: ValueKey(item.id),
      direction: DismissDirection.endToStart,
      background: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: colorScheme.error,
          borderRadius: BorderRadius.circular(16),
        ),
        alignment: Alignment.centerRight,
        padding: EdgeInsets.symmetric(horizontal: isSmallScreen ? 16 : 20),
        child: Icon(Icons.delete_outline, color: colorScheme.onError),
      ),
      onDismissed: (_) => onDismissed(),
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        decoration: BoxDecoration(
          color: item.read
              ? colorScheme.surfaceContainerLow
              : colorScheme.primaryContainer.withValues(alpha: 0.22),
          borderRadius: BorderRadius.circular(16),
        ),
        clipBehavior: Clip.antiAlias,
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: EdgeInsets.symmetric(
                horizontal: horizontalPad,
                vertical: 12,
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Container(
                    width: isSmallScreen ? 36 : 42,
                    height: isSmallScreen ? 36 : 42,
                    decoration: BoxDecoration(
                      color: badge.background,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      badge.icon,
                      color: badge.foreground,
                      size: isSmallScreen ? 18 : 20,
                    ),
                  ),
                  SizedBox(width: isSmallScreen ? 8 : 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(
                              child: Text(
                                item.title,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelLarge(
                                  color: colorScheme.onSurface,
                                  fontWeight: item.read
                                      ? FontWeight.normal
                                      : FontWeight.w600,
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
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
                        const SizedBox(height: 4),
                        Text(
                          item.body,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: AppTextStyles.bodySmall(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!item.read) ...[
                    SizedBox(width: isSmallScreen ? 4 : 8),
                    Padding(
                      padding: const EdgeInsets.only(top: 4),
                      child: Container(
                        width: 8,
                        height: 8,
                        decoration: BoxDecoration(
                          color: colorScheme.error,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  /// Icon + tint colors for the leading type badge, derived from the theme's
  /// color scheme so the tile stays theme-aware in light and dark mode.
  ({IconData icon, Color background, Color foreground}) _badgeFor(
    AppNotificationType type,
    ColorScheme colorScheme,
  ) {
    switch (type) {
      case AppNotificationType.newDesign:
        return (
          icon: Icons.auto_awesome,
          background: colorScheme.primaryContainer,
          foreground: colorScheme.onPrimaryContainer,
        );
      case AppNotificationType.purchase:
        return (
          icon: Icons.shopping_bag_outlined,
          background: colorScheme.secondaryContainer,
          foreground: colorScheme.onSecondaryContainer,
        );
      case AppNotificationType.broadcast:
        return (
          icon: Icons.campaign_outlined,
          background: colorScheme.tertiaryContainer,
          foreground: colorScheme.onTertiaryContainer,
        );
    }
  }

  String _formatTimestamp(DateTime dt) {
    final now = DateTime.now();
    final diff = now.difference(dt);
    if (diff.inMinutes < 1) return AppLocalization.strings.timestampJustNow;
    if (diff.inHours < 1) return AppLocalization.strings.timeAgoMinutes(diff.inMinutes);
    if (diff.inDays < 1) return AppLocalization.strings.timeAgoHours(diff.inHours);
    if (diff.inDays < 7) return AppLocalization.strings.timeAgoDays(diff.inDays);
    return '${dt.day}/${dt.month}/${dt.year}';
  }
}
